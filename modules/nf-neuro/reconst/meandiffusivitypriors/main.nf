process RECONST_MEANDIFFUSIVITYPRIORS {
    tag "all"
    label 'process_single'

    container "scilus/scilpy:2.2.1_cpu"

    input:
        path(para_diff_list)
        path(iso_diff_list)
        path(perp_diff_list) //** optional, input = [] **//

    output:
        path "mean_para_diff.txt", emit: mean_para_diff_file
        path "mean_iso_diff.txt" , emit: mean_iso_diff_file
        path "mean_perp_diff.txt", emit: mean_perp_diff_file, optional: true

        env  'mean_para_diff'    , emit: mean_para_diff
        env  'std_para_diff'     , emit: std_para_diff
        env  'min_para_diff'     , emit: min_para_diff
        env  'max_para_diff'     , emit: max_para_diff
        env  'mean_iso_diff'     , emit: mean_iso_diff
        env  'std_iso_diff'      , emit: std_iso_diff
        env  'min_iso_diff'      , emit: min_iso_diff
        env  'max_iso_diff'      , emit: max_iso_diff
        env  'mean_perp_diff'    , emit: mean_perp_diff, optional: true
        env  'std_perp_diff'     , emit: std_perp_diff, optional: true
        env  'min_perp_diff'     , emit: min_perp_diff, optional: true
        env  'max_perp_diff'     , emit: max_perp_diff, optional: true

        path "versions.yml"      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """

    average_files() {
        awk 'FNR==1 && NR==1 {header=\$0; next}  # Save header from first file
            FNR>1 {for (i=1; i<=NF; i++) sum[i]+=\$i; n++}  # Sum all numeric values
            END {
                print header;
                for (i=1; i<=NF; i++) printf "%g%s", sum[i]/n, (i==NF?ORS:OFS)
            }' "\$@"
    }

    average_files ${para_diff_list} > mean_para_diff.txt
    average_files ${iso_diff_list} > mean_iso_diff.txt

    if [[ -e ${perp_diff_list} ]]
    then
        average_files ${perp_diff_list} > mean_perp_diff.txt
    fi

    # Set output environment variables
    read mean_para_diff std_para_diff min_para_diff max_para_diff < <(awk 'NR==2' mean_para_diff.txt)
    read mean_iso_diff std_iso_diff min_iso_diff max_iso_diff < <(awk 'NR==2' mean_iso_diff.txt)

    if [[ -e mean_perp_diff.txt ]]
    then
        read mean_perp_diff std_perp_diff min_perp_diff max_perp_diff < <(awk 'NR==2' mean_perp_diff.txt)
    fi

    # NOTE: We don't actually run scilpy here, but this module was designed to
    # complement the diffusivity priors computation, which does use this scilpy version.
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    """
    touch mean_para_diff.txt
    touch mean_perp_diff.txt
    touch mean_iso_diff.txt

    # Set output environment variables
    mean_para_diff=0
    std_para_diff=0
    min_para_diff=0
    max_para_diff=0
    mean_iso_diff=0
    std_iso_diff=0
    min_iso_diff=0
    max_iso_diff=0
    mean_perp_diff=0
    std_perp_diff=0
    min_perp_diff=0
    max_perp_diff=0

    # NOTE: We don't actually run scilpy here, but this module was designed to
    # complement the diffusivity priors computation, which does use this scilpy version.
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
