process REGISTRATION_ANTSAPPLYTRANSFORMS {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
    tuple val(meta), path(image), path(reference), path(transform)

    output:
    tuple val(meta), path("*__warped.nii.gz")   , emit: warped_image
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.first_suffix ? "${task.ext.first_suffix}_warped" : "warped"

    def dimensionality = task.ext.dimensionality ? "-d " + task.ext.dimensionality : ""
    def image_type = task.ext.image_type ? "-e " + task.ext.image_type : ""
    def interpolation = task.ext.interpolation ? "-n " + task.ext.interpolation : ""
    def output_dtype = task.ext.output_dtype ? "-u " + task.ext.output_dtype : ""
    def default_val = task.ext.default_val ? "-f " + task.ext.default_val : ""

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$task.cpus
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1

    antsApplyTransforms $dimensionality\
                        -i $image\
                        -r $reference\
                        -o ${prefix}__${suffix}.nii.gz\
                        $interpolation\
                        -t $transform\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: antsRegistration --version | grep "Version" | sed -E 's/.*v([0-9]+\\.[0-9]+\\.[0-9]+).*/\\1/'
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.first_suffix ? "${task.ext.first_suffix}_warped" : "warped"

    def dimensionality = task.ext.dimensionality ? "-d " + task.ext.dimensionality : ""
    def image_type = task.ext.image_type ? "-e " + task.ext.image_type : ""
    def interpolation = task.ext.interpolation ? "-n " + task.ext.interpolation : ""
    def output_dtype = task.ext.output_dtype ? "-u " + task.ext.output_dtype : ""
    def default_val = task.ext.default_val ? "-f " + task.ext.default_val : ""

    """
    antsApplyTransforms -h

    touch ${prefix}__${suffix}.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: antsRegistration --version | grep "Version" | sed -E 's/.*v([0-9]+\\.[0-9]+\\.[0-9]+).*/\\1/'
    END_VERSIONS
    """
}
