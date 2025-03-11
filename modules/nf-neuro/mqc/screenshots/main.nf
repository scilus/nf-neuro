process MQC_SCREENSHOTS {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "https://scil.usherbrooke.ca/containers/scilus_latest.sif":
        "scilus/scilus:latest"}"

    input:
    tuple val(meta), path(image1), path(image2)

    output:
    tuple val(meta), path("*_screenshots_merged_mqc.gif"), emit: mqc_screenshots
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def title_image1 = task.ext.title_image1 ? task.ext.title_image1 : "image1"
    def title_image2 = task.ext.title_image2 ? task.ext.title_image2 : "image2"
    def suffix_qc = task.ext.suffix_qc ? "${task.ext.suffix_qc}" : ""
    def fourth_dim = task.ext.fourth_dim ? task.ext.fourth_dim : false



    """
    # Get the middle slice.
    extract_dim=\$(mrinfo $image2 -size)
    if $fourth_dim
    then
        read sagittal_dim coronal_dim axial_dim fourth_dim <<< "\${extract_dim}"
    else
        read sagittal_dim coronal_dim axial_dim <<< "\${extract_dim}"
    fi
    sagittal_dim=\$((\$sagittal_dim / 2))
    coronal_dim=\$((\$coronal_dim / 2))
    axial_dim=\$((\$axial_dim / 2))

    # Set viz params.
    viz_params="--display_slice_number --display_lr --size 256 256"

    for image in $image1 $image2;
    do
        basename=\$(basename \$image .nii.gz)
        scil_viz_volume_screenshot.py \$image \${basename}_coronal.png \
            --slices \$coronal_dim --axis coronal \$viz_params
        scil_viz_volume_screenshot.py \$image \${basename}_sagittal.png \
            --slices \$sagittal_dim --axis sagittal \$viz_params
        scil_viz_volume_screenshot.py \$image \${basename}_axial.png \
            --slices \$axial_dim --axis axial \$viz_params
        if [ \$image = $image1 ];
        then
            title="$title_image1"
        else
            title="$title_image2"
        fi
        convert +append \${basename}_coronal*.png \${basename}_axial*.png \
            \${basename}_sagittal*.png \${basename}_mosaic.png
        convert -annotate +20+230 "\${title}" -fill white -pointsize 30 \
            \${basename}_mosaic.png \${basename}_mosaic.png
        # Clean up.
        rm \${basename}_coronal*.png \${basename}_sagittal*.png \${basename}_axial*.png
    done

    # Create GIF.
    image1=\$(basename $image1 .nii.gz)
    image2=\$(basename $image2 .nii.gz)
    convert -delay 10 -loop 0 -morph 10 \
        \${image1}_mosaic.png \${image2}_mosaic.png \
        ${prefix}_${suffix_qc}_screenshots_merged_mqc.gif

    # Clean up.
    rm *_mosaic.png

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
        mrtrix: \$(mrinfo -version 2>&1 | sed -n 's/== mrinfo \\([0-9.]\\+\\).*/\\1/p')
        imagemagick: \$(magick -version | sed -n 's/.*ImageMagick \\([0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\).*/\\1/p')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mrinfo -h
    scil_viz_volume_screenshot.py -h
    convert -h

    touch ${prefix}_screenshots_merged_mqc.gif

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
        mrtrix: \$(mrinfo -version 2>&1 | sed -n 's/== mrinfo \\([0-9.]\\+\\).*/\\1/p')
        imagemagick: \$(magick -version | sed -n 's/.*ImageMagick \\([0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\).*/\\1/p')
    END_VERSIONS
    """
}
