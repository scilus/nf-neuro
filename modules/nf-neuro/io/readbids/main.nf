process IO_READBIDS {
    label 'process_single'

    container "scilus/scilpy:2.2.0_cpu"

    input:
        path(bids_folder)
        path(fs_folder)
        path(bids_ignore)

    output:
        path("bids_struct.json")    , emit: bidsstructure
        path("versions.yml")        , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    fs_folder = fs_folder ? "--fs $fs_folder" : ''
    bids_ignore = bids_ignore ? "--bids_ignore $bids_ignore" : ''
    def readout = task.ext.readout ? "--readout " + task.ext.readout : "--readout 0.062"
    def clean_flag = task.ext.clean_bids ? "--clean " : ''

    """
    scil_bids_validate $bids_folder bids_struct.json\
        $readout \
        $clean_flag \
        $fs_folder \
        $bids_ignore \
        -v -f

    cat bids_struct.json
    # Relativize paths in the output JSON
    cat <<< \$(jq 'map(map_values(
        if type == "string" then
            if contains("/") then
                scan("^.*/($bids_folder/.*)") | first
            else . end
        else . end ))' bids_struct.json) >| bids_struct.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
    stub:
    """
    scil_bids_validate -h

    cat <<-ENDSTRUCT > bids_struct.json
    [
        {
            "DWIPhaseEncodingDir": "y",
            "TotalReadoutTime": 0.062,
            "aparc_aseg": "",
            "bval": "i_bids/sub-01/ses-001/dwi/sub-01_ses-001_dir-AP_dwi.bval",
            "bvec": "i_bids/sub-01/ses-001/dwi/sub-01_ses-001_dir-AP_dwi.bvec",
            "dwi": "i_bids/sub-01/ses-001/dwi/sub-01_ses-001_dir-AP_dwi.nii.gz",
            "rev_DWIPhaseEncodingDir": "y-",
            "rev_bval": "",
            "rev_bvec": "",
            "rev_dwi": "",
            "rev_topup": "i_bids/sub-01/ses-001/fmap/sub-01_ses-001_dir-PA_epi.nii.gz",
            "run": 0,
            "session": "001",
            "subject": "01",
            "t1": "i_bids/sub-01/ses-001/anat/sub-01_ses-001_T1w.nii.gz",
            "topup": "i_bids/sub-01/ses-001/fmap/sub-01_ses-001_dir-AP_epi.nii.gz",
            "wmparc": ""
        }
    ]
    ENDSTRUCT

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
