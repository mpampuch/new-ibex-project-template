# TESTDATA / example_module

Per-module test fixtures. **Never commit large real data** — commit only a small,
documented subset.

## Minimum viable fixture
- `EXAMPLE_SAMPLE.fasta` — the smallest input that still exercises
  `EXAMPLE_MODULE` (enough records to produce a representative output and reach
  the logic branches the test asserts on), yet small enough to run in seconds.

## How this subset was chosen (record it!)
- Inspected with: `seqkit stats TESTDATA/EXAMPLE_SAMPLE.fasta` (or the
  format-appropriate tool; find it via `module avail <tool>`).
- Original data size: <record original record/sequence count + bytes>.
- Cap used: <e.g. "first N records via `seqkit seq` / `head`", "single contig",
  "downsampled reads via `seqkit sample`">.
- Rationale: <why this is the minimum that still tests the tool meaningfully>.

If the inspection tool was unavailable, it was accessed via <asked user / module
load ...>.
