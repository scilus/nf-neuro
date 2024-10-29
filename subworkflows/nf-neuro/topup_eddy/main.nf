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
        ch_topup = ch_dwi
            .join(ch_b0, remainder: true)
            .map{ it[0..3] + [it[4] ?: []] }

        ch_topup = ch_topup
            .join(ch_rev_dwi, remainder: true)
            .map{ it[5] ? it : it[0..4] + [[], [], []] }
            .join(ch_rev_b0, remainder: true)
            .branch{
                with_topup: it[5] || it[8]
            }

        // ** RUN TOPUP ** //
        PREPROC_TOPUP ( ch_topup.with_topup, ch_config_topup )
        ch_versions = ch_versions.mix(PREPROC_TOPUP.out.versions.first())

        // ** Create channel for EDDY ** //
        ch_eddy_input = ch_dwi
            .join(ch_rev_dwi, remainder: true)
            .map{ it[0..3] + [it[4] ? it[4..-1] : [], [], []] }
            .join(PREPROC_TOPUP.out.topup_corrected_b0s, remainder: true)
            .map{ it[0..6] + [it[7] ?: []] }
            .join(PREPROC_TOPUP.out.topup_fieldcoef, remainder: true)
            .map{ it[0..7] + [it[8] ?: []] }
            .join(PREPROC_TOPUP.out.topup_movpart, remainder: true)
            .map{ it[0..8] + [it[9] ?: []] }

        // ** RUN EDDY **//
        PREPROC_EDDY ( ch_eddy_input )
        ch_versions = ch_versions.mix(PREPROC_EDDY.out.versions.first())

        ch_dwi_extract_b0 = PREPROC_EDDY.out.dwi_corrected
            .join(PREPROC_EDDY.out.bval_corrected)
            .join(PREPROC_EDDY.out.bvec_corrected)

        UTILS_EXTRACTB0 { ch_dwi_extract_b0 }
        ch_versions = ch_versions.mix(UTILS_EXTRACTB0.out.versions.first())

    emit:
        dwi      = PREPROC_EDDY.out.dwi_corrected       // channel: [ val(meta), [ dwi_corrected ] ]
        bval     = PREPROC_EDDY.out.bval_corrected      // channel: [ val(meta), [ bval_corrected ] ]
        bvec     = PREPROC_EDDY.out.bvec_corrected      // channel: [ val(meta), [ bvec_corrected ] ]
        b0       = UTILS_EXTRACTB0.out.b0               // channel: [ val(meta), [ b0 ] ]
        b0_mask  = PREPROC_EDDY.out.b0_mask             // channel: [ val(meta), [ b0_mask ] ]
        versions = ch_versions                          // channel: [ versions.yml ]
}
