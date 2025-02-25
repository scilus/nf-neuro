process BUNDLE_RECOGNIZE {
    tag "$meta.id"
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
        tuple val(meta), path(tractograms), path(transform), path(config), path(directory)

    output:
    tuple val(meta), path("*_cleaned.trk")            , emit: bundles
    tuple val(meta), path("*_bundles_mosaic_mqc.png")     , emit: mqc, optional: true
    tuple val(meta), path("*_bundles_stats_mqc.json")     , emit: global_mqc, optional: true
    path "versions.yml"                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    // additional script arguments
    def run_qc = task.ext.run_qc ? task.ext.run_qc : false
    def minimal_vote_ratio = task.ext.minimal_vote_ratio ? "--minimal_vote_ratio " + task.ext.minimal_vote_ratio : ""
    def seed = task.ext.seed ? "--seed " + task.ext.seed : ""
    def rbx_processes = task.ext.rbx_processes ? "--processes " + task.ext.rbx_processes : "--processes 1"
    def outlier_alpha = task.ext.outlier_alpha ? "--alpha " + task.ext.outlier_alpha : ""


    """
    mkdir recobundles/
    scil_tractogram_segment_bundles.py ${tractograms} ${config} ${directory}/ ${transform} --inverse --out_dir recobundles/ \
        -v DEBUG $minimal_vote_ratio $seed $rbx_processes

    for bundle_file in recobundles/*.trk; do
        bname=\$(basename \${bundle_file} .trk)
        out_cleaned=${prefix}__\${bname}_cleaned.trk
        scil_bundle_reject_outliers.py \${bundle_file} "\${out_cleaned}" ${outlier_alpha}
    done

    if $run_qc;
    then
        # Take one file to generate temporary anat
        first_trk=(*_cleaned.trk)
        scil_tractogram_compute_density_map.py \${first_trk} tmp_anat.nii.gz --binary
        # Generate Mosaic for QC
        scil_viz_bundle_screenshot_mosaic.py tmp_anat.nii.gz *_cleaned.trk ${prefix}__bundles_mosaic_mqc.png --opacity_background 1
        rm -f tmp_anat.nii.gz

        # Generate JSON file stats
        for curr_bundle in *cleaned.trk; do
            bundle_name=\$(basename \${curr_bundle} _cleaned.trk)
            scil_bundle_shape_measures.py \${curr_bundle} --out_json \${bundle_name}__stats.json
        done
        scil_json_merge_entries.py *__stats.json ${prefix}__bundles_stats_mqc.json --keep_separate
        rm -f *__stats.json

    fi


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list --disable-pip-version-check --no-python-version-warning | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    scil_tractogram_segment_bundles.py -h
    scil_bundle_reject_outliers.py -h

    # dummy output for single bundle
    touch ${prefix}__AF_L_cleaned.trk
    touch ${prefix}__bundles_mosaic_mqc.png
    touch ${prefix}__bundles_stats_mqc.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list --disable-pip-version-check --no-python-version-warning | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
