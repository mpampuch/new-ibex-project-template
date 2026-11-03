// modules/local/example_module/example_module.nf
// Template for ONE nf-core local module. Rename folder + process to your tool.
// Ask user for container first; if none, ask to build custom Docker container
// (via Wave CLI, §3 of agent-resources/instructions/nf-core-pipeline-building.md). Pin version.
// Module files must start directly with the process block (never define helper functions above it).
// Avoid embedding multi-line HEREDOCS (e.g. python3 - <<'PY') inside the script block; use bin/ scripts.

process EXAMPLE_MODULE {
    /*
     * CONTAINER REFERENCE:
     * 1. Ask the user to supply a container first (e.g. ghcr.io/owner/tool:tag).
     * 2. If no, ask to build a custom Docker container (prefer Wave CLI).
     * Pin the tag, never `:latest`.
     * Wave package wired in modules.config:
     *   @wave = wave://<org>/<artifact>/<tag>
     *   processes {
     *     EXAMPLE_MODULE { container = '<the ref above>' }
     *   }
     * If an oras:// ref is provided, remember it bypasses NXF_SINGULARITY_CACHEDIR.
     */
    container '<ASK_USER: pinned registry image or Wave ref>'

    publishDir "${params.outdir}/example_module", mode: 'copy'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${prefix}.log"), emit: report
    path        "versions.yml",          emit: versions

    // The one valid `when:` exception: lets a process be skipped via a task
    // property instead of a hard `when:` param dependency.
    when:
    task.ext.when != false

    script:
    def args = task.ext.args ?: ''
    """
    tool --input "${fasta}" --prefix "${prefix}" ${args}
      > "${prefix}.log" 2>&1

    # record tool version for versions.yml
    echo 'tool "1.0.0"' | sort | sed 's/^/--- /' > "versions.yml"
    """

    // `touch` every declared output so `-stub-run` verifies the wiring without
    // running the real tool.
    stub:
    """
    touch "${prefix}.log"
    {
      echo 'tool "1.0.0"'
      echo '---'
    } > "versions.yml"
    """
}
