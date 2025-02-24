process IO_READBIDS {
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
        path(bids_folder)
        path(fs_folder)
        path(bids_ignore)

    output:
        path("tractoflow_bids_struct.json")             , emit: bidsstructure
        path "versions.yml"                             , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    fs_folder = fs_folder ? "--fs $fs_folder" : ''
    bids_ignore = bids_ignore ? "--bids_ignore $bids_ignore" : ''
    def readout = task.ext.readout ? "--readout " + task.ext.readout : "--readout 0.062"
    def clean_flag = task.ext.clean_bids ? "--clean " : ''

    """
    scil_bids_validate.py $bids_folder tractoflow_bids_struct.json\
        $readout \
        $clean_flag\
        $fs_folder\
        $bids_ignore\
        -v

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """


    stub:
    """
    scil_bids_validate.py -h

    touch tractoflow_bids_struct.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
