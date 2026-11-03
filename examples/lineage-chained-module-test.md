# Lineage-chained module tests (reference — EXPERIMENTAL)

Each downstream module test should **consume the upstream program's output** so
the test chain mirrors the real data flow (module N -> module N+1). Nextflow's
experimental **data lineage** feature (25.04+, "may change") locates and reuses
the real produced file instead of hand-copying an artifact.

See `instructions/nf-core-pipeline-building.md §5.3` and
https://docs.seqera.io/nextflow/tutorials/data-lineage

## 1. Enable lineage tracking
```groovy
// nextflow.config (or a test profile)
lineage.enabled = true
// optional shared store (must be visible to every compute node on the HPC):
// lineage.store.location = '<SCRATCH>/.lineage'
```

## 2. Discover the upstream output's reference
```bash
nextflow lineage list                                  # find the WorkflowRun LID
nextflow lineage find type=TaskRun workflowRun=lid://<run>
nextflow lineage view  lid://<task>                    # read spec.path / spec.source
```

## 3. Feed it into the next module's test (`lid://` is a valid URI in a script)
```groovy
// via a lineage path (resolves to the real file on disk):
Channel.fromPath('lid://<task>/' + 'OUTPUT_NAME.ext')

// or via the fromLineage channel factory:
Channel.fromLineage(type: "TaskRun", workflowRun: "lid://<run>")
```

A minimal `nextflow_process` block illustrating a downstream module consuming the
upstream output (adapt IDs/paths to your run):

```groovy
nextflow_process {
    name "Test Process DOWNSTREAM (consumes upstream lineage)"
    script "modules/local/downstream/downstream.nf"
    process "DOWNSTREAM"
    tag "fast"
    tag "lineage"

    test("DOWNSTREAM | consumes upstream output via lineage") {
        tag "fast"
        options "-dump-hashes"
        when {
            process {
                // The agent fills in the discovered LID/path, or falls back to a
                // pinned, subsetted real path when the store is not reproducible.
                input[0] = [
                    [ id: 'EXAMPLE_SAMPLE' ],
                    Channel.fromPath('lid://<TASK_LID>/' + 'EXAMPLE_SAMPLE.log')
                ]
            }
        }
        then {
            DebugUtils.printTree(process.out)
            assert process.success
            assert snapshot(process.out).match()
        }
    }
}
```

## 4. Verify and diagnose
```bash
nextflow lineage diff  <lidA> <lidB>      # spot unexpected re-execution / bad cache
nextflow lineage render 'lid://<run>/.../OUT.ext'   # open the HTML DAG
```

## Caveats (do not hide from the user)
- EXPERIMENTAL. A `lid://` test input needs a **reproducible, runner-visible**
  lineage store; on IBEX keep `NXF_WORK` / the store on shared, consistent
  scratch across submissions.
- If the store is not reproducible for the runner, **fall back to a pinned,
  subsetted real path** under the module's `TESTDATA/` (this is what the
  `20260309_NEXTFLOW-ALGAE-TAXA-FROM-GENOME` repo currently does — it uses real
  paths, not `lid://`, for its module inputs).
- Never silently drop a sample; record the lineage ref + its cap.
