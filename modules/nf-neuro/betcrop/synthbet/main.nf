process BETCROP_SYNTHBET {
    tag "$meta.id"
    label 'process_single'

    container "freesurfer/freesurfer:7.4.1"

    input:
    tuple val(meta), path(image), path(weights) /* optional, input = [] */

    output:
    tuple val(meta), path("*__bet_image.nii.gz"), emit: bet_image
    tuple val(meta), path("*__brain_mask.nii.gz"), emit: brain_mask
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    def gpu = task.ext.gpu ? "--gpu" : ""
    def border = task.ext.border ? "-b " + task.ext.border : ""
    def nocsf = task.ext.nocsf ? "--no-csf" : ""
    def model = "$weights" ? "--model $weights" : ""

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$task.cpus
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1

    mri_synthstrip -i $image --out ${prefix}__bet_image.nii.gz --mask ${prefix}__brain_mask.nii.gz $gpu $border $nocsf $model

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        Freesurfer: \$(mri_convert -version | grep "freesurfer" | sed -E 's/.* ([0-9]+\\.[0-9]+\\.[0-9]+).*/\\1/')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}__bet_image.nii.gz
    touch ${prefix}__brain_mask.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        Freesurfer: \$(mri_convert -version | grep "freesurfer" | sed -E 's/.* ([0-9]+\\.[0-9]+\\.[0-9]+).*/\\1/')
    END_VERSIONS

    function handle_code () {
    local code=\$?
    ignore=( 1 )
    exit \$([[ " \${ignore[@]} " =~ " \$code " ]] && echo 0 || echo \$code)
    }
    trap 'handle_code' ERR

    mri_synthstrip -h
    """
}
