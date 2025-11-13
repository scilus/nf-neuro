process RECONST_MEANDIFFUSIVITYPRIORS {
    tag "all"
    label 'process_single'

    container "scilus/scilpy:2.2.0_cpu"

    input:
        path(iso_diff_list)
        path(para_diff_list)
        path(perp_diff_list) //** optional, input = [] **//

    output:
        path "mean_iso_diff.txt"     , emit: mean_iso_diff
        path "mean_para_diff.txt"    , emit: mean_para_diff
        path "mean_perp_diff.txt"    , emit: mean_perp_diff, optional: true
        env  'mean_iso_diff'         , emit: mean_iso_diff_val
        env  'mean_para_diff'        , emit: mean_para_diff_val
        env  'mean_perp_diff'        , emit: mean_perp_diff_val, optional: true
        path "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    cat ${para_diff_list} > all_para_diff.txt
    awk '{ total += \$1; count++ } END { print total/count }' all_para_diff.txt > mean_para_diff.txt
    cat ${iso_diff_list} > all_iso_diff.txt
    awk '{ total += \$1; count++ } END { print total/count }' all_iso_diff.txt > mean_iso_diff.txt

    if [[ -e ${perp_diff_list} ]]
    then
        cat ${perp_diff_list} > all_perp_diff.txt
        awk '{ total += \$1; count++ } END { print total/count }' all_perp_diff.txt > mean_perp_diff.txt
    fi

    # Set output environment variables
    mean_iso_diff=\$(cat mean_iso_diff.txt)
    mean_para_diff=\$(cat mean_para_diff.txt)
    if [[ -e mean_perp_diff.txt ]]
    then
        mean_perp_diff=\$(cat mean_perp_diff.txt)
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
    touch all_para_diff.txt
    touch all_perp_diff.txt
    touch all_iso_diff.txt

    touch mean_para_diff.txt
    touch mean_perp_diff.txt
    touch mean_iso_diff.txt

    # NOTE: We don't actually run scilpy here, but this module was designed to
    # complement the diffusivity priors computation, which does use this scilpy version.
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
