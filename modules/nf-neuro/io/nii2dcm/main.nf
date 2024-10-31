process IO_NII2DCM {
    tag "$meta.id"
    label 'process_single'

    container "onsetlab/nii2dcm:0.1.0"

    input:
    tuple val(meta), path(niftis), path(dicom)

    output:
    tuple val(meta), path("DICOM/"), emit: dicom_directory
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    String nifti_list = niftis.join(", ").replace(',', '')
    String series_description =  niftis.join(" ").replace(".nii.gz", "").replace(prefix + "__", "")

    if ( task.ext.study_description ) args += " --study_description " + task.ext.study_description
    if ( task.ext.reference_dicom ) args += " -r ${dicom}"
    """
    for n in ${nifti_list};
    do
        mrconvert \${n} \${n} -stride -2,-1,3 -force
    done
    convert_nii2dcm.py *.nii.gz DICOM/ -d MR --series_description ${nifti_list} ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mrtrix: \$(mrcalc -version | grep mrcalc | cut -d" " -f3)
        nii2dcm: \$(convert_nii2dcm.py -v)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    convert_nii2dcm.py -h
    mkdir DICOM

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mrtrix: \$(mrcalc -version | grep mrcalc | cut -d" " -f3)
        nii2dcm: \$(convert_nii2dcm.py -v)
    END_VERSIONS
    """
}
