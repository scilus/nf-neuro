process REGISTRATION_TRACTOGRAM {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.1.0.sif':
        'scilus/scilus:2.1.0' }"

    input:
    tuple val(meta), path(anat), path(affine), path(tractogram), path(ref), path(deformation)

    output:
    tuple val(meta), path("*__*.{trk,tck}"), emit: tractogram
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.suffix ? "_${task.ext.suffix}" : ""
    def reference = "$ref" ? "--reference $ref" : ""
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

    for tractogram in ${tractogram};
    do

    ext=\${tractogram#*.}
    bname=\$(basename \${tractogram} .\${ext})

    scil_tractogram_apply_transform.py \$tractogram $anat \$affine \
        ${prefix}__\${bname}${suffix}.\${ext} \
        $in_deformation \
        $inverse \
        $reverse_operation \
        $reference \
        --keep_invalid -f

    if [[ "$invalid_management" == "keep" ]]; then
        echo "Skip invalid streamline detection: ${prefix}__\${bname}${suffix}.\${ext}"
        continue
    fi

    scil_tractogram_remove_invalid.py ${prefix}__\${bname}${suffix}.\${ext} \
        ${prefix}__\${bname}${suffix}.\${ext} \
        $cut_invalid \
        $remove_single_point \
        $remove_overlapping_points \
        $threshold \
        $no_empty \
        -f

    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list --disable-pip-version-check --no-python-version-warning | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.suffix ? "_${task.ext.suffix}" : ""
    """
    scil_tractogram_apply_transform.py -h
    scil_tractogram_remove_invalid.py -h

    for tractogram in ${tractogram};
    do

    ext=\${tractogram#*.}
    bname=\$(basename \${tractogram} .\${ext})

    touch ${prefix}__\${bname}${suffix}.\${ext}

    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        scilpy: \$(pip list --disable-pip-version-check --no-python-version-warning | grep scilpy | tr -s ' ' | cut -d' ' -f2)
    END_VERSIONS
    """
}
