
process DENOISING_MPPCA {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
    tuple val(meta), path(dwi), path(mask)

    output:
    tuple val(meta), path("*_dwi_denoised.nii.gz")  , emit: image
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def extent = task.ext.extent ? "-extent " + task.ext.extent : ""
    def args = ["-nthreads ${task.cpus - 1}"]
    if (mask) args += ["-mask $mask"]

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1
    export MRTRIX_RNG_SEED=12345

    dwidenoise $dwi ${prefix}_dwi_denoised.nii.gz $extent ${args.join(" ")} -debug
    scil_volume_math.py lower_clip ${prefix}_dwi_denoised.nii.gz 0 \
        ${prefix}_dwi_denoised.nii.gz -f

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mrtrix: \$(mrcalc -version 2>&1 | sed -n 's/== mrcalc \\([0-9.]\\+\\).*/\\1/p')
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    dwidenoise -h
    fslmaths -h

    touch ${prefix}_dwi_denoised.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mrtrix: \$(mrcalc -version 2>&1 | sed -n 's/== mrcalc \\([0-9.]\\+\\).*/\\1/p')
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
