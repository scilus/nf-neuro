process PYDEFACE {

    tag "${meta.id}_${nifti.name}"

    container "community.wave.seqera.io/library/procps-ng_pydeface_fsl-flirt:223b251c6cae5c95"

    containerOptions {
        workflow.containerEngine == 'docker' ? '--entrypoint ""' : ''
    }

    label "process_medium"



    input:
    tuple val(meta), path(nifti)

    output:
    tuple val(meta), path("*_defaced.nii.gz"), emit: defaced
    path("logs/*.log"), emit: logs
    path "versions.yml", emit: versions, topic: "versions"

    script:
    """
    set -euo pipefail

    export OMP_NUM_THREADS="${task.cpus}"
    export OMP_THREADS="${task.cpus}"

    export FSLDIR="\${FSLDIR:-/opt/conda}"
    export PATH="\${FSLDIR}/share/fsl/bin:\${FSLDIR}/bin:\${PATH}"

    mkdir -p logs

    base="\$(basename "${nifti}" .nii.gz)"
    out_file="\${base}_defaced.nii.gz"

    log_prefix="${meta.id}_\${base}"
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

    PYDEFACE_VERSION="\$(pydeface --version 2>&1 | grep -oE '[0-9]+[.][0-9]+([.][0-9]+)?' | head -n 1 || true)"
    [ -z "\$PYDEFACE_VERSION" ] && PYDEFACE_VERSION="unknown"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pydeface: "\$PYDEFACE_VERSION"
    END_VERSIONS
    """
}
