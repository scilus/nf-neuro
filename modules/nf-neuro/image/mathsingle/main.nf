process IMAGE_MATHSINGLE {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
        tuple val(meta), path(image)

    output:
        tuple val(meta), path("*.nii.gz")        , emit: image
        path "versions.yml"                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    assert task.ext.operation in ['lower_threshold', 'upper_threshold',
    'lower_threshold_eq', 'upper_threshold_eq', 'lower_threshold_otsu',
    'upper_threshold_otsu', 'lower_clip', 'upper_clip', 'absolute_value',
    'round', 'ceil', 'floor', 'normalize_sum', 'normalize_max',
    'log_10', 'log_e', 'convert', 'invert', 'dilation', 'erosion',
    'closing', 'opening', 'blur'] : "Operation ${task.ext.operation} not \
    supported. Supported operations are: \
    'lower_threshold', 'upper_threshold', 'lower_threshold_eq', \
    'upper_threshold_eq', 'lower_threshold_otsu', 'upper_threshold_otsu', \
    'lower_clip', 'upper_clip', 'absolute_value', 'round', 'ceil', \
    'floor', 'normalize_sum', 'normalize_max', 'log_10', 'log_e', \
    'convert', 'invert', 'dilation', 'erosion', 'closing', 'opening', \
    'blur'"

    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.suffix ?: "output"
    def value = task.ext.value ?: ""
    def data_type = task.ext.data_type ?: "float32"
    def exclude_background = task.ext.exclude_background ? "--exclude_background" : ""
    """
    scil_volume_math.py ${task.ext.operation} $image $value \
        ${prefix}__${suffix}.nii.gz --data_type $data_type $exclude_background

        cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.suffix ?: "output"
    """
    scil_volume_math.py -h
    touch ${prefix}_${suffix}.nii.gz


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
