process TRACKING_TRACTORACLE {
    tag "$meta.id"
    label 'process_single'

    container 'mrzarfir/tractoracle-irt:base'

    input:
    tuple val(meta), path(wm), path(gm), path(csf), path(fodf)

    output:
    tuple val(meta), path("*__tracking.trk"), emit: tractogram
    tuple val(meta), path("*__interface.nii.gz"), emit: interface_mask
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def compress = task.ext.compress ? "${task.ext.compress}" : "0.1"
    def n_actor = task.ext.n_actor ? "${task.ext.n_actor}" : "10000"
    def npv = task.ext.npv ? "${task.ext.npv}" : "1"
    def agent_checkpoint = task.ext.agent_checkpoint ? "${task.ext.agent_checkpoint}" : "public://sac_irt_inferno"
    def min_length = task.ext.min_length ? "${task.ext.min_length}" : "20"
    def max_length = task.ext.max_length ? "${task.ext.max_length}" : "200"

    """
    uv run scil_tracking_pft_maps.py $wm $gm $csf \
        --include ${prefix}__map_include.nii.gz \
        --exclude ${prefix}__map_exclude.nii.gz \
        --interface ${prefix}__interface.nii.gz -f

    uv run /tractoracle_irt/tractoracle_irt/runners/ttl_track.py \
        ${fodf} \
        ${prefix}__interface.nii.gz \
        ${wm} \
        --out_tractogram ${prefix}__tracking.trk \
        --agent_checkpoint ${agent_checkpoint} \
        --compress ${compress} \
        --n_actor ${n_actor} \
        --npv ${npv} \
        --min_length ${min_length} \
        --max_length ${max_length}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tractoracle-irt: \$(uv pip -q -n list | grep tractoracle-irt | tr -s ' ' | cut -d' ' -f2)
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    echo $args

    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tractoracle-irt: \$(uv pip -q -n list | grep tractoracle-irt | tr -s ' ' | cut -d' ' -f2)
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
