process IMAGE_CONVERT {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
    tuple val(meta), path(image)

    output:
    tuple val(meta), path("*_converted.nii.gz") , emit: image
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    def datatype = task.ext.datatype ? "--data_type ${task.ext.datatype}" : '' // REQUIRED.
    def suffix = task.ext.first_suffix ? "${task.ext.first_suffix}_${task.ext.datatype}_converted" : "${task.ext.datatype}_converted"

    """
    scil_volume_math.py convert $image ${prefix}_${suffix}.nii.gz $datatype

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    def suffix = task.ext.first_suffix ? "${task.ext.first_suffix}_${task.ext.datatype}_converted" : "${task.ext.datatype}_converted"

    """
    touch ${prefix}_${suffix}.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
