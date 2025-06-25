process BUNDLE_COLORING {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilpy_2.1.0.sif':
        'scilus/scilpy:2.1.0' }"

    input:
        tuple val(meta), path(bundles)

    output:
        tuple val(meta), path("*_colored.trk")      , emit: bundles
        path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def json_str = groovy.json.JsonOutput.toJson(task.ext.colors)
    String bundles_list = bundles.join(", ").replace(',', '')

    """
    echo '$json_str' >> colors.json
    scil_tractogram_assign_uniform_color.py --dict_colors colors.json \
        --out_suffix "_colored" $bundles_list

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list --disable-pip-version-check --no-python-version-warning | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    String bundles_list = bundles.join(", ").replace(',', '')
    """
    for bundle in $bundles_list; do
        bname=\$(basename \$bundle .\${ext})
        touch \${bname}_colored.trk
    done

    scil_tractogram_assign_uniform_color.py -h

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list --disable-pip-version-check --no-python-version-warning | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
