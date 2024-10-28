
process BETCROP_ANTSBET {
    tag "$meta.id"
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
    tuple val(meta), path(t1), path(template), path(tissues_probabilities), path(mask), path(initial_affine)

    output:
    tuple val(meta), path("*t1_bet.nii.gz")     , emit: t1
    tuple val(meta), path("*t1_bet_mask.nii.gz"), emit: mask
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = []
    if (mask) args += ["-f $mask"]
    if (initial_affine) args += ["-r $initial_affine"]

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$task.cpus
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1
    export ANTS_RANDOM_SEED=1234

    antsBrainExtraction.sh -d 3 -a $t1 -o bet/ -u 0 \
        -e $template -m $tissues_probabilities ${args.join(' ')}
    scil_volume_math.py convert bet/BrainExtractionMask.nii.gz \
        ${prefix}__t1_bet_mask.nii.gz --data_type uint8
    mrcalc $t1 ${prefix}__t1_bet_mask.nii.gz -mult ${prefix}__t1_bet.nii.gz -nthreads $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
        mrtrix: \$(mrcalc -version 2>&1 | sed -n 's/== mrcalc \\([0-9.]\\+\\).*/\\1/p')
        ants: 2.4.3
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

        """
    antsBrainExtraction.sh -h
    scil_volume_math.py -h
    mrcalc -h

    touch ${prefix}__t1_bet.nii.gz
    touch ${prefix}__t1_bet_mask.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
        mrtrix: \$(mrcalc -version 2>&1 | sed -n 's/== mrcalc \\([0-9.]\\+\\).*/\\1/p')
        ants: 2.4.3
    END_VERSIONS
    """
}
