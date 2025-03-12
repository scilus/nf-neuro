process UTILS_TEMPLATEFLOW {
    tag "$template"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ 'community.wave.seqera.io/library/pip_templateflow:2f726c524c63271e' }"

    input:
        tuple val(template)

    output:
        path("tpl-${template}")             , emit: folder
        path("${template}_metadata.json")   , emit: metadata
        path("${template}_citations.bib")   , emit: citations
        path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    template 'templateflow.py'

    stub:

    """
    mkdir tpl-${template}
    touch ${template}_metadata.json
    touch ${template}_citations.bib

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        templateflow: \$(python3 -c 'import templateflow; print(templateflow.__version__)')
        python: \$(python3 -c 'import platform; print(platform.python_version())')
    END_VERSIONS
    """
}
