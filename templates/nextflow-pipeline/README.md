# Nextflow / nf-core pipeline scaffolds

Reusable templates for building nf-core-style pipelines with TDD, run on **IBEX**
(HPC, `singularity,kaust`) or **locally** (`docker`). Read the companion playbook
first: `instructions/nf-core-pipeline-building.md`.

## What's here

| Path | Use it as | Notes |
|---|---|---|
| `nf-test.config` | `nf-test.config` | nf-test harness; switch `profile` per IBEX vs local. |
| `conf/test.config` | `conf/test.config` | test profile; `input = "${projectDir}/samplesheet.test.csv"`. |
| `tests/lib/DebugUtils.groovy` | `tests/lib/DebugUtils.groovy` | REQUIRED helper; `DebugUtils.printTree(process.out)`, loaded via `libDir`. |
| `launch-job.sbatch` | production runs on IBEX | copy + fill `<PLACEHOLDER>`; ASK the user for site values. |
| `launch-test.sbatch` | full-pipeline tests on IBEX | `sbatch` wrapper for `-profile singularity,test`. |
| `modules/local/example_module/` | one-tool nf-core local module | `main.nf` + `meta.yml` + `.nf.test` + `TESTDATA/`. |
| `subworkflows/local/example_subworkflow/` | subworkflow combining modules | `main.nf` + `.meta.yml` + workflow test. |
| `examples/lineage-chained-module-test.md` | chaining module tests via lineage | EXPERIMENTAL; with the real-path fallback. |

## Rules the templates encode
- **Container provision:** Ask the user to supply a container first. If the user
  says no, ask if they want to build a custom Docker container (prefer Wave CLI
  for `linux/amd64` builds) and pin the version (`§3` of the playbook). The
  module `container:` line is a `<ASK_USER>` placeholder on purpose.
- **TDD:** real + stub `.nf.test` variants, `DebugUtils.printTree` first, semantic
  asserts + `snapshot().match()`, `tags` `fast`/`slow`/`stub` (`§5`).
- **Bioinformatics data is large:** inspect with format-appropriate tools
  (`seqkit`, `samtools`, …; via `module avail <tool>`), build a **minimum viable
  subset** per fixture, and cap + document it (`§5.2`, `§7`).
- **Nextflow `>= 25.10`** (recommend newest stable); `V2` parser enabled on
  `< 26.04` (`§1`).
- **MultiQC at the end of the pipeline**, including custom `*_mqc` summaries
  for checks the core modules do not parse (`§11`).
- **Site-specific values are prompts, never hardcoded** — project scratch, module
  versions, partition/account/QOS, container tags (`§8`).
