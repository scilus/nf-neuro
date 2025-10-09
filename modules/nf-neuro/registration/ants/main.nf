
process REGISTRATION_ANTS {
    tag "$meta.id"
    label 'process_medium'

    container "scilus/scilus:2.2.0"

    input:
    tuple val(meta), path(fixedimage), path(movingimage), path(mask) /* optional, input = [] */

    output:
    tuple val(meta), path("*_warped.nii.gz")                        , emit: image
    tuple val(meta), path("*__output0GenericAffine.mat")             , emit: affine
    tuple val(meta), path("*__output1InverseAffine.mat")            , emit: inverse_affine
    tuple val(meta), path("*__output1Warp.nii.gz")                  , emit: warp, optional:true
    tuple val(meta), path("*__output0InverseWarp.nii.gz")           , emit: inverse_warp, optional: true
    tuple val(meta), path("*_registration_ants_mqc.gif")            , emit: mqc, optional: true
    path "versions.yml"                                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix_qc = task.ext.suffix_qc ? "${task.ext.suffix_qc}" : ""
    def ants = task.ext.quick ? "antsRegistrationSyNQuick.sh " :  "antsRegistrationSyN.sh "
    def dimension = task.ext.dimension ? "-d " + task.ext.dimension : "-d 3"
    def transform = task.ext.transform ? task.ext.transform : "s"
    def seed = task.ext.random_seed ? " -e " + task.ext.random_seed : "-e 1234"
    def run_qc = task.ext.run_qc ? task.ext.run_qc : false

    if ( task.ext.threads ) args += "-n " + task.ext.threads
    if ( task.ext.initial_transform ) args += " -i " + task.ext.initial_transform
    if ( task.ext.histogram_bins ) args += " -r " + task.ext.histogram_bins
    if ( task.ext.spline_distance ) args += " -s " + task.ext.spline_distance
    if ( task.ext.gradient_step ) args += " -g " + task.ext.gradient_step
    if ( task.ext.mask ) args += " -x $mask"
    if ( task.ext.type ) args += " -p " + task.ext.type
    if ( task.ext.histogram_matching ) args += " -j " + task.ext.histogram_matching
    if ( task.ext.repro_mode ) args += " -y " + task.ext.repro_mode
    if ( task.ext.collapse_output ) args += " -z " + task.ext.collapse_output

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$task.cpus
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1

    $ants $dimension -f $fixedimage -m $movingimage -o output -t $transform $args $seed

    mv outputWarped.nii.gz ${prefix}__warped.nii.gz
    mv output0GenericAffine.mat ${prefix}__output0GenericAffine.mat

    if [ $transform != "t" ] && [ $transform != "r" ] && [ $transform != "a" ];
    then
        mv output1InverseWarp.nii.gz ${prefix}__output0InverseWarp.nii.gz
        mv output1Warp.nii.gz ${prefix}__output1Warp.nii.gz
    fi

    antsApplyTransforms -d 3 -i $fixedimage -r $movingimage \
                        -o Linear[${prefix}__output1InverseAffine.mat] \
                        -t [${prefix}__output0GenericAffine.mat,1]

    ### ** QC ** ###
    if $run_qc;
    then
        mv $fixedimage fixedimage.nii.gz
        extract_dim=\$(mrinfo fixedimage.nii.gz -size)
        read sagittal_dim coronal_dim axial_dim <<< "\${extract_dim}"

        # Get the middle slice
        coronal_dim=\$((\$coronal_dim / 2))
        axial_dim=\$((\$axial_dim / 2))
        sagittal_dim=\$((\$sagittal_dim / 2))

        # Set viz params.
        viz_params="--display_slice_number --display_lr --size 256 256"
        # Iterate over images.
        for image in fixedimage warped;
        do
            mrconvert *\${image}.nii.gz *\${image}_viz.nii.gz -stride -1,2,3
            scil_viz_volume_screenshot *\${image}_viz.nii.gz \${image}_coronal.png \
                --slices \$coronal_dim --axis coronal \$viz_params
            scil_viz_volume_screenshot *\${image}_viz.nii.gz \${image}_sagittal.png \
                --slices \$sagittal_dim --axis sagittal \$viz_params
            scil_viz_volume_screenshot *\${image}_viz.nii.gz \${image}_axial.png \
                --slices \$axial_dim --axis axial \$viz_params
            if [ \$image != fixedimage ];
            then
                title="T1 Warped"
            else
                title="fixedimage"
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
            warped_mosaic.png fixedimage_mosaic.png warped_mosaic.png \
            ${prefix}_${suffix_qc}_registration_ants_mqc.gif
        # Clean up.
        rm *_mosaic.png
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
        ants: \$(antsRegistration --version | grep "Version" | sed -E 's/.*: v?([0-9.a-zA-Z-]+).*/\\1/')
        mrtrix: \$(mrinfo -version 2>&1 | grep "== mrinfo" | sed -E 's/== mrinfo ([0-9.]+).*/\\1/')
        imagemagick: \$(convert -version | grep "Version:" | sed -E 's/.*ImageMagick ([0-9.-]+).*/\\1/')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    set +e
    function handle_code () {
    local code=\$?
    ignore=( 1 )
    [[ " \${ignore[@]} " =~ " \$code " ]] || exit \$code
    }
    trap 'handle_code' ERR

    antsRegistrationSyNQuick.sh -h
    antsApplyTransforms -h
    convert -h
    scil_viz_volume_screenshot -h

    touch ${prefix}__t1_warped.nii.gz
    touch ${prefix}__output0GenericAffine.mat
    touch ${prefix}__output1InverseAffine.mat
    touch ${prefix}__output0InverseWarp.nii.gz
    touch ${prefix}__output1Warp.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
        ants: \$(antsRegistration --version | grep "Version" | sed -E 's/.*: v?([0-9.a-zA-Z-]+).*/\\1/')
        mrtrix: \$(mrinfo -version 2>&1 | grep "== mrinfo" | sed -E 's/== mrinfo ([0-9.]+).*/\\1/')
        imagemagick: \$(convert -version | grep "Version:" | sed -E 's/.*ImageMagick ([0-9.-]+).*/\\1/')
    END_VERSIONS
    """
}
