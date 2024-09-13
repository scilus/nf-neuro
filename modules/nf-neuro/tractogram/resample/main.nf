process TRACTOGRAM_RESAMPLE {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
        tuple val(meta), path(tractograms)

    output:
        tuple val(meta), path("*_resampled.trk")       , emit: tractograms
        path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    def nb_points = task.ext.nb_points ?: 1
    def nb_streamlines = task.ext.nb_streamlines ?: 1000
    def never_upsample = task.ext.never_upsample ? "--never_upsample " : ""
    def seed = task.ext.seed ? "--seed ${task.ext.seed} " : ""
    def point_wise_std = task.ext.point_wise_std ? "--point_wise_std ${task.ext.point_wise_std} " : ""
    def tube_radius = task.ext.tube_radius ? "--tube_radius ${task.ext.tube_radius} " : ""
    def gaussian = task.ext.gaussian ? "--gaussian ${task.ext.gaussian} " : ""
    def error_rate = task.ext.error_rate ? "-e ${task.ext.error_rate} " : ""
    def keep_invalid = task.ext.keep_invalid ? "--keep_invalid " : ""
    def downsample_per_cluster = task.ext.downsample_per_cluster ? "--downsample_per_cluster " : ""
    def qbx_threshold = task.ext.qbx_threshold ? "--qbx_threshold ${task.ext.qbx_threshold} " : ""

    """
    for tractogram in ${tractograms};
        do
        ext=\${tractogram#*.}

        if [[ $nb_points -gt 1 ]]; then
            if [[ \$tractogram == *"__"* ]]; then
                pos=\$((\$(echo \$tractogram | grep -b -o __ | cut -d: -f1)+2))
                bname=\${tractogram:\$pos}
                bname=\$(basename \$bname .\${ext})
            else
                bname=\$(basename \$tractogram .\${ext})
            fi

            scil_tractogram_resample_nb_points.py \$tractogram \
                "${prefix}_\${bname}_resampled.\${ext}" \
                --nb_pts_per_streamline $nb_points -f
        else
            bname=\$(basename \${tractogram} .\${ext})

            scil_tractogram_resample.py \$tractogram $nb_streamlines \
                "${prefix}_\${bname}_resampled.\${ext}" \
                $never_upsample $seed $point_wise_std $tube_radius \
                $gaussian $error_rate $keep_invalid \
                $downsample_per_cluster $qbx_threshold
        fi
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.0.2
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    scil_tractogram_resample_nb_points.py -h
    scil_tractogram_resample.py -h

    for tractogram in ${tractograms};
        do \
        ext=\${tractogram#*.}
        bname=\$(basename \${tractogram} .\${ext})
        touch ${prefix}__\${bname}_resampled.\${ext}
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.0.2
    END_VERSIONS
    """
}
