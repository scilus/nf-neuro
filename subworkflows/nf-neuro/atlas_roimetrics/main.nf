include { REGISTRATION_ANTS as REGISTER_ATLAS_REF } from '../../../modules/nf-neuro/registration/ants/main'
include { REGISTRATION_ANTSAPPLYTRANSFORMS as TRANSFORM_ATLAS_BUNDLES } from '../../../modules/nf-neuro/registration/antsapplytransforms/main.nf'
include { REGISTRATION_ANTSAPPLYTRANSFORMS as TRANSFORM_GM_ATLAS } from '../../../modules/nf-neuro/registration/antsapplytransforms/main.nf'
include { STATS_METRICSINROI     } from '../../../modules/nf-neuro/stats/metricsinroi/main'
include { STATS_METRICSINROI as STATS_GM_ROIMETRICS } from '../../../modules/nf-neuro/stats/metricsinroi/main'
include { STATS_ROIVOLUMES as STATS_WM_VOLUMES } from '../../../modules/nf-neuro/stats/roivolumes/main'
include { STATS_ROIVOLUMES as STATS_GM_VOLUMES } from '../../../modules/nf-neuro/stats/roivolumes/main'
include { ATLAS_IIT              } from '../../nf-neuro/atlas_iit/main'
include { UTILS_OPTIONS } from '../utils_options/main'

