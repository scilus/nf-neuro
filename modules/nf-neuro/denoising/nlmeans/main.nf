
process DENOISING_NLMEANS {
    tag "$meta.id"
    label 'process_medium'

    container "scilus/scilpy:2.2.0_cpu"

    input:
    tuple val(meta), path(image), path(mask)

    output:
    tuple val(meta), path("*_denoised.nii.gz")      , emit: image
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def ncoils = task.ext.number_of_coils ? "--number_coils $task.ext.number_of_coils" : ""
    def gaussian = task.ext.gaussian ? "--gaussian" : ""
    def piesno = task.ext.piesno ? "--piesno" : ""
    def sigma = task.ext.sigma ? "--sigma $task.ext.sigma" : ""
    def args = ["--processes $task.cpus"]
    if (mask) args += ["--mask_denoise $mask"]

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1

    scil_denoising_nlmeans $image ${prefix}__denoised.nii.gz \
        $ncoils $piesno $gaussian $sigma ${args.join(" ")}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    scil_denoising_nlmeans -h

    touch ${prefix}_denoised.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
