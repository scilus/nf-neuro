process IMAGE_RESAMPLE {
    tag "$meta.id"
    label 'process_single'
    label 'process_high_memory'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
    tuple val(meta), path(image), path(ref) /* optional, input = [] */

    output:
    tuple val(meta), path("*_resampled.nii.gz") , emit: image
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.suffix ? "${task.ext.first_suffix}_resampled" : "resampled"
    def reference = "$ref" ? "--ref $ref" : ""
    def voxel_size = task.ext.voxel_size ? "--voxel_size " + task.ext.voxel_size : ""
    def volume_size = task.ext.volume_size ? "--volume_size " + task.ext.volume_size : ""
    def iso_min = task.ext.iso_min ? "--iso_min" : ""
    def interp = task.ext.interp ? "--interp " + task.ext.interp : ""
    def f = task.ext.f ? "-f" : ""
    def enforce_dimensions = task.ext.enforce_dimensions ? "--enforce_dimensions" : ""

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1

    scil_volume_resample.py $image ${prefix}_${suffix}.nii.gz \
        $voxel_size $volume_size $reference $iso_min \
        $f $enforce_dimensions $interp

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.suffix ? "${task.ext.first_suffix}_resampled" : "resampled"
    """
    scil_volume_resample.py -h

    touch ${prefix}_${suffix}.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
