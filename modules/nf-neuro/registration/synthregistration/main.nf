process REGISTRATION_SYNTHREGISTRATION {
    tag "$meta.id"
    label 'process_high'

    container "freesurfer/synthmorph:4"
    containerOptions {
        (workflow.containerEngine == 'docker') ? '--entrypoint "" --env PYTHONPATH="/freesurfer/env/lib/python3.11/site-packages"' : "--env PYTHONPATH='/freesurfer/env/lib/python3.11/site-packages'"
    }

    input:
    tuple val(meta), path(moving), path(fixed)

    output:
    tuple val(meta), path("*__output_warped.nii.gz")        , emit: warped_image
    tuple val(meta), path("*__deform_warp.nii.gz")          , emit: warp
    tuple val(meta), path("*__affine_warp.lta")             , emit: affine
    path "versions.yml"                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    def affine = task.ext.affine ? "-m " + task.ext.affine : "-m affine"
    def warp = task.ext.warp ? "-m " + task.ext.warp : "-m deform"
    def header = task.ext.header ? "-H" : ""
    def gpu = task.ext.gpu ? "-g" : ""
    def lambda = task.ext.lambda ? "-r " + task.ext.lambda : ""
    def steps = task.ext.steps ? "-n " + task.ext.steps : ""
    def extent = task.ext.extent ? "-e " + task.ext.extent : ""
    def weight = task.ext.weight ? "-w " + task.ext.weight : ""

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1
    mri_synthmorph -j $task.cpus ${affine} -t ${prefix}__affine_warp.lta $moving $fixed
    mri_synthmorph -j $task.cpus ${warp} ${gpu} ${lambda} ${steps} ${extent} ${weight} -i ${prefix}__affine_warp.lta  -t ${prefix}__deform_warp.nii.gz -o ${prefix}__output_warped.nii.gz $moving $fixed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        synthmoprh: 4
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mri_synthmorph -h

    touch ${prefix}__output_warped.nii.gz
    touch ${prefix}__deform_warp.nii.gz
    touch ${prefix}__affine_warp.lta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        synthmoprh: 4
    END_VERSIONS
    """
}
