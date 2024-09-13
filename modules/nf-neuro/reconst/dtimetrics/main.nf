
process RECONST_DTIMETRICS {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
        tuple val(meta), path(dwi), path(bval), path(bvec), path(b0mask)

    output:
        tuple val(meta), path("*__ad.nii.gz")                      , emit: ad, optional: true
        tuple val(meta), path("*__evecs.nii.gz")                   , emit: evecs, optional: true
        tuple val(meta), path("*__evecs_v1.nii.gz")                , emit: evecs_v1, optional: true
        tuple val(meta), path("*__evecs_v2.nii.gz")                , emit: evecs_v2, optional: true
        tuple val(meta), path("*__evecs_v3.nii.gz")                , emit: evecs_v3, optional: true
        tuple val(meta), path("*__evals.nii.gz")                   , emit: evals, optional: true
        tuple val(meta), path("*__evals_e1.nii.gz")                , emit: evals_e1, optional: true
        tuple val(meta), path("*__evals_e2.nii.gz")                , emit: evals_e2, optional: true
        tuple val(meta), path("*__evals_e3.nii.gz")                , emit: evals_e3, optional: true
        tuple val(meta), path("*__fa.nii.gz")                      , emit: fa, optional: true
        tuple val(meta), path("*__ga.nii.gz")                      , emit: ga, optional: true
        tuple val(meta), path("*__rgb.nii.gz")                     , emit: rgb, optional: true
        tuple val(meta), path("*__md.nii.gz")                      , emit: md, optional: true
        tuple val(meta), path("*__mode.nii.gz")                    , emit: mode, optional: true
        tuple val(meta), path("*__norm.nii.gz")                    , emit: norm, optional: true
        tuple val(meta), path("*__rd.nii.gz")                      , emit: rd, optional: true
        tuple val(meta), path("*__tensor.nii.gz")                  , emit: tensor, optional: true
        tuple val(meta), path("*__nonphysical.nii.gz")             , emit: nonphysical, optional: true
        tuple val(meta), path("*__pulsation_std_dwi.nii.gz")       , emit: pulsation_std_dwi, optional: true
        tuple val(meta), path("*__pulsation_std_b0.nii.gz")        , emit: pulsation_std_b0, optional: true
        tuple val(meta), path("*__residual.nii.gz")                , emit: residual, optional: true
        tuple val(meta), path("*__residual_iqr_residuals.npy")     , emit: residual_iqr_residuals, optional: true
        tuple val(meta), path("*__residual_mean_residuals.npy")    , emit: residual_mean_residuals, optional: true
        tuple val(meta), path("*__residual_q1_residuals.npy")      , emit: residual_q1_residuals, optional: true
        tuple val(meta), path("*__residual_q3_residuals.npy")      , emit: residual_q3_residuals, optional: true
        tuple val(meta), path("*__residual_residuals_stats.png")   , emit: residual_residuals_stats, optional: true
        tuple val(meta), path("*__residual_std_residuals.npy")     , emit: residual_std_residuals, optional: true
        path "versions.yml"                                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def dwi_shell_tolerance = task.ext.dwi_shell_tolerance ? "--tolerance " + task.ext.dwi_shell_tolerance : ""
    def max_dti_shell_value = task.ext.max_dti_shell_value ?: 1500
    def b0_thr_extract_b0 = task.ext.b0_thr_extract_b0 ?: 10
    def b0_threshold = task.ext.b0_thr_extract_b0 ? "--b0_threshold $task.ext.b0_thr_extract_b0" : ""
    def dti_shells = task.ext.dti_shells ?: "\$(cut -d ' ' --output-delimiter=\$'\\n' -f 1- $bval | awk -F' ' '{v=int(\$1)}{if(v<=$max_dti_shell_value|| v<=$b0_thr_extract_b0)print v}' | uniq)"

    if ( b0mask ) args += " --mask $b0mask"
    if ( task.ext.ad ) args += " --ad ${prefix}__ad.nii.gz"
    if ( task.ext.evecs ) args += " --evecs ${prefix}__evecs.nii.gz"
    if ( task.ext.evals ) args += " --evals ${prefix}__evals.nii.gz"
    if ( task.ext.fa ) args += " --fa ${prefix}__fa.nii.gz"
    if ( task.ext.ga ) args += " --ga ${prefix}__ga.nii.gz"
    if ( task.ext.rgb ) args += " --rgb ${prefix}__rgb.nii.gz"
    if ( task.ext.md ) args += " --md ${prefix}__md.nii.gz"
    if ( task.ext.mode ) args += " --mode ${prefix}__mode.nii.gz"
    if ( task.ext.norm ) args += " --norm ${prefix}__norm.nii.gz"
    if ( task.ext.rd ) args += " --rd ${prefix}__rd.nii.gz"
    if ( task.ext.tensor ) args += " --tensor ${prefix}__tensor.nii.gz"
    if ( task.ext.nonphysical ) args += " --non-physical ${prefix}__nonphysical.nii.gz"
    if ( task.ext.pulsation ) args += " --pulsation ${prefix}__pulsation.nii.gz"
    if ( task.ext.residual ) args += " --residual ${prefix}__residual.nii.gz"


    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1

    scil_dwi_extract_shell.py $dwi $bval $bvec $dti_shells \
                dwi_dti_shells.nii.gz bval_dti_shells bvec_dti_shells \
                $dwi_shell_tolerance -f

    scil_dti_metrics.py dwi_dti_shells.nii.gz bval_dti_shells bvec_dti_shells \
        --not_all $args $b0_threshold -f

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list --disable-pip-version-check --no-python-version-warning | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    scil_dwi_extract_shell.py -h
    scil_dti_metrics.py -h

    touch ${prefix}__ad.nii.gz
    touch ${prefix}__evecs.nii.gz
    touch ${prefix}__evecs_v1.nii.gz
    touch ${prefix}__evecs_v2.nii.gz
    touch ${prefix}__evecs_v3.nii.gz
    touch ${prefix}__evals.nii.gz
    touch ${prefix}__evals_e1.nii.gz
    touch ${prefix}__evals_e2.nii.gz
    touch ${prefix}__evals_e3.nii.gz
    touch ${prefix}__fa.nii.gz
    touch ${prefix}__ga.nii.gz
    touch ${prefix}__rgb.nii.gz
    touch ${prefix}__md.nii.gz
    touch ${prefix}__mode.nii.gz
    touch ${prefix}__norm.nii.gz
    touch ${prefix}__rd.nii.gz
    touch ${prefix}__tensor.nii.gz
    touch ${prefix}__nonphysical.nii.gz
    touch ${prefix}__pulsation_std_dwi.nii.gz
    touch ${prefix}__pulsation_std_b0.nii.gz
    touch ${prefix}__residual.nii.gz
    touch ${prefix}__residual_iqr_residuals.npy
    touch ${prefix}__residual_mean_residuals.npy
    touch ${prefix}__residual_q1_residuals.npy
    touch ${prefix}__residual_q3_residuals.npy
    touch ${prefix}__residual_residuals_stats.png
    touch ${prefix}__residual_std_residuals.npy

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list --disable-pip-version-check --no-python-version-warning | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
