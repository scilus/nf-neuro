process PREPROC_GIBBS {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
    tuple val(meta), path(dwi)

    output:
    tuple val(meta), path("*dwi_gibbs_corrected.nii.gz"), emit: dwi
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1
    mrdegibbs $dwi ${prefix}__dwi_gibbs_corrected.nii.gz -nthreads 1

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mrtrix: \$(mrdegibbs -version 2>&1 | sed -n 's/== mrdegibbs \\([0-9.]\\+\\).*/\\1/p')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mrdegibbs -h

    touch ${prefix}__dwi_gibbs_corrected.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mrtrix: \$(mrdegibbs -version 2>&1 | sed -n 's/== mrdegibbs \\([0-9.]\\+\\).*/\\1/p')
    END_VERSIONS
    """
}
