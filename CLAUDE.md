# Claude Code Project Guidance

@agent-resources/AGENTS.md

Use the shared instructions as the baseline. Read the repository's `PROJECT.md` and the relevant specialized playbook before substantial work:
- nf-core-style Nextflow pipelines (build with TDD, on IBEX or locally): `agent-resources/instructions/nf-core-pipeline-building.md`
- Nextflow (general): `agent-resources/instructions/nextflow.md`
- HPC analysis: `agent-resources/instructions/hpc.md`
- Scientific writing: `agent-resources/instructions/scientific-writing.md`

For complex or risky changes, present a concise plan before editing. Use tools to verify claims and report only checks actually executed. Do not submit expensive Slurm jobs, delete shared data, or overwrite production outputs without explicit approval.

Extended Nextflow pipeline notes that previously lived in this file are in `DOCS/BUILDING-PIPELINES.md`.

This file is a stub. Delete it with `./agent-resources/uninstall.sh` when agent scaffolding is no longer needed.
