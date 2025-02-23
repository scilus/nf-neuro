process REGISTRATION_ANATTODWI {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:latest' }"

    input:
    tuple val(meta), path(t1), path(b0), path(metric)

    output:
    tuple val(meta), path("*0GenericAffine.mat")                                , emit: affine
    tuple val(meta), path("*1Warp.nii.gz")                                      , emit: warp
    tuple val(meta), path("*1InverseWarp.nii.gz")                               , emit: inverse_warp
    tuple val(meta), path("*t1_warped.nii.gz")                                  , emit: t1_warped
    tuple val(meta), path("*_registration_anattodwi_mqc.gif")                   , emit: mqc, optional: true
    path "versions.yml"                                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    def run_qc = task.ext.run_qc ? task.ext.run_qc : false

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$task.cpus
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1
    export ANTS_RANDOM_SEED=1234

    antsRegistration --dimensionality 3 --float 0\
        --output [output,outputWarped.nii.gz,outputInverseWarped.nii.gz]\
        --interpolation Linear --use-histogram-matching 0\
        --winsorize-image-intensities [0.005,0.995]\
        --initial-moving-transform [$b0,$t1,1]\
        --transform Rigid['0.2']\
        --metric MI[$b0,$t1,1,32,Regular,0.25]\
        --convergence [500x250x125x50,1e-6,10] --shrink-factors 8x4x2x1\
        --smoothing-sigmas 3x2x1x0\
        --transform Affine['0.2']\
        --metric MI[$b0,$t1,1,32,Regular,0.25]\
        --convergence [500x250x125x50,1e-6,10] --shrink-factors 8x4x2x1\
        --smoothing-sigmas 3x2x1x0\
        --transform SyN[0.1,3,0]\
        --metric MI[$b0,$t1,1,32]\
        --metric CC[$metric,$t1,1,4]\
        --convergence [50x25x10,1e-6,10] --shrink-factors 4x2x1\
        --smoothing-sigmas 3x2x1

    mv outputWarped.nii.gz ${prefix}__t1_warped.nii.gz
    mv output0GenericAffine.mat ${prefix}__output0GenericAffine.mat
    mv output1InverseWarp.nii.gz ${prefix}__output1InverseWarp.nii.gz
    mv output1Warp.nii.gz ${prefix}__output1Warp.nii.gz

    ### ** QC ** ###
    if $run_qc;
    then
        # Extract dimensions.
        dim=\$(mrinfo ${prefix}__t1_warped.nii.gz -size)
        read sagittal_dim coronal_dim axial_dim <<< "\${dim}"

        # Get middle slices.
        coronal_mid=\$((\$coronal_dim / 2))
        sagittal_mid=\$((\$sagittal_dim / 2))
        axial_mid=\$((\$axial_dim / 2))

        # Set viz params.
        viz_params="--display_slice_number --display_lr --size 256 256"

        # Iterate over images.
        for image in t1_warped b0;
        do
            scil_viz_volume_screenshot.py *\${image}.nii.gz \${image}_coronal.png \
                --slices \$coronal_mid --axis coronal \$viz_params
            scil_viz_volume_screenshot.py *\${image}.nii.gz \${image}_sagittal.png \
                --slices \$sagittal_mid --axis sagittal \$viz_params
            scil_viz_volume_screenshot.py *\${image}.nii.gz \${image}_axial.png \
                --slices \$axial_mid --axis axial \$viz_params

            if [ \$image != b0 ];
            then
                title="Warped T1"
            else
                title="Reference B0"
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
            t1_warped_mosaic.png b0_mosaic.png t1_warped_mosaic.png \
            ${prefix}_registration_anattodwi_mqc.gif

        # Clean up.
        rm t1_warped_mosaic.png b0_mosaic.png
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: \$(antsRegistration --version | grep "Version" | sed -E 's/.*v([0-9]+\\.[0-9]+\\.[0-9]+).*/\\1/')
        mrtrix: \$(mrinfo -version 2>&1 | sed -n 's/== mrinfo \\([0-9.]\\+\\).*/\\1/p')
        imagemagick: \$(convert -version | sed -n 's/.*ImageMagick \\([0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\).*/\\1/p')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    antsRegistration -h

    touch ${prefix}__t1_warped.nii.gz
    touch ${prefix}__output0GenericAffine.mat
    touch ${prefix}__output1InverseWarp.nii.gz
    touch ${prefix}__output1Warp.nii.gz
    touch ${prefix}__registration_anattodwi_mqc.gif

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: \$(antsRegistration --version | grep "Version" | sed -E 's/.*v([0-9]+\\.[0-9]+\\.[0-9]+).*/\\1/')
        mrtrix: \$(mrinfo -version 2>&1 | sed -n 's/== mrinfo \\([0-9.]\\+\\).*/\\1/p')
        imagemagick: \$(convert -version | sed -n 's/.*ImageMagick \\([0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\).*/\\1/p')
    END_VERSIONS
    """
}
