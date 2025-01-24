
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
    scil_volume_math.py multiplication $t1 ${prefix}__t1_bet_mask.nii.gz \
        ${prefix}__t1_bet.nii.gz --data_type float32

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
        ants: \$(antsRegistration --version | grep "Version" | sed -E 's/.*v([0-9]+\\+\\).*/\\1/')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """

    touch ${prefix}__t1_bet.nii.gz
    touch ${prefix}__t1_bet_mask.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
        ants: \$(antsRegistration --version | grep "Version" | sed -E 's/.*v([0-9]+\\+\\).*/\\1/')
    END_VERSIONS

    function handle_code () {
    local code=\$?
    ignore=( 1 )
    exit \$([[ " \${ignore[@]} " =~ " \$code " ]] && echo 0 || echo \$code)
    }
    trap 'handle_code' ERR

    antsBrainExtraction.sh
    scil_volume_math.py -h

    """
}
