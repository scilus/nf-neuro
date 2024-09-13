process BUNDLE_STATS {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
    tuple val(meta), path(bundles), path(labels_map), path(metrics), path(lesions)

    output:
    tuple val(meta), path("*_length_stats.json")                , emit: length, optional: true
    tuple val(meta), path("*_endpoints_map_raw.json")           , emit: endpoints_raw, optional: true
    tuple val(meta), path("*_endpoints_metric_stats.json")      , emit: endpoints_metric_stats, optional: true
    tuple val(meta), path("*_mean_std.json")                    , emit: mean_std, optional: true
    tuple val(meta), path("*_volume.json")                      , emit: volume, optional: true
    tuple val(meta), path("*_volume_lesions.json")              , emit: volume_lesions, optional: true
    tuple val(meta), path("*_streamline_count.json")            , emit: streamline_count, optional: true
    tuple val(meta), path("*_streamline_count_lesions.json")    , emit: streamline_count_lesions, optional: true
    tuple val(meta), path("*_volume_per_label.json")            , emit: volume_per_labels, optional: true
    tuple val(meta), path("*_volume_per_label_lesions.json")    , emit: volume_per_labels_lesions, optional: true
    tuple val(meta), path("*_mean_std_per_point.json")          , emit: mean_std_per_point, optional: true
    tuple val(meta), path("*__lesion_stats.json")               , emit: lesion_stats, optional: true
    tuple val(meta), path("*_endpoints_map_head.nii.gz")        , emit: endpoints_head, optional: true
    tuple val(meta), path("*_endpoints_map_tail.nii.gz")        , emit: endpoints_tail, optional: true
    tuple val(meta), path("*_lesion_map.nii.gz")                , emit: lesion_map, optional: true
    path "versions.yml"                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def density_weighting = task.ext.density_weighting ? "--density_weighting" : ""
    def normalize_weights = task.ext.normalize_weights ? "--normalize_weights" : "--bin"
    def length_stats = task.ext.length_stats ?: ""
    def endpoints = task.ext.endpoints ?: ""
    def mean_std = task.ext.mean_std ?: ""
    def volume = task.ext.volume ?: ""
    def lesions_stats = task.ext.lesions_stats ?: ""
    def min_lesion_vol = task.ext.min_lesion_vol ?: ""
    def streamline_count = task.ext.streamline_count ?: ""
    def volume_per_labels = task.ext.volume_per_labels ?: ""
    def mean_std_per_point = task.ext.mean_std_per_point ?: ""

    """
    bundles=( ${bundles.join(" ")} )
    label_map=( ${labels_map.join(" ")} )

    for index in \${!bundles[@]};
    do\
    bname=\$(basename \${bundles[index]} .trk);
    b_metrics="$metrics";

    if [[ "$length_stats" ]];
    then
        scil_tractogram_print_info.py \${bundles[index]} > \${bname}_length.json
    fi

    if [[ "$endpoints" ]];
    then
        scil_bundle_compute_endpoints_map.py \${bundles[index]} \
            ${prefix}__\${bname}_endpoints_map_head.nii.gz \
            ${prefix}__\${bname}_endpoints_map_tail.nii.gz >\
            ${prefix}__\${bname}_endpoints_raw.json;

        scil_volume_stats_in_ROI.py ${prefix}__\${bname}_endpoints_map_head.nii.gz $normalize_weights\
            --metrics \${b_metrics} > \${bname}_head.json
        scil_volume_stats_in_ROI.py ${prefix}__\${bname}_endpoints_map_tail.nii.gz $normalize_weights\
            --metrics \${b_metrics} > \${bname}_tail.json;

    fi

    if [[ "$mean_std" ]];
    then
        scil_bundle_mean_std.py $density_weighting \${bundles[index]} \${b_metrics} >\
            \${bname}_std.json
    fi

    if [[ "$volume" ]];
    then
        scil_bundle_shape_measures.py \${bundles[index]} > \${bname}_volume_stat.json

        if [[ "$lesions_stats" ]];
        then
            scil_lesions_info.py $lesions \${bname}_volume_lesions_stat.json \
                --bundle \${bundles[index]} --out_lesion_stats ${prefix}__lesion_stats.json \
                --out_streamlines_stats \${bname}_streamline_count_lesions_stat.json \
                --min_lesion_vol $min_lesion_vol -f
        fi

    elif [[ "$streamline_count" ]];
    then
        scil_tractogram_count_streamlines.py \${bundles[index]} > \${bname}_streamlines.json
    fi

    if [[ "$volume_per_labels" ]];
    then
        scil_bundle_volume_per_label.py \${label_map[index]} \$bname --sort_keys >\
            \${bname}_volume_label.json

        if [[ "$lesions_stats" ]];
        then
            scil_analyse_lesions_load.py $lesions \${bname}_volume_per_label_lesions_stat.json \
                --bundle_labels_map \${label_map[index]} \
                --out_lesion_atlas "${prefix}__\${bname}_lesion_map.nii.gz" \
                --min_lesion_vol $min_lesion_vol
        fi
    fi

    if [[ "$mean_std_per_point" ]];
    then
        scil_bundle_mean_std.py \${bundles[index]} \${b_metrics}\
            --per_point \${label_map[index]} --sort_keys $density_weighting > \${bname}_std_per_point.json
    fi;

    done

    #Bundle_Length_Stats
    if [[ "$length_stats" ]];
    then
        scil_json_merge_entries.py *_length.json ${prefix}_length_stats.json --add_parent_key ${prefix} \
                --keep_separate
    fi

    #Bundle_Endpoints_Map
    if [[ "$endpoints" ]];
    then
        scil_json_merge_entries.py *_endpoints_raw.json ${prefix}_endpoints_map_raw.json \
            --no_list --add_parent_key ${prefix}

    #Bundle_Metrics_Stats_In_Endpoints

        scil_json_merge_entries.py *_tail.json *_head.json ${prefix}_endpoints_metric_stats.json \
            --no_list --add_parent_key ${prefix}
    fi

    #Bundle_Mean_Std
    if [[ "$mean_std" ]];
    then
        scil_json_merge_entries.py *_std.json ${prefix}_mean_std.json --no_list --add_parent_key ${prefix}
    fi

    #Bundle_Volume
    if [[ "$volume" ]];
    then
        scil_json_merge_entries.py *_volume_stat.json ${prefix}_volume.json --no_list --add_parent_key ${prefix}

        if [[ "$lesions_stats" ]];
        then
            scil_json_merge_entries.py *_volume_lesions_stat.json ${prefix}_volume_lesions.json --no_list --add_parent_key ${prefix}
            scil_json_merge_entries.py *_streamline_count_lesions_stat.json ${prefix}_streamline_count_lesions.json \
                --no_list --add_parent_key ${prefix}
            scil_merge_json.py ${prefix}__lesion_stats.json ${prefix}__lesion_stats.json \
                --remove_parent_key --add_parent_key ${prefix} -f
        fi

    #Bundle_Streamline_Count
    elif [[ "$streamline_count" ]];
    then
        scil_json_merge_entries.py *_streamlines.json ${prefix}_streamline_count.json --no_list \
            --add_parent_key ${prefix}
    fi

    #Bundle_Volume_Per_Label
    if [[ "$volume_per_labels" ]];
    then
        scil_json_merge_entries.py *_volume_label.json ${prefix}_volume_per_label.json --no_list \
            --add_parent_key ${prefix}

        if [[ "$lesions_stats" ]];
        then
            scil_json_merge_entries.py *_volume_per_label_lesions_stat.json ${prefix}_volume_per_label_lesions.json \
                --no_list --add_parent_key ${prefix}
        fi
    fi

    #Bundle_Mean_Std_Per_Point
    if [[ "$mean_std_per_point" ]];
    then
        scil_json_merge_entries.py *_std_per_point.json ${prefix}_mean_std_per_point.json --no_list \
            --add_parent_key ${prefix}
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.0.2
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    scil_tractogram_print_info.py -h
    scil_bundle_compute_endpoints_map.py -h
    scil_volume_stats_in_ROI.py -h
    scil_bundle_mean_std.py -h
    scil_bundle_shape_measures.py -h
    scil_tractogram_count_streamlines.py -h
    scil_bundle_volume_per_label.py -h
    scil_bundle_mean_std.py -h
    scil_json_merge_entries.py -h

    touch ${prefix}__length_stats.json
    touch ${prefix}__endpoints_map_raw.json
    touch ${prefix}__endpoints_metric_stats.json
    touch ${prefix}__mean_std.json
    touch ${prefix}__volume.json
    touch ${prefix}__streamline_count.json
    touch ${prefix}__volume_per_label.json
    touch ${prefix}__mean_std_per_point.json
    touch ${prefix}_endpoints_map_head.nii.gz
    touch ${prefix}_endpoints_map_tail.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.0.2
    END_VERSIONS
    """
}
