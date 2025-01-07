process CONNECTIVITY_VISUALIZE {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
    tuple val(meta), path(matrix), path (atlas_labels), path(labels_list)

    output:
    tuple val(meta), path("*.png"), emit: figure
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    String matrix_list = matrix.join(", ").replace(',', '')
    def args = ""
    if (atlas_labels) args += [" --lookup_table $atlas_labels "]
    if (labels_list) args += [" --labels_list $labels_list "]

    """
    for matrix in $matrix_list; do
        scil_viz_connectivity.py \$matrix \${matrix/.npy/_matrix.png} \
            --name_axis --display_legend --histogram \${matrix/.npy/_histogram.png} \
            --nb_bins 50 --exclude_zeros --axis_text_size 5 5 \
            $args
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    matrix_list = matrix.join(", ").replace(',', '')
    """
    for metric in $matrix_list; do
        base_name=\$(basename "\${metric}" .npy)
        touch "\${base_name}.png"
    done

    scil_viz_connectivity.py -h

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
