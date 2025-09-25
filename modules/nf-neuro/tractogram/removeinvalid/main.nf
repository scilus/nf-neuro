process TRACTOGRAM_REMOVEINVALID {
    tag "$meta.id"
    label 'process_single'

    container "scilus/scilpy:2.2.0_cpu"

    input:
        tuple val(meta), path(tractogram)

    output:
        tuple val(meta), path("*.{trk,tck}"), emit: tractograms
        path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.suffix ? "_${task.ext.suffix}" : ""

    def cut_invalid = task.ext.cut_invalid ? "--cut_invalid" : ""
    def remove_single_point = task.ext.remove_single_point ? "--remove_single_point" : ""
    def remove_overlapping_points = task.ext.remove_overlapping_points ? "--remove_overlapping_points" : ""
    def threshold = task.ext.threshold ? "--threshold " + task.ext.threshold : ""
    def no_empty = task.ext.no_empty ? "--no_empty" : ""

    """
    for tractogram in ${tractogram};
        do \
        ext=\${tractogram#*.}
        bname=\$(basename \${tractogram} .\${ext})

        scil_tractogram_remove_invalid \$tractogram ${prefix}__\${bname}${suffix}.\${ext}\
                        $cut_invalid\
                        $remove_single_point\
                        $remove_overlapping_points\
                        $threshold\
                        $no_empty -f
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.suffix ? "_${task.ext.suffix}" : ""

    """
    scil_tractogram_remove_invalid -h

    for tractogram in ${tractogram};
        do \
        ext=\${tractogram#*.}
        bname=\$(basename \${tractogram} .\${ext})

        touch ${prefix}__\${bname}${suffix}.\${ext}
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
