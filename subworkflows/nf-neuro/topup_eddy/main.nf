// ** Importing modules from nf-neuro ** //
include { PREPROC_TOPUP } from '../../../modules/nf-neuro/preproc/topup/main'
include { PREPROC_EDDY } from '../../../modules/nf-neuro/preproc/eddy/main'
include { UTILS_EXTRACTB0 } from '../../../modules/nf-neuro/utils/extractb0/main'

workflow TOPUP_EDDY {

    // ** The subworkflow will optionally run topup if a reverse b0 or reverse DWI is provided.   ** //
    // ** In both cases, it will perform EDDY and also extract a b0 from the corrected DWI image. ** //

    take:
        ch_dwi // channel: [ val(meta), [ dwi, bval, bvec ]
        ch_b0 // channel: [ val(meta), b0 ]
        ch_rev_dwi // channel: [ val(meta), [ rev_dwi, rev_bval, rev_bvec ]
        ch_rev_b0 // channel: [ val(meta), rev_b0 ]
        ch_config_topup // channel

    main:
        ch_versions = Channel.empty()

        // ** Create channel for TOPUP ** //
        if ( ch_rev_dwi )
        {
            ch_image =    ch_dwi.join(ch_b0)
                                .join(ch_rev_dwi)
            ch_eddy_input =   ch_dwi.combine(ch_rev_dwi, by: 0)
        }
        else {
            ch_image =    ch_dwi.join(ch_b0)
                                .map{ it + [[], [], []] }
            ch_eddy_input =   ch_dwi.map{ it + [[], [], []] }
        }
        if ( ch_rev_b0 )
        {
            ch_image =    ch_image.join(ch_rev_b0)
        }
        else {
            ch_image =    ch_image.map{ it + [[]] }
        }

        if ( ch_rev_dwi || ch_rev_b0 )
        {
            // ** RUN TOPUP ** //
            PREPROC_TOPUP ( ch_image, ch_config_topup )
            ch_versions = ch_versions.mix(PREPROC_TOPUP.out.versions.first())

            // ** Create channel for EDDY ** //
            ch_eddy_input =    ch_eddy_input.combine(PREPROC_TOPUP.out.topup_corrected_b0s, by: 0)
                                            .combine(PREPROC_TOPUP.out.topup_fieldcoef, by: 0)
                                            .combine(PREPROC_TOPUP.out.topup_movpart, by: 0)
        }
        else
        {
            // ** RUN EDDY ** //
            ch_eddy_input =    ch_dwi.map{ it + [[], [], [], [], [], []] }
        }

        PREPROC_EDDY ( ch_eddy_input )
        ch_dwi_extract_b0 =   PREPROC_EDDY.out.dwi_corrected.combine(PREPROC_EDDY.out.bval_corrected, by: 0)
                                                            .combine(PREPROC_EDDY.out.bvec_corrected, by: 0)
        UTILS_EXTRACTB0 { ch_dwi_extract_b0 }

        ch_versions = ch_versions.mix(UTILS_EXTRACTB0.out.versions.first())
        ch_versions = ch_versions.mix(PREPROC_EDDY.out.versions.first())

    emit:
        dwi      = PREPROC_EDDY.out.dwi_corrected       // channel: [ val(meta), [ dwi_corrected ] ]
        bval     = PREPROC_EDDY.out.bval_corrected      // channel: [ val(meta), [ bval_corrected ] ]
        bvec     = PREPROC_EDDY.out.bvec_corrected      // channel: [ val(meta), [ bvec_corrected ] ]
        b0       = UTILS_EXTRACTB0.out.b0               // channel: [ val(meta), [ b0 ] ]
        b0_mask  = PREPROC_EDDY.out.b0_mask             // channel: [ val(meta), [ b0_mask ] ]
        versions = ch_versions                  // channel: [ versions.yml ]
}
