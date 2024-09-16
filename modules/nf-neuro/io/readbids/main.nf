process IO_READBIDS {
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.0.sif':
        'scilus/scilus:2.0.0' }"

    input:
        path(bids_folder)
        path(fsfolder)
        path(bidsignore)

    output:
        path("tractoflow_bids_struct.json")             , emit: bidsstructure
        path "versions.yml"                             , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def fsfolder = task.ext.fs_folder ? "--fs " + task.ext.fs_folder : ''
    def bidsignore = task.ext.bidsignore ? "--bids_ignore " + task.ext.bidsignore : ''
    def readout = task.ext.readout ? "--readout " + task.ext.readout : ""
    def clean_flag = task.ext.clean_bids ? '--clean ' : ''

    """
    scil_bids_validate.py $bids_folder tractoflow_bids_struct.json\
        $readout \
        $clean_flag\
        $fsfolder\
        $bidsignore\
        -v

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.0.0
    END_VERSIONS
    """


    stub:
    def args = task.ext.args ?: ''
    """
    scil_bids_validate.py -h

    touch tractoflow_bids_struct.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: 2.0.0
    END_VERSIONS
    """
}
