process SEGMENTATION_SYNTHSEG {
    tag "$meta.id"
    label 'process_single'
    label 'process_high'

    container "freesurfer/freesurfer:7.4.1"

    input:
    tuple val(meta), path(image), path(lesion) /* optional, input = [] */, path(fs_license) /* optional, input = [] */

    output:
    tuple val(meta), path("*__mask_wm.nii.gz")                , emit: wm_mask
    tuple val(meta), path("*__mask_gm.nii.gz")                , emit: gm_mask
    tuple val(meta), path("*__mask_csf.nii.gz")               , emit: csf_mask
    tuple val(meta), path("*__gm_parc.nii.gz")                , emit: gm_parc, optional: true
    tuple val(meta), path("*__resampled_image.nii.gz")        , emit: resample, optional: true
    tuple val(meta), path("*__volume.csv")                    , emit: volume, optional: true
    tuple val(meta), path("*__qc_score.csv")                  , emit: qc_score, optional: true
    path "versions.yml"                                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def gpu = task.ext.gpu ? "" : "--cpu"
    def gm_parc = task.ext.gm_parc ? "--parc" : ""
    def robust = task.ext.robust ? "--robust" : ""
    def fast = task.ext.fast ? "--fast" : ""
    def ct = task.ext.ct ? "--ct" : ""
    def output_resample = task.ext.output_resample ? "--resample ${prefix}__resampled_image.nii.gz": ""
    def output_volume = task.ext.output_volume ?  "--vol ${prefix}__volume.csv" : ""
    def output_qc_score = task.ext.output_qc_score ?  "--qc ${prefix}__qc_score.csv" : ""
    def crop = task.ext.crop ? "--crop " + task.ext.crop: ""

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1

    cp $fs_license \$FREESURFER_HOME/license.txt

    mri_synthseg --i $image --o seg.nii.gz --threads $task.cpus $gpu $robust $fast $ct $output_resample $output_volume $output_qc_score $crop

    if [[ $task.gm_parc ]];
    then
        # Cortical grey matter parcellation
        mri_synthseg --i $image --o ${prefix}__gm_parc.nii.gz --threads $task.cpus $gpu $gm_parc $robust $fast $crop
        mri_convert -i ${prefix}__gm_parc.nii.gz --out_data_type uchar -o ${prefix}__gm_parc.nii.gz
    fi

    # WM Mask
    mri_binarize --i seg.nii.gz \
        --match 2 7 10 12 13 16 28 41 46 49 51 52 60 \
        --o ${prefix}__mask_wm.nii.gz

    # GM Mask
    mri_binarize --i seg.nii.gz \
        --match 3 8 11 17 18 26 42 47 50 52 53 54 58 \
        --o ${prefix}__mask_gm.nii.gz

    # CSF Mask
    mri_binarize --i seg.nii.gz \
        --match 4 5 14 15 24 43 44 \
        --o ${prefix}__mask_csf.nii.gz

    if [[ -f "$lesion" ]];
    then
        mri_binarize --i ${prefix}__mask_wm.nii.gz --merge $lesion --min 0.5 --o ${prefix}__mask_wm.nii.gz
    fi

    mri_convert -i ${prefix}__mask_wm.nii.gz --out_data_type uchar -o ${prefix}__mask_wm.nii.gz
    mri_convert -i ${prefix}__mask_gm.nii.gz --out_data_type uchar -o ${prefix}__mask_gm.nii.gz
    mri_convert -i ${prefix}__mask_csf.nii.gz --out_data_type uchar -o ${prefix}__mask_csf.nii.gz
    mri_convert -i ${prefix}__gm_parc.nii.gz --out_data_type uchar ${prefix}__gm_parc.nii.gz

    rm \$FREESURFER_HOME/license.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        Freesurfer: 7.4.1
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mri_synthseg -h
    mri_binarize -h
    mri_convert -h

    touch ${prefix}__mask_wm.nii.gz
    touch ${prefix}__mask_gm.nii.gz
    touch ${prefix}__mask_csf.nii.gz
    touch ${prefix}__gm_parc.nii.gz
    touch ${prefix}__resampled_image.nii.gz
    touch ${prefix}__volume.csv
    touch ${prefix}__qc_score.csv


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        Freesurfer: 7.4.1
    END_VERSIONS
    """
}
