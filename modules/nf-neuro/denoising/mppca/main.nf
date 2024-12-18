
process DENOISING_MPPCA {
    tag "$meta.id"
    label 'process_medium'

    container "mrtrix3/mrtrix3:latest"

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
    export MRTRIX_RNG_SEED=112524

    dwidenoise $dwi ${prefix}_dwi_denoised.nii.gz $extent ${args.join(" ")}
    mrcalc ${prefix}_dwi_denoised.nii.gz 0 -gt ${prefix}_dwi_denoised.nii.gz 0 \
        -if ${prefix}_dwi_denoised.nii.gz -force

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mrtrix: \$(mrcalc -version 2>&1 | sed -n 's/== mrcalc \\([0-9.]\\+\\).*/\\1/p')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    dwidenoise -h
    mrcalc -h

    touch ${prefix}_dwi_denoised.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mrtrix: \$(mrcalc -version 2>&1 | sed -n 's/== mrcalc \\([0-9.]\\+\\).*/\\1/p')
    END_VERSIONS
    """
}
