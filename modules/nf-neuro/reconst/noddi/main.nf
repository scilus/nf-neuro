process RECONST_NODDI {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
        tuple val(meta), path(dwi), path(bval), path(bvec), path(mask), path(kernels)

    output:
        tuple val(meta), path("*__fit_dir.nii.gz")      , emit: dir, optional: true
        tuple val(meta), path("*__fit_FWF.nii.gz")      , emit: fwf, optional: true
        tuple val(meta), path("*__fit_NDI.nii.gz")      , emit: ndi, optional: true
        tuple val(meta), path("*__fit_ECVF.nii.gz")     , emit: ecvf, optional: true
        tuple val(meta), path("*__fit_ODI.nii.gz")      , emit: odi, optional: true
        path("kernels")                                 , emit: kernels, optional: true
        path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    def para_diff = task.ext.para_diff ? "--para_diff " + task.ext.para_diff : ""
    def iso_diff = task.ext.iso_diff ? "--iso_diff " + task.ext.iso_diff : ""
    def lambda1 = task.ext.lambda1 ? "--lambda1 " + task.ext.lambda1 : ""
    def lambda2 = task.ext.lambda2 ? "--lambda2 " + task.ext.lambda2 : ""
    def nb_threads = task.ext.nb_threads ? "--processes " + task.ext.nb_threads : ""
    def b_thr = task.ext.b_thr ? "--tolerance " + task.ext.b_thr : ""
    def set_kernels = kernels ? "--load_kernels $kernels" : "--save_kernels kernels/"
    def set_mask = mask ? "--mask $mask" : ""
    def compute_only = task.ext.compute_only && !kernels ? "--compute_only" : ""

    """
    scil_NODDI_maps.py $dwi $bval $bvec $para_diff $iso_diff $lambda1 \
        $lambda2 $nb_threads $b_thr $set_mask $set_kernels --skip_b0_check $compute_only

    if [ -z "${compute_only}" ];
    then
        mv results/fit_dir.nii.gz ${prefix}__fit_dir.nii.gz
        mv results/fit_NDI.nii.gz ${prefix}__fit_NDI.nii.gz # ICVF -> NDI
        mv results/fit_FWF.nii.gz ${prefix}__fit_FWF.nii.gz # ISOVF/FISO -> FWF
        mv results/fit_ODI.nii.gz ${prefix}__fit_ODI.nii.gz # OD -> ODI

        mrcalc 1 ${prefix}__fit_FWF.nii.gz -subtract \
            ${prefix}__fit_ECVF.nii.gz

        rm -rf results
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.0.2
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    scil_NODDI_maps.py -h
    scil_volume_math.py -h
    mkdir kernels
    touch "${prefix}__fit_dir.nii.gz"
    touch "${prefix}__fit_FWF.nii.gz"
    touch "${prefix}__fit_NDI.nii.gz"
    touch "${prefix}__fit_ECVF.nii.gz"
    touch "${prefix}__fit_ODI.nii.gz"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.0.2
    END_VERSIONS
    """
}
