// ** Importing modules from nf-neuro ** //
include { DENOISING_NLMEANS } from '../../../modules/nf-neuro/denoising/nlmeans/main'
include { PREPROC_N4 } from '../../../modules/nf-neuro/preproc/n4/main'
include { IMAGE_RESAMPLE } from '../../../modules/nf-neuro/image/resample/main'
include { BETCROP_ANTSBET } from '../../../modules/nf-neuro/betcrop/antsbet/main'
include { BETCROP_SYNTHBET} from '../../../modules/nf-neuro/betcrop/synthbet/main'
include { IMAGE_CROPVOLUME as IMAGE_CROPVOLUME_T1 } from '../../../modules/nf-neuro/image/cropvolume/main'
include { IMAGE_CROPVOLUME as IMAGE_CROPVOLUME_MASK } from '../../../modules/nf-neuro/image/cropvolume/main'

params.preproc_t1_run_synthbet = false

workflow PREPROC_T1 {

    take:
        ch_image            // channel: [ val(meta), image ]
        ch_template         // channel: [ val(meta), template ]                              , optional
        ch_probability_map  // channel: [ val(meta), probability-map, mask, initial-affine ] , optional
        ch_mask_nlmeans     // channel: [ val(meta), mask ]                                  , optional
        ch_ref_n4           // channel: [ val(meta), ref, ref-mask ]                         , optional
        ch_ref_resample     // channel: [ val(meta), ref ]                                   , optional
        ch_weights          // channel: [ val(meta), weights ]                               , optional

    main:

        ch_versions = Channel.empty()

        if ( params.preproc_t1_run_denoising ) {

            // ** Denoising ** //
            // Result : [ meta, image, mask | [] ]
            //  Steps :
            //   - join [ meta, image, mask | null ]
            //   - map  [ meta, image, mask | [] ]
            ch_nlmeans = ch_image
                .join(ch_mask_nlmeans, remainder: true)
                .map{ it[0..1] + [it[2] ?: []] }

            DENOISING_NLMEANS ( ch_nlmeans )
            ch_versions = ch_versions.mix(DENOISING_NLMEANS.out.versions.first())
            image_nlmeans = DENOISING_NLMEANS.out.image
        }
        else {
            image_nlmeans = ch_image
        }

        if ( params.preproc_t1_run_N4 ) {
            // ** N4 correction ** //
            // Result : [ meta, image, reference | [], mask | [] ]
            //  Steps :
            //   - join [ meta, image ] + [ reference, mask ] | [ reference, null ] | [ null ]
            //   - map  [ meta, image, reference | [], mask | [] ]
            //   - join [ meta, image, reference | [], mask | [], nlmeans-mask | null ]
            //   - map  [ meta, image, reference | [], mask | [] ]
            ch_N4 = image_nlmeans
                .join(ch_ref_n4, remainder: true)
                .map{ it[0..1] + [it[2] ?: [], it[3] ?: []] }
                .join(ch_mask_nlmeans, remainder: true)
                .map{ it[0..2] + [it[3] ?: it[4] ?: []] }

            PREPROC_N4 ( ch_N4 )
            ch_versions = ch_versions.mix(PREPROC_N4.out.versions.first())
            image_N4 = PREPROC_N4.out.image
        }
        else {
            image_N4 = image_nlmeans
        }

        if ( params.preproc_t1_run_resampling ) {
            // ** Resampling ** //
            // Result : [ meta, image, reference | [] ]
            //  Steps :
            //   - join [ meta, image, reference | null ]
            //   - map  [ meta, image, reference | [] ]
            ch_resampling = image_N4
                .join(ch_ref_resample, remainder: true)
                .map{ it[0..1] + [it[2] ?: []] }

            IMAGE_RESAMPLE ( ch_resampling )
            ch_versions = ch_versions.mix(IMAGE_RESAMPLE.out.versions.first())
            image_resample = IMAGE_RESAMPLE.out.image
        }
        else {
            image_resample = image_N4
        }

        if ( params.preproc_t1_run_synthbet ) {
            // ** SYNTHBET ** //
            // Result : [ meta, image, weights | [] ]
            //  Steps :
            //   - join [ meta, image, weights | null ]
            //   - map  [ meta, image, weights | [] ]
            ch_bet = image_resample
                .join(ch_weights, remainder: true)
                .map{ it[0..1] + [it[2] ?: []] }

            BETCROP_SYNTHBET ( ch_bet )
            ch_versions = ch_versions.mix(BETCROP_SYNTHBET.out.versions.first())

            // ** Setting BET output ** //
            image_bet = BETCROP_SYNTHBET.out.bet_image
            mask_bet = BETCROP_SYNTHBET.out.brain_mask
        }
        else if ( params.preproc_t1_run_ants_bet ) {
            // ** ANTSBET ** //
            // The template and probability maps are mandatory if running antsBET. Since the
            // error message from nextflow when they are absent is either non-informative or
            // missing, we use ifEmpty to provide a more informative one.
            ch_bet = image_resample
                .join(ch_template.ifEmpty{ error("ANTS BET needs a template") })
                .join(ch_probability_map.ifEmpty{ error("ANTS BET needs a tissue probability map") })
                .map{ it + [[], []] }

            BETCROP_ANTSBET ( ch_bet )
            ch_versions = ch_versions.mix(BETCROP_ANTSBET.out.versions.first())

            // ** Setting BET output ** //
            image_bet = BETCROP_ANTSBET.out.t1
            mask_bet = BETCROP_ANTSBET.out.mask
        }
        else {
            image_bet = image_resample
            mask_bet = Channel.empty()
        }

        if ( params.preproc_t1_run_crop ) {
            // ** Crop image ** //
            ch_crop = image_bet
                .map{ it + [[]] }

            IMAGE_CROPVOLUME_T1 ( ch_crop )
            ch_versions = ch_versions.mix(IMAGE_CROPVOLUME_T1.out.versions.first())
            image_crop = IMAGE_CROPVOLUME_T1.out.image
            bbox = IMAGE_CROPVOLUME_T1.out.bounding_box

            // ** Crop mask ** //
            ch_crop_mask = mask_bet
                .join(IMAGE_CROPVOLUME_T1.out.bounding_box)

            IMAGE_CROPVOLUME_MASK ( ch_crop_mask )
            ch_versions = ch_versions.mix(IMAGE_CROPVOLUME_MASK.out.versions.first())
            mask_crop = IMAGE_CROPVOLUME_MASK.out.image
        }
        else {
            image_crop = image_bet
            mask_crop = Channel.empty()
            bbox = Channel.empty()
        }

    emit:
        t1_final        = image_crop                    // channel: [ val(meta), t1-preprocessed ]
        mask_final      = mask_crop                     // channel: [ val(meta), t1-mask ]
        image_nlmeans   = image_nlmeans                 // channel: [ val(meta), t1-after-denoise ]
        image_N4        = image_N4                      // channel: [ val(meta), t1-after-unbias ]
        image_resample  = image_resample                // channel: [ val(meta), t1-after-resample ]
        image_bet       = image_bet                     // channel: [ val(meta), t1-after-bet ]
        mask_bet        = mask_bet                      // channel: [ val(meta), intermediary-mask ]
        crop_box        = bbox                          // channel: [ val(meta), bounding-box ]
        versions        = ch_versions                   // channel: [ versions.yml ]
}
