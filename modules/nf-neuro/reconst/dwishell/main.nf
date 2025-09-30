process RECONST_DWISHELL {
    tag "$meta.id"
    label 'process_single'

    container "scilus/scilpy:2.2.0_cpu"

    input:
        tuple val(meta), path(dwi), path(bval), path(bvec)
        val(shell_to_fit)

    output:
        tuple val(meta), path("*__dwi_sh_shells.nii.gz"), path("*__bval_sh_shells"), path("*__bvec_sh_shells"), emit: dwi_shells
        tuple val(meta), path("*__out_indices"), emit: out_indices, optional: true
        path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    def out_indices = task.ext.out_indices ? "--out_indices ${prefix}__out_indices" : ''
    def block_size = task.ext.block_size ? "--block_size ${task.ext.block_size}" : ''
    def tolerance = task.ext.tolerance ? "--tolerance ${task.ext.tolerance}" : ''
    def force = task.ext.force ? "-f" : ''

    """
    scil_dwi_extract_shell $dwi $bval $bvec $shell_to_fit \
        ${prefix}__dwi_sh_shells.nii.gz \
        ${prefix}__bval_sh_shells \
        ${prefix}__bvec_sh_shells \
        ${out_indices} \
        ${block_size} \
        ${tolerance} \
        ${force}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    echo $args

    touch ${prefix}__dwi_sh_shells.nii.gz
    touch ${prefix}__bval_sh_shells
    touch ${prefix}__bvec_sh_shells

    if ${task.ext.out_indices} {
        touch ${meta.id}__out_indices
    }

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
