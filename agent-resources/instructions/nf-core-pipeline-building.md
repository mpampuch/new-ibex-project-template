# Building nf-core-style Nextflow Pipelines (with TDD, on IBEX or locally)

This is the specialized playbook for designing, building, and testing
nf-core-style Nextflow pipelines. Read it before any pipeline work.

It sits **under** the shared scientific-integrity baseline in `../AGENTS.md` —
preserve it: preserve raw data, validate sample identity and reference versions,
never invent test results or citations, and report only checks actually executed.
This document adds the Nextflow/nf-core/IBEX specifics; it does not weaken those
rules.

Also read, as relevant: `hpc.md` (Slurm) and
`../templates/nextflow-pipeline/` (the reusable scaffolds this playbook references).

## 0. Environment: ask, then auto-suggest (do this first)

Before running anything, establish the execution environment. **Ask the user**
which they are on — **IBEX** (the HPC) or **local** — then propose a default by
detecting, and confirm before acting:

| Signal | IBEX (HPC) | Local |
|---|---|---|
| Modules | `module load nextflow`, `module load singularity`, `module load tower-cli` available | `docker` on `PATH`, no IBEX modules |
| Profile (runs) | `-profile singularity,kaust` | `-profile docker` |
| Profile (tests) | `-profile singularity,test` | `-profile docker,test` |
| Executor | `singularity` via Apptainer 1.4.5 (`mamba activate apptainer`; §3) | `docker` |
| Launch mechanism | `sbatch launch-job.sbatch` / `sbatch launch-test.sbatch` | `nextflow run ...` directly |

- **The `kaust` institutional profile points Singularity/Apptainer at IBEX
  modules and scratch.** It is IBEX-only; do not use it locally.
- **Container engine on IBEX:** `module load singularity` is SingularityCE
  3.9.7. Launch scripts must then `mamba activate apptainer` so `singularity`
  on `PATH` is Apptainer 1.4.5. SingularityCE 3.9.7 cannot pull Wave ORAS SIF
  images (§3).
- If the signals are ambiguous, **do not guess** — ask.
- Confirm the environment with the user *before* any submission or run.

