import nextflow.util.BlankSeparatedList

def compute_noddi_priors ( fa, ad, rd, md, fa_min, fa_max, md_min, roi_radius, prefix, output_directory ) {
    """
    mkdir -p $output_directory

    scil_NODDI_priors.py $fa $ad $rd $md $fa_min $fa_max $md_min $roi_radius \
        --out_txt_1fiber_para $output_directory/${prefix}__para_diff.txt \
        --out_txt_1fiber_perp $output_directory/${prefix}__perp_diff.txt \
        --out_txt_ventricles $output_directory/${prefix}__iso_diff.txt
    """
}


def is_directory ( pathlike ) {
    return !(pathlike instanceof BlankSeparatedList) && pathlike.isDirectory()
}

process RECONST_DIFFUSIVITYPRIORS {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
        tuple val(meta), path(fa), path(ad), path(rd), path(md), path(priors)

    output:
        tuple val(meta), path("*__para_diff.txt")       , emit: para_diff, optional: true
        tuple val(meta), path("*__perp_diff.txt")       , emit: perp_diff, optional: true
        tuple val(meta), path("*__iso_diff.txt")        , emit: iso_diff, optional: true
        path("priors")                                  , emit: priors, optional: true
        path("mean_para_diff.txt")                      , emit: mean_para_diff, optional: true
        path("mean_perp_diff.txt")                      , emit: mean_perp_diff, optional: true
        path("mean_iso_diff.txt")                       , emit: mean_iso_diff, optional: true
        path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    def fa_min = task.ext.fa_min ? "--fa_min " + task.ext.fa_min : ""
    def fa_max = task.ext.fa_max ? "--fa_max " + task.ext.fa_max : ""
    def md_min = task.ext.md_min ? "--md_min " + task.ext.md_min : ""
    def roi_radius = task.ext.roi_radius ? "--roi_radius " + task.ext.roi_radius : ""

    def priors_directory = priors.isEmpty() ? "priors" : !is_directory(priors) ? "priors" : priors
    """
    ${ priors.isEmpty() ? compute_noddi_priors( fa, ad, md, rd, fa_min, fa_max, md_min, roi_radius, prefix, priors_directory ) : ""}

    ${ !priors.isEmpty() && !is_directory(priors) ? "mkdir -p priors && ln $priors priors" : "" }

    cat $priors_directory/*__para_diff.txt > all_para_diff.txt
    awk '{ total += \$1; count++ } END { print total/count }' all_para_diff.txt > mean_para_diff.txt
    cat $priors_directory/*__iso_diff.txt > all_iso_diff.txt
    awk '{ total += \$1; count++ } END { print total/count }' all_iso_diff.txt > mean_iso_diff.txt

    if [[ -e $priors_directory/*__perp_diff.txt ]]
    then
        cat $priors_directory/*__perp_diff.txt > all_perp_diff.txt
        awk '{ total += \$1; count++ } END { print total/count }' all_perp_diff.txt > mean_perp_diff.txt
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.0.2
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    scil_NODDI_priors.py -h

    mkdir priors
    touch priors/${prefix}__para_diff.txt
    touch priors/${prefix}__perp_diff.txt
    touch priors/${prefix}__iso_diff.txt

    touch "mean_para_diff.txt"
    touch "mean_perp_diff.txt"
    touch "mean_iso_diff.txt"


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.0.2
    END_VERSIONS
    """
}
