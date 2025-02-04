process CONNECTIVITY_AFDFIXEL {
    tag "$meta.id"
    label 'process_single'

    container "${ 'scilus/scilus:latest' }"

    input:
    tuple val(meta), path(hdf5), path(fodf)

    output:
    tuple val(meta), path("*afd_fixel.h5")      , emit: hdf5
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    def length_weighting = task.ext.length_weighting ? "--length_weighting ": ""
    def sh_basis = task.ext.sh_basis ? "--sh_basis $task.ext.sh_basis": ""

    """
    scil_bundle_mean_fixel_afd_from_hdf5.py $hdf5 $fodf \
        "${prefix}__afd_fixel.h5" \
        $length_weighting \
        $sh_basis \
        --processes $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}__afd_fixel.h5

    scil_bundle_mean_fixel_afd_from_hdf5.py -h

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
