process PYDEFACE {

    tag "${meta.subject}_${meta.session}_${nifti.name}"

    container {
        workflow.containerEngine in ['singularity', 'apptainer'] && !(task.ext.singularity_pull_docker_container ?: false)
            ? 'docker://poldracklab/pydeface:latest'
            : 'poldracklab/pydeface:latest'
    }

    containerOptions {
        workflow.containerEngine == 'docker' ? '--entrypoint ""' : ''
    }

    cpus   { (params.pydeface_cpus ?: 4) as Integer }
    memory { params.pydeface_mem ?: '8 GB' }
    time   { params.pydeface_time ?: '2h' }

    input:
    tuple val(meta), path(nifti)

    output:
    tuple val(meta), path("sub-${meta.subject}/ses-${meta.session}/anat/*_defaced.nii.gz"), emit: defaced
    path("logs/*.log"), emit: logs

    script:
    """
    set -euo pipefail

    export OMP_NUM_THREADS="${task.cpus}"
    export OMP_THREADS="${task.cpus}"

    sub="sub-${meta.subject}"
    ses="ses-${meta.session}"

    mkdir -p "\$sub/\$ses/anat" logs

    base="\$(basename "${nifti}" .nii.gz)"
    out_file="\$sub/\$ses/anat/\${base}_defaced.nii.gz"

    log_prefix="sub-${meta.subject}_ses-${meta.session}_\${base}"
    out_log="logs/\${log_prefix}_out.log"
    err_log="logs/\${log_prefix}_err.log"

    {
        echo "=== PYDEFACE ==="
        echo "INPUT:         ${nifti}"
        echo "OUTPUT:        \$out_file"
        echo "CPUS:          ${task.cpus}"
        echo "OMP_THREADS:   \$OMP_THREADS"
        echo "DATE:          \$(date -Is)"
        echo "==============="
        echo
    } | tee -a "\$out_log"

    if [[ "\$base" == *"_defaced" ]]; then
        echo "[SKIP] Input already looks defaced: \$base" | tee -a "\$out_log"
        cp "${nifti}" "\$out_file"
        : >> "\$err_log"
        exit 0
    fi

    if [[ -f /shell-hook.sh ]]; then
        /bin/bash /shell-hook.sh pydeface "${nifti}" --outfile "\$out_file" \\
            1> >(tee -a "\$out_log") \\
            2> >(tee >(grep -i -e "warning" -e "error" >> "\$err_log") >&2)
    elif command -v pydeface >/dev/null 2>&1; then
        pydeface "${nifti}" --outfile "\$out_file" \\
            1> >(tee -a "\$out_log") \\
            2> >(tee >(grep -i -e "warning" -e "error" >> "\$err_log") >&2)
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m pydeface "${nifti}" --outfile "\$out_file" \\
            1> >(tee -a "\$out_log") \\
            2> >(tee >(grep -i -e "warning" -e "error" >> "\$err_log") >&2)
    else
        echo "ERROR: Neither /shell-hook.sh, pydeface nor python3 available in container" >&2
        exit 127
    fi

    : >> "\$err_log"
    """
}
