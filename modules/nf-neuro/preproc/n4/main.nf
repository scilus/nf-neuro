process PREPROC_N4 {
    tag "$meta.id"
    label 'process_medium'
    label "process_high_memory"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
    tuple val(meta), path(image), path(ref), path(ref_mask)

    output:
    tuple val(meta), path("*__image_n4.nii.gz")     , emit: image
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def bspline_knot_per_voxel = task.ext.bspline_knot_per_voxel ? "$task.ext.bspline_knot_per_voxel" : "1"
    def shrink_factor = task.ext.shrink_factor ? "$task.ext.shrink_factor" : "1"
    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1
    export ANTS_RANDOM_SEED=1234

    if [[ -f "$ref" ]]
    then
        spacing=\$(mrinfo -spacing $ref | tr " " "\\n" | sort -n | tail -1)
        knot_spacing=\$(echo "\$spacing/$bspline_knot_per_voxel" | bc -l)

        N4BiasFieldCorrection -i $ref\
            -o [${prefix}__ref_n4.nii.gz, bias_field_ref.nii.gz]\
            -c [300x150x75x50, 1e-6] -v 1\
            -b [\${knot_spacing}, 3] \
            -s $shrink_factor

        scil_dwi_apply_bias_field.py $image bias_field_ref.nii.gz\
            ${prefix}__image_n4.nii.gz --mask $ref_mask -f

    else
        N4BiasFieldCorrection -i $image\
            -o [${prefix}__image_n4.nii.gz, bias_field_t1.nii.gz]\
            -c [300x150x75x50, 1e-6] -v 1
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
        N4BiasFieldCorrection: \$(N4BiasFieldCorrection --version 2>&1 | sed -n 's/ANTs Version: v\\([0-9.]\\+\\)/\\1/p')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    N4BiasFieldCorrection -h
    scil_dwi_apply_bias_field.py -h

    touch ${prefix}__image_n4.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
        N4BiasFieldCorrection: \$(N4BiasFieldCorrection --version 2>&1 | sed -n 's/ANTs Version: v\\([0-9.]\\+\\)/\\1/p')
    END_VERSIONS
    """
}
