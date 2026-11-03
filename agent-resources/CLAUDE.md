# Claude Code Project Guidance

Paths below are relative to this directory (`agent-resources/`), except `../PROJECT.md` and `../DOCS/BUILDING-PIPELINES.md`.

@AGENTS.md

Use the shared instructions as the baseline. Read the repository's `../PROJECT.md` and the relevant specialized playbook before substantial work:
- nf-core-style Nextflow pipelines (build with TDD, on IBEX or locally): `instructions/nf-core-pipeline-building.md`
- Nextflow (general): `instructions/nextflow.md`
- HPC analysis: `instructions/hpc.md`
- Scientific writing: `instructions/scientific-writing.md`

For complex or risky changes, present a concise plan before editing. Use tools to verify claims and report only checks actually executed. Do not submit expensive Slurm jobs, delete shared data, or overwrite production outputs without explicit approval.

Extended Nextflow pipeline notes that previously lived in this file are in `../DOCS/BUILDING-PIPELINES.md`.
