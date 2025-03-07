process UTILS_TEMPLATEFLOW {
    tag "$template"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ 'community.wave.seqera.io/library/pip_templateflow:2f726c524c63271e' }"

    input:
        tuple val(template), val(resolution), val(suffix)

    output:
    path("*.nii.gz")              , emit: templates
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def metadata = task.ext.metadata ?: false
    def citations = task.ext.citations ?: false

    """
    #!/usr/bin/env python
    import os

    import templateflow as tf

    # Set up the templateflow home folder in work directory.
    os.environ['TEMPLATEFLOW_HOME'] = os.path($workDir)
    tf.conf.setup_home(force=True)

    # Fetch the specified template.
    str(tf.api.get($template, resolution=$resolution, suffix='$suffix'))

    if $metadata:
        # Fetch the metadata for the specified template.
        metadata = get_metadata($template)

        # Convert into .txt file.
        with open('metadata.txt', 'w') as f:
            f.write(metadata)

    if $citations:
        # Fetch citations.
        citations = get_citations($template, bibtex=True)

        # Convert into .bib file.
        with open('citations.bib', 'w') as f:
            f.write(citations)

    # Write versions.yml file.
    

    """

    stub:

    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        utils: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}
