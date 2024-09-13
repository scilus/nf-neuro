include { REGISTRATION_ANATTODWI  } from '../../../modules/nf-scil/registration/anattodwi/main'
include { REGISTRATION_ANTS   } from '../../../modules/nf-scil/registration/ants/main'

workflow REGISTRATION {

    // ** The subworkflow requires at least ch_image and ch_ref as inputs to   ** //
    // ** properly perform the registration. Supplying a ch_metric will select ** //
    // ** the REGISTRATION_ANATTODWI module meanwhile NOT supplying a ch_metric    ** //
    // ** will select the REGISTRATION_ANTS (SyN or SyNQuick) module.          ** //

    take:
        ch_image                  // channel: [ val(meta), [ image ] ]
        ch_ref                    // channel: [ val(meta), [ ref ] ]
        ch_metric                 // channel: [ val(meta), [ metric ] ], optional
        ch_mask                   // channel: [ val(meta), [ mask ] ], optional

    main:

        ch_versions = Channel.empty()

        if ( ch_metric ) {
            // ** Set up input channel ** //
            ch_register =   ch_image.combine(ch_ref, by: 0)
                                    .combine(ch_metric, by: 0)

            // ** Registration using AntsRegistration ** //
            REGISTRATION_ANATTODWI ( ch_register )
            ch_versions = ch_versions.mix(REGISTRATION_ANATTODWI.out.versions.first())

            // ** Setting outputs ** //
            image_warped = REGISTRATION_ANATTODWI.out.t1_warped
            transfo_image = REGISTRATION_ANATTODWI.out.transfo_image
            transfo_trk = REGISTRATION_ANATTODWI.out.transfo_trk
        }
        else {
            // ** Set up input channel, input are inverted compared to REGISTRATION_ANATTODWI. ** //
            if ( ch_mask ) {
                ch_register = ch_ref.combine(ch_image, by: 0)
                                    .combine(ch_mask, by: 0)
            }
            else {
                ch_register = ch_ref.combine(ch_image, by: 0)
                                    .map{ it + [[]] }
            }

            // ** Registration using antsRegistrationSyN.sh or antsRegistrationSyNQuick.sh. ** //
            // ** Has to be defined in the config file or else the default (SyN) will be    ** //
            // ** used.                                                                     ** //
            REGISTRATION_ANTS ( ch_register )
            ch_versions = ch_versions.mix(REGISTRATION_ANTS.out.versions.first())

            // ** Setting outputs ** //
            image_warped = REGISTRATION_ANTS.out.image
            transfo_image = REGISTRATION_ANTS.out.transfo_image
            transfo_trk = REGISTRATION_ANTS.out.transfo_trk
        }

    emit:
        image_warped  = image_warped           // channel: [ val(meta), [ image ] ]
        transfo_image = transfo_image          // channel: [ val(meta), [ warp, affine ] ]
        transfo_trk   = transfo_trk            // channel: [ val(meta), [ inverseAffine, inverseWarp ] ]

        versions = ch_versions                 // channel: [ versions.yml ]
}
