// ** Importing modules from nf-neuro ** //
include { DENOISING_NLMEANS } from '../../../modules/nf-neuro/denoising/nlmeans/main'
include { PREPROC_N4 } from '../../../modules/nf-neuro/preproc/n4/main'
include { IMAGE_RESAMPLE } from '../../../modules/nf-neuro/image/resample/main'
include { BETCROP_ANTSBET } from '../../../modules/nf-neuro/betcrop/antsbet/main'
include { BETCROP_SYNTHBET} from '../../../modules/nf-neuro/betcrop/synthbet/main'
include { BETCROP_CROPVOLUME as BETCROP_CROPVOLUME_T1 } from '../../../modules/nf-neuro/betcrop/cropvolume/main'
include { BETCROP_CROPVOLUME as BETCROP_CROPVOLUME_MASK } from '../../../modules/nf-neuro/betcrop/cropvolume/main'

params.run_synthbet = false

workflow PREPROC_T1 {

    take:
        ch_image           // channel: [ val(meta), [ image ] ]
        ch_template        // channel: [ val(meta), [ template ] ]        , optional
        ch_probability_map // channel: [ val(meta), [ probability_map ] ] , optional
        ch_mask_nlmeans    // channel: [ val(meta), [ mask ] ]            , optional
        ch_ref_n4          // channel: [ val(meta), [ ref, ref_mask ] ]   , optional
        ch_ref_resample    // channel: [ val(meta), [ ref ] ]             , optional
        ch_weights         // channel: [ val(meta), [ weights ] ]         , optional

    main:

        ch_versions = Channel.empty()

        // ** Denoising ** //
        ch_nlmeans = ch_image.join(ch_mask_nlmeans)
        DENOISING_NLMEANS ( ch_nlmeans )
        ch_versions = ch_versions.mix(DENOISING_NLMEANS.out.versions.first())

        // ** N4 correction ** //
        ch_N4 = DENOISING_NLMEANS.out.image.join(ch_ref_n4)
        PREPROC_N4 ( ch_N4 )
        ch_versions = ch_versions.mix(PREPROC_N4.out.versions.first())

        // ** Resampling ** //
        ch_resampling = PREPROC_N4.out.image.join(ch_ref_resample)
        IMAGE_RESAMPLE ( ch_resampling )
        ch_versions = ch_versions.mix(IMAGE_RESAMPLE.out.versions.first())

        // ** Brain extraction ** //
        if ( params.run_synthbet) {
            ch_bet = IMAGE_RESAMPLE.out.image.join(ch_weights)
            BETCROP_SYNTHBET ( ch_bet )
            ch_versions = ch_versions.mix(BETCROP_SYNTHBET.out.versions.first())

            // ** Setting BET output ** //
            image_bet = BETCROP_SYNTHBET.out.bet_image
            mask_bet = BETCROP_SYNTHBET.out.brain_mask
        }

        else {
            ch_template = ch_template.ifEmpty(Channel.error('Template is required for ANTS registration'))
            ch_probability_map = ch_probability_map.ifEmpty(Channel.error('Probability map is required for ANTS registration'))
            ch_bet = IMAGE_RESAMPLE.out.image.join(ch_template).join(ch_probability_map)
            BETCROP_ANTSBET ( ch_bet )
            ch_versions = ch_versions.mix(BETCROP_ANTSBET.out.versions.first())

            // ** Setting BET output ** //
            image_bet = BETCROP_ANTSBET.out.t1
            mask_bet = BETCROP_ANTSBET.out.mask
        }

        // ** crop image ** //
        ch_crop = image_bet.map{it + [[]]}
        BETCROP_CROPVOLUME_T1 ( ch_crop )
        ch_versions = ch_versions.mix(BETCROP_CROPVOLUME_T1.out.versions.first())

        // ** crop mask ** //
        ch_crop_mask = mask_bet.join(BETCROP_CROPVOLUME_T1.out.bounding_box)
        BETCROP_CROPVOLUME_MASK ( ch_crop_mask )
        ch_versions = ch_versions.mix(BETCROP_CROPVOLUME_MASK.out.versions.first())

    emit:
        image_nlmeans   = DENOISING_NLMEANS.out.image            // channel: [ val(meta), [ image ] ]
        image_N4        = PREPROC_N4.out.image                   // channel: [ val(meta), [ image ] ]
        image_resample  = IMAGE_RESAMPLE.out.image               // channel: [ val(meta), [ image ] ]
        image_bet       = image_bet                              // channel: [ val(meta), [ t1 ] ]
        mask_bet        = mask_bet                               // channel: [ val(meta), [ mask ] ]
        crop_box        = BETCROP_CROPVOLUME_T1.out.bounding_box // channel: [ val(meta), [ bounding_box ] ]
        mask_final      = BETCROP_CROPVOLUME_MASK.out.image      // channel: [ val(meta), [ mask ] ]
        t1_final        = BETCROP_CROPVOLUME_T1.out.image        // channel: [ val(meta), [ image ] ]
        versions        = ch_versions                            // channel: [ versions.yml ]
}
