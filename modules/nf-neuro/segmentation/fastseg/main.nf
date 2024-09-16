process SEGMENTATION_FASTSEG {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
        tuple val(meta), path(image), path(lesion)

    output:
        tuple val(meta), path("*mask_wm.nii.gz")                , emit: wm_mask
        tuple val(meta), path("*mask_gm.nii.gz")                , emit: gm_mask
        tuple val(meta), path("*mask_csf.nii.gz")               , emit: csf_mask
        tuple val(meta), path("*map_wm.nii.gz")                 , emit: wm_map
        tuple val(meta), path("*map_gm.nii.gz")                 , emit: gm_map
        tuple val(meta), path("*map_csf.nii.gz")                , emit: csf_map
        path "versions.yml"                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1

    fast -t 1 -n 3\
        -H 0.1 -I 4 -l 20.0 -g -o t1.nii.gz $image
    scil_volume_math.py convert t1_seg_2.nii.gz ${prefix}__mask_wm.nii.gz --data_type uint8
    scil_volume_math.py convert t1_seg_1.nii.gz ${prefix}__mask_gm.nii.gz --data_type uint8
    scil_volume_math.py convert t1_seg_0.nii.gz ${prefix}__mask_csf.nii.gz --data_type uint8
    mv t1_pve_2.nii.gz ${prefix}__map_wm.nii.gz
    mv t1_pve_1.nii.gz ${prefix}__map_gm.nii.gz
    mv t1_pve_0.nii.gz ${prefix}__map_csf.nii.gz

    if [[ -f "$lesion" ]];
    then
        scil_volume_math.py union ${prefix}__mask_wm.nii.gz $lesion ${prefix}__mask_wm.nii.gz --data_type uint8 -f
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.0.2
        fsl: \$(flirt -version 2>&1 | sed -n 's/FLIRT version \\([0-9.]\\+\\)/\\1/p')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    fast -h
    scil_volume_math.py -h

    touch ${prefix}__mask_wm.nii.gz
    touch ${prefix}__mask_gm.nii.gz
    touch ${prefix}__mask_csf.nii.gz
    touch ${prefix}__map_wm.nii.gz
    touch ${prefix}__map_gm.nii.gz
    touch ${prefix}__map_csf.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.0.0
        fsl: \$(flirt -version 2>&1 | sed -n 's/FLIRT version \\([0-9.]\\+\\)/\\1/p')
    END_VERSIONS
    """
}
