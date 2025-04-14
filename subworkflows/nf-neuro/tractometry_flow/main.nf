include { TRACTOGRAM_REMOVEINVALID    } from '../../../modules/nf-neuro/tractogram/removeinvalid/main'
include { BUNDLE_FIXELAFD             } from '../../../modules/nf-neuro/bundle/fixelafd/main'
include { BUNDLE_CENTROID             } from '../../../modules/nf-neuro/bundle/centroid/main'
include { TRACTOGRAM_RESAMPLE         } from '../../../modules/nf-neuro/tractogram/resample/main'
include { BUNDLE_LABELMAP             } from '../../../modules/nf-neuro/bundle/labelmap/main'
include { BUNDLE_UNIFORMIZE           } from '../../../modules/nf-neuro/bundle/uniformize/main'
include { BUNDLE_STATS                } from '../../../modules/nf-neuro/bundle/stats/main'

workflow TRACTOMETRY_FLOW {

    take:
        ch_bundles          // channel: [ val(meta), [ bundles ] ]
        ch_centroids        // channel: [ val(meta), [ centroids ] ]
        ch_metrics          // channel: [ val(meta), [ metrics ] ]
        ch_lesion_mask      // channel: [ val(meta), lesions ]
        ch_fodf             // channel: [ val(meta), fodf ]

    main:

    ch_versions = Channel.empty()

    TRACTOGRAM_REMOVEINVALID ( ch_bundles )
    ch_versions = ch_versions.mix(TRACTOGRAM_REMOVEINVALID.out.versions.first())
    ch_bundle_cleaned = TRACTOGRAM_REMOVEINVALID.out.tractograms

    // Merge channels, but if one is empty, the channel will be empty
    ch_fixel = ch_bundle_cleaned.join( ch_fodf )
                .filter { it != [] && !it.isEmpty() }

    BUNDLE_FIXELAFD ( ch_fixel )
    ch_versions = ch_versions.mix(BUNDLE_FIXELAFD.out.versions.first())
    ch_fixelafd = BUNDLE_FIXELAFD.out.fixel_afd
    ch_metrics = ch_metrics.join(ch_fixelafd)

    ch_centroids_present = ch_centroids.filter { it != null }

    // TRACTOGRAM_RESAMPLE if ch_centroids has content
    if (ch_centroids_present) {
        TRACTOGRAM_RESAMPLE(ch_centroids_present)
        ch_versions = ch_versions.mix(TRACTOGRAM_RESAMPLE.out.versions.first())
        ch_centroids_cleaned = TRACTOGRAM_RESAMPLE.out.tractograms
    }
    // BUNDLE_CENTROID if ch_centroids is empty
    else {
        BUNDLE_CENTROID(ch_bundle_cleaned)
        ch_centroids_cleaned = BUNDLE_CENTROID.out.centroids
        ch_versions = ch_versions.mix(BUNDLE_CENTROID.out.versions.first())
    }

    ch_label_map = ch_bundle_cleaned.join( ch_centroids_cleaned )

    BUNDLE_LABELMAP ( ch_label_map )
    ch_versions = ch_versions.mix(BUNDLE_LABELMAP.out.versions.first())
    ch_labels_trk = BUNDLE_LABELMAP.out.labels_trk
    ch_labels_bundles = BUNDLE_LABELMAP.out.labels

    BUNDLE_UNIFORMIZE ( ch_labels_trk )
    ch_versions = ch_versions.mix(BUNDLE_UNIFORMIZE.out.versions.first())
    ch_labels_trk_cleaned = BUNDLE_UNIFORMIZE.out.bundles

    ch_stats = ch_labels_trk_cleaned.join( ch_labels_bundles )
                                    .join( ch_metrics )
                                    .join( ch_lesion_mask )

    BUNDLE_STATS ( ch_stats )
    ch_versions = ch_versions.mix(BUNDLE_STATS.out.versions.first())

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

    //ch_length = stat_length.collect()
    //ch_endpoints_raw = stat_endpoints_raw.collect()
    //ch_endpoints_metric = stat_endpoints_metric.collect()
    //ch_mean_std = stat_mean_std.collect()
    //ch_volume = stat_volume.collect()
    //ch_volume_lesions = stat_volume_lesions.collect()
    //ch_streamline_count = stat_streamline_count.collect()
    //ch_streamline_count_lesions = stat_streamline_count_lesions.collect()
    //ch_mean_std_per_point = stat_mean_std_per_point.collect()
    //ch_lesion_stats = stat_lesion_stats.collect()

    //BUNDLE_MERGE_LENGTH ( ch_length )
    //global_length = BUNDLE_MERGE_LENGTH.out.stats

    //BUNDLE_MERGE_RAW ( ch_endpoints_raw )
    //global_endpoints_raw = BUNDLE_MERGE_RAW.out.stats

    //BUNDLE_MERGE_METRIC ( ch_endpoints_metric )
    //global_endpoints_metric = BUNDLE_MERGE_METRIC.out.stats

    //BUNDLE_MERGE_STD ( ch_mean_std )
    //global_mean_std = BUNDLE_MERGE_STD.out.stats

    //BUNDLE_MERGE_VOLUME ( ch_volume )
    //global_volume = BUNDLE_MERGE_VOLUME.out.stats

    //BUNDLE_MERGE_VOLUME_LESION ( ch_volume_lesions )
    //global_volume_lesions = BUNDLE_MERGE_VOLUME_LESION.out.stats

    //BUNDLE_MERGE_COUNT ( ch_streamline_count )
    //global_streamline_count = BUNDLE_MERGE_COUNT.out.stats

    //BUNDLE_MERGE_COUNT_LESION ( ch_streamline_count_lesions )
    //global_streamline_count_lesions = BUNDLE_MERGE_COUNT_LESION.out.stats

    //BUNDLE_MERGE_STD_POINT ( ch_mean_std_per_point )
    //global_mean_std_per_point = BUNDLE_MERGE_STD_POINT.out.stats

    //BUNDLE_MERGE_LESION ( ch_lesion_stats )
    //global_lesion_stats = BUNDLE_MERGE_LESION.out.stats


    emit:
        stat_length
        stat_endpoints_raw
        stat_endpoints_metric
        stat_mean_std
        stat_volume
        stat_volume_lesions
        stat_streamline_count
        stat_streamline_count_lesions
        stat_volume_per_labels
        stat_volume_per_labels_lesions
        stat_mean_std_per_point
        stat_lesion_stats
        endpoints_head
        endpoints_tail
        lesion_map
        //global_length
        //global_endpoints_raw
        //global_endpoints_metric
        //global_mean_std
        //global_volume
        //global_volume_lesions
        //global_streamline_count
        //global_streamline_count_lesions
        //global_mean_std_per_point
        //global_lesion_stats
        versions = ch_versions
}