### 0.1 Environment variables (`NXF_*`)
Nextflow is configured by environment variables ([ref](https://docs.seqera.io/nextflow/reference/env-vars)).
On IBEX set, per job, the runtime and cache locations to shared scratch, e.g.:

```bash
export NXF_OPTS='-Xms3G -Xmx5G'                       # JVM heap for the driver
export NXF_SINGULARITY_CACHEDIR=<SCRATCH>/NXF_SINGULARITY_CACHEDIR
export NXF_APPTAINER_CACHEDIR=<SCRATCH>/NXF_APPTAINER_CACHEDIR
export NXF_WORK=<SCRATCH>/work
```

- **Never hardcode the site paths.** `<SCRATCH>` (project id like `c2303`,
  `/ibex/scratch/projects/...`), the exact module versions, and the partition /
  account / QOS are **things you ask the user for**, then record them in the run
  config / `launch-*.sbatch`. Do not leave `c2303` or any absolute IBEX path in
  source, templates, logs, or git.
- `NXF_AGENT_MODE=true` (Nextflow 26.04+) prints tagged `[PIPELINE]/[PROCESS]/
  [ERROR]/[FAILED]` output an agent can parse instead of the long ANSI log; it
  also switches on automatically when `AGENT` or `CLAUDECODE` is set. Use it on
  long runs.
- `NXF_FILE_ROOT`, `NXF_CLOUDCACHE_PATH`, proxy vars (`HTTPS_PROXY`, `NO_PROXY`,
  …) matter on HPC; ask the user how their site handles them.

## 1. Nextflow version

- **Hard floor: Nextflow `>= 25.10`.** Declare `manifest.nextflowVersion =
  ">=25.10"` (or the pipeline's supported range) and never write config/scripts
  that require below it.
- **Recommend the newest stable** the site offers. Stable versions land the 4th
  and 10th month (e.g. 25.10, 26.04); recommend that one and **confirm the exact
  module with the user** (`module avail nextflow`) — do not hardcode `25.04.2`
  or any guessed tag.
- **Syntax parser:** the V2 *strict* parser is the default from 26.04. If the
  resolved version is `>= 25.10` and `< 26.04`, enable it explicitly
  (`NXF_SYNTAX_PARSER='v2'`) so typed inputs/outputs and newer nf-core modules
  behave as on 26.04+. (Feature flags: https://docs.seqera.io/nextflow/reference/feature-flags )
- `lineage`/`fromLineage` are available at 25.10+ but are **experimental**
  ("may change", since 25.04). Handle that in §5.

## 2. Authoritative references (consult, don't invent)

- Nextflow: https://docs.seqera.io/nextflow/
  - Environment variables: https://docs.seqera.io/nextflow/reference/env-vars
  - Modules: https://docs.seqera.io/nextflow/modules/
  - Reports / debugging: https://docs.seqera.io/nextflow/reports
  - `nextflow log`: https://docs.seqera.io/nextflow/reference/cli/log
  - Data lineage: https://docs.seqera.io/nextflow/tutorials/data-lineage
- nf-core:
  - Developing: https://nf-co.re/docs/developing/
  - nf-core tools: https://nf-co.re/docs/nf-core-tools
  - Guidelines: https://nf-co.re/docs/guidelines/
- nf-test: https://www.nf-test.com/docs/getting-started/
- nf-schema: https://nextflow-io.github.io/nf-schema/latest/
- MultiQC: https://docs.seqera.io/multiqc
  - Custom content (pipeline-specific summaries): https://docs.seqera.io/multiqc/custom_content/
  - Report text (title, intro, comment): https://docs.seqera.io/multiqc/reports/customisation
  - Pipeline integration: https://docs.seqera.io/multiqc/usage/pipelines
  - AI summaries: https://docs.seqera.io/multiqc/ai/
- Wave CLI: https://docs.seqera.io/wave/cli/
  - Use cases (Docker file vs image-to-Singularity): https://docs.seqera.io/wave/cli/use-cases

When unsure about a feature, look it up here. **Do not fabricate** command
output, test results, or version strings.

### 2.1 Gold-standard pipeline shape (when local style is silent)

If you are unsure how a good nf-core-style pipeline, module, subworkflow,
config, or test layout is supposed to look, read these two workflows and use
them as the reference. Do not invent structure.

- [nf-core/rnaseq](https://github.com/nf-core/rnaseq)
- [nf-core/mag](https://github.com/nf-core/mag)

**Precedence** (highest first):

1. Explicit instruction in the current task.
2. This playbook and conventions already in the repository you are editing.
   Keep these custom conventions; do not rewrite them to match upstream nf-core:
   - `DebugUtils.printTree(process.out)` at the top of every nf-test `then`,
     loaded via `libDir "tests/lib"` (§4.2, §5.1).
   - Dated folders: project names like `YYYYMMDD_NEXTFLOW-...`, and timestamped
     run directories `OUTPUTS/<timestamp>` and `TESTS/TEST_OUTPUTS/<timestamp>`
     (§5, §8).
3. [nf-core/rnaseq](https://github.com/nf-core/rnaseq) and
   [nf-core/mag](https://github.com/nf-core/mag), only to fill a gap the sources
   above do not cover (layout, modules, subworkflows, `conf/` profiles, schema,
   CI). MultiQC summaries are specified in §11.

When a gold-standard repo disagrees with a custom convention, keep the custom
convention and say which reference was set aside. This does not override the
scientific-integrity or safety rules in `../AGENTS.md`.

## 3. Containers: ask first, then build if needed (Wave CLI)

When a module needs a bioinformatics tool:
1. **Ask the user to supply a container first.**
2. **If the user says no, ask if they would like to build a custom Docker container.**
3. **If you are building custom containers, follow this section and [Wave CLI](https://docs.seqera.io/wave/cli/).**
   - Wave is especially good for Docker `linux/amd64` builds. A local dev machine is often `arm64` (macOS Apple Silicon); Wave runs the `linux/amd64` build remotely, without local emulation.
   - On IBEX, `wave` comes from `module load tower-cli`. There is no separate Wave module. `tower-cli` is optional for a plain Nextflow run (it pairs with `TOWER_*` for Seqera Platform). It is required to build images.
   - Source Seqera credentials from `${HOME}/.secrets/seqera-platform.sh`. Do not commit that file, and do not print the token.

### 3.1 Build a Docker image

`wave -f` reads a Dockerfile. `--freeze` publishes an immutable tag. Example (linux/amd64, 2026-11-03):

```bash
#!/usr/bin/env bash
# Frozen image from this Dockerfile:
# mpampuch/smudgeplot_v0.5.4_linux-amd64:bb0188a7f15fe8e9
# Build ID bd-bb0188a7f15fe8e9_1, linux/amd64, 2026-10-29.
set -euo pipefail
cd "$(dirname "$0")"
set -a
source "${HOME}/.secrets/seqera-platform.sh"
set +a
wave -f Dockerfile \
  --platform linux/amd64 \
  --freeze \
  --build-repo mpampuch/smudgeplot_v0.5.4_linux-amd64_20261103-test \
  --await 90m \
  --log-level DEBUG
```

A successful build ends with the frozen image name, for example:

```text
mpampuch/smudgeplot_v0.5.4_linux-amd64_20261103-test:7205eba8ecbe26c7
```

The DEBUG log also reports `buildId` (here `bd-7205eba8ecbe26c7_1`) when `status` is `DONE` and `succeeded` is true. Pull or run the image with:

```bash
docker run mpampuch/smudgeplot_v0.5.4_linux-amd64_20261103-test:7205eba8ecbe26c7
```

Record that tag. Never commit a floating `:latest`.

### 3.2 Build a Singularity image from the Docker image

Build the SIF from the frozen Docker image. Do not pass the Dockerfile to `wave -f` for this step. Wave parses `-f` as a Singularity definition, so a Dockerfile is rejected (`invalid header keyword: from`). See [Wave CLI use cases](https://docs.seqera.io/wave/cli/use-cases).

```bash
#!/usr/bin/env bash
# Singularity freeze of the Docker image. Wave parses -f as a Singularity
# definition, so the Dockerfile is rejected (invalid header keyword: from).
# https://docs.seqera.io/wave/cli/use-cases
# oras://docker.io/mpampuch/smudgeplot_v0.5.4_linux-amd64-sif:9674543663c3d774
# Build ID bd-9674543663c3d774_1, linux/amd64, 2026-10-29.
set -euo pipefail
cd "$(dirname "$0")"
set -a
source "${HOME}/.secrets/seqera-platform.sh"
set +a
wave -i mpampuch/smudgeplot_v0.5.4_linux-amd64_20261103-test:7205eba8ecbe26c7 \
  --singularity \
  --platform linux/amd64 \
  --freeze \
  --build-repo mpampuch/smudgeplot_v0.5.4_linux-amd64-sif_20261103-test \
  --await 90m \
  --log-level DEBUG
```

Success prints an ORAS reference without a registry host, for example:

```text
oras://mpampuch/smudgeplot_v0.5.4_linux-amd64-sif_20261103-test:87e5e441b79958ba
```

Prefix `docker.io` before use:

```text
oras://docker.io/mpampuch/smudgeplot_v0.5.4_linux-amd64-sif_20261103-test:87e5e441b79958ba
```

### 3.3 Pulling Wave ORAS images on IBEX

`module load singularity` (SingularityCE can also be loaded with `module load tower-cli`) provides **SingularityCE 3.9.7**. That client cannot pull these Wave SIFs. Observed 2026-11-03:

```text
$ singularity --version
singularity-ce version 3.9.7
$ singularity shell oras://docker.io/mpampuch/smudgeplot_v0.5.4_linux-amd64-sif_20261103-test:87e5e441b79958ba
FATAL:   Unable to handle oras://docker.io/mpampuch/smudgeplot_v0.5.4_linux-amd64-sif_20261103-test:87e5e441b79958ba uri: failed to get checksum for oras://docker.io/mpampuch/smudgeplot_v0.5.4_linux-amd64-sif_20261103-test:87e5e441b79958ba: could not get image manifest, received mediaType: application/vnd.docker.distribution.manifest.v2+json
```

Wave publishes the SIF to Docker Hub as an ORAS artifact, not as a conventional Docker image. Docker Hub returns the Docker schema 2 manifest media type `application/vnd.docker.distribution.manifest.v2+json`. An OCI artifact manifest is generally `application/vnd.oci.image.manifest.v1+json`. SingularityCE 3.9.7 rejects the Docker media type on the `oras://` path.

Apptainer 1.4.5 accepts the same reference. It chooses the image format from the transport: `docker://` is a container image, `oras://` is an artifact such as a SIF (Apptainer issue #2178). Observed 2026-11-03, after `mamba activate apptainer`:

```text
$ apptainer shell oras://docker.io/mpampuch/smudgeplot_v0.5.4_linux-amd64-sif_20261103-test:87e5e441b79958ba
INFO:    Downloading oras image
...
Singularity> smudgeplot
usage:
            smudgeplot <task> [options]
...
```

Load it on IBEX with:

```bash
eval "$(mamba shell hook --shell bash)"
mamba activate apptainer
```

That environment replaces `singularity` on `PATH`. Afterwards `singularity --version` reports `apptainer version 1.4.5`, and `singularity shell oras://docker.io/<repo>:<tag>` downloads the SIF. Because `-profile singularity` invokes whichever `singularity` is on `PATH`, every IBEX launcher must run those two lines after the module loads: `launch-job.sbatch`, `launch-test.sbatch`, and the `pre-run.sh` that `launch-seqera-platform.sh` hands to Tower. The outer Slurm script's environment does not carry into the Tower compute job; `pre-run.sh` does.

### 3.4 References in the pipeline

- Expected forms of container references:
  - **Registry image** — `container 'ghcr.io/owner/tool:tag'` (or Docker Hub / Quay image) in the module's `main.nf` (and/or `meta.yml`).
  - **Wave package** — a `wave://…` / `@wave` reference wired in `modules.config` (e.g. `processes { FOO { container = ... } }` plus the Wave `@wave` line).
  - **Wave ORAS SIF** — `oras://docker.io/<owner>/<repo>:<freeze-tag>`. An `oras://` reference bypasses `NXF_SINGULARITY_CACHEDIR` caching; tell the user when one is used.
- **Pin the version/tag.** Record the frozen digest or tag; never use a floating `:latest` in source.
- Keep a small **"software → container"** manifest (a note or `modules.config` block) so a run is reproducible and the user can audit which images were used.
- Do **not** install or build tooling directly on host environments to satisfy a module. If a needed binary is absent, ask the user or containerize via Wave.

## 4. Build order (TDD)

Follow the project's existing conventions (e.g. the IBEX new-project template's
`BUILDING-PIPELINES.md`). The sequence, refined:

1. **Scaffold** the project (`newproj` / `nf-core create`) and run its **smoke
   test**; if it did not run, run it yourself to confirm the boiler plate
   works.
2. **Commit** the clean scaffold.
3. **Get small test data** and place it under `TESTS/TEST_DATA`
   (`nf-core test-datasets` can help find/construct it).
4. **Populate `samplesheet.test.csv`** with the test data.
5. **Update `assets/schema_input.json`** (`nf-core pipelines schema build`
   regenerates `nextflow_schema.json` from it).
6. **Update the test profile `conf/test.config`**, e.g.
   `input = "${projectDir}/samplesheet.test.csv"`.
7. **Parse the samplesheet** — usually handled by the
   `subworkflows/local/utils_nfcore_pipeline_pipeline` subworkflow; edit it to
   match your sample columns. Verify by adding `ch_samplesheet.view()`
   (or a `log.info(...)` mapping) to `workflows/main.nf` and inspecting the
   emitted channel — confirm metadata/read associations look right before
   wiring.
8. **Commit input handling** (e.g. "update parsing samplesheet", then
   "parse samplesheet correctly").
9. **Set up nf-test** — point `nf-test.config` `profile` at your executor
   (`singularity,test` on IBEX, `docker,test` locally).
10. **Add modules with TDD** (the red→green→refactor loop, §4.1):
    - First check `nf-core modules list remote` for an existing nf-core module;
      `nf-core modules install <module>` if it exists.
    - Otherwise `nf-core modules create <module>`, then
      `nf-core subworkflows create` to combine modules.
    - Wire the module into the workflow and add its test **before** trusting it.
11. **Commit per module** once its tests are green.

### 4.1 TDD discipline
For every new feature or fix:
1. Inspect entry points, modules, config, tests, and current conventions.
2. Specify inputs, outputs, invariants, expected errors, scientific assumptions.
3. Write the focused test (red) and **run it**; confirm it fails *for the
   intended reason*.
4. Write the smallest correct implementation.
5. Run the test green, then run regression tests.
6. Run lint/format and broader validation.
7. Review the diff; report exact commands and results.

**Never fake a red/green result.** If cluster access, containers, or fixtures
are unavailable, mark the phase *not run* and give the command to run it.
Do not weaken a test to make an implementation pass.

### 4.2 nf-test configuration (`nf-test.config`)

```groovy
config {
    testsDir "."
    workDir System.getenv("NFT_WORKDIR") ?: ".nf-test"
    configFile "tests/nextflow.config"
    // By default, tests of pulled-in nf-core modules are ignored.
    ignore 'modules/nf-core/**/tests/*', 'subworkflows/nf-core/**/tests/*'
    // Remove (or narrow) this to actually verify a pulled-in module on this site.
    libDir "tests/lib"                 // loads DebugUtils.groovy
    profile "test,singularity"         // IBEX: "test,singularity"; local: "test,docker"
    triggers 'nextflow.config', 'nf-test.config', 'conf/test.config', 'tests/nextflow.config', 'tests/.nftignore'
    plugins { load "nft-utils@0.0.3" }
}
```

- `nf-test init` generates the `ignore` lines: pulled-in module/subworkflow tests
  are skipped, and you can rely on them as working. To test a specific pulled
  module on this site, narrow/remove the `ignore` for that module (verify with
  `nf-test list`).
- Keep `tests/lib/DebugUtils.groovy` present (see §6); load it via `libDir`.

## 5. Module tests: TDD + nf-test + lineage-chained fixtures + subsetting

Use `nf-test` ([ref](https://www.nf-test.com/docs/getting-started/)). Model the
tests on the
[`20260309_NEXTFLOW-ALGAE-TAXA-FROM-GENOME`](https://github.com/mpampuch-bioinformatics-pipelines/20260309_NEXTFLOW-ALGAE-TAXA-FROM-GENOME)
repo, especially its `modules/local/*.nf.test` files.

### 5.1 Per-module test shape
Each module gets a test with a **real** variant and a **stub** variant:

```groovy
nextflow_process {
    name "Test Process COMBINE_GFF"
    script "modules/local/combine_gff/combine_gff.nf"
    process "COMBINE_GFF"

    test("... real ...") {
        tag "fast"
        options "-dump-hashes"
        when {
            process { """
                input[0] = [
                    [ id: 'KAUST067_purged' ],
                    [ file("${projectDir}/.../IN1.gff"), file("$.../IN2.gff") ]
                ]
            """ }
        }
        then {
            DebugUtils.printTree(process.out)          // ALWAYS first
            assert process.success
            // semantic asserts: counts, names, versions.yml tags, content
            assert process.out.gff.size() == 1
            def (meta, gffPath) = process.out.gff[0]
            assert meta.id == 'KAUST067_purged'
            ...
            assert snapshot(process.out).match()
        }
    }

    test("stub | ...") {
        tag "stub"
        tag "fast"
        options "-stub-run -dump-hashes"
        when { process { """ input[0] = [ ... ] """ } }
        then {
            DebugUtils.printTree(process.out)
            assert process.success
            // stub uses `touch`: empty-but-named outputs
            assert file(process.out.its1[0][1]).size() == 0
            assert snapshot(process.out).match()
        }
    }
}
```

Conventions:
- Call `DebugUtils.printTree(process.out)` at the top of every `then` — it
  pretty-prints the output tuple so mismatches are visible.
- **Test behavior, not just existence:** assert counts, file names
  (`${prefix}.ext`), versions.yml tags, and (where meaningful) content/headers.
  Use `snapshot(process.out).match()` for the output contract; keep snapshots
  under version control.
- Tag tests deliberately so a subset can be selected without reading every
  file: `fast` (run often; small), `slow` (real big data), `stub`
  (`-stub-run`), `pipeline` (end-to-end), plus module- or process-specific
  tags when a change should be isolatable. On a large project the full suite
  is slow. While iterating, do not run every nf-test by default — run only
  what the change needs, for example `nf-test test <file> --tags fast` or
  `nf-test test modules/local/<module> --tags <tag>`. Save a full
  `nf-test test` for when the pipeline is ready for a full test (readiness or
  pre-merge), not for day-to-day module work.
- Include **failure / edge tests**: malformed or missing inputs, empty inputs,
  unexpected input cardinality.
- Preserve sample identity: assertions must confirm `meta.id` propagation and
  sample-to-file pairing; never silently drop a sample.
- Run: `nf-test test tests/....nf.test --verbose` (and with the right `--tags`).

### 5.2 Subsetting for tests (bioinformatics data is large)
Module tests must run in seconds, so each fixture is a **small subset**.

> **Before you touch any real data file (a run input or a fixture), inspect its
> *structure*, not just its byte size.** (Full text in §7.)
>
> For every module/test being written, determine or estimate its **minimum
> viable test file**: the smallest input that still genuinely exercises the
> tool — enough reads / contigs / features / records to produce a
> representative output and reach the logic branches you care about.
>
> Cap by reads (`seqkit sample`), contigs (first N / a chromosome subset),
> or records (`head`), and **document the cap + rationale** in the module's
> `TESTDATA/` README. Never silently drop — if you cap, record it.
>
> If the tool needed to inspect the data is not available, find it with
> `module avail <tool>`; **if still not available, ask the user how to access
> it** — do not install or build.

### 5.3 Chaining module tests via lineage
Each module's test should consume the **output of the upstream program**, so the
test chain mirrors the real data flow (module *N* → module *N+1*). Use
Nextflow's experimental **data lineage** ([ref](https://docs.seqera.io/nextflow/tutorials/data-lineage))
to locate and reuse the real file, rather than hand-copying an artifact:

1. Enable tracking: add `lineage.enabled = true` to your config
   (store at `.lineage`, or a shared path via `lineage.store.location`).
2. **Discover** the upstream output's reference:
   ```bash
   nextflow lineage list                       # pick the WorkflowRun LID
   nextflow lineage find type=TaskRun workflowRun=lid://<run>   # list task LIDs
   nextflow lineage view  lid://<task>          # read spec.path / spec.source
   ```
3. **Feed it downstream** as the next module's test input, either by `lid://`
   path (a lineage id is a valid URI in a script) or the `fromLineage` channel
   factory:
   ```groovy
   Channel.fromPath('lid://<task>/' + 'OUTPUT_NAME.ext')    // real path of the file
   // or
   Channel.fromLineage(type: "TaskRun", workflowRun: "lid://<run>")
   ```
4. Check for unexpected re-execution / cache invalidation with
   `nextflow lineage diff lidA lidB`; eyeball the wiring with
   `nextflow lineage render lid://<run>...ext` (HTML).

Caveats (do not hide these from the user):
- Experimental (25.04+, "may change"). A `lid://` test input requires a
  **reproducible, runner-visible lineage store** — on IBEX the store /
  `NXF_WORK` must be consistent across submissions (shared scratch).
- If the store is not reproducible for the runner, **fall back to a pinned,
  subsetted real path** under the module's `TESTDATA/` and record the
  rationale. (Note: the algae repo itself currently uses real paths, not
  `lid://`, for its module inputs — treat that as the pragmatic fallback.)

### 5.4 Module standards (nf-core)
- **Module files start with `process`:** A module `main.nf` must start directly
  with the `process` block (preceded only by module header comments). **Do not
  define helper functions above process blocks** (e.g. Groovy `def mqcArg(...) { ... }`
  preceding `process FOO { ... }`). Top-level helper functions in module `main.nf`
  files violate nf-core module conventions and linting; handle argument formatting,
  flag assembly, or collection flattening inline inside the `script:` / `stub:`
  block or upstream in channel operators.
- **Discourage HEREDOCS inside process blocks:** Avoid embedding multi-line
  inline scripts via heredocs (e.g. `python3 - <<'PY' ... PY`, `Rscript - <<'RSCRIPT'`,
  or large inline shell heredocs) within process `script:` / `stub:` blocks.
  Inline heredocs break process atomicity, conceal script logic from linters
  and syntax checkers, and obfuscate error tracebacks. Instead:
  - Put non-trivial pre/post-processing or data-reorganizing scripts into `bin/`
    (or package them directly in the container),
  - Split the preparation/reorganization step into its own atomic module/process, or
    handle data manipulations via workflow channel operators.
  *(The single conventional exception is the minimal software version capture
  block `cat <<-END_VERSIONS > versions.yml`.)*
- **One tool per module** (atomic). Name complex tools `tool/subtool`.
- `meta.yml` documents the module; report `versions.yml` for every tool used.
- Inputs/outputs as `tuple val(meta), path(files)`; name outputs with `emit:`
  and mark optional ones `optional: true`; name output files with `${prefix}`.
- Put optional args behind `$task.ext.args`; resource via process labels
  (`process_low`/`process_medium`/…) and `${task.cpus}` for multithreading.
- **`when:` sections:** avoid; implement conditional flow in the workflow. The
  one valid exception is `task.ext.when == null || task.ext.when` (used to gate
  a process without a hard dependency on a boolean param).
- Add a `stub:` block that `touch`es the output files so `-stub-run` works.

### 5.5 Full-pipeline test (`tests/default.nf.test`)
A pipeline-level test verifies the wired workflow end-to-end on the test sample
sheet. Model on the algae repo's `tests/default.nf.test`:

```groovy
nextflow_pipeline {
    name "Test pipeline"
    script "../main.nf"
    tag "pipeline"

    test("-profile test") {
        when { params { outdir = "$outputDir" } }
        then {
            def stable_name = getAllFilesFromDir(params.outdir, relative: true, includeDir: true, ignore: ['pipeline_info/*.{html,json,txt}'])
            def stable_path = getAllFilesFromDir(params.outdir, ignoreFile: 'tests/.nftignore')
            assertAll(
                { assert workflow.success },
                { assert snapshot(
                        workflow.trace.succeeded().size(),
                        removeNextflowVersion("$outputDir/pipeline_info/pipeline_software_mqc_versions.yml"),
                        stable_name,
                        stable_path
                    ).match() }
            )
        }
    }
}
```

- Strip the Nextflow version from `versions.yml` (`removeNextflowVersion`) so the
  pipeline can be tested across Nextflow releases.
- List volatile files in `tests/.nftignore`.
- Launch full-pipeline tests through **`sbatch launch-test.sbatch`** on IBEX
  (`-profile singularity,test`) — see §8.

## 6. Debugging & troubleshooting ladder

**Nextflow logs are routinely huge** — never `cat`/read the whole
`.nextflow.log` into context. Instead escalate through structured queries:

1. **Structured query first (not the raw log):**
   ```bash
   nextflow log                    # list previous runs (name / session)
   nextflow log <run|session> -f name,hash,exit,status
   nextflow log <run> -F 'process =~ /FOO/ && status == "COMPLETED"'   # one process
   nextflow log <run> -t my-template.md > report.md                     # templated
   ```
   The per-run output points to each task's **work folder** `work/xx/yyyy…`.
2. **Read that work folder, not the run log:** `.command.run`/`.command.sh`
   (what ran), `.command.err`/`.err` + `.out` (the error/output — `rg`/`grep`
   these, do not dump large files), and the produced output files.
3. **Find provenance / a reusable file:** `nextflow lineage` (§5.3). If a data
   file for troubleshooting or testing cannot be located, use
   `nextflow log` / `nextflow lineage` to resolve its path or `lid://` and reuse
   it.
4. **Run inspection without executing:** `nextflow retrace`, `nextflow logfile`,
   `nextflow config` (dump the *resolved* config), `nextflow inspect`,
   `nextflow list`.
5. **Resource / DAG analysis:** `-with-report` (HTML: Summary / Resources /
   Tasks), `-with-trace trace.txt` (needs `awk date grep ps sed tail tee` in
   the image), `-with-timeline`, `-preview -with-dag` (Mermaid, no execution).
6. **Agent-mode logs** on long runs: `NXF_AGENT_MODE=true` (Nextflow 26.04+;
   auto when `AGENT`/`CLAUDECODE` set) gives tagged `[PROCESS]/[ERROR]/[FAILED]`
   lines that parse cleanly without raw-log bloat. (`nextflow report`,
   `-with-report`, and `nextflow lineage render` produce human-readable HTML
   reports when a human needs them.)

When you inspect data, prefer **bioinformatics-appropriate** inspection tools
over `ls -l` (see §7). Distinguish **scheduler / infra** failure from **node /
software / data** failure before retrying a job (see `hpc.md`).
Never treat partial files from an interrupted job as complete.

## 7. Data inspection & minimum-viable test sizing

See also §5.2. In short, *always* know the structure and cost of the data you
touch:

- **Structure, not just bytes.** `ls -l` on a `.fastq`/`.fasta`/`.bam`/`.gff`
  is not enough. Use format-appropriate tools that report both size and
  structure, e.g.:
  - sequences/reads: `seqkit stats`, `seqkit count`, read counts
  - alignments: `samtools stats`, `samtools idxstats`
  - features: feature counts for GFF/BED; record counts for TSV
- **Find tools with `module avail <tool>`** on IBEX (runner/engine/Tower come
  from `module load nextflow singularity tower-cli`); **if the tool you need is
  not available, ask the user how to access it** — don't install or build.
- **Estimate the minimum viable test file** for every tool you test: the
  smallest input that still exercises the tool meaningfully. Document the cap and
  the command that justified it, so the test is reproducible.
- **If you cannot inspect the data**, say so and give the inspection command.

## 8. Launching on IBEX (sbatch templates)

Use the templates in `../templates/nextflow-pipeline/`. Both launchers:
- `module load nextflow` (confirm `>= 25.10`; recommend newest stable),
  `module load singularity`, `module load tower-cli` (`tower-cli` provides
  `wave`; §3);
- then activate Apptainer so `singularity` is 1.4.5 (§3.3). `module load
  singularity` alone is SingularityCE 3.9.7 and cannot pull Wave ORAS SIFs.
  The job-launcher snippet below includes the `mamba` lines;
- set `NXF_OPTS`, the `*_CACHEDIR` and `NXF_WORK` vars to IBEX scratch (ask for
  the project path);
- copy the input, the config, and the launch script into a **timestamped output
  directory** and write `projectDir.txt`, so a run can be reconstructed
  afterward.

**`launch-job.sbatch`** — one or a batch of production runs:
```bash
#SBATCH --partition=batch          # ASK the user for the right partition/QOS
#SBATCH --time=48:00:00            # ask; size to evidence
#SBATCH --cpus-per-task=1 --ntasks=1 --mem=5G    # match the job
...
module load nextflow             # ASK for exact version (>= 25.10)
module load singularity          # SingularityCE 3.9.7; replaced on PATH below
module load tower-cli            # provides wave (§3); optional for a plain run
# Apptainer 1.4.5 replaces SingularityCE on PATH so Wave ORAS SIFs pull (§3.3).
eval "$(mamba shell hook --shell bash)"
mamba activate apptainer
export NXF_OPTS='-Xms3G -Xmx5G'
export NXF_SINGULARITY_CACHEDIR=<SCRATCH>/NXF_SINGULARITY_CACHEDIR   # ASK
export NXF_WORK=<SCRATCH>/work                                         # ASK
NXF_OUTPUT_DIR="OUTPUTS/$(date -Iseconds | sed 's/-//g; s/://g; s/T/_/; s/+.*//')"
NXF_LOG_FILE="$NXF_OUTPUT_DIR/nextflow.log"
mkdir -p "$NXF_OUTPUT_DIR"
cp "$INPUT_FILE" "$CONFIG_FILE" "$0" "$NXF_OUTPUT_DIR/"
echo "$(pwd)" > "$NXF_OUTPUT_DIR/projectDir.txt"
nextflow -log "$NXF_LOG_FILE" run . -c "$CONFIG_FILE" -with-report \
    -profile singularity,kaust --input "$INPUT_FILE" --outdir "$NXF_OUTPUT_DIR"
```

**`launch-test.sbatch`** — full-pipeline tests:
```bash
#SBATCH --job-name=TEST-PIPELINE
# (same module load, Apptainer activation, and NXF_* as the job launcher; smaller --time, e.g. 00:30:00)
NXF_OUTPUT_DIR="TESTS/TEST_OUTPUTS/$(date -Iseconds | sed 's/-//g; s/://g; s/T/_/; s/+.*//')"
...
nextflow -log "$NXF_LOG_FILE" run . -c "$CONFIG_FILE" -with-report \
    -profile singularity,test --outdir "$NXF_OUTPUT_DIR"
```

Note how outputs are collected: everything (input, config, the script itself,
`nextflow.log`) is copied into the run's own timestamped directory, and
`projectDir.txt` records the launch directory. **Locally**, run with
`-profile docker` (or `docker,test`) and the equivalent `nextflow run` command —
no sbatch.

**Submission safety** (see `hpc.md`): do not submit production jobs
or large arrays without explicit user approval; before submitting an approved job,
summarize command, job count, partition/account/QOS, CPUs, memory, wall time, and
output paths. Align `--cpus-per-task` with tool-level threads; avoid nested
parallelism (OMP/BLAS/wave). Never put credentials in scripts or logs.

## 9. Reproducibility & hygiene

- Pin / constrain tool **and** container versions; record the "software →
  container" manifest (§3).
- Commit `tests/` fixtures and snapshots (`.snap`) and `nf-test.config`; add
  `tests/.nftignore` for volatile outputs.
- **Do not commit** `work/`, `.nextflow/`, `.nf-test/`, `results/`,
  `SLURM_LOGS/`, `.lineage/`, large real datasets, or secrets. Keep
  `NXF_WORK`/scratch outputs out of git.
- Test resume/cache when relevant, but do not assume caching ⇒ correctness
  (use `nextflow lineage diff` to check for unexpected re-execution).
- Separate test outputs from production outputs (`TESTS/TEST_OUTPUTS` vs `OUTPUTS`).

## 10. Definition of done (report per `../AGENTS.md`)
- Relevant module + pipeline tests exist and are **run** where possible
  (`nf-test test … --tags fast`, `sbatch launch-test.sbatch`).
- Focused and regression results reported honestly (red→green; "did not run"
  where blocked).
- Lint/format reported if available.
- Version, container, and reference versions documented; subsetting caps and
  lineage refs recorded.
- The exact commands + config needed to reproduce the validation are given.
- No `c2303` / absolute IBEX paths / credentials leaked into source, templates,
  logs, or git.
- When the pipeline reports results, the MultiQC HTML includes the standard
  summaries and any pipeline-specific custom sections (§11), and a test checks
  that those files are produced.

## 11. MultiQC summaries (including custom summaries)

MultiQC belongs at the end of a pipeline. It does not analyse reads, assemblies,
or bins. It finds outputs the pipeline already wrote and turns them into one
HTML report plus a `multiqc_data/` directory of parsed tables
([overview](https://docs.seqera.io/multiqc)).

When the repository does not already show how its report is built, copy the
shape used by [nf-core/rnaseq](https://github.com/nf-core/rnaseq) and
[nf-core/mag](https://github.com/nf-core/mag). Local style still wins (§2.1).

### 11.1 Standard report

Install the nf-core `multiqc` module (`nf-core modules install multiqc`) and
match **that** module's current inputs. Do not paste a process signature from
memory, and do not author a MultiQC container (§3).

Collect every file the report should see into one channel and `.collect()` it
so MultiQC runs once. Optional upstreams need an empty-channel fallback
(`.ifEmpty([])`, or whatever the installed module expects) so a skipped tool
does not block the report. Stage `multiqc_config.yml` through a channel. A path
that exists only on the launch machine is not in the task work directory. When
the module accepts it, pass `params.multiqc_config` as an extra `--config`.

If two inputs share a filename, Nextflow will not stage them into one work
directory. Put each tool's files in its own subdirectory, or give them a
dynamic name (`file('tool/log*')`). Some modules recognise a fixed filename, so
a rename needs a search pattern. See
[Using MultiQC in pipelines](https://docs.seqera.io/multiqc/usage/pipelines).

Mix in the three summaries nf-core pipelines always add:

1. **Workflow summary.** `paramsSummaryMultiqc(paramsSummaryMap(...))`, written
   to `workflow_summary_mqc.yaml` (`plot_type: html`). This is the parameter
   summary. Its section id is `<manifest name>-summary` (slashes in the
   manifest name become dashes), not the filename.
2. **Software versions.** `softwareVersionsToYAML`, collected to
   `pipeline_info/<pipeline>_software_mqc_versions.yml`.
3. **Methods text.** `methodsDescriptionText` rendered from the pipeline's
   methods template (rnaseq keeps
   `workflows/rnaseq/assets/multiqc/methods_description_template.yml`), or from
   `params.multiqc_methods_description` when the user supplies one, written to
   `methods_description_mqc.yaml`.

Do not invent method citations. If the repo has no methods template, ask, or
copy the file shape from rnaseq or mag and leave the citations for the user to
confirm.

Do not emit MultiQC's own version onto the `versions` topic. MultiQC waits on
that topic, and publishing back onto it hangs the run. Follow the installed
module.

Publish the HTML report and `multiqc_data/` under the run's timestamped output
directory (§8).

### 11.2 Custom summaries

Use [custom content](https://docs.seqera.io/multiqc/custom_content/) for a
number the core modules do not already parse: a sample pass/fail table, a
pipeline status section, an in-house metric. If the file comes from a released
tool MultiQC already supports, give MultiQC that tool's native output and let
the core module parse it.

There are three ways to supply a custom section. Use the first unless the
producing tool cannot be renamed.

1. **Self-contained `*_mqc.*` file.** Discovered with no extra search pattern
   when the name ends in
   `*_mqc.(yaml|yml|json|txt|csv|tsv|log|out|png|jpg|jpeg|html)`. The file holds
   both the section config and the data. This is the usual pipeline path: the
   process writes the file, and the workflow `.mix()`es it into the MultiQC
   input channel.
2. **`custom_data` inside `multiqc_config.yml`.** Same section fields, for a
   small static block you already keep in config. A config file is not
   discovered via an `_mqc.yml` suffix. Pass it with `--config`.
3. **Config plus a search pattern**, when the tool's own filename must stay.
   The `custom_data` id and the `sp` key are the same string. The data file
   then has no embedded config:

```yaml
custom_data:
  example_files:
    file_format: "tsv"
    section_name: "Coverage decay"
    description: "Coverage by position, from the tool's own table."
    plot_type: "linegraph"
    pconfig:
      id: "example_coverage_lineplot"
      title: "Coverage decay"
      ylab: "Coverage"
      ymax: 100
      ymin: 0
sp:
  example_files:
    fn: "example_files_*"
```

   An image found only through `sp` also needs `ignore_images: false`.

In `module_order` or `run_modules`, the module name is `custom_content`.

Set `plot_type` explicitly. If it is omitted, MultiQC guesses, and the guess
can be wrong: nf-core/rnaseq's dupRadar line plot was drawn as a bar graph
until `plot_type` was set
([nf-core/rnaseq#1137](https://github.com/nf-core/rnaseq/pull/1137)).

The numbers in the examples below are a file-format sketch. Write the values
the pipeline actually computed.

Self-contained YAML (configuration and data in one file):

```yaml
id: "sample_qc_summary"
section_name: "Sample QC summary"
description: "Per-sample checks computed by this pipeline."
plot_type: "table"
pconfig:
  id: "sample_qc_summary_table"
  title: "Sample QC summary"
data:
  sample_1:
    reads: 1000
    status: "PASS"
  sample_2:
    reads: 50
    status: "FAIL"
```

A table built in the workflow is a TSV with YAML comments in the header, named
`*_mqc.tsv`. nf-core/rnaseq does this for sample-status checks: a header file
sets `parent_id`, `parent_name`, and `parent_description`, the workflow appends
the rows, and the result is mixed in as `fail_mapped_samples_mqc.tsv`. Files
that share a `parent_id` become subsections of one report section. `parent_id`
groups custom content only; it cannot insert a block into a core module's
section.

```text
# id: 'sample_qc_summary'
# section_name: 'Sample QC summary'
# parent_id: 'sample_status'
# parent_name: 'Sample status checks'
# plot_type: 'table'
Sample	Reads	Status
sample_1	1000	PASS
```

Accepted `plot_type` values include `generalstats`, `table`, `bargraph`,
`linegraph`, `boxplot`, `scatter`, `heatmap`, `violin`, and `html`. For `html`,
`data` is a string and has no sample keys. `generalstats` adds columns to the
top General Statistics table and does not open its own section; copy its column
config from the custom-content page, not from a `table` block. An image is
embedded when `_mqc` sits before the extension (`summary_mqc.png`). Images are
base64-inlined into the HTML, so keep them small.

Details that change the report:

- One plot per custom section.
- The first column of a table is the sample name. Header configuration on that
  column is ignored. Quote number-like ids (`"01"`) so they stay strings.
- Dedicated summary modules: When authoring a module or process to assemble
  custom summary tables/files (e.g. MultiQC custom summaries), adhere strictly
  to §5.4: start the module `main.nf` directly with the `process` block. Never
  define helper functions (e.g. `def mqcArg(...)`) above the process declaration;
  handle argument formatting, flags, or missing file fallbacks inside the
  `script:` block or upstream via channel operators.
- Use the same `meta.id` as the rest of the report, or the row will not join
  the General Statistics table.
- Files that share a section `id` are merged, so one file per sample is valid.
- Section order is otherwise unstable. `custom_content.order` pins custom
  sections against each other. `report_section_order` places a section before
  or after a core module
  ([report customisation](https://docs.seqera.io/multiqc/reports/customisation)):

```yaml
custom_content:
  order:
    - nf-core-rnaseq-summary
    - sample_qc_summary
report_section_order:
  sample_qc_summary:
    before: fastqc
```

  Those strings are section ids. For the workflow summary, use the id
  `paramsSummaryMultiqc` writes (`nf-core-rnaseq-summary` for that pipeline),
  not the filename. Custom sections missing from `custom_content.order` are
  placed at the top. The id is the fragment after `#` in the report URL
  (`multiqc_report.html#sample_qc_summary`).

While developing a new summary, run `multiqc --strict` (or set `strict: true`
/ `MULTIQC_STRICT`) and fix what it warns about. Then open the HTML and check
that the section exists and that every sample row is present. A successful
MultiQC exit only means the report was written.

Title, subtitle, `intro_text`, and `report_comment` belong in
`multiqc_config.yml`
([report customisation](https://docs.seqera.io/multiqc/reports/customisation)).

### 11.3 AI summaries

MultiQC 1.27 and newer can write an AI summary (`--ai` / `--ai-summary`, or
`ai_summary: true` in config, and `--ai-summary-full` for the longer one).
Enable it only when the user asks.
Generating the summary sends report data to an external provider (Seqera, unless
another provider is set). Ask before turning it on, and leave it off for private
or human-subject data. The text is not a result: do not cite it as a finding,
and do not let it stand in for the custom-content tables in §11.2.
Docs: https://docs.seqera.io/multiqc/ai/
