include { DENOISING_MPPCA as DENOISE_DWI } from '../../../modules/nf-scil/denoising/mppca/main'
include { DENOISING_MPPCA as DENOISE_REVDWI } from '../../../modules/nf-scil/denoising/mppca/main'
include { BETCROP_FSLBETCROP } from '../../../modules/nf-scil/betcrop/fslbetcrop/main'
include { BETCROP_CROPVOLUME } from '../../../modules/nf-scil/betcrop/cropvolume/main'
include { PREPROC_N4 as N4_DWI } from '../../../modules/nf-scil/preproc/n4/main'
include { PREPROC_NORMALIZE as NORMALIZE_DWI } from '../../../modules/nf-scil/preproc/normalize/main'
include { IMAGE_RESAMPLE as RESAMPLE_DWI } from '../../../modules/nf-scil/image/resample/main'
include { IMAGE_RESAMPLE as RESAMPLE_MASK } from '../../../modules/nf-scil/image/resample/main'
include { UTILS_EXTRACTB0 as EXTRACTB0_RESAMPLE } from '../../../modules/nf-scil/utils/extractb0/main'
include { UTILS_EXTRACTB0 as EXTRACTB0_TOPUP } from '../../../modules/nf-scil/utils/extractb0/main'
include { TOPUP_EDDY } from '../topup_eddy/main'


workflow PREPROC_DWI {

    take:
        ch_dwi           // channel: [ val(meta), [ dwi, bval, bvec ] ]
        ch_rev_dwi       // channel: [ val(meta), [ rev_dwi, bval, bvec ] ], optional
        ch_b0            // Channel: [ val(meta), [ b0 ] ], optional
        ch_rev_b0        // channel: [ val(meta), [ reverse b0 ] ], optional
        ch_config_topup  // channel: [ 'config_topup' ], optional

    main:

        ch_versions = Channel.empty()

        ch_denoise_dwi = ch_dwi
            .multiMap { meta, dwi, bval, bvec ->
                dwi:    [ meta, dwi ]
                bvs_files: [ meta, bval, bvec ]
            }

        // ** Denoised DWI ** //
        DENOISE_DWI (
            ch_denoise_dwi.dwi
                .map{ it + [[]] }
        )
        ch_versions = ch_versions.mix(DENOISE_DWI.out.versions.first())

        if ( ch_rev_dwi )
        {
            ch_denoise_rev_dwi = ch_rev_dwi
                .multiMap { meta, dwi, bval, bvec ->
                    rev_dwi:    [ [id: "${meta.id}_rev", cache: meta], dwi ]
                    rev_bvs_files: [ meta, bval, bvec ]
                }
            // ** Denoised reverse DWI ** //
            DENOISE_REVDWI (
                ch_denoise_rev_dwi.rev_dwi
                    .map{ it + [[]] }
            )
            ch_versions = ch_versions.mix(DENOISE_REVDWI.out.versions.first())

            ch_topup_eddy_rev_dwi = DENOISE_REVDWI.out.image
                .map{ meta, dwi -> [ meta.cache, dwi ] }
                .join(ch_denoise_rev_dwi.rev_bvs_files)
        }
        else
        {
            ch_topup_eddy_rev_dwi = []    // or Channel.empty()
        }

        // ** Eddy Topup ** //
        ch_topup_eddy_dwi = DENOISE_DWI.out.image.join(ch_denoise_dwi.bvs_files)

        if ( ! ch_b0 ) {
            EXTRACTB0_TOPUP { ch_topup_eddy_dwi }
            ch_versions = ch_versions.mix(EXTRACTB0_TOPUP.out.versions.first())
            ch_b0 = EXTRACTB0_TOPUP.out.b0
        }

        TOPUP_EDDY ( ch_topup_eddy_dwi, ch_b0, ch_topup_eddy_rev_dwi, ch_rev_b0, ch_config_topup )
        ch_versions = ch_versions.mix(TOPUP_EDDY.out.versions.first())

        // ** Bet-crop DWI ** //
        ch_betcrop_dwi = TOPUP_EDDY.out.dwi
            .join(TOPUP_EDDY.out.bval)
            .join(TOPUP_EDDY.out.bvec)
        BETCROP_FSLBETCROP ( ch_betcrop_dwi )
        ch_versions = ch_versions.mix(BETCROP_FSLBETCROP.out.versions.first())

        // ** Crop b0 ** //
        ch_crop_b0 = TOPUP_EDDY.out.b0
            .join(BETCROP_FSLBETCROP.out.bbox)
        BETCROP_CROPVOLUME ( ch_crop_b0 )
        ch_versions = ch_versions.mix(BETCROP_CROPVOLUME.out.versions.first())

        // ** N4 DWI ** //
        ch_N4 = BETCROP_FSLBETCROP.out.image
            .join(BETCROP_CROPVOLUME.out.image)
            .join(BETCROP_FSLBETCROP.out.mask)
        N4_DWI ( ch_N4 )
        ch_versions = ch_versions.mix(N4_DWI.out.versions.first())

        // ** Normalize DWI ** //
        ch_normalize = N4_DWI.out.image
            .join(TOPUP_EDDY.out.bval)
            .join(TOPUP_EDDY.out.bvec)
            .join(BETCROP_FSLBETCROP.out.mask)
        NORMALIZE_DWI ( ch_normalize )
        ch_versions = ch_versions.mix(NORMALIZE_DWI.out.versions.first())

        // ** Resample DWI ** //
        ch_resample_dwi = NORMALIZE_DWI.out.dwi.map{ it + [[]] }
        RESAMPLE_DWI ( ch_resample_dwi )
        ch_versions = ch_versions.mix(RESAMPLE_DWI.out.versions.first())

        // ** Extract b0 ** //
        ch_dwi_extract_b0 =   RESAMPLE_DWI.out.image
            .join(TOPUP_EDDY.out.bval)
            .join(TOPUP_EDDY.out.bvec)

        EXTRACTB0_RESAMPLE { ch_dwi_extract_b0 }
        ch_versions = ch_versions.mix(EXTRACTB0_RESAMPLE.out.versions.first())

        // ** Resample mask ** //
        ch_resample_mask = BETCROP_FSLBETCROP.out.mask.map{ it + [[]] }
        RESAMPLE_MASK ( ch_resample_mask )
        ch_versions = ch_versions.mix(RESAMPLE_MASK.out.versions.first())

    emit:
        dwi_resample        = RESAMPLE_DWI.out.image            // channel: [ val(meta), [ dwi_resample ] ]
        bval                = TOPUP_EDDY.out.bval     // channel: [ val(meta), [ bval_corrected ] ]
        bvec                = TOPUP_EDDY.out.bvec     // channel: [ val(meta), [ bvec_corrected ] ]
        b0                  = EXTRACTB0_RESAMPLE.out.b0                 // channel: [ val(meta), [ b0 ] ]
        b0_mask             = RESAMPLE_MASK.out.image            // channel: [ val(meta), [ b0_mask ] ]
        dwi_bounding_box    = BETCROP_FSLBETCROP.out.bbox       // channel: [ val(meta), [ dwi_bounding_box ] ]
        dwi_topup_eddy      = TOPUP_EDDY.out.dwi      // channel: [ val(meta), [ dwi_topup_eddy ] ]
        dwi_n4              = N4_DWI.out.image                  // channel: [ val(meta), [ dwi_n4 ] ]
        versions            = ch_versions                       // channel: [ versions.yml ]
}
