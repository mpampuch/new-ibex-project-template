# Nextflow DSL2 Pipeline Engineering with TDD

## Required workflow
For new behavior and bug fixes, use this sequence where execution is available:
1. Inspect workflow entry points, modules, configuration, tests, and current conventions.
2. Specify inputs, outputs, invariants, expected errors, and scientific assumptions.
3. Add a focused test that captures the intended behavior.
4. Run it and confirm the expected failure for the intended reason (red phase).
5. Implement the smallest correct change.
6. Re-run the focused test (green phase), then relevant regression tests.
7. Run formatting/linting and broader validation when available.
8. Review the diff and report exact commands/results.

Never invent a red/green result. If dependencies, cluster access, or fixtures are unavailable, mark the phase as not run and explain how to run it.

## Architecture
- Prefer DSL2 and reusable modules, following the repository's conventions.
- Module `main.nf` files must start directly with the `process` block; discourage defining top-level helper functions above process declarations.
- Discourage multi-line HEREDOCS (e.g. `python3 - <<'PY' ... PY`) inside process blocks; move non-trivial logic to scripts in `bin/` or dedicated processes.
- Keep process interfaces explicit and channel transformations understandable.
- Keep sample metadata and file associations explicit; avoid relying on ordering alone.
- Use typed/validated parameters where supported by the project's Nextflow version.
- Separate scientific parameters from execution/resource configuration.
- Make reference files, genome builds, annotation releases, and tool versions explicit.
- Declare outputs deliberately and avoid hidden working-directory assumptions.
- Use profiles for execution environments; do not hard-code site-specific paths in reusable modules.
- Do not introduce abstractions that obscure a simple workflow.

## Testing
Use `nf-test` when suitable and respect the project's pinned version. Add tests at appropriate levels:
- Process/module tests for transformation and tool behavior.
- Workflow/pipeline tests for channel wiring and output contracts.
- Configuration/parameter tests for important supported modes.
- Failure tests for malformed/missing inputs and invalid parameters.
- Regression tests for previously fixed bugs.

Fixtures should be tiny, deterministic, synthetic or appropriately licensed, and must not contain sensitive data. Stub expensive external tools when useful, but retain integration tests for critical interfaces. Validate semantic properties, not only file existence or snapshots.

## Bioinformatics invariants
Where relevant, test:
- Sample ID uniqueness and sample-to-file pairing.
- Paired-end read association and read count assumptions.
- Input format validity and empty-file behavior.
- Reference genome/build, contig naming, annotation version, and coordinate conventions.
- Expected output schema, sample identities, and metadata propagation.
- Filtering thresholds, units, and statistical assumptions.
- Behavior when a process fails, emits no output, or receives an unexpected number of inputs.

Never silently drop samples, reads, variants, or errors. Do not change scientific thresholds to make tests pass without user approval.

## Reporting

End a pipeline that reports results with MultiQC. It summarises outputs the
pipeline already produced; it does not run the analysis. Include custom
summaries for pipeline-specific checks (sample status, in-house metrics) as
`*_mqc` files collected into that one MultiQC step. Follow
`nf-core-pipeline-building.md` §11, and
https://docs.seqera.io/multiqc/custom_content/ for the file format.

## Reproducibility and execution
- Use containers or environment lockfiles where practical and policy-compliant (ask the user for a container first; if none, ask to build a custom Docker container, preferring Wave CLI for linux/amd64 builds).
- Pin or constrain tool versions intentionally; document update policy.
- Make resource requests configurable and align threads with scheduler allocations.
- Test resume/cache behavior when relevant; do not assume caching guarantees correctness.
- Separate test outputs from production outputs.
- Avoid committing `.nextflow/`, `work/`, large results, or private data.
- Do not run production-scale workflows or submit expensive Slurm jobs without explicit approval.

## Definition of done
- Relevant tests exist and are run where possible.
- Focused and regression results are reported honestly.
- Lint/format checks are reported if available.
- Scientific assumptions and reference versions are documented.
- The command and configuration needed to reproduce validation are included.
