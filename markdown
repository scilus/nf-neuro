---
title: anatomical_segmentation
head:
- tag: meta
  attrs:
    name: keywords
    content: Anatomical, Segmentation, Maps, Masks
- tag: meta
  attrs:
    name: description
    content: |
        Subworkflow performing anatomical segmentation to produce WM, GM and CSF maps/masks. It handles two type of input channels, either an anatomical image (most likely T1) and/or freesurfer parcellations files. Depending on which channel is provided, the subworkflow will perform either of the following: 1)  Channel with an anatomical image with run_synthseg parameter will result in using Freesurfer synthseg producing WM, GM     and CSF masks/maps. 2)  Channel with an anatomical image will result in using FSL's fast segmentation producing WM, GM,     and CSF masks/maps. ...
---

## Subworkflow: anatomical_segmentation

Subworkflow performing anatomical segmentation to produce WM, GM and CSF maps/masks. It handles
two type of input channels, either an anatomical image (most likely T1) and/or freesurfer parcellations
files. Depending on which channel is provided, the subworkflow will perform either of the following:
1)  Channel with an anatomical image with run_synthseg parameter will result in using Freesurfer synthseg producing WM, GM
    and CSF masks/maps.
2)  Channel with an anatomical image will result in using FSL's fast segmentation producing WM, GM,
    and CSF masks/maps.
3)  Channel with FreeSurfer's parcellations files will result in using Scilpy's tools to produce
    WM, GM, and CSF masks. Probability maps will be produced by FSLFast.
Typical next steps after this subworkflow would be to combine the resulting masks/maps with fODF
data to perform TRACKING.


**Keywords :** Anatomical, Segmentation, Maps, Masks

---


### Inputs

| | Type | Description | Mandatory | Pattern |
|-|------|-------------|-----------|---------|
| ch_image | file | The input channel containing the anatomical images (typically T1s). If provided, the subworkflow will perform segmentation using FSL's fast. Structure: [ val(meta), path(image) ]  |  | *.{nii,nii.gz} |
| ch_freesurferseg | file | The input channel containing freesurfer parcellations files (aparc+aseg and wm_parc parcellations). If provided, the subworkflow will use Scilpy's tools to convert the parcellations into masks. Structure: [ val(meta), path(aparc_aseg), path(wm_parc) ]  |  | *.mgz |
| ch_lesion | file | The input channel containing a lesion mask file to correct the white matter mask. The lesion mask must be a binary mask. Structure: [ val(meta), path(lesion) ]  |  | *{nii.nii.gz} |
| ch_fs_license | file | The input channel containing the FreeSurfer license.To get one, go to https://surfer.nmr.mgh.harvard.edu/registration.html. Optional. If you have already set your license as prescribed by Freesurfer (copied to a .license file in your $FREESURFER_HOME), this is not required. Structure: [ val(meta). path(fs_license) ]  |  |  |



### Outputs

| | Type | Description | Pattern |
|-|------|-------------|---------|
| wm_mask | file | Channel containing WM mask files. Will be outputted regardless of the selected segmentation method and inputs provided. Structure: [ val(meta), path(wm_mask) ]  | *.{nii,nii.gz} |
| gm_mask | file | Channel containing GM mask files. Will be outputted regardless of the selected segmentation method and inputs provided. Structure: [ val(meta), path(gm_mask) ]  | *.{nii,nii.gz} |
| csf_mask | file | Channel containing CSF mask files. Will be outputted regardless of the selected segmentation method and inputs provided. Structure: [ val(meta), path(csf_mask) ]  | *.{nii,nii.gz} |
| wm_map | file | Channel containing WM probability maps. Structure: [ val(meta), path(wm_map) ]  | *.{nii,nii.gz} |
| gm_map | file | Channel containing GM probability maps. Structure: [ val(meta), path(gm_map) ]  | *.{nii,nii.gz} |
| csf_map | file | Channel containing CSF probability maps. Structure: [ val(meta), path(csf_map) ]  | *.{nii,nii.gz} |
| seg | file | Channel containing the optional nifti segmentation volume from synthseg. Structure: [ val(meta), path(seg) ]  | *.{nii,nii.gz} |
| aparc_aseg | file | Channel containing the optional nifti cortical parcellation and segmentation volume from synthseg. Structure: [ val(meta), path(aparc_aseg) ]  | *.{nii,nii.gz} |
| resample | file | Channel containing the optional resampled images at 1mm. Structure: [ val(meta), path(resample) ]  | *.{nii.nii.gz} |
| volume | file | Channel containing the optional Output CSV file with volumes for all structures and subjects. Structure: [ val(meta), path(volume) ]  | *.csv |
| qc_score | file | Channel containing the optional output CSV file with qc scores for all subjects. Structure: [ val(meta), path(qc_score) ]  | *.csv |
| versions | file | File containing software versions. Structure: [ path(versions.yml) ]  | versions.yml |




---


### Components

- [segmentation/fastseg](https://scilus.github.io/nf-neuro/api/modules/segmentation/fastseg)
- [segmentation/freesurferseg](https://scilus.github.io/nf-neuro/api/modules/segmentation/freesurferseg)
- [segmentation/synthseg](https://scilus.github.io/nf-neuro/api/modules/segmentation/synthseg)


---

### Authors

@gagnonanthony





---
**Last updated** : [2025-09-09](https://github.com/scilus/nf-neuro/commit/1234)
