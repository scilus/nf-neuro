include { UTILS_TEMPLATEFLOW                            } from '../../../modules/nf-neuro/utils/templateflow/main.nf'
include { IMAGE_APPLYMASK as MASK_T1W                   } from '../../../modules/nf-neuro/image/applymask/main.nf'
include { IMAGE_APPLYMASK as MASK_T2W                   } from '../../../modules/nf-neuro/image/applymask/main.nf'
include { BETCROP_FSLBETCROP as BET_T1W                 } from '../../../modules/nf-neuro/betcrop/fslbetcrop/main.nf'
include { BETCROP_FSLBETCROP as BET_T2W                 } from '../../../modules/nf-neuro/betcrop/fslbetcrop/main.nf'
include { REGISTRATION_ANTS                             } from '../../../modules/nf-neuro/registration/ants/main.nf'
include { REGISTRATION_ANTSAPPLYTRANSFORMS as WARPIMAGES} from '../../../modules/nf-neuro/registration/antsapplytransforms/main.nf'
include { REGISTRATION_ANTSAPPLYTRANSFORMS as WARPMASK  } from '../../../modules/nf-neuro/registration/antsapplytransforms/main.nf'
include { REGISTRATION_ANTSAPPLYTRANSFORMS as WARPLABELS} from '../../../modules/nf-neuro/registration/antsapplytransforms/main.nf'
include { REGISTRATION_TRACTOGRAM                       } from '../../../modules/nf-neuro/registration/tractogram/main.nf'

