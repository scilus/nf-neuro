process TRACKING_TRACTORACLE {
    tag "$meta.id"
    label 'process_single'

    container 'mrzarfir/tractoracle-irt:latest'

    input:
    tuple val(meta), path(wm), path(gm), path(csf), path(fodf)

    output:
    tuple val(meta), path("*__tracking.trk"), emit: tractogram
    tuple val(meta), path("*__interface.nii.gz"), emit: interface_mask
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    uv run scil_tracking_pft_maps $wm $gm $csf \
        --include ${prefix}__map_include.nii.gz \
        --exclude ${prefix}__map_exclude.nii.gz \
        --interface ${prefix}__interface.nii.gz -f

    uv run tractoracle_irt/runners/ttl_track.py \
        ${fodf} \
        ${prefix}__interface.nii.gz \
        ${wm} \
        --out_tractogram ${prefix}__tracking.trk

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
