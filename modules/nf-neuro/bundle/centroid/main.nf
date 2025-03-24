process BUNDLE_CENTROID {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
        tuple val(meta), path(bundles)

    output:
        tuple val(meta), path("*_centroid_*.trk")           , emit: centroids
        path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def nb_points = task.ext.nb_points ?: 5

    """
    for bundle in ${bundles};
        do
        ext=\${bundle#*.}

        if [[ \$bundle == *"__"* ]]; then
            pos=\$((\$(echo \$bundle | grep -b -o __ | cut -d: -f1)+2))
            bname=\${bundle:\$pos}
            bname=\$(basename \$bname .\${ext})
        else
            bname=\$(basename \$bundle .\${ext})
        fi
        bname=\${bname/_ic/}
        scil_bundle_compute_centroid.py \$bundle centroid.\${ext} \
            --nb_points $nb_points -f
        scil_bundle_uniformize_endpoints.py centroid.\${ext} \
            ${prefix}__\${bname}_centroid_${nb_points}.\${ext} --auto
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def nb_points = task.ext.nb_points ?: 5
    """
    scil_bundle_compute_centroid.py -h
    scil_bundle_uniformize_endpoints.py -h

    for bundle in ${bundles};
        do \
        ext=\${bundle#*.}
        bname=\$(basename \${bundle} .\${ext})
        touch ${prefix}__\${bname}_centroid_${nb_points}.\${ext}
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
