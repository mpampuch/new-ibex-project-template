// subworkflows/local/example_subworkflow/example_subworkflow.nf
// Template subworkflow: combine one or more modules behind a clean interface.
// Create with:  nf-core subworkflows create example_subworkflow
// See agent-resources/instructions/nf-core-pipeline-building.md §4.9.

workflow EXAMPLE_SUBWORKFLOW {
    input:
    ch_input                          // channel: tuple val(meta), path(fasta)

    output:
    report = EXAMPLE_MODULE.report

    main:
    EXAMPLE_MODULE(ch_input)
}
