process REGISTRATION_CONVERT {
    tag "$meta.id"
    label 'process_single'

    container "freesurfer/freesurfer:7.4.1"
    containerOptions "--entrypoint ''"
    containerOptions "--env FSLOUTPUTTYPE='NIFTI_GZ'"

    input:
    tuple val(meta), path(affine), path(deform), path(source), path(target) /* optional, value = [] */, path(fs_license) /* optional, value = [] */

    output:
    tuple val(meta), path("*.{txt,lta,mat,dat}"), emit: init_transform
    tuple val(meta), path("*.{nii,nii.gz,mgz,m3z}"), emit: deform_transform
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    //For arguments definition, lta_convert -h
    def invert = task.ext.invert ? "--invert" : ""
    def source_geometry_init = "$source" ? "--src " + "$source" : ""
    def target_geometry_init = "$target" ? "--trg " + "$target" : ""
    def in_format_init = task.ext.in_format_init ? "--in" + task.ext.in_format_init + " " + "$affine" : "--inlta " + "$affine"
    def out_format_init = task.ext.out_format_init ? "--out" + task.ext.out_format_init : "--outitk"

    //For arguments definition, mri_warp_convert -h
    def source_geometry_deform = "$source" ? "--insrcgeom " + "$source" : ""
    def in_format_deform = task.ext.in_format_deform ? "--in" + task.ext.in_format_deform + " " + "$deform" : "--inras " + "$deform"
    def out_format_deform = task.ext.out_format_deform ? "--out" + task.ext.out_format_deform : "--outitk"
    def downsample = task.ext.downsample ? "--downsample" : ""

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$task.cpus
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1

    cp $fs_license \$FREESURFER_HOME/license.txt

    declare -A affine_dictionnary=( ["--outlta"]="lta" \
                                    ["--outfsl"]="mat" \
                                    ["--outmni"]="xfm" \
                                    ["--outreg"]="dat" \
                                    ["--outniftyreg"]="txt" \
                                    ["--outitk"]="txt" \
                                    ["--outvox"]="txt" )

    ext_affine=\${affine_dictionnary[${out_format_init}]}

    declare -A deform_dictionnary=( ["--outm3z"]="m3z" \
                                    ["--outfsl"]="nii.gz" \
                                    ["--outlps"]="nii.gz" \
                                    ["--outitk"]="nii.gz" \
                                    ["--outras"]="nii.gz" \
                                    ["--outvox"]="mgz" )

    ext_deform=\${deform_dictionnary[${out_format_deform}]}

    lta_convert ${invert} ${source_geometry_init} ${target_geometry_init} ${in_format_init} ${out_format_init} ${prefix}__init_warp.\${ext_affine}
    mri_warp_convert ${source_geometry_deform} ${downsample} ${in_format_deform} ${out_format_deform}  ${prefix}__deform_warp.\${ext_deform}

    rm \$FREESURFER_HOME/license.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        Freesurfer: 7.4.1
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    lta_convert -h
    mri_warp_convert -h

    touch ${prefix}__init_transform.txt
    touch ${prefix}__deform_transform.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        Freesurfer: 7.4.1
    END_VERSIONS
    """
}
