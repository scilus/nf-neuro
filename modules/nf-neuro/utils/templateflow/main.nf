process UTILS_TEMPLATEFLOW {
    tag "$template"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ 'community.wave.seqera.io/library/pip_templateflow:2f726c524c63271e' }"

    input:
        tuple val(template), val(res) /* Optional Input */, val(cohort) /* Optional Input */

    output:
        path("tpl-${template}")             , emit: folder
        path("*T1w.nii.gz")                 , emit: T1w, optional: true
        path("*T2w.nii.gz")                 , emit: T2w, optional: true
        path("*desc-brain_mask.nii.gz")     , emit: brain_mask, optional: true
        path("*label-CSF_probseg.nii.gz")   , emit: label_CSF, optional: true
        path("*label-GM_probseg.nii.gz")    , emit: label_GM, optional: true
        path("*label-WM_probseg.nii.gz")    , emit: label_WM, optional: true
        path("${template}_metadata.json")   , emit: metadata
        path("${template}_citations.bib")   , emit: citations
        path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    res = res ? "res-*${res}" : ""
    cohort = cohort ? "cohort-${cohort}" : ""

    template 'templateflow.py'

    stub:

    """
    mkdir tpl-${template}
    touch ${template}_metadata.json
    touch ${template}_citations.bib
    touch ${template}_T1w.nii.gz
    touch ${template}_T2w.nii.gz
    touch ${template}_desc-brain_mask.nii.gz
    touch ${template}_label-CSF_probseg.nii.gz
    touch ${template}_label-GM_probseg.nii.gz
    touch ${template}_label-WM_probseg.nii.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        templateflow: \$(python -c 'import os; os.environ["TEMPLATEFLOW_HOME"] = os.path.join(os.getcwd()); import templateflow; print(templateflow.__version__)')
        python: \$(python -c 'import platform; print(platform.python_version())')
    END_VERSIONS
    """
}
