process MQC_SCREENSHOTS {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "https://scil.usherbrooke.ca/containers/scilus_latest.sif":
        "scilus/scilus:latest"}"

    input:
    tuple val(meta), path(warped), path(reference)

    output:
    tuple val(meta), path("*_screenshots_merged_mqc.gif"), emit: mqc_screenshots
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def fourth_dim = task.ext.fourth_dim ? task.ext.fourth_dim : false
    def title_warped = task.ext.title_warped ? task.ext.title_warped : "Warped T1"
    def title_ref = task.ext.title_ref ? task.ext.title_ref : "Reference"
    def prefix = task.ext.prefix ?: "${meta.id}"


    """
    mv $reference reference.nii.gz
    mv $warped warped.nii.gz

    # Get the middle slice.
    extract_dim=\$(mrinfo reference.nii.gz -size)
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

    # Iterate over images.
    for image in reference warped;
    do
        scil_viz_volume_screenshot.py *\${image}.nii.gz \${image}_coronal.png \
            --slices \$coronal_dim --axis coronal \$viz_params
        scil_viz_volume_screenshot.py *\${image}.nii.gz \${image}_sagittal.png \
            --slices \$sagittal_dim --axis sagittal \$viz_params
        scil_viz_volume_screenshot.py *\${image}.nii.gz \${image}_axial.png \
            --slices \$axial_dim --axis axial \$viz_params
        if [ \$image = reference ];
        then
            title="$title_ref"
        else
            title="$title_warped"
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
        ${prefix}_screenshots_merged_mqc.gif

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