workflow OUTPUT_TEMPLATE_SPACE {

    take:
        ch_anat                     // channel: [ val(meta), [ anat ] ]
        ch_nifti_files              // channel: [ val(meta), [ nifti_files ] ]
        ch_mask_files               // channel: [ val(meta), [ mask_files ] ]
        ch_labels_files             // channel: [ val(meta), [ labels_files ] ]
        ch_trk_files                // channel: [ val(meta), [ trk_files ] ]

    main:

    ch_versions = Channel.empty()

    // ** First, let's assess if the desired template exists in      ** //
    // ** the templateflow home directory (user-specified as params. ** //
    // ** or default to $outdir/../templateflow)                     ** //
    if ( !file("${params.templateflow_home}/tpl-${params.template}").exists() ) {
        log.info("Template ${params.template} not found in " +
                "${params.templateflow_home}. Will be downloaded." +
                "If you do not have access to the internet while running" +
                "this pipeline, please download the template manually" +
                "and provide the location using --templateflow_home.")
        log.info("${params.template} will be downloaded at resolution " +
                "${params.templateflow_res} from cohort ${params.templateflow_cohort}.")

        UTILS_TEMPLATEFLOW (
            [
                params.template,
                params.templateflow_res != null ? params.templateflow_res : [],
                params.templateflow_cohort != null ? params.templateflow_cohort : []
            ]
        )
        ch_versions = ch_versions.mix(UTILS_TEMPLATEFLOW.out.versions)

        // ** Setting outputs ** //
        ch_t1w_tpl = UTILS_TEMPLATEFLOW.out.T1w
        ch_t2w_tpl = UTILS_TEMPLATEFLOW.out.T2w
        ch_brain_mask = UTILS_TEMPLATEFLOW.out.brain_mask
    } else {
        // ** If the template exists, we will not download it again. ** //
        log.info("Template ${params.template} found in " +
                "${params.templateflow_home}. Will be used.")

        // ** Load the files from the templateflow directory ** //
        def path = "${params.templateflow_home}/tpl-${params.template}/"
        if ( params.templateflow_cohort ) {
            ch_t1w_tpl = Channel.fromPath(
                "${path}/cohort-${params.templateflow_cohort}/*res-*${params.templateflow_res}_T1w.nii.gz",
                checkIfExists: false
            )
            ch_t2w_tpl = Channel.fromPath(
                "${path}/cohort-${params.templateflow_cohort}/*res-*${params.templateflow_res}_T2w.nii.gz",
                checkIfExists: false
            )
            ch_brain_mask = Channel.fromPath(
                "${path}/cohort-${params.templateflow_cohort}/*res-*${params.templateflow_res}_desc-brain_mask.nii.gz",
                checkIfExists: false
            ) ?: Channel.empty()
        } else {
            ch_t1w_tpl = Channel.fromPath(
                "${path}/*res-*${params.templateflow_res}_T1w.nii.gz",
                checkIfExists: false
            )
            ch_t2w_tpl = Channel.fromPath(
                "${path}/*res-*${params.templateflow_res}_T2w.nii.gz",
                checkIfExists: false
            )
            ch_brain_mask = Channel.fromPath(
                "${path}/*res-*${params.templateflow_res}_desc-brain_mask.nii.gz",
                checkIfExists: false
            ) ?: Channel.empty()
        }
    }

    ch_brain_mask = ch_brain_mask
        | branch {
            TRUE: it[0] != []
            FALSE: false
        }

    // ** If the template has a brain mask, we will use it ** //
    if ( ! ch_brain_mask.FALSE ) {
        ch_bet_tpl_t1w = ch_t1w_tpl
            | combine(ch_brain_mask)
            | map{ t1w, mask -> [ [id: "template"], t1w, mask ] }

        MASK_T1W ( ch_bet_tpl_t1w )
        ch_versions = ch_versions.mix(MASK_T1W.out.versions)

        // ** Strip the template from the meta field so we can combine it ** //
        ch_t1w_tpl = MASK_T1W.out.image
            | map{ _meta, image -> image }

        ch_bet_tpl_t2w = ch_t2w_tpl
            | combine(ch_brain_mask)
            | map{ t2w, mask -> [ [id: "template"], t2w, mask ] }

        MASK_T2W ( ch_bet_tpl_t2w )
        ch_versions = ch_versions.mix(MASK_T2W.out.versions)

        // ** Strip the template from the meta field so we can combine it ** //
        ch_t2w_tpl = MASK_T2W.out.image
            | map{ _meta, image -> image }
    } else {
        // ** The template may not have a brain mask, so we will ** //
        // ** run BET by default (bit painful, but necessary)    ** //
        ch_bet_tpl_t1w = ch_t1w_tpl
            | map{ t1w -> [ [id: "template"], t1w, [], [] ] }

        BET_T1W ( ch_bet_tpl_t1w )
        ch_versions = ch_versions.mix(BET_T1W.out.versions)
        // ** Strip the template from the meta field so we can combine it ** //
        ch_t1w_tpl = BET_T1W.out.image
            | map{ _meta, image -> image }

        ch_bet_tpl_t2w = ch_t2w_tpl
            | map{ t2w -> [ [id: "template"], t2w, [], [] ] }

        BET_T2W ( ch_bet_tpl_t2w )
        ch_versions = ch_versions.mix(BET_T2W.out.versions)
        // ** Strip the template from the meta field so we can combine it ** //
        ch_t2w_tpl = BET_T2W.out.image
            | map{ _meta, image -> image }
    }

    // ** Register the subject to the template space ** //
    ch_registration = ch_anat
        | combine(params.use_template_t2w ? ch_t2w_tpl : ch_t1w_tpl)
        | map{ meta, anat, tpl -> tuple(meta, tpl, anat, []) }

    REGISTRATION_ANTS ( ch_registration )
    ch_versions = ch_versions.mix(REGISTRATION_ANTS.out.versions)

    // ** Apply the transformation to all files ** //
    // ** The channel ch_nifti_files contains all the files that ** //
    // ** need to be transformed to the template space in that structure: ** //
    // ** [ tuple(meta, [ file1, file2, ... ]) ] ** //
    // ** Need to unpack the files and apply the transformation to each one ** //
    ch_files_to_transform = ch_nifti_files
        | join(REGISTRATION_ANTS.out.image)
        | join(REGISTRATION_ANTS.out.warp)
        | join(REGISTRATION_ANTS.out.affine)

    WARPIMAGES ( ch_files_to_transform )
    ch_versions = ch_versions.mix(WARPIMAGES.out.versions)

    // ** Same process for the masks ** //
    ch_masks_to_transform = ch_mask_files
        | join(REGISTRATION_ANTS.out.image)
        | join(REGISTRATION_ANTS.out.warp)
        | join(REGISTRATION_ANTS.out.affine)
    WARPMASK ( ch_masks_to_transform )
    ch_versions = ch_versions.mix(WARPMASK.out.versions)

    // ** Same process for the labels ** //
    ch_labels_to_transform = ch_labels_files
        | join(REGISTRATION_ANTS.out.image)
        | join(REGISTRATION_ANTS.out.warp)
        | join(REGISTRATION_ANTS.out.affine)
    WARPLABELS ( ch_labels_to_transform )
    ch_versions = ch_versions.mix(WARPLABELS.out.versions)

    // ** Apply the transformation to the tractograms ** //
    ch_tractograms_to_transform = ch_trk_files
        | join(REGISTRATION_ANTS.out.image)
        | join(REGISTRATION_ANTS.out.inverse_warp)
        | join(REGISTRATION_ANTS.out.affine)
        | map{ meta, trk, image, warp, affine ->
            tuple(meta, image, affine, trk, [], warp)
        }

    REGISTRATION_TRACTOGRAM ( ch_tractograms_to_transform )
    ch_versions = ch_versions.mix(REGISTRATION_TRACTOGRAM.out.versions)

    emit:
        ch_t1w_tpl                  = ch_t1w_tpl                                        // channel: [ tpl-T1w ]
        ch_t2w_tpl                  = ch_t2w_tpl                                        // channel: [ tpl-T2w ]
        ch_registered_anat          = REGISTRATION_ANTS.out.image                       // channel: [ val(meta), [ image ] ]
        ch_warped_nifti_files       = WARPIMAGES.out.warped_image                       // channel: [ val(meta), [ warped_image ] ]
        ch_warped_mask_files        = WARPMASK.out.warped_image                         // channel: [ val(meta), [ warped_mask ] ]
        ch_warped_labels_files      = WARPLABELS.out.warped_image                       // channel: [ val(meta), [ warped_labels ] ]
        ch_warped_trk_files         = REGISTRATION_TRACTOGRAM.out.warped_tractogram     // channel: [ val(meta), [ warped_tractogram ] ]
        versions                    = ch_versions                                       // channel: [ versions.yml ]
}

