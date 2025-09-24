process REGISTRATION_SYNTHREGISTRATION {
    tag "$meta.id"
    label 'process_high'

    container "freesurfer/synthmorph:4"
    containerOptions {
        (workflow.containerEngine == 'docker') ? '--entrypoint ""' : ""
    }

    input:
    tuple val(meta), path(fixed_image), path(moving_image)

    output:
    tuple val(meta), path("*__warped.nii.gz")                               , emit: image_warped
    tuple val(meta), path("*__forward{0,1,_standalone}_affine.lta")         , emit: affine, optional: true
    tuple val(meta), path("*__forward0_deform.nii.gz")                      , emit: warp, optional: true
    tuple val(meta), path("*__backward1_deform.nii.gz")                     , emit: inverse_warp, optional: true
    tuple val(meta), path("*__backward{0,_standalone}_affine.lta")          , emit: inverse_affine, optional: true
    tuple val(meta), path("*__forward[!_]*.{lta,nii.gz}", arity: '1..*')    , emit: image_transform
    tuple val(meta), path("*__backward[!_]*.{lta,nii.gz}", arity: '1..*')   , emit: inverse_image_transform
    tuple val(meta), path("*__backward[!_]*.{lta,nii.gz}", arity: '1..*')   , emit: tractogram_transform
    tuple val(meta), path("*__forward[!_]*.{lta,nii.gz}", arity: '1..*')    , emit: inverse_tractogram_transform
    path "versions.yml"                                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    def models = task.ext.models ?: ["affine", "deform"]
    def weights = (task.ext.weight ?: [null] * models.size()).collect{ it ? "-w $it" : "none" }.join(" ")
    def use_gpu = task.ext.use_gpu ? "-g" : ""
    def regularization = "-r ${task.ext.regularization ?: 0.5}"
    def steps = "-n ${task.ext.steps ?: 7 }"
    def extent = "-e ${task.ext.extent ?: 256}"
    def update_header = task.ext.disable_resampling ? "-H" : ""

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1
    export CUDA_VISIBLE_DEVICES="-1"

    echo "Available memory : ${task.memory}"

    moving=$moving_image
    mv $fixed_image fixed.nii.gz

    declare -A extension=(  ["affine"]="lta" \
                            ["rigid"]="lta" \
                            ["deform"]="nii.gz" \
                            ["joint"]="nii.gz" )

    weights=( $weights )

    i=0
    skip=0
    j=${models.size()}
    initializer=""
    init_assoc=""
    for model in ${models.join(" ")}
    do
    echo "Processing model: \$model"
    # Post-incrementation ensure no error on last index = 0
    ((j--))

    weight=""
    if [ "\${weights[i + skip]}" != "none" ]
    then
        weight="-w \${weights[i + skip]}"

        if [ "\$model" = "joint" ]
        then
            # Pre-incrementation ensure no error on first index = 0
            ((++skip))
            if [ "\${weights[i + skip]}" = "none" ]
            then
                echo "Joint deformations need 2 weights, only 1 given"
                exit 1
            else
                weight="\$weight -w \${weights[i + skip]}"
            fi
        fi
    fi

    args=""
    if [ \$model = "joint" ] || [ \$model = "deform" ]
    then
        args="$regularization $steps"
    else
        args="$update_header"
    fi

    if [ \$initializer ]
    then
        args="\$args -i \$initializer"
    fi

    mri_synthmorph register \$moving fixed.nii.gz -v -m \$model \$weight \$args \
        -t ${prefix}__forward\${j}_\$model.\${extension[\$model]} \
        -T ${prefix}__backward\${i}_\$model.\${extension[\$model]} \
        -o warped.nii.gz -j $task.cpus $extent $use_gpu

    if [ \$initializer ]
    then
        # rm \$initializer \$init_assoc
        # Retag initializer file to standalone using sed
        #  - replace the number after forward/backward to standalone
        mv \$initializer \$(echo "\$initializer" | sed -r 's/(_forward|_backward)[[:digit:]]+/\\1_standalone/')
        mv \$init_assoc \$(echo "\$init_assoc" | sed -r 's/(_forward|_backward)[[:digit:]]+/\\1_standalone/')
    fi

    if [ \${extension[\$model]} = "lta" ]
    then
        initializer=${prefix}__forward\${j}_\$model.\${extension[\$model]}
        init_assoc=${prefix}__backward\${i}_\$model.\${extension[\$model]}
    else
        moving=warped.nii.gz
    fi

    # Pre-incrementation ensure no error on first index = 0
    ((++i))

    done

    mv warped.nii.gz ${prefix}__warped.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        synthmorph: 4
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mri_synthmorph -h

    touch ${prefix}__warped.nii.gz
    touch ${prefix}__forward1_affine.lta
    touch ${prefix}__forward0_warp.nii.gz
    touch ${prefix}__backward1_warp.nii.gz
    touch ${prefix}__backward0_affine.lta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        synthmorph: 4
    END_VERSIONS
    """
}
