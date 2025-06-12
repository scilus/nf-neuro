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
    def prefix = task.ext.prefix ?: "${meta.id}"
    def nb_voxels_between_knots = task.ext.nb_voxels_between_knots ?: "8"
    def shrink_factor = task.ext.shrink_factor ?: "4"
    def maxiter = task.ext.maxiter ?: "1000"
    def miniter = task.ext.miniter ?: "100"
    def retain = task.ext.retain ?: "0.6"
    def mask = ref_mask ? "-w $ref_mask" : ""
    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$task.cpus
    export ANTS_RANDOM_SEED=1234

    if [[ -f "$ref" ]]
    then
        cp $ref reference_for_formula.nii.gz
    else
        cp $image reference_for_formula.nii.gz
    fi

    # Fetching the smallest dimension of the reference volume and the resolution.
    spacing=\$(PrintHeader reference_for_formula.nii.gz 1 | tr 'x' '\\n' | sort -n | head -n 1)
    smallest_dim=\$(PrintHeader reference_for_formula.nii.gz 2 | tr 'x' '\\n' | sort -n | head -n 1)

    # Computing the optimal number of stages to include in the pyramid.
    if (( \$(echo "\$smallest_dim <= $nb_voxels_between_knots * $shrink_factor" | bc -l) )); then
        n_stages="1"
    else
        logval=\$(echo "l(\$smallest_dim / ($nb_voxels_between_knots * $shrink_factor)) / l(2)" | bc -l)
        n_stages=\$(echo "\$logval" | awk '{ if (\$1 == int(\$1)) print int(\$1)+1; else print int(\$1)+2 }')
    fi

    # Computing the BSpline parameters.
    bspline=\$(echo "2^(\$n_stages - 1) * $nb_voxels_between_knots * $shrink_factor * \$spacing" | bc -l)

    # Setting the iterations.
    if [[ "\$n_stages" -eq 1 ]]; then
        iterations="$maxiter"
    else
        iterations=""
        slope=\$(echo "scale=6; ($miniter - $maxiter) / (1 - $retain)" | bc -l)
        intercept=\$(echo "scale=6; $maxiter - \$slope * $retain" | bc -l)
        n=\$(printf "%.0f" \$n_stages)
        step=\$(echo "scale=6; 1 / (\$n - 1)" | bc -l)
        for ((idx=0; idx<\$n; idx++)); do
            i=\$(echo "scale=6; \$idx * \$step" | bc -l)
            is_less=\$(echo "\$i < $retain" | bc)

            if [[ "\$is_less" -eq 1 ]]; then
                iter=$maxiter
            else
                val=\$(echo "scale=6; \$i * \$slope + \$intercept" | bc -l)
                iter=\$(printf "%.0f" "\$val")
            fi

            if [[ -z "\$iterations" ]]; then
                iterations="\$iter"
            else
                iterations="\${iterations}x\$iter"
            fi
        done
    fi

    echo "Number of stages: \$n_stages"
    echo "Spacing: \$spacing"
    echo "Smallest dimension: \$smallest_dim"
    echo "Shrink factor: $shrink_factor"
    echo "Number of voxel between knots: $nb_voxels_between_knots"
    echo "Iterations: \$iterations"
    echo "BSpline: \$bspline"

    if [[ -f "$ref" ]]
    then
        N4BiasFieldCorrection -i $ref\
            -o [${prefix}__ref_n4.nii.gz, bias_field_ref.nii.gz]\
            -c [\$iterations, 1e-6] -v 0\
            $mask\
            -b [\$bspline, 3] \
            -s $shrink_factor
        scil_dwi_apply_bias_field.py $image bias_field_ref.nii.gz\
            ${prefix}__image_n4.nii.gz --mask $ref_mask -f
    else
        N4BiasFieldCorrection -i $image\
            -o [${prefix}__image_n4.nii.gz, bias_field_t1.nii.gz]\
            -c [\$iterations, 1e-6] -v 0\
            $mask\
            -b [\$bspline, 3] \
            -s $shrink_factor
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
        N4BiasFieldCorrection: \$(N4BiasFieldCorrection --version 2>&1 | sed -n 's/ANTs Version: v\\([0-9.]\\+\\)/\\1/p')
    END_VERSIONS
    """

    stub:
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
