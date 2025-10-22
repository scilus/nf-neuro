process BUNDLE_STATS {
    tag "$meta.id"
    label 'process_single'

    container "scilus/scilus:2.2.0"

    input:
    tuple val(meta), path(bundles), path(labels_map), path(metrics), path(lesions)

    output:
    tuple val(meta), path("*__length_stats.json")               , emit: length, optional: true
    tuple val(meta), path("*__endpoints_map_raw.json")          , emit: endpoints_raw, optional: true
    tuple val(meta), path("*__endpoints_metric_stats.json")     , emit: endpoints_metric_stats, optional: true
    tuple val(meta), path("*__mean_std.json")                   , emit: mean_std, optional: true
    tuple val(meta), path("*__volume.json")                     , emit: volume, optional: true
    tuple val(meta), path("*__volume_lesions.json")             , emit: volume_lesions, optional: true
    tuple val(meta), path("*__streamline_count.json")           , emit: streamline_count, optional: true
    tuple val(meta), path("*__streamline_count_lesions.json")   , emit: streamline_count_lesions, optional: true
    tuple val(meta), path("*__volume_per_label.json")           , emit: volume_per_labels, optional: true
    tuple val(meta), path("*__volume_per_label_lesions.json")   , emit: volume_per_labels_lesions, optional: true
    tuple val(meta), path("*__mean_std_per_point.json")         , emit: mean_std_per_point, optional: true
    tuple val(meta), path("*__lesion_stats.json")               , emit: lesion_stats, optional: true
    tuple val(meta), path("*_endpoints_map_head.nii.gz")        , emit: endpoints_head, optional: true
    tuple val(meta), path("*_endpoints_map_tail.nii.gz")        , emit: endpoints_tail, optional: true
    tuple val(meta), path("*_lesion_map.nii.gz")                , emit: lesion_map, optional: true
    tuple val(meta), path("*tractometry_mqc.tsv")               , emit: mqc, optional: true
    path "versions.yml"                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
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
    def run_qc = task.ext.run_qc ? task.ext.run_qc : false

    """
    bundles=( ${bundles.join(" ")} )
    label_map=( ${labels_map.join(" ")} )

    for index in \${!bundles[@]};
    do\
        bname=\$(basename \${bundles[index]} .trk);
        b_metrics="$metrics";

        if [[ "$length_stats" ]];
        then
            scil_tractogram_print_info \${bundles[index]} > \${bname}_length.json
        fi

        if [[ "$endpoints" ]];
        then
            scil_bundle_compute_endpoints_map \${bundles[index]} \
                ${prefix}__\${bname}_endpoints_map_head.nii.gz \
                ${prefix}__\${bname}_endpoints_map_tail.nii.gz --out_json \
                ${prefix}__\${bname}_endpoints_raw.json;

            scil_volume_stats_in_ROI ${prefix}__\${bname}_endpoints_map_head.nii.gz $normalize_weights\
                --metrics \${b_metrics} > \${bname}_head.json
            scil_volume_stats_in_ROI ${prefix}__\${bname}_endpoints_map_tail.nii.gz $normalize_weights\
                --metrics \${b_metrics} > \${bname}_tail.json;
            fi

        if [[ "$mean_std" ]];
        then
            scil_bundle_mean_std $density_weighting \${bundles[index]} \${b_metrics} >\
                \${bname}__std.json
        fi

        if [[ "$volume" ]];
        then
            scil_bundle_shape_measures \${bundles[index]} > \${bname}_volume_stat.json

            if [[ "$lesions_stats" ]];
            then
                scil_lesions_info $lesions \${bname}_volume_lesions_stat.json \
                    --bundle \${bundles[index]} --out_lesion_stats ${prefix}__lesion_stats.json \
                    --out_streamlines_stats \${bname}__streamline_count_lesions_stat.json \
                    --min_lesion_vol $min_lesion_vol -f
            fi
        fi

        if [[ "$streamline_count" ]];
        then
            scil_tractogram_count_streamlines \${bundles[index]} > \${bname}_streamlines.json
        fi

        if [[ "$volume_per_labels" ]];
        then
            scil_bundle_volume_per_label \${label_map[index]} \$bname --sort_keys >\
                \${bname}_volume_label.json

            if [[ "$lesions_stats" ]];
            then
                scil_lesions_info $lesions \${bname}_volume_per_label_lesions_stat.json \
                    --bundle_labels_map \${label_map[index]} \
                    --out_lesion_atlas "${prefix}__\${bname}_lesion_map.nii.gz" \
                    --min_lesion_vol $min_lesion_vol
            fi
        fi

        if [[ "$mean_std_per_point" ]];
        then
            scil_bundle_mean_std \${bundles[index]} \${b_metrics}\
                --per_point \${label_map[index]} --sort_keys $density_weighting > \${bname}_std_per_point.json
        fi
    done

    #Bundle_Length_Stats
    if [[ "$length_stats" ]];
    then
        echo "Merging Bundle_Length_Stats"
        scil_json_merge_entries *_length.json ${prefix}__length_stats.json --add_parent_key ${prefix} \
                --keep_separate
    fi

    #Bundle_Endpoints_Map
    if [[ "$endpoints" ]];
    then
        echo "Merging Bundle_Endpoints_Map"
        scil_json_merge_entries *_endpoints_raw.json ${prefix}__endpoints_map_raw.json \
            --no_list --add_parent_key ${prefix}

        #Bundle_Metrics_Stats_In_Endpoints
        scil_json_merge_entries *_tail.json *_head.json ${prefix}__endpoints_metric_stats.json \
            --no_list --add_parent_key ${prefix}
    fi

    #Bundle_Mean_Std
    if [[ "$mean_std" ]];
    then
        echo "Merging Bundle_Mean_Std"
        scil_json_merge_entries *_std.json ${prefix}__mean_std.json --no_list --add_parent_key ${prefix}
    fi

    #Bundle_Volume
    if [[ "$volume" ]];
    then
        echo "Merging Bundle_Volume"
        scil_json_merge_entries *_volume_stat.json ${prefix}__volume.json --no_list --add_parent_key ${prefix}

        if [[ "$lesions_stats" ]];
        then
            echo "Merging Lesions Stats"
            scil_json_merge_entries *_volume_lesions_stat.json ${prefix}__volume_lesions.json --no_list --add_parent_key ${prefix}
            scil_json_merge_entries *_streamline_count_lesions_stat.json ${prefix}__streamline_count_lesions.json \
                --no_list --add_parent_key ${prefix}
            scil_json_merge_entries ${prefix}__lesion_stats.json ${prefix}__lesion_stats.json \
                --remove_parent_key --add_parent_key ${prefix} -f
        fi
    fi

    #Bundle_Streamline_Count
    if [[ "$streamline_count" ]];
    then
        echo "Merging Bundle_Streamline_Count"
        scil_json_merge_entries *_streamlines.json ${prefix}__streamline_count.json --no_list \
            --add_parent_key ${prefix}
    fi

    #Bundle_Volume_Per_Label
    if [[ "$volume_per_labels" ]];
    then
        echo "Merging Bundle_Volume_Per_Label"
        scil_json_merge_entries *_volume_label.json ${prefix}__volume_per_label.json --no_list \
            --add_parent_key ${prefix}

        if [[ "$lesions_stats" ]];
        then
            echo "Merging Bundle_Volume_Per_Label in Lesions"
            scil_json_merge_entries *_volume_per_label_lesions_stat.json ${prefix}__volume_per_label_lesions.json \
                --no_list --add_parent_key ${prefix}
        fi
    fi

    #Bundle_Mean_Std_Per_Point
    if [[ "$mean_std_per_point" ]];
    then
        echo "Merging Bundle_Mean_Std_Per_Point"
        scil_json_merge_entries *_std_per_point.json ${prefix}__mean_std_per_point.json --no_list \
            --add_parent_key ${prefix}
    fi

    ### ** QC ** ###
    if $run_qc;
    then
        mean_std_file="${prefix}__mean_std.json"
        output_file="${prefix}__tractometry_mqc.tsv"

        echo "QC summary: extracting mean values from \${mean_std_file}"
        echo -e "sample\tbundle\tmetric\tvalue" > "\${output_file}"

        bundles=(\$(jq -r ".\"${prefix}\" | keys[]" "\${mean_std_file}"))
        metrics=(\$(jq -r ".\"${prefix}\" | .[] | keys[]" "\${mean_std_file}" | sort -u))

        for bundle in "\${bundles[@]}"; do
            for metric in "\${metrics[@]}"; do
                value=\$(jq -r ".\"${prefix}\".\"\${bundle}\".\"\${metric}\".mean // empty" "\${mean_std_file}")
                if [[ -n "\${value}" ]]; then
                    echo -e "${prefix}\t\${bundle}\t\${metric}\t\${value}" >> "\${output_file}"
                fi
            done
        done
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    scil_tractogram_print_info -h
    scil_bundle_compute_endpoints_map -h
    scil_volume_stats_in_ROI -h
    scil_bundle_mean_std -h
    scil_bundle_shape_measures -h
    scil_tractogram_count_streamlines -h
    scil_bundle_volume_per_label -h
    scil_bundle_mean_std -h
    scil_json_merge_entries -h

    touch ${prefix}__length_stats.json
    touch ${prefix}__endpoints_map_raw.json
    touch ${prefix}__endpoints_metric_stats.json
    touch ${prefix}__mean_std.json
    touch ${prefix}__volume.json
    touch ${prefix}__volume_lesions.json
    touch ${prefix}__streamline_count.json
    touch ${prefix}__streamline_count_lesions.json
    touch ${prefix}__volume_per_label.json
    touch ${prefix}__volume_per_label_lesions.json
    touch ${prefix}__mean_std_per_point.json
    touch ${prefix}_endpoints_map_head.nii.gz
    touch ${prefix}_endpoints_map_tail.nii.gz
    touch ${prefix}__lesion_stats.json
    touch ${prefix}_lesion_map.nii.gz
    touch ${prefix}__tractometry_mqc.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
