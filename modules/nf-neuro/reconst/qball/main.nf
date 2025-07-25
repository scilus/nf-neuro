process RECONST_QBALL {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
    tuple val(meta), path(dwi), path(bval), path(bvec), path(mask)

    output:
        tuple val(meta), path("*__gfa.nii.gz")           , emit: gfa, optional: true
        tuple val(meta), path("*__peaks.nii.gz")        , emit: peaks, optional: true
        tuple val(meta), path("*__peak_indices.nii.gz")        , emit: peak_indices, optional: true
        tuple val(meta), path("*__sh.nii.gz")       , emit: sh, optional: true
        tuple val(meta), path("*__nufo.nii.gz")             , emit: nufo, optional: true
        tuple val(meta), path("*__a_power.nii.gz")         , emit: a_power, optional: true
        path "versions.yml"                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def set_mask = task.ext.mask ? "--mask $mask" : ""
    def b0_threshold = task.ext.b0_threshold ? "--b0_threshold " + task.ext.b0_threshold : ""

    if ( task.ext.gfa ) gfa = "--gfa_fODF ${prefix}__gfa.nii.gz" else gfa = ""
    if ( task.ext.peaks ) peaks = "--peaks ${prefix}__peaks.nii.gz" else peaks = ""
    if ( task.ext.peak_indices ) peak_indices = "--peak_indices ${prefix}__peak_indices.nii.gz" else peak_indices = ""
    if ( task.ext.sh) sh = "--sh ${prefix}__sh.nii.gz" else sh = ""
    if ( task.ext.nufo) nufo = "--nufo ${prefix}__nufo.nii.gz" else nufo = ""
    if ( task.ext.a_power) a_power = "--a_power ${prefix}__a_power.nii.gz" else a_power = ""
    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1

    scil_qball_metrics.py $dwi $bval $bvec $set_mask --not_all \
    $gfa $peaks $peak_indices $sh $nufo $a_power $b0_threshold
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    scil_qball_metrics.py -h

    touch ${prefix}__gfa.nii.gz
    touch ${prefix}__peaks.nii.gz
    touch ${prefix}__peak_indices.nii.gz
    touch ${prefix}__sh.nii.gz
    touch ${prefix}__nufo.nii.gz
    touch ${prefix}__a_power.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
