// ** Importing modules from nf-neuro ** //
include { DENOISING_NLMEANS } from '../../../modules/nf-neuro/denoising/nlmeans/main'
include { PREPROC_N4 } from '../../../modules/nf-neuro/preproc/n4/main'
include { IMAGE_RESAMPLE } from '../../../modules/nf-neuro/image/resample/main'
include { BETCROP_ANTSBET } from '../../../modules/nf-neuro/betcrop/antsbet/main'
include { BETCROP_SYNTHBET} from '../../../modules/nf-neuro/betcrop/synthbet/main'
include { IMAGE_CROPVOLUME as IMAGE_CROPVOLUME_T1 } from '../../../modules/nf-neuro/image/cropvolume/main'
include { IMAGE_CROPVOLUME as IMAGE_CROPVOLUME_MASK } from '../../../modules/nf-neuro/image/cropvolume/main'

params.run_synthbet = false

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

        // ** N4 correction ** //
        // Result : [ meta, image, reference | [], mask | [] ]
        //  Steps :
        //   - join [ meta, image ] + [ reference, mask ] | [ reference, null ] | [ null ]
        //   - map  [ meta, image, reference | [], mask | [] ]
        //   - join [ meta, image, reference | [], mask | [], nlmeans-mask | null ]
        //   - map  [ meta, image, reference | [], mask | [] ]
        ch_N4 = DENOISING_NLMEANS.out.image
            .join(ch_ref_n4, remainder: true)
            .map{ it[0..1] + [it[2] ?: [], it[3] ?: []] }
            .join(ch_mask_nlmeans, remainder: true)
            .map{ it[0..2] + [it[3] ?: it[4] ?: []] }

        PREPROC_N4 ( ch_N4 )
        ch_versions = ch_versions.mix(PREPROC_N4.out.versions.first())

        // ** Resampling ** //
        // Result : [ meta, image, reference | [] ]
        //  Steps :
        //   - join [ meta, image, reference | null ]
        //   - map  [ meta, image, reference | [] ]
        ch_resampling = PREPROC_N4.out.image
            .join(ch_ref_resample, remainder: true)
            .map{ it[0..1] + [it[2] ?: []] }

        IMAGE_RESAMPLE ( ch_resampling )
        ch_versions = ch_versions.mix(IMAGE_RESAMPLE.out.versions.first())

        // ** Brain extraction ** //
        if ( params.run_synthbet ) {
            // ** SYNTHBET ** //
            // Result : [ meta, image, weights | [] ]
            //  Steps :
            //   - join [ meta, image, weights | null ]
            //   - map  [ meta, image, weights | [] ]
            ch_bet = IMAGE_RESAMPLE.out.image
                .join(ch_weights, remainder: true)
                .map{ it[0..1] + [it[2] ?: []] }

            BETCROP_SYNTHBET ( ch_bet )
            ch_versions = ch_versions.mix(BETCROP_SYNTHBET.out.versions.first())

            // ** Setting BET output ** //
            image_bet = BETCROP_SYNTHBET.out.bet_image
            mask_bet = BETCROP_SYNTHBET.out.brain_mask
        }

        else {
            // ** ANTSBET ** //
            // The template and probability maps are mandatory if running antsBET. Since the
            // error message from nextflow when they are absent is either non-informative or
            // missing, we use ifEmpty to provide a more informative one.
            ch_bet = IMAGE_RESAMPLE.out.image
                .join(ch_template.ifEmpty{ error("ANTS BET needs a template") })
                .join(ch_probability_map.ifEmpty{ error("ANTS BET needs a tissue probability map") })

            BETCROP_ANTSBET ( ch_bet )
            ch_versions = ch_versions.mix(BETCROP_ANTSBET.out.versions.first())

            // ** Setting BET output ** //
            image_bet = BETCROP_ANTSBET.out.t1
            mask_bet = BETCROP_ANTSBET.out.mask
        }

        // ** Crop image ** //
        ch_crop = image_bet
            .map{ it + [[]] }

        IMAGE_CROPVOLUME_T1 ( ch_crop )
        ch_versions = ch_versions.mix(IMAGE_CROPVOLUME_T1.out.versions.first())

        // ** Crop mask ** //
        ch_crop_mask = mask_bet
            .join(IMAGE_CROPVOLUME_T1.out.bounding_box)

        IMAGE_CROPVOLUME_MASK ( ch_crop_mask )
        ch_versions = ch_versions.mix(IMAGE_CROPVOLUME_MASK.out.versions.first())

    emit:
        t1_final        = IMAGE_CROPVOLUME_T1.out.image           // channel: [ val(meta), t1-preprocessed ]
        mask_final      = IMAGE_CROPVOLUME_MASK.out.image         // channel: [ val(meta), t1-mask ]
        image_nlmeans   = DENOISING_NLMEANS.out.image               // channel: [ val(meta), t1-after-denoise ]
        image_N4        = PREPROC_N4.out.image                      // channel: [ val(meta), t1-after-unbias ]
        image_resample  = IMAGE_RESAMPLE.out.image                  // channel: [ val(meta), t1-after-resample ]
        image_bet       = image_bet                                 // channel: [ val(meta), t1-after-bet ]
        mask_bet        = mask_bet                                  // channel: [ val(meta), intermediary-mask ]
        crop_box        = IMAGE_CROPVOLUME_T1.out.bounding_box    // channel: [ val(meta), bounding-box ]
        versions        = ch_versions                               // channel: [ versions.yml ]
}
