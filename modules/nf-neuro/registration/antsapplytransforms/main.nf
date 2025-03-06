process REGISTRATION_ANTSAPPLYTRANSFORMS {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "https://scil.usherbrooke.ca/containers/scilus_latest.sif":
        "scilus/scilus:latest"}"

    input:
    tuple val(meta), path(image), path(reference), path(warp), path(affine)

    output:
    tuple val(meta), path("*__warped.nii.gz")                           , emit: warped_image
    tuple val(meta), path("*_registration_antsapplytransforms_mqc.gif") , emit: mqc, optional: true
    path "versions.yml"                                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.first_suffix ? "${task.ext.first_suffix}__warped" : "warped"
    def suffix_qc = task.ext.suffix_qc ? "${task.ext.suffix_qc}" : ""

    def dimensionality = task.ext.dimensionality ? "-d " + task.ext.dimensionality : ""
    def image_type = task.ext.image_type ? "-e " + task.ext.image_type : ""
    def interpolation = task.ext.interpolation ? "-n " + task.ext.interpolation : ""
    def output_dtype = task.ext.output_dtype ? "-u " + task.ext.output_dtype : ""
    def default_val = task.ext.default_val ? "-f " + task.ext.default_val : ""
    def run_qc = task.ext.run_qc ? task.ext.run_qc : false

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$task.cpus
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1

    antsApplyTransforms $dimensionality\
                        -i $image\
                        -r $reference\
                        -o ${prefix}__${suffix}.nii.gz\
                        $interpolation\
                        -t $warp $affine\
                        $image_type\
                        $default_val\
                        $output_dtype

    ### ** QC ** ###
    if $run_qc;
    then
        mv $reference reference.nii.gz
        extract_dim=\$(mrinfo ${prefix}__${suffix}.nii.gz -size)
        read sagittal_dim coronal_dim axial_dim <<< "\${extract_dim}"

        # Get the middle slice
        coronal_dim=\$((\$coronal_dim / 2))
        axial_dim=\$((\$axial_dim / 2))
        sagittal_dim=\$((\$sagittal_dim / 2))

        # Set viz params.
        viz_params="--display_slice_number --display_lr --size 256 256"
        # Iterate over images.
        for image in reference warped;
        do
            scil_viz_volume_screenshot.py *\${image}.nii.gz \${image}_coronal.png \
                --slices \$coronal_dim --axis coronal \$viz_params
            scil_viz_volume_screenshot.py *\${image}.nii.gz \${image}_sagittal.png \
                --slices \$sagittal_dim --axis sagittal \$viz_params
            scil_viz_volume_screenshot.py *\${image}.nii.gz \${image}_axial.png \
                --slices \$axial_dim --axis axial \$viz_params
            if [ \$image != reference ];
            then
                title="Transformed"
            else
                title="Reference"
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
            warped_mosaic.png reference_mosaic.png warped_mosaic.png \
            ${prefix}_${suffix_qc}_registration_antsapplytransforms_mqc.gif
        # Clean up.
        rm *_mosaic.png
    fi
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: \$(antsRegistration --version | grep "Version" | sed -E 's/.*v([0-9]+\\.[0-9]+\\.[0-9]+).*/\\1/')
        mrtrix: \$(mrinfo -version 2>&1 | sed -n 's/== mrinfo \\([0-9.]\\+\\).*/\\1/p')
        imagemagick: \$(magick -version | sed -n 's/.*ImageMagick \\([0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\).*/\\1/p')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.first_suffix ? "${task.ext.first_suffix}__warped" : "warped"

    """
    antsApplyTransforms -h

    touch ${prefix}__${suffix}.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: \$(antsRegistration --version | grep "Version" | sed -E 's/.*v([0-9]+\\.[0-9]+\\.[0-9]+).*/\\1/')
        mrtrix: \$(mrinfo -version 2>&1 | sed -n 's/== mrinfo \\([0-9.]\\+\\).*/\\1/p')
        imagemagick: \$(magick -version | sed -n 's/.*ImageMagick \\([0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\).*/\\1/p')
    END_VERSIONS
    """
}
