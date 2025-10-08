process REGISTRATION_ANATTODWI {
    tag "$meta.id"
    label 'process_single'

    container "scilus/scilus:2.2.0"

    input:
        tuple val(meta), path(fixed_reference), path(moving_anat), path(metric)

    output:
        tuple val(meta), path("*_warped.nii.gz")                            , emit: anat_warped
        tuple val(meta), path("*__forward1_affine.mat")                     , emit: affine
        tuple val(meta), path("*__forward0_warp.nii.gz")                    , emit: warp
        tuple val(meta), path("*__backward1_warp.nii.gz")                   , emit: inverse_warp
        tuple val(meta), path("*__backward0_affine.mat")                    , emit: inverse_affine
        tuple val(meta), path("*__forward*.{nii.gz,mat}", arity: '1..2')    , emit: image_transform
        tuple val(meta), path("*__backward*.{nii.gz,mat}", arity: '1..2')   , emit: inverse_image_transform
        tuple val(meta), path("*__backward*.{nii.gz,mat}", arity: '1..2')   , emit: tractogram_transform
        tuple val(meta), path("*__forward*.{nii.gz,mat}", arity: '1..2')    , emit: inverse_tractogram_transform
        tuple val(meta), path("*_registration_anattodwi_mqc.gif")           , emit: mqc, optional: true
        path "versions.yml"                                                 , emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def run_qc = task.ext.run_qc as Boolean || false

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$task.cpus
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1
    export ANTS_RANDOM_SEED=1234

    antsRegistration --dimensionality 3 --float 0\
        --output [trans,warped.nii.gz]\
        --interpolation Linear --use-histogram-matching 0\
        --winsorize-image-intensities [0.005,0.995]\
        --initial-moving-transform [$fixed_reference,$moving_anat,1]\
        --transform Rigid['0.2']\
        --metric MI[$fixed_reference,$moving_anat,1,32,Regular,0.25]\
        --convergence [500x250x125x50,1e-6,10] --shrink-factors 8x4x2x1\
        --smoothing-sigmas 3x2x1x0\
        --transform Affine['0.2']\
        --metric MI[$fixed_reference,$moving_anat,1,32,Regular,0.25]\
        --convergence [500x250x125x50,1e-6,10] --shrink-factors 8x4x2x1\
        --smoothing-sigmas 3x2x1x0\
        --transform SyN[0.1,3,0]\
        --metric MI[$fixed_reference,$moving_anat,1,32]\
        --metric CC[$metric,$moving_anat,1,4]\
        --convergence [50x25x10,1e-6,10] --shrink-factors 4x2x1\
        --smoothing-sigmas 3x2x1

    moving_id=\$(basename $moving_anat .nii.gz)
    moving_id=\${moving_id#${meta.id}__*}

    mv warped.nii.gz ${prefix}__\${moving_id}_warped.nii.gz
    mv trans0GenericAffine.mat ${prefix}__forward1_affine.mat
    mv trans1Warp.nii.gz ${prefix}__forward0_warp.nii.gz
    mv trans1InverseWarp.nii.gz ${prefix}__backward1_warp.nii.gz

    antsApplyTransforms -d 3 -i $moving_anat -r $fixed_reference \
        -o Linear[${prefix}__backward0_affine.mat] \
        -t [${prefix}__forward1_affine.mat,1]

    ### ** QC ** ###
    if $run_qc; then
        # Extract dimensions.
        dim=\$(mrinfo ${prefix}__\${moving_id}_warped.nii.gz -size)
        read sagittal_dim coronal_dim axial_dim <<< "\${dim}"

        # Get middle slices.
        coronal_mid=\$((\$coronal_dim / 2))
        sagittal_mid=\$((\$sagittal_dim / 2))
        axial_mid=\$((\$axial_dim / 2))

        # Set viz params.
        viz_params="--display_slice_number --display_lr --size 256 256"

        # Get fixed ID, moving ID already computed
        fixed_id=\$(basename $fixed_reference .nii.gz)
        fixed_id=\${fixed_id#${meta.id}__*}

        # Iterate over images.
        for image in \${moving_id}_warped \${fixed_id}; do
            mrconvert *\${image}.nii.gz *\${image}_viz.nii.gz -stride -1,2,3
            scil_viz_volume_screenshot *\${image}_viz.nii.gz \${image}_coronal.png \
                --slices \$coronal_mid --axis coronal \$viz_params
            scil_viz_volume_screenshot *\${image}_viz.nii.gz \${image}_sagittal.png \
                --slices \$sagittal_mid --axis sagittal \$viz_params
            scil_viz_volume_screenshot *\${image}_viz.nii.gz \${image}_axial.png \
                --slices \$axial_mid --axis axial \$viz_params

            if [ \$image != \${fixed_id} ]; then
                title="Warped \${moving_id^^}"
            else
                title="Reference \${fixed_id^^}"
            fi

            convert +append \${image}_coronal*.png \${image}_axial*.png \
                \${image}_sagittal*.png \${image}_mosaic.png
            convert -annotate +20+230 "\${title}" -fill white -pointsize 30 \
                \${image}_mosaic.png \${image}_mosaic.png

            # Clean up.
            rm \${image}_coronal*.png \${image}_sagittal*.png \${image}_axial*.png
        done

        # Create GIF.
        convert -delay 10 -loop 0 -morph 10 \
            \${moving_id}_warped_mosaic.png \${fixed_id}_mosaic.png \${moving_id}_warped_mosaic.png \
            ${prefix}_registration_anattodwi_mqc.gif

        # Clean up.
        rm \${moving_id}_warped_mosaic.png \${fixed_id}_mosaic.png
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: \$(antsRegistration --version | grep "Version" | sed -E 's/.*: v?([0-9.a-zA-Z-]+).*/\\1/')
        imagemagick: \$(convert -version | grep "Version:" | sed -E 's/.*ImageMagick ([0-9.-]+).*/\\1/')
        mrtrix: \$(mrinfo -version 2>&1 | grep "== mrinfo" | sed -E 's/== mrinfo ([0-9.]+).*/\\1/')
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def run_qc = task.ext.run_qc as Boolean || false

    """
    set +e
    function handle_code () {
        local code=\$?
        ignore=( 1 )
        [[ " \${ignore[@]} " =~ " \$code " ]] || exit \$code
    }
    trap 'handle_code' ERR

    antsRegistration -h
    scil_viz_volume_screenshot -h
    convert -h

    moving_id=\$(basename $moving_anat .nii.gz)
    moving_id=\${moving_id#${meta.id}__*}

    touch ${prefix}__\${moving_id}_warped.nii.gz
    touch ${prefix}__forward1_affine.mat
    touch ${prefix}__forward0_warp.nii.gz
    touch ${prefix}__backward1_warp.nii.gz
    touch ${prefix}__backward0_affine.mat

    if $run_qc; then
        touch ${prefix}__registration_anattodwi_mqc.gif
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: \$(antsRegistration --version | grep "Version" | sed -E 's/.*: v?([0-9.a-zA-Z-]+).*/\\1/')
        imagemagick: \$(convert -version | grep "Version:" | sed -E 's/.*ImageMagick ([0-9.-]+).*/\\1/')
        mrtrix: \$(mrinfo -version 2>&1 | grep "== mrinfo" | sed -E 's/== mrinfo ([0-9.]+).*/\\1/')
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
