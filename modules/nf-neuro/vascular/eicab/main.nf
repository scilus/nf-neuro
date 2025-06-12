
process VASCULAR_EICAB {
    tag "$meta.id"
    label 'process_medium'

    container "${ 'felixdumais1/eicab:v1.0.1' }"
    containerOptions {
        (workflow.containerEngine == 'docker') ? '--entrypoint ""' : ''
    }

    input:
        tuple val(meta), path(in_tof)

    output:
        tuple val(meta), path("*_eicab")                  , emit: eicabdirectory
        tuple val(meta), path("*_eicab/*_eICAB_CW.nii.gz"), emit: eicabcw
        path "versions.yml"                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def out_folder = task.ext.out_folder ?: "${prefix}_eicab"
    def resolution = task.ext.resolution ?: "0.625"
    """
    /vessel_segmentation_snaillab/eICAB.sh -t $in_tof \
                                           -o $out_folder \
                                           -r $resolution

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vessel-segmentation: \$(pip list | grep vessel-segmentation | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_eicab/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vessel-segmentation: \$(pip list | grep vessel-segmentation | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
