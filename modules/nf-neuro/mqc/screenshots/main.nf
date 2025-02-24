process MQC_SCREENSHOTS {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "https://scil.usherbrooke.ca/containers/scilus_latest.sif":
        "scilus/scilus:latest"}"

    input:
    tuple val(meta), path(warped), path(reference), path(title_warped), path(title_ref)

    output:
    tuple val(meta), path("*__registration_mqc.gif"), emit: mqc_screenshots
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"


    """
    if [[ -f "$title_warped" ]];
    then
        title_warped = "$title_warped"
    else
        title_warped = "Warped T1"
    fi

        if [[ -f "$title_ref" ]];
    then
        title_ref = "$title_ref"
    else
        title_ref = "reference"
    fi

    mv $reference reference.nii.gz
    mv $warped warped.nii.gz
    extract_dim=\$(mrinfo reference.nii.gz -size)
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
            title=\${title_ref}
        else
            title=\${title_warped}
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
        ${prefix}_registration_ants_mqc.gif
    # Clean up.
    rm *_mosaic.png

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mqc: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mqc: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}
