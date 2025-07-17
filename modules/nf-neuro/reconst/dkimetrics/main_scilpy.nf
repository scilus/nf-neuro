
process RECONST_DKIMETRICS {
    tag "$meta.id"
    label 'process_single'

    container "mrtrix3/mrtrix3:3.0.5"

    input:
        tuple val(meta), path(dwi), path(bval), path(bvec), path(mask)

    output:
        tuple val(meta), path("*__ak.nii.gz")                      , emit: ak, optional: true
        tuple val(meta), path("*__dki_ad.nii.gz")                  , emit: dki_ad, optional: true
        tuple val(meta), path("*__dki_fa.nii.gz")                  , emit: dki_fa, optional: true
        tuple val(meta), path("*__dki_md.nii.gz")                  , emit: dki_md, optional: true
        tuple val(meta), path("*__dki_rd.nii.gz")                  , emit: dki_rd, optional: true
        tuple val(meta), path("*__dki_residual.nii.gz")            , emit: dki_residual, optional: true
        tuple val(meta), path("*__mk.nii.gz")                      , emit: mk, optional: true
        tuple val(meta), path("*__msd.nii.gz")                     , emit: msd, optional: true
        tuple val(meta), path("*__rk.nii.gz")                      , emit: rk, optional: true
        tuple val(meta), path("*__dki_mqc.png")                    , emit: mqc, optional: true
        path "versions.yml"                                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def run_qc = task.ext.run_qc ?: false

    if ( mask ) args += " --mask $mask"
    if ( task.ext.ak ) args += " --ak ${prefix}__ak.nii.gz"
    if ( task.ext.dki_ad ) args += " --dki_ad ${prefix}__dki_ad.nii.gz"
    if ( task.ext.dki_fa ) args += " --dki_fa ${prefix}__dki_fa.nii.gz"
    if ( task.ext.dki_md ) args += " --dki_md ${prefix}__dki_md.nii.gz"
    if ( task.ext.dki_rd ) args += " --dki_rd ${prefix}__dki_rd.nii.gz"
    if ( task.ext.dki_residual ) args += " --dki_residual ${prefix}__dki_residual.nii.gz"
    if ( task.ext.mk ) args += " --mk ${prefix}__mk.nii.gz"
    if ( task.ext.msd ) args += " --msd ${prefix}__msd.nii.gz"
    if ( task.ext.rk ) args += " --rk ${prefix}__rk.nii.gz"

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1

    scil_dki_metrics.py $dwi $bval $bvec --not_all $args -f

    if [ "$run_qc" = true ] && [ "$args" != '' ];
    then
        nii_files=\$(echo "$args" | awk '{for(i=1; i<NF; i++) if (\$i ~ /^--(dki_ad|dki_fa|dki_md|dki_rd|dki_residual)\$/) print \$(i+1)}')

        # Viz 3D images
        for image in \${nii_files};
        do
            dim=\$(mrinfo \${image} -ndim)
            extract_dim=\$(mrinfo \${image} -size)
            if [ "\$dim" == 3 ];
            then
                read sagittal_dim coronal_dim axial_dim <<< "\${extract_dim}"
            elif [ "\$dim" == 4 ];
            then
                read sagittal_dim coronal_dim axial_dim forth_dim <<< "\${extract_dim}"
            fi

            # Get the middle slice
            coronal_dim=\$((\$coronal_dim / 2))
            axial_dim=\$((\$axial_dim / 2))
            sagittal_dim=\$((\$sagittal_dim / 2))

            echo \$coronal_dim
            echo \$axial_dim
            echo \$sagittal_dim

            image=\${image/${prefix}__/}
            image=\${image/.nii.gz/}
            viz_params="--display_slice_number --display_lr --size 256 256"
            scil_viz_volume_screenshot.py ${prefix}__\${image}.nii.gz ${prefix}__\${image}_coronal.png \${viz_params} --slices \${coronal_dim} --axis coronal
            scil_viz_volume_screenshot.py ${prefix}__\${image}.nii.gz ${prefix}__\${image}_axial.png \${viz_params} --slices \${axial_dim} --axis axial
            scil_viz_volume_screenshot.py ${prefix}__\${image}.nii.gz ${prefix}__\${image}_sagittal.png \${viz_params} --slices \${sagittal_dim} --axis sagittal

            convert +append ${prefix}__\${image}_coronal_slice_\${coronal_dim}.png \
                    ${prefix}__\${image}_axial_slice_\${axial_dim}.png  \
                    ${prefix}__\${image}_sagittal_slice_\${sagittal_dim}.png \
                    ${prefix}__\${image}.png

            convert -annotate +20+230 "\${image}" -fill white -pointsize 30 ${prefix}__\${image}.png ${prefix}__\${image}.png
        done

        rm -rf *slice*
        convert -append *png ${prefix}__dki_mqc.png
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list --disable-pip-version-check --no-python-version-warning | grep scilpy | tr -s ' ' | cut -d' ' -f2)
        mrtrix: \$(mrinfo -version 2>&1 | sed -n 's/== mrinfo \\([0-9.]\\+\\).*/\\1/p')
        imagemagick: \$(convert -version | sed -n 's/.*ImageMagick \\([0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\).*/\\1/p')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    scil_dki_metrics.py -h

    touch ${prefix}__ak.nii.gz
    touch ${prefix}__dki_ad.nii.gz
    touch ${prefix}__dki_fa.nii.gz
    touch ${prefix}__dki_md.nii.gz
    touch ${prefix}__dki_rd.nii.gz
    touch ${prefix}__dki_residual.nii.gz
    touch ${prefix}__mk.nii.gz
    touch ${prefix}__msd.nii.gz
    touch ${prefix}__rk.nii.gz
    touch ${prefix}__dki_mqc.png

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list --disable-pip-version-check --no-python-version-warning | grep scilpy | tr -s ' ' | cut -d' ' -f2)
        mrtrix: \$(mrinfo -version 2>&1 | sed -n 's/== mrinfo \\([0-9.]\\+\\).*/\\1/p')
    END_VERSIONS
    """
}
