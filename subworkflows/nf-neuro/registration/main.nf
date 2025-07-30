include { REGISTRATION_ANATTODWI  } from '../../../modules/nf-neuro/registration/anattodwi/main'
include { REGISTRATION_ANTS   } from '../../../modules/nf-neuro/registration/ants/main'
include { REGISTRATION_EASYREG   } from '../../../modules/nf-neuro/registration/easyreg/main'
include { REGISTRATION_SYNTHREGISTRATION } from '../../../modules/nf-neuro/registration/synthregistration/main'
include { REGISTRATION_CONVERT } from '../../../modules/nf-neuro/registration/convert/main'

params.run_easyreg      = false
params.run_synthmorph   = false


workflow REGISTRATION {

    // The subworkflow requires at least ch_fixed_image and ch_moving_image as inputs to
    // properly perform the registration. Supplying a ch_metric will select
    // the REGISTRATION_ANATTODWI module meanwhile NOT supplying a ch_metric
    // will select the REGISTRATION_ANTS (SyN or SyNQuick) module. Alternatively,
    // NOT supplying ch_metric and activating alternative module flag with select
    // REGISTRATION_EASYREG or REGISTRATION_SYNTHMORPH

    take:
        ch_fixed_image                  // channel: [ val(meta), image ]
        ch_moving_image                 // channel: [ val(meta), reference ]
        ch_metric                       // channel: [ val(meta), metric ], optional
        ch_fixed_mask                   // channel: [ val(meta), mask ], optional
        ch_segmentation                 // channel: [ val(meta), segmentation ], optional
        ch_moving_segmentation          // channel: [ val(meta), segmentation ], optional
        ch_freesurfer_license           // channel: [ license ], optional
    main:
        ch_versions = Channel.empty()
        ch_mqc = Channel.empty()

        if ( params.run_easyreg ) {
            // ** Registration using Easyreg ** //
            // Result : [ meta, reference, image | [], ref-segmentation | [], segmentation | [] ]
            //  Steps :
            //   - join [ meta, reference, image | null ]
            //   - join [ meta, reference, image | null, ref-segmentation | null ]
            //   - join [ meta, reference, image | null, ref-segmentation | null, segmentation | null ]
            //   -  map [ meta, reference, image | [], ref-segmentation | [], segmentation | [] ]
            ch_register = ch_moving_image
                .join(ch_fixed_image, remainder: true)
                .join(ch_moving_segmentation, remainder: true)
                .join(ch_segmentation, remainder: true)
                .map{ it[0..1] + [it[2] ?: [], it[3] ?: [], it[4] ?: []] }

            REGISTRATION_EASYREG ( ch_register )
            ch_versions = ch_versions.mix(REGISTRATION_EASYREG.out.versions.first())

            // ** Set compulsory outputs ** //
            out_image_warped = REGISTRATION_EASYREG.out.image_warped
            out_affine = Channel.empty()
            out_warp = REGISTRATION_EASYREG.out.warp
            out_inverse_affine = Channel.empty()
            out_inverse_warp = REGISTRATION_EASYREG.out.inverse_warp
            out_image_transform = REGISTRATION_EASYREG.out.warp
            out_inverse_image_transform = REGISTRATION_EASYREG.out.inverse_warp
            out_tractogram_transform = REGISTRATION_EASYREG.out.inverse_warp
            out_inverse_tractogram_transform = REGISTRATION_EASYREG.out.warp

            // ** Set optional outputs. ** //
            // If segmentations are not provided as inputs,
            // easyreg will outputs synthseg segmentations
            out_ref_warped = REGISTRATION_EASYREG.out.fixed_warped
            out_segmentation = ch_segmentation.mix( REGISTRATION_EASYREG.out.segmentation_warped )
            out_ref_segmentation = ch_moving_segmentation.mix( REGISTRATION_EASYREG.out.fixed_segmentation_warped )
        }
        else if ( params.run_synthmorph ) {
            // ** Registration using synthmorph ** //
            ch_register = ch_fixed_image
                .join(ch_moving_image)

            REGISTRATION_SYNTHREGISTRATION ( ch_register )
            ch_versions = ch_versions.mix(REGISTRATION_SYNTHREGISTRATION.out.versions.first())

            // Tag all synthmorph transforms per type, and index if in a chain. This info will be
            // used after conversion to sort out the transforms from the conversion module.
            ch_convert_affine = REGISTRATION_SYNTHREGISTRATION.out.affine
                .map{ meta, affine -> [meta, [tag: "affine"], affine] }
            ch_convert_warp = REGISTRATION_SYNTHREGISTRATION.out.warp
                .map{ meta, warp -> [meta, [tag: "warp"], warp] }
            ch_convert_inverse_affine = REGISTRATION_SYNTHREGISTRATION.out.inverse_affine
                .map{ meta, inverse_affine -> [meta, [tag: "inverse_affine"], inverse_affine] }
            ch_convert_inverse_warp = REGISTRATION_SYNTHREGISTRATION.out.inverse_warp
                .map{ meta, inverse_warp -> [meta, [tag: "inverse_warp"], inverse_warp] }
            ch_convert_image_transform = REGISTRATION_SYNTHREGISTRATION.out.image_transform
                .map{ meta, transforms -> [meta, [tag: "image_transform"], 0..<transforms.size(), transforms] }
                .transpose()
                .map{ meta, tag, idx, transform -> [meta, tag + [idx: idx], transform]}
            ch_convert_inverse_image_transform = REGISTRATION_SYNTHREGISTRATION.out.inverse_image_transform
                .map{ meta, transforms -> [meta, [tag: "inverse_image_transform"], 0..<transforms.size(), transforms] }
                .transpose()
                .map{ meta, tag, idx, transform -> [meta, tag + [idx: idx], transform]}

            // Mix all transforms into a single channel for conversion
            ch_convert = ch_convert_affine.view{ "affine $it" }
                .mix(ch_convert_warp.view{ "warp $it" })
                .mix(ch_convert_inverse_affine.view{ "inv-affine $it" })
                .mix(ch_convert_inverse_warp.view{ "inv-warp $it" })
                .mix(ch_convert_image_transform.view{ "image-transform $it" })
                .mix(ch_convert_inverse_image_transform.view{ "inv-image-transform $it" })
                .combine(ch_fixed_image, by: 0)
                .combine(ch_moving_image, by: 0)
                .map{ meta, tag, transform, fixed, moving ->
                    def extension = transform.name.tokenize('.')[1..-1].join(".")
                    return [
                        meta + tag + [cache: meta],
                        transform,
                        extension == "lta" ? "lta" : "ras",
                        "itk",
                        extension == "lta" ? fixed : moving,
                        [],
                    ]}
                .combine(ch_freesurfer_license)

            REGISTRATION_CONVERT ( ch_convert )
            ch_versions = ch_versions.mix(REGISTRATION_CONVERT.out.versions.first())

            // Un-mix conversion outputs using the tags. Save indexes for output sorting
            ch_conversion_outputs = REGISTRATION_CONVERT.out.transformation
                .branch{ meta, transform ->
                    affine: meta.tag == "affine"
                        return [meta.cache, transform]
                    warp: meta.tag == "warp"
                        return [meta.cache, transform]
                    inverse_affine: meta.tag == "inverse_affine"
                        return [meta.cache, transform]
                    inverse_warp: meta.tag == "inverse_warp"
                        return [meta.cache, transform]
                    image_transform: meta.tag == "image_transform"
                        return [meta.cache, [idx: meta.idx, trans: transform]]
                    inverse_image_transform: meta.tag == "inverse_image_transform"
                        return [meta.cache, [idx: meta.idx, trans: transform]]
                }


            // ** Set compulsory outputs ** //
            out_image_warped = REGISTRATION_SYNTHREGISTRATION.out.image_warped
            out_affine = ch_conversion_outputs.affine
            out_warp = ch_conversion_outputs.warp
            out_inverse_affine = ch_conversion_outputs.inverse_affine
            out_inverse_warp = ch_conversion_outputs.inverse_warp
            out_image_transform = ch_conversion_outputs.image_transform
                .groupTuple()
                .map{ meta, trans -> [meta, trans.sort{ t1, t2 -> t1.idx <=> t2.idx }.collect{ it.trans }] }
            out_inverse_image_transform = ch_conversion_outputs.inverse_image_transform
                .groupTuple()
                .map{ meta, trans -> [meta, trans.sort{ t1, t2 -> t1.idx <=> t2.idx }.collect{ it.trans }] }
            out_tractogram_transform = out_inverse_image_transform
            out_inverse_tractogram_transform = out_image_transform
            // ** and optional outputs. ** //
            out_ref_warped = Channel.empty()
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
            ch_register = ch_fixed_image
                .join(ch_moving_image)
                .join(ch_metric, remainder: true)
                .map{ it[0..2] + [it[3] ?: []] }
                .branch{
                    anat_to_dwi : it[3]
                    ants_syn: true
                }

            // ** Registration using ANAT TO DWI ** //
            REGISTRATION_ANATTODWI ( ch_register.anat_to_dwi )
            ch_versions = ch_versions.mix(REGISTRATION_ANATTODWI.out.versions.first())
            ch_mqc = ch_mqc.mix(REGISTRATION_ANATTODWI.out.mqc)

            // ** Set compulsory outputs ** //
            out_image_warped = REGISTRATION_ANATTODWI.out.anat_warped
            out_affine = REGISTRATION_ANATTODWI.out.affine
            out_warp = REGISTRATION_ANATTODWI.out.warp
            out_inverse_affine = REGISTRATION_ANATTODWI.out.inverse_affine
            out_inverse_warp = REGISTRATION_ANATTODWI.out.inverse_warp
            out_image_transform = REGISTRATION_ANATTODWI.out.image_transform
            out_inverse_image_transform = REGISTRATION_ANATTODWI.out.inverse_image_transform
            out_tractogram_transform = REGISTRATION_ANATTODWI.out.tractogram_transform
            out_inverse_tractogram_transform = REGISTRATION_ANATTODWI.out.inverse_tractogram_transform

            // ** Registration using ANTS SYN SCRIPTS ** //
            // Registration using antsRegistrationSyN.sh or antsRegistrationSyNQuick.sh, has
            // to be defined in the config file or else the default (SyN) will be used.
            // Result : [ meta, image, mask | [] ]
            //  Steps :
            //   - join [ meta, image, metric | [], mask | null ]
            //   - map  [ meta, image, mask | [] ]
            ch_register = ch_register.ants_syn
                .join(ch_fixed_mask, remainder: true)
                .map{ it[0..2] + [it[4] ?: []] }

            REGISTRATION_ANTS ( ch_register )
            ch_versions = ch_versions.mix(REGISTRATION_ANTS.out.versions.first())
            ch_mqc = ch_mqc.mix(REGISTRATION_ANTS.out.mqc)

            // ** Set compulsory outputs ** //
            out_image_warped = out_image_warped.mix(REGISTRATION_ANTS.out.image_warped)
            out_affine = out_affine.mix(REGISTRATION_ANTS.out.affine)
            out_warp = out_warp.mix(REGISTRATION_ANTS.out.warp)
            out_inverse_affine = out_inverse_affine.mix(REGISTRATION_ANTS.out.inverse_affine)
            out_inverse_warp = out_inverse_warp.mix(REGISTRATION_ANTS.out.inverse_warp)
            out_image_transform = out_image_transform.mix(REGISTRATION_ANTS.out.image_transform)
            out_inverse_image_transform = out_inverse_image_transform.mix(REGISTRATION_ANTS.out.inverse_image_transform)
            out_tractogram_transform = out_tractogram_transform.mix(REGISTRATION_ANTS.out.tractogram_transform)
            out_inverse_tractogram_transform = out_inverse_tractogram_transform.mix(REGISTRATION_ANTS.out.inverse_tractogram_transform)

            // **and optional outputs **//
            out_ref_warped = Channel.empty()
            out_segmentation = Channel.empty()
            out_ref_segmentation = Channel.empty()
        }
    emit:
        image_warped                    = out_image_warped                  // channel: [ val(meta), image ]
        ref_warped                      = out_ref_warped                    // channel: [ val(meta), ref ]
        // Individual transforms
        affine                          = out_affine                        // channel: [ val(meta), <affine> ]
        warp                            = out_warp                          // channel: [ val(meta), <warp> ]
        inverse_warp                    = out_inverse_warp                  // channel: [ val(meta), <inverse-warp> ]
        inverse_affine                  = out_inverse_affine                // channel: [ val(meta), <inverse-affine> ]
        // Combined transforms
        image_transform                 = out_image_transform               // channel: [ val(meta), [ <warp>, <affine> ] ]
        inverse_image_transform         = out_inverse_image_transform       // channel: [ val(meta), [ <inverse-affine>, <inverse-warp> ] ]
        tractogram_transform            = out_tractogram_transform          // channel: [ val(meta), [ <inverse-affine>, <inverse-warp> ] ]
        inverse_tractogram_transform    = out_inverse_tractogram_transform  // channel: [ val(meta), [ <warp>, <affine> ] ]
        // Segmentations
        segmentation                    = out_segmentation                  // channel: [ val(meta), segmentation ]
        ref_segmentation                = out_ref_segmentation              // channel: [ val(meta), ref-segmentation ]

        mqc                             = ch_mqc                            // channel: [ *mqc.*, ... ]
        versions                        = ch_versions                       // channel: [ versions.yml ]
}
