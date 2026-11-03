#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# launch-test.sbatch — TEMPLATE for FULL-PIPELINE tests on the IBEX HPC.
# Copy this file, then replace every <PLACEHOLDER>. The agent must ASK the user
# for each site-specific value; do NOT hardcode any of them.
# See instructions/nf-core-pipeline-building.md §5.5 / §8.
#
# The test profile ("test,singularity") points nf-test / nextflow at small test
# data (samplesheet.test.csv) and a fast executor. Test outputs land in a
# timestamped TESTS/TEST_OUTPUTS/<ts>/ dir; the input, config, this script, and
# nextflow.log are copied in and projectDir.txt records the launch dir.
#
# Alternative for module/subworkflow-level TDD runs: submit
#   sbatch --wrap="nf-test test tests/<file>.nf.test --tags fast --verbose"
# instead. (For local work use `nextflow run ... -profile docker,test` or run
# `nf-test test ...` directly — no sbatch.)
# ---------------------------------------------------------------------------
#SBATCH --time=00:30:00                     # ASK the user; tests should be short
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1                   # match the job's --cpus-per-task
#SBATCH --ntasks=1
#SBATCH --mem=6G
#SBATCH --partition=<PARTITION>             # ASK the user: partition / QOS (e.g. batch)
#SBATCH --account=<ACCOUNT>                 # ASK the user — do not hardcode
#SBATCH --job-name=TEST-PIPELINE
#SBATCH --output=SLURM_LOGS/.slurm_%j.out
#SBATCH --error=SLURM_LOGS/.slurm_%j.err
#SBATCH --mail-type=ALL

# Load the IBEX toolchain (ASK the user for exact module versions):
module load nextflow                       # ASK exact version: >= 25.10 (recommend newest stable, e.g. 26.04.x)
module load singularity                    # container engine (apptainer is v4)
module load tower-cli                      # Seqera Platform CLI (optional for a plain run)

# Runtime / cache locations -> shared IBEX scratch (ASK the user for <SCRATCH>):
export NXF_OPTS='-Xms3G -Xmx5G'
export NXF_SINGULARITY_CACHEDIR=<SCRATCH>/NXF_SINGULARITY_CACHEDIR
export NXF_APPTAINER_CACHEDIR=<SCRATCH>/NXF_APPTAINER_CACHEDIR
export NXF_WORK=<SCRATCH>/work

# (Optional) conda env:
# source "/ibex/user/<user>/mambaforge/etc/profile.d/conda.sh"
# conda activate "$(pwd)/env"

# Inputs / config / timestamped TEST output dir
INPUT_FILE="samplesheet.test.csv"
CONFIG_FILE="nextflow.config"
NXF_OUTPUT_DIR="TESTS/TEST_OUTPUTS/$(date -Iseconds | sed 's/-//g; s/://g; s/T/_/; s/+.*//')"
NXF_LOG_FILE="$NXF_OUTPUT_DIR/nextflow.log"

mkdir -p "$NXF_OUTPUT_DIR"
cp "$INPUT_FILE" "$NXF_OUTPUT_DIR"
cp "$CONFIG_FILE" "$NXF_OUTPUT_DIR"
cp "$0" "$NXF_OUTPUT_DIR/slurm_script.sbatch"
echo "$(pwd)" > "$NXF_OUTPUT_DIR/projectDir.txt"

# Run the test suite (IBEX profile: singularity + test)
nextflow -log "$NXF_LOG_FILE" run . -c "$CONFIG_FILE" -with-report \
    -profile singularity,test --outdir "$NXF_OUTPUT_DIR"

# Examples:
# nextflow -log "$NXF_LOG_FILE" run nf-core/rnaseq -r 3.20.0 -c "$CONFIG_FILE" \
#     -with-report --input "$INPUT_FILE" --gtf <GTF> --fasta <FASTA> \
#     -profile singularity,test --trimmer fastp --remove_ribo_rna true -resume
