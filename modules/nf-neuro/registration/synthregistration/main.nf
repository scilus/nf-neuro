process REGISTRATION_SYNTHREGISTRATION {
    tag "$meta.id"
    label 'process_single'

    container "freesurfer/synthmorph:3"
    containerOptions "--entrypoint ''"

    input:
    tuple val(meta), path(moving), path(fixed)

    output:
    tuple val(meta), path("*__output_warped.nii.gz"), emit: warped_image
    tuple val(meta), path("*__deform_warp.nii.gz"), emit: deform_transform
    tuple val (meta), path("*__init_warp.lta"), emit: init_transform
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def init = task.ext.init ? "-m " + task.ext.init : "-m affine"
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

    mri_synthmorph -j $task.cpus ${init} -t ${prefix}__init_warp.lta $moving $fixed
    mri_synthmorph -j $task.cpus ${warp} ${gpu} ${lambda} ${steps} ${extent} ${weight} -i ${prefix}__init_warp.lta  -t ${prefix}__deform_warp.nii.gz -o ${prefix}__output_warped.nii.gz $moving $fixed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        Freesurfer: 7.4
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mri_synthmorph -h

    touch ${prefix}__output_warped.nii.gz
    touch ${prefix}__deform_warp.nii.gz
    touch ${prefix}__init_warp.lta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        Freesurfer: 7.4
    END_VERSIONS
    """
}
