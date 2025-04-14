

process STATS_MERGEJSON {
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_latest.sif':
        'scilus/scilus:latest' }"

    input:
    tuple val(meta), path(jsons)

    output:
    path("*_stats.json")  , emit: json
    path("*_stats.xlsx")  , emit: xlsx
    path "versions.yml"   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${task.ext.prefix}"
    def suffix = task.ext.suffix ? "${task.ext.suffix}_stats" : "stats"
    def per_point = task.ext.per_point ? true : false
    def average_last_layer = task.ext.average_last_layer ? "--average_last_layer" : ""
    def recursive = task.ext.recursive ? "--recursive" : ""
    def no_list = task.ext.no_list ? "--no_list" : ""
    def stats_over_population = task.ext.stats_over_population ? "--stats_over_population" : ""

    """
    if $per_point;
        then
        for json in $jsons
            do scil_json_merge_entries.py \$json \${json/.json/_avg.json} --remove_parent_key --recursive $average_last_layer
        done
            scil_json_merge_entries.py *_avg.json ${prefix}.json --recursive
    else
        scil_json_merge_entries.py $jsons ${prefix}.json $no_list $recursive
    fi

    scil_json_harmonize_entries.py ${prefix}.json ${prefix}_${suffix}.json -f -v --sort_keys
    scil_json_convert_entries_to_xlsx.py ${prefix}_${suffix}.json ${prefix}_${suffix}.xlsx $stats_over_population

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def suffix = task.ext.first_suffix ? "${task.ext.first_suffix}_stats" : "_stats"
    def prefix = task.ext.prefix ?: "${task.ext.prefix}"

    """
    scil_json_merge_entries.py -h
    scil_json_harmonize_entries.py -h
    scil_json_convert_entries_to_xlsx.py -h

    touch ${prefix}_${suffix}.json
    touch ${prefix}_${suffix}.xlsx

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
