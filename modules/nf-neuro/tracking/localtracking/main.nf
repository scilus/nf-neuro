process TRACKING_LOCALTRACKING {
    tag "$meta.id"
    label 'process_high_memory'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
    tuple val(meta), path(wm), path(fodf), path(fa)

    output:
    tuple val(meta), path("*__local_tracking.trk"), emit: trk
    tuple val(meta), path("*__local_tracking_config.json"), emit: config
    tuple val(meta), path("*__local_seeding_mask.nii.gz"), emit: seedmask
    tuple val(meta), path("*__local_tracking_mask.nii.gz"), emit: trackmask
    tuple val(meta), path("*__local_tracking_mqc.png"), emit: mqc, optional: true
    tuple val(meta), path("*__local_tracking_stats.json"), emit: global_mqc, optional: true
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    def local_fa_tracking_mask_threshold = task.ext.local_fa_tracking_mask_threshold ? task.ext.local_fa_tracking_mask_threshold : ""
    def local_fa_seeding_mask_threshold = task.ext.local_fa_seeding_mask_threshold ? task.ext.local_fa_seeding_mask_threshold : ""
    def local_tracking_mask = task.ext.local_tracking_mask_type ? "${task.ext.local_tracking_mask_type}" : ""
    def local_seeding_mask = task.ext.local_seeding_mask_type ? "${task.ext.local_seeding_mask_type}" : ""

    def local_step = task.ext.local_step ? "--step " + task.ext.local_step : ""
    def local_random_seed = task.ext.local_random_seed ? "--seed " + task.ext.local_random_seed : ""
    def local_seeding = task.ext.local_seeding ? "--" + task.ext.local_seeding : ""
    def local_nbr_seeds = task.ext.local_nbr_seeds ? "" + task.ext.local_nbr_seeds : ""
    def local_min_len = task.ext.local_min_len ? "--min_length " + task.ext.local_min_len : ""
    def local_max_len = task.ext.local_max_len ? "--max_length " + task.ext.local_max_len : ""
    def local_theta = task.ext.local_theta ? "--theta "  + task.ext.local_theta : ""
    def local_sfthres = task.ext.local_sfthres ? "--sfthres "  + task.ext.local_sfthres : ""
    def local_algo = task.ext.local_algo ? "--algo " + task.ext.local_algo: ""
    def compress = task.ext.local_compress_streamlines ? "--compress " + task.ext.local_compress_value : ""
    def basis = task.ext.basis ? "--sh_basis " + task.ext.basis : ""

    def gpu_batch_size = task.ext.gpu_batch_size ? "--batch_size " + task.ext.gpu_batch_size : ""
    def enable_gpu = task.ext.enable_gpu ? "--use_gpu $gpu_batch_size" : ""

    def run_qc = task.ext.run_qc ? task.ext.run_qc : false

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1

    if [ "${local_tracking_mask}" == "wm" ]; then
        scil_volume_math.py convert $wm ${prefix}__local_tracking_mask.nii.gz \
            --data_type uint8 -f
        cp $wm tmp_anat_qc.nii.gz

    elif [ "${local_tracking_mask}" == "fa" ]; then
        scil_volume_math.py lower_threshold $fa \
            $local_fa_tracking_mask_threshold \
            ${prefix}__local_tracking_mask.nii.gz \
            --data_type uint8 -f
        cp $fa tmp_anat_qc.nii.gz
    fi

    if [ "${local_seeding_mask}" == "wm" ]; then
        scil_volume_math.py convert $wm ${prefix}__local_seeding_mask.nii.gz \
            --data_type uint8 -f

    elif [ "${local_seeding_mask}" == "fa" ]; then
        scil_volume_math.py lower_threshold $fa \
            $local_fa_seeding_mask_threshold \
            ${prefix}__local_seeding_mask.nii.gz \
            --data_type uint8 -f
    fi

    scil_tracking_local.py $fodf ${prefix}__local_seeding_mask.nii.gz \
            ${prefix}__local_tracking_mask.nii.gz tmp.trk $enable_gpu\
            $local_algo $local_seeding $local_nbr_seeds\
            $local_random_seed $local_step $local_theta\
            $local_sfthres $local_min_len\
            $local_max_len $compress $basis -f

    scil_tractogram_remove_invalid.py tmp.trk\
            ${prefix}__local_tracking.trk\
            --remove_single_point -f

    cat <<-TRACKING_INFO > ${prefix}__local_tracking_config.json
    {"algorithm": "${task.ext.local_algo}",
    "fa_tracking_threshold": $task.ext.local_fa_tracking_mask_threshold,
    "fa_seeding_threshlod": $task.ext.local_fa_seeding_mask_threshold,
    "seeding_type": "${task.ext.local_seeding}",
    "tracking_mask": "${task.ext.local_tracking_mask_type}",
    "nb_seed": $task.ext.local_nbr_seeds,
    "seeding_mask": "${task.ext.local_seeding_mask_type}",
    "random_seed": $task.ext.local_random_seed,
    "is_compress": "${task.ext.local_compress_streamlines}",
    "compress_value": $task.ext.local_compress_value,
    "step": $task.ext.local_step,
    "theta": $task.ext.local_theta,
    "sfthres": $task.ext.local_sfthres,
    "min_len": $task.ext.local_min_len,
    "max_len": $task.ext.local_max_len,
    "sh_basis": "${task.ext.basis}"}
    TRACKING_INFO

    if $run_qc;
    then
        scil_viz_bundle_screenshot_mosaic.py tmp_anat_qc.nii.gz ${prefix}__local_tracking.trk\
            ${prefix}__local_tracking_mqc.png --opacity_background 1 --light_screenshot
        scil_tractogram_print_info.py ${prefix}__local_tracking.trk >> ${prefix}__local_tracking_stats.json
    fi
    rm -f tmp_anat_qc.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    scil_tracking_local.py -h
    scil_tractogram_remove_invalid.py -h
    scil_volume_math.py -h

    touch ${prefix}__local_tracking.trk
    touch ${prefix}__local_tracking_config.json
    touch ${prefix}__local_seeding_mask.nii.gz
    touch ${prefix}__local_tracking_mask.nii.gz
    touch ${prefix}__local_tracking_mqc.png
    touch ${prefix}__local_tracking_stats.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
