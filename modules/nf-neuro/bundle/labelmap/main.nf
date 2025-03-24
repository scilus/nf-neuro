process BUNDLE_LABELMAP {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
        tuple val(meta), path(bundles), path(centroids)

    output:
    tuple val(meta), path("*_labels.nii.gz")    , emit: labels
    tuple val(meta), path("*_labels.trk")       , emit: labels_trk
    tuple val(meta), path("*_distances.nii.gz") , emit: distances
    tuple val(meta), path("*_distances.trk")    , emit: distances_trk
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def nb_points = task.ext.nb_points ? "--nb_pts ${task.ext.nb_points} ": ""
    def colormap = task.ext.colormap ? "--colormap ${task.ext.colormap} ": ""
    def new_labelling = task.ext.new_labelling ? "--new_labelling ": ""

    """
    bundles=(${bundles.join(" ")})
    centroids=(${centroids.join(" ")})

    for index in \${!bundles[@]};
        do ext=\${bundles[index]#*.}
        bname=\$(basename \${bundles[index]} .\${ext})

        scil_bundle_label_map.py \${bundles[index]} \${centroids[index]} \
            tmp_out $nb_points $colormap $new_labelling -f

        mv tmp_out/labels_map.nii.gz ${prefix}__\${bname}_labels.nii.gz
        mv tmp_out/distance_map.nii.gz ${prefix}__\${bname}_distances.nii.gz
        mv tmp_out/labels.trk ${prefix}__\${bname}_labels.trk
        mv tmp_out/distance.trk ${prefix}__\${bname}_distances.trk
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    scil_bundle_label_map.py -h

    for index in \${!bundles[@]};
        do ext=\${bundles[index]#*.}
        bname=\$(basename \${bundles[index]} .\${ext})

        touch ${prefix}__\${bname}_labels.nii.gz
        touch ${prefix}__\${bname}_labels.trk
        touch ${prefix}__\${bname}_distances.nii.gz
        touch ${prefix}__\${bname}_distances.trk
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
