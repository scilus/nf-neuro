process REGISTRATION_ANTSAPPLYTRANSFORMS {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        "https://scil.usherbrooke.ca/containers/scilus_latest.sif":
        "scilus/scilus:latest"}"

    input:
    tuple val(meta), path(image), path(reference), path(warp), path(affine)

    output:
    tuple val(meta), path("*__warped.nii.gz")       , emit: warped_image
    tuple val(meta), path("*__registration_mqc.gif"), emit: mqc, optional: true
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.first_suffix ? "${task.ext.first_suffix}__warped" : "warped"

    def dimensionality = task.ext.dimensionality ? "-d " + task.ext.dimensionality : ""
    def image_type = task.ext.image_type ? "-e " + task.ext.image_type : ""
    def interpolation = task.ext.interpolation ? "-n " + task.ext.interpolation : ""
    def output_dtype = task.ext.output_dtype ? "-u " + task.ext.output_dtype : ""
    def default_val = task.ext.default_val ? "-f " + task.ext.default_val : ""
    def run_qc = task.ext.run_qc ? task.ext.run_qc : false

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$task.cpus
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1

    antsApplyTransforms $dimensionality\
                        -i $image\
                        -r $reference\
                        -o ${prefix}__${suffix}.nii.gz\
                        $interpolation\
                        -t $warp $affine\
                        $image_type\
                        $default_val\
                        $output_dtype

    ### ** QC ** ###
    if $run_qc;
    then
        extract_dim=\$(mrinfo ${prefix}__${suffix}.nii.gz -size)
        read coronal_dim axial_dim sagittal_dim <<< "\${extract_dim}"

        # Get the middle slice
        axial_dim=\$((axial_dim / 2))
        sagittal_dim=\$((sagittal_dim / 2))
        coronal_dim=\$((coronal_dim / 2))

        ### ** Axial ** ###
        scil_viz_volume_screenshot.py ${prefix}__${suffix}.nii.gz warped_ax.png \
            --slices axial_dim --axis axial
        scil_viz_volume_screenshot.py $reference  ref_ax.png \
            --slices axial_dim --axis axial

        ### ** Sagittal ** ###
        scil_viz_volume_screenshot.py ${prefix}__${suffix}.nii.gz warped_sag.png \
            --slices sagittal_dim --axis sagittal
        scil_viz_volume_screenshot.py $reference  ref_sag.png \
            --slices sagittal_dim --axis sagittal

        ### ** Coronal ** ###
        scil_viz_volume_screenshot.py ${prefix}__${suffix}.nii.gz warped_cor.png \
            --slices coronal_dim --axis coronal
        scil_viz_volume_screenshot.py $reference  ref_cor.png \
            --slices coronal_dim --axis coronal

        ### ** Creating mosaics ** ###
        convert ref*.png +append mosaic_ref.png
        convert warped*.png +append mosaic_warped.png

        ### ** Final gif file ** ###
        convert -resize 50% -delay 60 -loop 0 mosaic*.png ${prefix}__${suffix}_ants_apply__registration_mqc.gif
        ### remove intermediate files
        rm *.png

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: \$(antsRegistration --version | grep "Version" | sed -E 's/.*v([0-9]+\\.[0-9]+\\.[0-9]+).*/\\1/')
        mrtrix: \$(mrinfo -version 2>&1 | sed -n 's/== mrinfo \\([0-9.]\\+\\).*/\\1/p')
        imagemagick: \$(magick -version | sed -n 's/.*ImageMagick \\([0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\).*/\\1/p')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.first_suffix ? "${task.ext.first_suffix}__warped" : "warped"

    """
    antsApplyTransforms -h

    touch ${prefix}__${suffix}.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: \$(antsRegistration --version | grep "Version" | sed -E 's/.*v([0-9]+\\.[0-9]+\\.[0-9]+).*/\\1/')
        mrtrix: \$(mrinfo -version 2>&1 | sed -n 's/== mrinfo \\([0-9.]\\+\\).*/\\1/p')
        imagemagick: \$(magick -version | sed -n 's/.*ImageMagick \\([0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\.[0-9]\\{1,\\}\\).*/\\1/p')
    END_VERSIONS
    """
}
