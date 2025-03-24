process BUNDLE_FIXELAFD {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
        tuple val(meta), path(bundles), path(fodf)

    output:
        tuple val(meta), path("*_afd_metric.nii.gz"), emit: fixel_afd
        path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    for bundle in $bundles;
        do\
        bname=\$(basename \${bundle} .trk)
        scil_compute_mean_fixel_afd_from_bundles.py \$bundle $fodf ${prefix}__\${bname}_afd_metric.nii.gz
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    scil_compute_mean_fixel_afd_from_bundles.py -h

    touch ${prefix}_test_afd_metric.nii.gz


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
