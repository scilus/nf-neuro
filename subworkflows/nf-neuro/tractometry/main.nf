include { TRACTOGRAM_REMOVEINVALID    } from '../../../modules/nf-neuro/tractogram/removeinvalid/main'
include { BUNDLE_FIXELAFD             } from '../../../modules/nf-neuro/bundle/fixelafd/main'
include { BUNDLE_CENTROID             } from '../../../modules/nf-neuro/bundle/centroid/main'
include { TRACTOGRAM_RESAMPLE         } from '../../../modules/nf-neuro/tractogram/resample/main'
include { BUNDLE_LABELMAP             } from '../../../modules/nf-neuro/bundle/labelmap/main'
include { BUNDLE_UNIFORMIZE           } from '../../../modules/nf-neuro/bundle/uniformize/main'
include { BUNDLE_STATS                } from '../../../modules/nf-neuro/bundle/stats/main'

workflow TRACTOMETRY {

take:
    ch_bundles
    ch_centroids
    ch_metrics
    ch_lesion_mask
    ch_fodf

main:

    ch_versions = Channel.empty()

    TRACTOGRAM_REMOVEINVALID( ch_bundles )
    ch_versions = ch_versions.mix( TRACTOGRAM_REMOVEINVALID.out.versions.first() )

    ch_fixel = TRACTOGRAM_REMOVEINVALID.out.tractograms
        .join( ch_fodf )
        .filter { it[1].size() > 0 }

    BUNDLE_FIXELAFD( ch_fixel )
    ch_versions = ch_versions.mix( BUNDLE_FIXELAFD.out.versions.first() )

    // ** Append fixel AFD metrics to metrics channel ** //
    ch_metrics  = ch_metrics
        .mix( BUNDLE_FIXELAFD.out.fixel_afd )
        .groupTuple(by: 0)
        .map { meta, metrics -> [ meta, metrics.flatten() ] }

    ch_bundles_centroids = TRACTOGRAM_REMOVEINVALID.out.tractograms
        .join( ch_centroids, remainder: true )
        .map { [ it[0], it[1], it[2] ?: [] ] }
        .branch {
            centroids_only: it[2].size() > 0
                return [ it[0], it[2] ]
            for_centroid: it[2].size() == 0
                return [ it[0], it[1] ]
        }

    TRACTOGRAM_RESAMPLE(ch_bundles_centroids.centroids_only )
    ch_versions = ch_versions.mix(TRACTOGRAM_RESAMPLE.out.versions.first())
    ch_centroids_cleaned_from_input = TRACTOGRAM_RESAMPLE.out.tractograms

    BUNDLE_CENTROID(ch_bundles_centroids.for_centroid)
    ch_versions = ch_versions.mix(BUNDLE_CENTROID.out.versions.first())
    ch_centroids_cleaned = ch_centroids_cleaned_from_input.mix(BUNDLE_CENTROID.out.centroids)
    ch_label_map = TRACTOGRAM_REMOVEINVALID.out.tractograms
        .join(ch_centroids_cleaned)

    BUNDLE_LABELMAP ( ch_label_map )
    ch_versions = ch_versions.mix(BUNDLE_LABELMAP.out.versions.first())
    ch_labels_trk = BUNDLE_LABELMAP.out.labels_trk
        .join( ch_centroids_cleaned )

    BUNDLE_UNIFORMIZE ( ch_labels_trk )
    ch_versions = ch_versions.mix(BUNDLE_UNIFORMIZE.out.versions.first())

    ch_stats = BUNDLE_UNIFORMIZE.out.bundles
        .join( BUNDLE_LABELMAP.out.labels )
        .join( ch_metrics )
        .join( ch_lesion_mask, remainder: true )
        .map { [ it[0], it[1], it[2], it[3], it[4] ?: [] ] }

    BUNDLE_STATS ( ch_stats )
    ch_versions = ch_versions.mix(BUNDLE_STATS.out.versions.first())

    emit:
    stat_length                     = BUNDLE_STATS.out.length ?: Channel.empty()
    stat_endpoints_raw              = BUNDLE_STATS.out.endpoints_raw ?: Channel.empty()
    stat_endpoints_metric           = BUNDLE_STATS.out.endpoints_metric_stats ?: Channel.empty()
    stat_mean_std                   = BUNDLE_STATS.out.mean_std ?: Channel.empty()
    stat_volume                     = BUNDLE_STATS.out.volume ?: Channel.empty()
    stat_volume_lesions             = BUNDLE_STATS.out.volume_lesions ?: Channel.empty()
    stat_streamline_count           = BUNDLE_STATS.out.streamline_count ?: Channel.empty()
    stat_streamline_count_lesions   = BUNDLE_STATS.out.streamline_count_lesions ?: Channel.empty()
    stat_volume_per_labels          = BUNDLE_STATS.out.volume_per_labels ?: Channel.empty()
    stat_volume_per_labels_lesions  = BUNDLE_STATS.out.volume_per_labels_lesions ?: Channel.empty()
    stat_mean_std_per_point         = BUNDLE_STATS.out.mean_std_per_point ?: Channel.empty()
    stat_lesion_stats               = BUNDLE_STATS.out.lesion_stats ?: Channel.empty()
    endpoints_head                  = BUNDLE_STATS.out.endpoints_head ?: Channel.empty()
    endpoints_tail                  = BUNDLE_STATS.out.endpoints_tail ?: Channel.empty()
    lesion_map                      = BUNDLE_STATS.out.lesion_map ?: Channel.empty()
    versions = ch_versions
}