workflow ATLAS_ROIMETRICS {
    take:
        ch_subject_reference  // channel : [required] meta, subject_ref_image
        ch_metrics            // channel : [required] meta, [metrics]
        ch_registered_atlas   // channel : [optional] meta, [rois], labelmap, labelmap_lut
        options               // channel : [optional] map of options

    main:
        ch_versions = channel.empty()

        UTILS_OPTIONS("${moduleDir}/meta.yml", options, true)
        options = UTILS_OPTIONS.out.options.value

        assert [options.use_atlas_iit, options.use_registered_atlas].count(true) <= 1 :
            "Only one atlas source can be selected at a time for ROI metrics extraction." +
            " Please set only one of the options 'use_atlas_*' or 'use_registered_atlas' to 'true'."

        // ROIs in the subject's own space, whatever their provenance. Both branches below
        // must populate these before the statistics section runs.
        ch_rois_subject_space = channel.empty()  // [meta, [rois]]
        ch_labelmap_with_lut  = channel.empty()  // [meta, labelmap, lut]

        if (options.use_atlas_iit) {
            ATLAS_IIT(
                [
                    threshold_bundles: options.use_binary_masks,
                    atlas_iit_b0: options.atlas_iit_b0,
                    atlas_iit_bundle_masks_dir: options.atlas_iit_bundle_masks_dir,
                    run_gm_roimetrics: options.run_gm_roimetrics,
                    atlas_iit_gm_atlas: options.atlas_iit_gm_atlas,
                    atlas_iit_gm_lut: options.atlas_iit_gm_lut
                ]
            )
            ch_versions = ch_versions.mix(ATLAS_IIT.out.versions)
            def ch_bundle_masks = ATLAS_IIT.out.bundles.toList()
            def ch_template_ref = ATLAS_IIT.out.b0

            // Register atlas reference image to subject space
            ch_input_register_atlas = ch_subject_reference
                .combine(ch_template_ref)
                .map{ meta, subject_ref, template_ref -> [meta, subject_ref, template_ref, [], []] }
            REGISTER_ATLAS_REF(ch_input_register_atlas)
            ch_versions = ch_versions.mix(REGISTER_ATLAS_REF.out.versions)

            // Apply the transformation to subject space to the bundles
            ch_atlas_transform_bundles = ch_subject_reference
                .join(REGISTER_ATLAS_REF.out.forward_image_transform)
                .combine(ch_bundle_masks)
                .map {
                    meta, subject_ref, transform, bundles ->
                        [meta, bundles, subject_ref, transform]
                }
            TRANSFORM_ATLAS_BUNDLES(ch_atlas_transform_bundles)
            ch_versions = ch_versions.mix(TRANSFORM_ATLAS_BUNDLES.out.versions)

            ch_rois_subject_space = TRANSFORM_ATLAS_BUNDLES.out.warped_image

            if (options.run_gm_roimetrics) {
                // Reuse the atlas B0 → subject registration transform for the GM atlas
                ch_transform_gm = ch_subject_reference
                    .join(REGISTER_ATLAS_REF.out.forward_image_transform)
                    .combine(ATLAS_IIT.out.gm_atlas)
                    .map { meta, subject_ref, transform, gm_atlas ->
                        [meta, gm_atlas, subject_ref, transform]
                    }
                TRANSFORM_GM_ATLAS(ch_transform_gm)
                ch_versions = ch_versions.mix(TRANSFORM_GM_ATLAS.out.versions)

                ch_labelmap_with_lut = TRANSFORM_GM_ATLAS.out.warped_image
                    .combine(ATLAS_IIT.out.gm_lut)
            }
        }
        else if (options.use_registered_atlas) {
            // The caller registered the atlas itself, so no download and no registration
            // happen here. Entries are already in each subject's space.
            ch_rois_subject_space = ch_registered_atlas
                .map { meta, rois, _labelmap, _lut -> [meta, rois] }
                .filter { _meta, rois -> rois }

            ch_labelmap_with_lut = ch_registered_atlas
                .filter { _meta, _rois, labelmap, lut -> labelmap && lut }
                .map { meta, _rois, labelmap, lut -> [meta, labelmap, lut] }
        }
        else {
            error "No atlas selected for ROI metrics extraction. " +
                "Please set one of the options 'use_atlas_*' to 'true' to run atlas-based ROI metrics, " +
                "or set 'use_registered_atlas' to 'true' and supply the atlas through 'ch_registered_atlas'."
        }

        //
        // EXTRACT ROI DIFFUSION METRICS STATISTICS (optional, default: true)
        //
        ch_stats_json = channel.empty()
        ch_stats_mean = channel.empty()
        ch_stats_std  = channel.empty()

        if (options.run_roi_metrics) {
            // Input: [meta, [metrics_list], [masks]]
            ch_input_metricsinroi = ch_metrics
                .join(ch_rois_subject_space)
                .map {
                    meta, metrics, masks ->
                        [meta, metrics, masks, []]
                }

            STATS_METRICSINROI(ch_input_metricsinroi)
            ch_versions = ch_versions.mix(STATS_METRICSINROI.out.versions)

            ch_stats_json = STATS_METRICSINROI.out.stats_json
            ch_stats_mean = STATS_METRICSINROI.out.stats_mean
            ch_stats_std  = STATS_METRICSINROI.out.stats_std
        }

        //
        // COMPUTE WM BUNDLE VOLUMES (optional)
        //
        ch_wm_volumes = channel.empty()

        if (options.run_roi_volumes) {
            ch_wm_volumes_input = ch_rois_subject_space
                .map { meta, masks -> [meta, masks, []] }
            STATS_WM_VOLUMES(ch_wm_volumes_input)
            ch_versions = ch_versions.mix(STATS_WM_VOLUMES.out.versions)
            ch_wm_volumes = STATS_WM_VOLUMES.out.volumes
        }

        //
        // LABELMAP ROI METRICS — the GM Desikan parcellation under the IIT atlas, or
        // whatever labelmap the caller supplied through ch_registered_atlas. When no
        // labelmap is available ch_labelmap_with_lut stays empty and nothing runs.
        //
        ch_gm_stats_json = channel.empty()
        ch_gm_stats_mean = channel.empty()
        ch_gm_stats_std  = channel.empty()
        ch_gm_volumes    = channel.empty()

        if (options.run_gm_roimetrics || options.use_registered_atlas) {
            if (options.run_roi_metrics) {
                ch_gm_input = ch_metrics
                    .join(ch_labelmap_with_lut)
                    .map { meta, metrics, labelmap, lut -> [meta, metrics, labelmap, lut] }

                STATS_GM_ROIMETRICS(ch_gm_input)
                ch_versions = ch_versions.mix(STATS_GM_ROIMETRICS.out.versions)

                ch_gm_stats_json = STATS_GM_ROIMETRICS.out.stats_json
                ch_gm_stats_mean = STATS_GM_ROIMETRICS.out.stats_mean
                ch_gm_stats_std  = STATS_GM_ROIMETRICS.out.stats_std
            }

            //
            // COMPUTE LABELMAP REGION VOLUMES (optional, only when run_roi_volumes also active)
            //
            if (options.run_roi_volumes) {
                STATS_GM_VOLUMES(ch_labelmap_with_lut)
                ch_versions = ch_versions.mix(STATS_GM_VOLUMES.out.versions)
                ch_gm_volumes = STATS_GM_VOLUMES.out.volumes
            }
        }

    emit:
        stats_json        = ch_stats_json
        stats_tab_mean    = ch_stats_mean
        stats_tab_std     = ch_stats_std

        wm_volumes        = ch_wm_volumes

        gm_stats_json     = ch_gm_stats_json
        gm_stats_tab_mean = ch_gm_stats_mean
        gm_stats_tab_std  = ch_gm_stats_std
        gm_volumes        = ch_gm_volumes

        versions        = ch_versions
}
