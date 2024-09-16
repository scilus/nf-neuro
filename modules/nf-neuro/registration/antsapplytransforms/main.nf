process REGISTRATION_ANTSAPPLYTRANSFORMS {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'scil.usherbrooke.ca/containers/scilus_1.6.0.sif':
        'scilus/scilus:1.6.0' }"

    input:
    tuple val(meta), path(image), path(reference), path(transform)

    output:
    tuple val(meta), path("*__warped.nii.gz"), emit: warped_image
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def dimensionality = task.ext.dimensionality ? "-d " + task.ext.dimensionality : ""
    def image_type = task.ext.image_type ? "-e " + task.ext.image_type : ""
    def interpolation = task.ext.interpolation ? "-n " + task.ext.interpolation : ""
    def output_dtype = task.ext.output_dtype ? "-u " + task.ext.output_dtype : ""
    def default_val = task.ext.default_val ? "-f " + task.ext.default_val : ""

    """
    antsApplyTransforms $dimensionality\
                        -i $image\
                        -r $reference\
                        -o ${prefix}__warped.nii.gz\
                        $interpolation\
                        -t $transform\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: 2.4.3
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def dimensionality = task.ext.dimensionality ? "-d " + task.ext.dimensionality : ""
    def image_type = task.ext.image_type ? "-e " + task.ext.image_type : ""
    def interpolation = task.ext.interpolation ? "-n " + task.ext.interpolation : ""
    def output_dtype = task.ext.output_dtype ? "-u " + task.ext.output_dtype : ""
    def default_val = task.ext.default_val ? "-f " + task.ext.default_val : ""

    """
    antsApplyTransforms -h

    touch ${prefix}__warped_image.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: 2.4.3
    END_VERSIONS
    """
}
