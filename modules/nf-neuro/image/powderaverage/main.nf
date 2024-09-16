process IMAGE_POWDERAVERAGE {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
        tuple val(meta), path(dwi), path(bval), path(mask)

    output:
        tuple val(meta), path("*pwd_avg.nii.gz")    , emit: pwd_avg
        path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def b0_thr = task.ext.b0_thr ? "--b0_thr ${task.ext.b0_thr}" : ''
    def shells = task.ext.shells ? "--shells ${task.ext.shells}" : ''
    def shell_thr = task.ext.shell_thr ? "--shell_thr ${task.ext.shell_thr}" : ''

    if ( mask ) args += "--mask ${mask}"

    """
    scil_dwi_powder_average.py $dwi $bval ${prefix}_pwd_avg.nii.gz \
        $b0_thr $shells $shell_thr $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.0.2
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}_pwd_avg.nii.gz

    scil_dwi_powder_average.py -h

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.0.2
    END_VERSIONS
    """
}
