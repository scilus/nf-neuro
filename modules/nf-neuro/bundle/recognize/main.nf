process BUNDLE_RECOGNIZE {
    tag "$meta.id"
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_latest.sif':
        'scilus/scilus:latest' }"

    input:
        tuple val(meta), path(tractograms), path(transform), path(config), path(directory)

    output:
    tuple val(meta), path("*_cleaned.trk")            , emit: bundles
    tuple val(meta), path("*_bundles_mosaic.png")     , emit: mosaic
    tuple val(meta), path("*_bundles_stats.json")     , emit: stats
    path "versions.yml"                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    // additional script arguments
    def minimal_vote_ratio = task.ext.minimal_vote_ratio ? "--minimal_vote_ratio " + task.ext.minimal_vote_ratio : ""
    def seed = task.ext.seed ? "--seed " + task.ext.seed : ""
    def rbx_processes = task.ext.rbx_processes ? "--processes " + task.ext.rbx_processes : "--processes 1"
    def outlier_alpha = task.ext.outlier_alpha ? "--alpha " + task.ext.outlier_alpha : ""
    def run_qc = task.ext.run_qc ? task.ext.run_qc : false
    """
    mkdir recobundles/
    scil_tractogram_segment_bundles.py ${tractograms} ${config} ${directory}/ ${transform} --inverse --out_dir recobundles/ \
        -v DEBUG $minimal_vote_ratio $seed $rbx_processes

    for bundle_file in recobundles/*.trk; do
        bname=\$(basename \${bundle_file} .trk)
        out_cleaned=${prefix}__\${bname}_cleaned.trk
        scil_bundle_reject_outliers.py \${bundle_file} "\${out_cleaned}" ${outlier_alpha}
    done


    if $run_qc; then
        scil_tractogram_compute_density_map.py recobundles/PYT_l.trk tmp_anat.nii.gz --binary
        scil_viz_bundle_screenshot_mosaic.py tmp_anat.nii.gz *_cleaned.trk --opacity_background 1
        scil_bundle_shape_measures.py *_cleaned.trk --out_json ${prefix}__bundles_stats.json
    fi


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.0.0
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    scil_tractogram_segment_bundles.py -h
    scil_bundle_reject_outliers.py -h

    # dummy output for single bundle
    touch ${prefix}__AF_L_cleaned.trk

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.0.0
    END_VERSIONS
    """
}
