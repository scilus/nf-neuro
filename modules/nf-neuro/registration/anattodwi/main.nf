

process REGISTRATION_ANATTODWI {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://scil.usherbrooke.ca/containers/scilus_2.0.2.sif':
        'scilus/scilus:2.0.2' }"

    input:
    tuple val(meta), path(t1), path(b0), path(metric)

    output:
    tuple val(meta), path("*0GenericAffine.mat"), path("*1InverseWarp.nii.gz")  , emit: transfo_trk
    tuple val(meta), path("*1Warp.nii.gz"), path("*0GenericAffine.mat")         , emit: transfo_image
    tuple val(meta), path("*t1_warped.nii.gz")                                  , emit: t1_warped
    path "versions.yml"                                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def cpus = task.ext.cpus ? "$task.ext.cpus" : "1"

    """
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$task.ext.cpus
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1
    export ANTS_RANDOM_SEED=1234

    antsRegistration --dimensionality 3 --float 0\
        --output [output,outputWarped.nii.gz,outputInverseWarped.nii.gz]\
        --interpolation Linear --use-histogram-matching 0\
        --winsorize-image-intensities [0.005,0.995]\
        --initial-moving-transform [$b0,$t1,1]\
        --transform Rigid['0.2']\
        --metric MI[$b0,$t1,1,32,Regular,0.25]\
        --convergence [500x250x125x50,1e-6,10] --shrink-factors 8x4x2x1\
        --smoothing-sigmas 3x2x1x0\
        --transform Affine['0.2']\
        --metric MI[$b0,$t1,1,32,Regular,0.25]\
        --convergence [500x250x125x50,1e-6,10] --shrink-factors 8x4x2x1\
        --smoothing-sigmas 3x2x1x0\
        --transform SyN[0.1,3,0]\
        --metric MI[$b0,$t1,1,32]\
        --metric CC[$metric,$t1,1,4]\
        --convergence [50x25x10,1e-6,10] --shrink-factors 4x2x1\
        --smoothing-sigmas 3x2x1

    mv outputWarped.nii.gz ${prefix}__t1_warped.nii.gz
    mv output0GenericAffine.mat ${prefix}__output0GenericAffine.mat
    mv output1InverseWarp.nii.gz ${prefix}__output1InverseWarp.nii.gz
    mv output1Warp.nii.gz ${prefix}__output1Warp.nii.gz


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: antsRegistration --version | grep "Version" | sed -E 's/.*v([0-9]+\\.[0-9]+\\.[0-9]+).*/\\1/'
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    antsRegistration -h

    touch ${prefix}__t1_warped.nii.gz
    touch ${prefix}__output0GenericAffine.mat
    touch ${prefix}__output1InverseWarp.nii.gz
    touch ${prefix}__output1Warp.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ants: antsRegistration --version | grep "Version" | sed -E 's/.*v([0-9]+\\.[0-9]+\\.[0-9]+).*/\\1/'
    END_VERSIONS
    """
}
