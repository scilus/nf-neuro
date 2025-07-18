include { REGISTRATION_ANATTODWI  } from '../../../modules/nf-neuro/registration/anattodwi/main'
include { REGISTRATION_ANTS   } from '../../../modules/nf-neuro/registration/ants/main'
include { REGISTRATION_EASYREG   } from '../../../modules/nf-neuro/registration/easyreg/main'
include { REGISTRATION_SYNTHREGISTRATION } from '../../../modules/nf-neuro/registration/synthregistration/main'

params.run_easyreg      = false
params.run_synthmorph   = false

workflow REGISTRATION {

    // The subworkflow requires at least ch_image and ch_ref as inputs to
    // properly perform the registration. Supplying a ch_metric will select
    // the REGISTRATION_ANATTODWI module meanwhile NOT supplying a ch_metric
    // will select the REGISTRATION_ANTS (SyN or SyNQuick) module. Alternatively,
    // NOT supplying ch_metric and activating alternative module flag with select
    // REGISTRATION_EASYREG or REGISTRATION_SYNTHMORPH

    take:
        ch_image                // channel: [ val(meta), image ]
        ch_ref                  // channel: [ val(meta), reference ]
        ch_metric               // channel: [ val(meta), metric ], optional
        ch_mask                 // channel: [ val(meta), mask ], optional
        ch_segmentation         // channel: [ val(meta), segmentation ], optional
        ch_ref_segmentation     // channel: [ val(meta), ref-segmentation ], optional

    main:

        ch_versions = Channel.empty()

        if ( params.run_easyreg ) {
            // ** Registration using Easyreg ** //
            // Result : [ meta, reference, image | [], ref-segmentation | [], segmentation | [] ]
            //  Steps :
            //   - join [ meta, reference, image | null ]
            //   - join [ meta, reference, image | null, ref-segmentation | null ]
            //   - join [ meta, reference, image | null, ref-segmentation | null, segmentation | null ]
            //   -  map [ meta, reference, image | [], ref-segmentation | [], segmentation | [] ]
            ch_register = ch_ref
                .join(ch_image, remainder: true)
                .join(ch_ref_segmentation, remainder: true)
                .join(ch_segmentation, remainder: true)
                .map{ it[0..1] + [it[2] ?: [], it[3] ?: [], it[4] ?: []] }

            REGISTRATION_EASYREG ( ch_register )
            ch_versions = ch_versions.mix(REGISTRATION_EASYREG.out.versions.first())

            // ** Set compulsory outputs ** //
            affine = Channel.empty()
            warp = REGISTRATION_EASYREG.out.fwd_field
            inverse_affine = Channel.empty()
            inverse_warp = REGISTRATION_EASYREG.out.bak_field
            image_warped = REGISTRATION_EASYREG.out.flo_reg
            image_transform = REGISTRATION_EASYREG.out.fwd_field
            inverse_image_transform = REGISTRATION_EASYREG.out.bak_field
            tractogram_transform = REGISTRATION_EASYREG.out.bak_field
            inverse_tractogram_transform = REGISTRATION_EASYREG.out.fwd_field

            // ** Set optional outputs. ** //
            // If segmentations are not provided as inputs,
            // easyreg will outputs synthseg segmentations
            ref_warped = REGISTRATION_EASYREG.out.ref_reg
            out_segmentation = ch_segmentation.mix( REGISTRATION_EASYREG.out.flo_seg )
            out_ref_segmentation = ch_ref_segmentation.mix( REGISTRATION_EASYREG.out.ref_seg )
        }
        else if ( params.run_synthmorph ) {
            // ** Registration using synthmorph ** //
            ch_register = ch_image
                .join(ch_ref)

            REGISTRATION_SYNTHREGISTRATION ( ch_register )
            ch_versions = ch_versions.mix(REGISTRATION_SYNTHREGISTRATION.out.versions.first())

            // ** Set compulsory outputs ** //
            affine = REGISTRATION_SYNTHREGISTRATION.out.affine
            warp = REGISTRATION_SYNTHREGISTRATION.out.warp
            inverse_affine = Channel.empty() // FIXME : this transformation should be available
            inverse_warp = Channel.empty()   // FIXME : this transformation should be available

            image_warped = REGISTRATION_SYNTHREGISTRATION.out.warped_image
            // FIXME : this is .lta, should be .mat, but we need a custom container for that
            image_transform = REGISTRATION_SYNTHREGISTRATION.out.warp
                .join(REGISTRATION_SYNTHREGISTRATION.out.affine)
            inverse_image_transform = Channel.empty() // FIXME : this transformation should be available
            tractogram_transform = Channel.empty()    // FIXME : this transformation should be available
            inverse_tractogram_transform = REGISTRATION_SYNTHREGISTRATION.out.warp
                .join(REGISTRATION_SYNTHREGISTRATION.out.affine)

            // ** and optional outputs. ** //
            ref_warped = Channel.empty()
            out_segmentation = Channel.empty()
            out_ref_segmentation = Channel.empty()
        }
        else {
            // ** Classic registration using antsRegistration  ** //
            // Result : [ meta, image, reference, metric | [] ]
            //  Steps :
            //   - join [ meta, image, ref ]
            //   - join [ meta, image, ref, metric | null ]
            //   - map  [ meta, image, ref, metric | [] ]
            // Branches :
            //   - anat_to_dwi : has a metric at index 3
            //   - ants_syn    : doesn't have a metric at index 3 ( [] or null )
            ch_register = ch_image
                .join(ch_ref)
                .join(ch_metric, remainder: true)
                .map{ it[0..2] + [it[3] ?: []] }
                .branch{
                    anat_to_dwi : it[3]
                    ants_syn: true
                }

            // ** Registration using ANAT TO DWI ** //
            REGISTRATION_ANATTODWI ( ch_register.anat_to_dwi )
            ch_versions = ch_versions.mix(REGISTRATION_ANATTODWI.out.versions.first())

            // ** Set compulsory outputs ** //
            affine = REGISTRATION_ANATTODWI.out.affine
            warp = REGISTRATION_ANATTODWI.out.warp
            inverse_affine = REGISTRATION_ANATTODWI.out.inverse_affine
            inverse_warp = REGISTRATION_ANATTODWI.out.inverse_warp

            image_warped = REGISTRATION_ANATTODWI.out.t1_warped
            image_transform = REGISTRATION_ANATTODWI.out.image_transform
            inverse_image_transform = REGISTRATION_ANATTODWI.out.inverse_image_transform
            tractogram_transform = REGISTRATION_ANATTODWI.out.tractogram_transform
            inverse_tractogram_transform = REGISTRATION_ANATTODWI.out.inverse_tractogram_transform

            // ** Registration using ANTS SYN SCRIPTS ** //
            // Registration using antsRegistrationSyN.sh or antsRegistrationSyNQuick.sh, has
            // to be defined in the config file or else the default (SyN) will be used.
            // Result : [ meta, image, mask | [] ]
            //  Steps :
            //   - join [ meta, image, metric | [], mask | null ]
            //   - map  [ meta, image, mask | [] ]
            ch_register = ch_register.ants_syn
                .join(ch_mask, remainder: true)
                .map{ it[0..2] + [it[4] ?: []] }

            REGISTRATION_ANTS ( ch_register )
            ch_versions = ch_versions.mix(REGISTRATION_ANTS.out.versions.first())

            // ** Set compulsory outputs ** //
            affine = affine.mix(REGISTRATION_ANTS.out.affine)
            warp = warp.mix(REGISTRATION_ANTS.out.warp)
            inverse_affine = inverse_affine.mix(REGISTRATION_ANTS.out.inverse_affine)
            inverse_warp = inverse_warp.mix(REGISTRATION_ANTS.out.inverse_warp)

            image_warped = image_warped
                .mix(REGISTRATION_ANTS.out.image)
            image_transform = image_transform
                .mix(REGISTRATION_ANTS.out.image_transform)
            inverse_image_transform = inverse_image_transform
                .mix(REGISTRATION_ANTS.out.inverse_image_transform)
            tractogram_transform = tractogram_transform
                .mix(REGISTRATION_ANTS.out.tractogram_transform)
            inverse_tractogram_transform = inverse_tractogram_transform
                .mix(REGISTRATION_ANTS.out.inverse_tractogram_transform)

            // **and optional outputs **//
            ref_warped = Channel.empty()
            out_segmentation = Channel.empty()
            out_ref_segmentation = Channel.empty()
        }

    emit:
        image_warped                    = image_warped                  // channel: [ val(meta), image ]
        ref_warped                      = ref_warped                    // channel: [ val(meta), ref ]
        // Individual transforms
        affine                          = affine                        // channel: [ val(meta), <affine> ]
        warp                            = warp                          // channel: [ val(meta), <warp> ]
        inverse_affine                  = inverse_affine                // channel: [ val(meta), <inverse-affine> ]
        inverse_warp                    = inverse_warp                  // channel: [ val(meta), <inverse-warp> ]
        // Combined transforms
        image_transform                 = image_transform               // channel: [ val(meta), [ <warp>, <affine> ] ]
        inverse_image_transform         = inverse_image_transform       // channel: [ val(meta), [ <inverse-affine>, <inverse-warp> ] ]
        tractogram_transform            = tractogram_transform          // channel: [ val(meta), [ <inverse-affine>, <inverse-warp> ] ]
        inverse_tractogram_transform    = inverse_tractogram_transform  // channel: [ val(meta), [ <warp>, <affine> ] ]
        // Segmentations
        segmentation                    = out_segmentation              // channel: [ val(meta), segmentation ]
        ref_segmentation                = out_ref_segmentation          // channel: [ val(meta), ref-segmentation ]

        versions                        = ch_versions                   // channel: [ versions.yml ]
}
