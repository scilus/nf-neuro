process REGISTRATION_TRACTOGRAM {
    tag "$meta.id"
    label 'process_single'

    container "scilus/scilus:2.2.1"

    input:
    tuple val(meta), path(anat), path(affine), path(tractogram), path(reference), path(deformation)

    output:
    tuple val(meta), path("*.{trk,tck,h5}") , emit: tractogram
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.suffix ? "_${task.ext.suffix}" : ""
    reference = "$reference" ? "--reference $reference" : ""
    def in_deformation = "$deformation" ? "--in_deformation $deformation" : ""

    def inverse = task.ext.inverse ? "--inverse" : ""
    def reverse_operation = task.ext.reverse_operation ? "--reverse_operation" : ""

    def invalid_management = task.ext.invalid_streamlines ?: "cut"
    def cut_invalid = invalid_management == "cut" ? "--cut_invalid" : ""
    def remove_single_point = task.ext.remove_single_point ? "--remove_single_point" : ""
    def remove_overlapping_points = task.ext.remove_overlapping_points ? "--remove_overlapping_points" : ""
    def threshold = task.ext.threshold ? "--threshold " + task.ext.threshold : ""
    def no_empty = task.ext.no_empty ? "--no_empty" : ""

    """
    affine=$affine
    if [[ "$affine" == *.txt ]]; then
        ConvertTransformFile 3 $affine affine.mat --convertToAffineType \
            && affine="affine.mat" \
            || echo "TXT affine transform file conversion failed, using original file."
    fi

    for tractogram in ${tractogram}; do
        ext=\${tractogram#*.}
        bname=\$(basename \${tractogram} .\${ext} | sed 's/${prefix}_\\+//')
        name=${prefix}_\${bname}${suffix}.\${ext}

        if [[ \$ext == "h5" ]]; then

            scil_tractogram_apply_transform_to_hdf5 \$tractogram \
                $anat \
                \$affine \
                \$name \
                $in_deformation \
                $inverse \
                $reverse_operation \
                $reference \
                $cut_invalid -f

        else

            scil_tractogram_apply_transform \$tractogram $anat \$affine \$name \
                $in_deformation \
                $inverse \
                $reverse_operation \
                $reference \
                --keep_invalid -f

            if [[ "$invalid_management" == "keep" ]]; then
                echo "Skip invalid streamline detection: \$name"
                continue
            fi

            scil_tractogram_remove_invalid \$name \$name \
                $cut_invalid\
                $remove_single_point\
                $remove_overlapping_points\
                $threshold\
                $no_empty\
                -f
        fi
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: \$(antsRegistration --version | grep "Version" | sed -E 's/.*Version: ([0-9.]+).*/\\1/')
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.suffix ? "_${task.ext.suffix}" : ""
    """
    scil_tractogram_apply_transform -h
    scil_tractogram_remove_invalid -h

    for tractogram in ${tractogram}; do
        ext=\${tractogram#*.}
        bname=\$(basename \${tractogram} .\${ext} | sed 's/${prefix}_\\+//')
        name=${prefix}_\${bname}${suffix}.\${ext}
        touch \$name
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: \$(antsRegistration --version | grep "Version" | sed -E 's/.*Version: ([0-9.]+).*/\\1/')
        scilpy: \$(uv pip -q -n list | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
