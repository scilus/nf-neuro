process PREPROC_EDDY {
    tag "$meta.id"
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "https://scil.usherbrooke.ca/containers/scilus_latest.sif":
        "scilus/scilus:latest"}"

    input:
        tuple val(meta), path(dwi), path(bval), path(bvec), path(rev_dwi), path(rev_bval), path(rev_bvec), path(corrected_b0s), path(topup_fieldcoef), path(topup_movpart)

    output:
        tuple val(meta), path("*__dwi_corrected.nii.gz")    , emit: dwi_corrected
        tuple val(meta), path("*__dwi_eddy_corrected.bval") , emit: bval_corrected
        tuple val(meta), path("*__dwi_eddy_corrected.bvec") , emit: bvec_corrected
        tuple val(meta), path("*__b0_bet_mask.nii.gz")      , emit: b0_mask
        tuple val(meta), path("*__dwi_eddy_mqc.gif")        , emit: dwi_eddy_mqc, optional:true
        tuple val(meta), path("*__rev_dwi_eddy_mqc.gif")    , emit: rev_dwi_eddy_mqc, optional:true
        path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def slice_drop_flag = task.ext.slice_drop_correction ? "--slice_drop_correction " : ""
    def bet_topup_before_eddy_f = task.ext.bet_topup_before_eddy_f ?: ""
    def prefix_topup = task.ext.prefix_topup ? task.ext.prefix_topup : ""
    def b0_thr_extract_b0 = task.ext.b0_thr_extract_b0 ? task.ext.b0_thr_extract_b0 : ""
    def encoding = task.ext.encoding ? task.ext.encoding : ""
    def readout = task.ext.readout ? task.ext.readout : ""
    def dilate_b0_mask_prelim_brain_extraction = task.ext.dilate_b0_mask_prelim_brain_extraction ? task.ext.dilate_b0_mask_prelim_brain_extraction : ""
    def eddy_cmd = task.ext.eddy_cmd ? task.ext.eddy_cmd : "eddy_cpu"
    def bet_prelim_f = task.ext.bet_prelim_f ? task.ext.bet_prelim_f : ""
    def extra_args = task.ext.extra_args ?: ""
    def run_qc = task.ext.run_qc ? task.ext.run_qc : false

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$task.cpus
    export OMP_NUM_THREADS=$task.cpus
    export OPENBLAS_NUM_THREADS=1
    export ANTS_RANDOM_SEED=7468
    export MRTRIX_RNG_SEED=12345

    orig_bval=$bval
    # Concatenate DWIs
    number_rev_dwi=0
    if [[ -f "$rev_dwi" ]];
    then
        scil_dwi_concatenate.py ${prefix}__concatenated_dwi.nii.gz ${prefix}__concatenated_dwi.bval ${prefix}__concatenated_dwi.bvec -f\
            --in_dwis ${dwi} ${rev_dwi} --in_bvals ${bval} ${rev_bval}\
            --in_bvecs ${bvec} ${rev_bvec}

        number_rev_dwi=\$(scil_header_print_info.py ${rev_dwi} --key dim | sed "s/  / /g" | sed "s/  / /g" | rev | cut -d' ' -f4-4 | rev)

        dwi=${prefix}__concatenated_dwi.nii.gz
        bval=${prefix}__concatenated_dwi.bval
        bvec=${prefix}__concatenated_dwi.bvec
    else
        dwi=${dwi}
        bval=${bval}
        bvec=${bvec}
    fi

    # If topup has been run before
    if [[ -f "$topup_fieldcoef" ]]
    then
        mrconvert $corrected_b0s b0_corrected.nii.gz -coord 3 0 -axes 0,1,2 -nthreads $task.cpus
        bet b0_corrected.nii.gz ${prefix}__b0_bet.nii.gz -m -R\
            -f $bet_topup_before_eddy_f

        scil_dwi_prepare_eddy_command.py \${dwi} \${bval} \${bvec} ${prefix}__b0_bet_mask.nii.gz\
            --topup $prefix_topup --eddy_cmd $eddy_cmd\
            --b0_thr $b0_thr_extract_b0\
            --encoding_direction $encoding\
            --readout $readout --out_script --fix_seed\
            --n_reverse \${number_rev_dwi}\
            --lsr_resampling\
            $slice_drop_flag
    else
        scil_dwi_extract_b0.py \${dwi} \${bval} \${bvec} ${prefix}__b0.nii.gz --mean\
            --b0_threshold $b0_thr_extract_b0 --skip_b0_check
        bet ${prefix}__b0.nii.gz ${prefix}__b0_bet.nii.gz -m -R -f $bet_prelim_f
        scil_volume_math.py convert ${prefix}__b0_bet_mask.nii.gz ${prefix}__b0_bet_mask.nii.gz --data_type uint8 -f
        maskfilter ${prefix}__b0_bet_mask.nii.gz dilate ${prefix}__b0_bet_mask_dilated.nii.gz\
            --npass $dilate_b0_mask_prelim_brain_extraction -nthreads $task.cpus
        scil_volume_math.py multiplication ${prefix}__b0.nii.gz ${prefix}__b0_bet_mask_dilated.nii.gz\
            ${prefix}__b0_bet.nii.gz --data_type float32 -f

        scil_dwi_prepare_eddy_command.py \${dwi} \${bval} \${bvec} ${prefix}__b0_bet_mask.nii.gz\
            --eddy_cmd $eddy_cmd --b0_thr $b0_thr_extract_b0\
            --encoding_direction $encoding\
            --readout $readout --out_script --fix_seed\
            $slice_drop_flag
    fi

    echo "--very_verbose $extra_args --nthr=$task.cpus" >> eddy.sh
    sh eddy.sh
    scil_volume_math.py lower_clip dwi_eddy_corrected.nii.gz 0 ${prefix}__dwi_corrected.nii.gz

    if [[ \$number_rev_dwi -eq 0 ]]
    then
        mv dwi_eddy_corrected.eddy_rotated_bvecs ${prefix}__dwi_eddy_corrected.bvec
        mv \${orig_bval} ${prefix}__dwi_eddy_corrected.bval
    else
        scil_gradients_validate_correct_eddy.py dwi_eddy_corrected.eddy_rotated_bvecs \${bval} \${number_rev_dwi} ${prefix}__dwi_eddy_corrected.bvec ${prefix}__dwi_eddy_corrected.bval
    fi

    if $run_qc;
    then
        extract_dim=\$(mrinfo ${dwi} -size)
        read sagittal_dim coronal_dim axial_dim fourth_dim <<< "\${extract_dim}"

        # Get the middle slice
        coronal_dim=\$((\$coronal_dim / 2))
        axial_dim=\$((\$axial_dim / 2))
        sagittal_dim=\$((\$sagittal_dim / 2))

        viz_params="--display_slice_number --display_lr --size 256 256"
        rev_dwi=""
        if [[ -f "$rev_dwi" ]];
        then
            scil_dwi_powder_average.py ${rev_dwi} ${prefix}__dwi_eddy_corrected.bval ${prefix}__rev_dwi_powder_average.nii.gz
            scil_volume_math.py normalize_max ${prefix}__rev_dwi_powder_average.nii.gz ${prefix}__rev_dwi_powder_average_norm.nii.gz
            rev_dwi="rev_dwi"
        fi
        scil_dwi_powder_average.py ${dwi} ${prefix}__dwi_eddy_corrected.bval ${prefix}__dwi_powder_average.nii.gz
        scil_dwi_powder_average.py ${prefix}__dwi_corrected.nii.gz ${prefix}__dwi_eddy_corrected.bval ${prefix}__dwi_corrected_powder_average.nii.gz
        scil_volume_math.py normalize_max ${prefix}__dwi_powder_average.nii.gz ${prefix}__dwi_powder_average_norm.nii.gz
        scil_volume_math.py normalize_max ${prefix}__dwi_corrected_powder_average.nii.gz ${prefix}__dwi_corrected_powder_average_norm.nii.gz

        for image in dwi_corrected dwi \${rev_dwi}
        do
            scil_viz_volume_screenshot.py ${prefix}__\${image}_powder_average_norm.nii.gz ${prefix}__\${image}_coronal.png \${viz_params} --slices \${coronal_dim} --axis coronal
            scil_viz_volume_screenshot.py ${prefix}__\${image}_powder_average_norm.nii.gz ${prefix}__\${image}_axial.png \${viz_params} --slices \${axial_dim} --axis axial
            scil_viz_volume_screenshot.py ${prefix}__\${image}_powder_average_norm.nii.gz ${prefix}__\${image}_sagittal.png \${viz_params} --slices \${sagittal_dim} --axis sagittal

            if [ \$image == "dwi_corrected" ] || [ \$image == "rev_dwi" ]
            then
                title="After"
            else
                title="Before"
            fi

            convert +append ${prefix}__\${image}_coronal_slice_\${coronal_dim}.png \
                    ${prefix}__\${image}_axial_slice_\${axial_dim}.png  \
                    ${prefix}__\${image}_sagittal_slice_\${sagittal_dim}.png \
                    ${prefix}__\${image}.png

            convert -annotate +20+230 "\${title}" -fill white -pointsize 30 ${prefix}__\${image}.png ${prefix}__\${image}.png
        done

        if [[ -f "$rev_dwi" ]];
        then
            convert -delay 10 -loop 0 -morph 10 \
                ${prefix}__rev_dwi.png ${prefix}__dwi_corrected.png ${prefix}__rev_dwi.png \
                ${prefix}__rev_dwi_eddy_mqc.gif
        fi

        convert -delay 10 -loop 0 -morph 10 \
                ${prefix}__dwi.png ${prefix}__dwi_corrected.png ${prefix}__dwi.png \
                ${prefix}__dwi_eddy_mqc.gif

        rm -rf *png
        rm -rf *powder_average*
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
        mrtrix: \$(dwidenoise -version 2>&1 | sed -n 's/== dwidenoise \\([0-9.]\\+\\).*/\\1/p')
        fsl: \$(flirt -version 2>&1 | sed -n 's/FLIRT version \\([0-9.]\\+\\)/\\1/p')
        imagemagick: \$(convert -version | sed -n 's/.*ImageMagick \\([0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\).*/\\1/p')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}__dwi_corrected.nii.gz
    touch ${prefix}__dwi_eddy_mqc.gif
    touch ${prefix}__rev_dwi_eddy_mqc.gif
    touch ${prefix}__dwi_eddy_corrected.bval
    touch ${prefix}__dwi_eddy_corrected.bvec
    touch ${prefix}__b0_bet_mask.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
        mrtrix: \$(dwidenoise -version 2>&1 | sed -n 's/== dwidenoise \\([0-9.]\\+\\).*/\\1/p')
        fsl: \$(flirt -version 2>&1 | sed -n 's/FLIRT version \\([0-9.]\\+\\)/\\1/p')
        imagemagick: \$(convert -version | sed -n 's/.*ImageMagick \\([0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\).*/\\1/p')
    END_VERSIONS

    function handle_code () {
    local code=\$?
    ignore=( 1 )
    exit \$([[ " \${ignore[@]} " =~ " \$code " ]] && echo 0 || echo \$code)
    }
    trap 'handle_code' ERR

    scil_volume_math.py -h
    maskfilter -h
    bet -h
    scil_dwi_extract_b0.py -h
    scil_gradients_validate_correct_eddy.py -h
    scil_dwi_concatenate.py -h
    mrconvert -h
    scil_dwi_prepare_eddy_command.py -h
    scil_header_print_info.py -h
    scil_viz_volume_screenshot -h
    convert
    """
}
