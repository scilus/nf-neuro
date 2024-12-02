// ** Importing modules from nf-neuro ** //
include { PREPROC_TOPUP } from '../../../modules/nf-neuro/preproc/topup/main'
include { PREPROC_EDDY } from '../../../modules/nf-neuro/preproc/eddy/main'
include { UTILS_EXTRACTB0 } from '../../../modules/nf-neuro/utils/extractb0/main'

workflow TOPUP_EDDY {

    // ** The subworkflow will optionally run topup if a reverse b0 or reverse DWI is provided.   ** //
    // ** In both cases, it will perform EDDY and also extract a b0 from the corrected DWI image. ** //

    take:
        ch_dwi          // channel: [ val(meta), dwi, bval, bvec ]
        ch_b0           // channel: [ val(meta), b0 ], optional
        ch_rev_dwi      // channel: [ val(meta), rev-dwi, rev-bval, rev-bvec ], optional
        ch_rev_b0       // channel: [ val(meta), rev-b0 ], optional
        ch_config_topup // channel: [ 'topup.cnf' ], optional

    main:
        ch_versions = Channel.empty()

        // ** Create channel for TOPUP ** //
        // Result : [ meta, dwi, bval, bvec, b0 | [], rev-dwi | [], rev-bval | [], rev-bvec | [], rev-b0 | [] ]
        //  Steps :
        //   - join [ meta, dwi, bval, bvec, b0 | null ]
        //   - map  [ meta, dwi, bval, bvec, b0 | [] ]
        //   - join [ meta, dwi, bval, bvec, b0 | [] ] + [ rev-dwi, rev-bval, rev-bvec ] | [ null ]
        //   - map  [ meta, dwi, bval, bvec, b0 | [], rev-dwi | [], rev-bval | [], rev-bvec | [] ]
        //   - join [ meta, dwi, bval, bvec, b0 | [], rev-dwi | [], rev-bval | [], rev-bvec | [], rev-b0 | null ]
        //   - map  [ meta, dwi, bval, bvec, b0 | [], rev-dwi | [], rev-bval | [], rev-bvec | [], rev-b0 | [] ]
        //
        // Finally, to create ch_topup, filter ensures DWI comes with either a rev-dwi (index 5) or a rev-b0 (index 8)
        ch_topup = ch_dwi
            .join(ch_b0, remainder: true)
            .map{ it[0..3] + [it[4] ?: []] }
            .join(ch_rev_dwi, remainder: true)
            .map{ it[5] ? it : it[0..4] + [[], [], []] }
            .join(ch_rev_b0, remainder: true)
            .map{ it[0..7] + [it[8] ?: []] }
            .filter{ it[5] || it[8] }

        // ** RUN TOPUP ** //
        PREPROC_TOPUP ( ch_topup, ch_config_topup )
        ch_versions = ch_versions.mix(PREPROC_TOPUP.out.versions.first())

        // ** Create channel for EDDY ** //
        // Result : [ meta, dwi, bval, bvec, rev-dwi | [], rev-bval | [], rev-bvec | [], b0 | [], coeffs | [], movpar | [] ]
        //  Steps :
        //   - join [ meta, dwi, bval, bvec ] + [ rev-dwi, rev-bval, rev-bvec ] | [ null ]
        //   - map  [ meta, dwi, bval, bvec, rev-dwi | [], rev-bval | [], rev-bvec | [] ]
        //   - join [ meta, dwi, bval, bvec, rev-dwi | [], rev-bval | [], rev-bvec | [], b0 | null ]
        //   - map  [ meta, dwi, bval, bvec, rev-dwi | [], rev-bval | [], rev-bvec | [], b0 | [] ]
        //   - join [ meta, dwi, bval, bvec, rev-dwi | [], rev-bval | [], rev-bvec | [], b0 | [], coeffs | null ]
        //   - map  [ meta, dwi, bval, bvec, rev-dwi | [], rev-bval | [], rev-bvec | [], b0 | [], coeffs | [] ]
        //   - join [ meta, dwi, bval, bvec, rev-dwi | [], rev-bval | [], rev-bvec | [], b0 | [], coeffs | [], movpar | null ]
        //   - map  [ meta, dwi, bval, bvec, rev-dwi | [], rev-bval | [], rev-bvec | [], b0 | [], coeffs | [], movpar | [] ]
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
        dwi      = PREPROC_EDDY.out.dwi_corrected       // channel: [ val(meta), dwi-corrected ]
        bval     = PREPROC_EDDY.out.bval_corrected      // channel: [ val(meta), bval-corrected ]
        bvec     = PREPROC_EDDY.out.bvec_corrected      // channel: [ val(meta), bvec-corrected ]
        b0       = UTILS_EXTRACTB0.out.b0               // channel: [ val(meta), b0-corrected ]
        b0_mask  = PREPROC_EDDY.out.b0_mask             // channel: [ val(meta), b0-mask ]
        versions = ch_versions                          // channel: [ versions.yml ]
}
