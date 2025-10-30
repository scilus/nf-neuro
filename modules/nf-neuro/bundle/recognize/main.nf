process BUNDLE_RECOGNIZE {
    tag "$meta.id"
    label 'process_high'

    container "scilus/scilpy:2.2.0_cpu"

    input:
        tuple val(meta), path(tractograms), path(transform), path(config), path(directory)

    output:
    tuple val(meta), path("*_cleaned.trk")     , emit: bundles
    path "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    // additional script arguments
    def minimal_vote_ratio = task.ext.minimal_vote_ratio ? "--minimal_vote_ratio " + task.ext.minimal_vote_ratio : ""
    def seed = task.ext.seed ? "--seed " + task.ext.seed : ""
    def rbx_processes = task.cpus ? "--processes " + task.cpus : "--processes 1"
    def outlier_alpha = task.ext.outlier_alpha ? "--alpha " + task.ext.outlier_alpha : ""
    """
    if [[ "$transform" == *.txt ]]; then
        ConvertTransformFile 3 $transform transform.mat --convertToAffineType \
            && transform="transform.mat" \
            || echo "TXT transform file conversion failed, using original file."
    fi

    mkdir recobundles/
    scil_tractogram_segment_with_bundleseg ${tractograms} ${config} ${directory}/ ${transform} --inverse --out_dir recobundles/ \
        -v DEBUG $minimal_vote_ratio $seed $rbx_processes

    for bundle_file in recobundles/*.trk; do
        bname=\$(basename \${bundle_file} .trk | sed 's/${prefix}_\\+//')
        out_cleaned=${prefix}_\${bname}_cleaned.trk
        scil_bundle_reject_outliers \${bundle_file} "\${out_cleaned}" ${outlier_alpha}
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    scil_tractogram_segment_with_bundleseg -h
    scil_bundle_reject_outliers -h

    # dummy output for single bundle
    touch ${prefix}_AF_L_cleaned.trk

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
