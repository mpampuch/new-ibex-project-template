#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# launch-job.sbatch — TEMPLATE for one or a batch of PRODUCTION Nextflow runs
# on the IBEX HPC. Copy this file, then replace every <PLACEHOLDER>. The agent
# must ASK the user for each site-specific value; do NOT hardcode any of them.
# See agent-resources/instructions/nf-core-pipeline-building.md §8.
#
# How outputs are collected: everything needed to reconstruct the run (input
# samplesheet, config, this script, and nextflow.log) is copied into a
# timestamped OUTPUTS/<ts>/ directory, and projectDir.txt records the launch
# directory, so any run can be reopened later.
# ---------------------------------------------------------------------------
#SBATCH --time=48:00:00                     # ASK the user; size to evidence (D-HH:MM:SS)
#SBATCH --nodes=1                           # compute nodes requested
#SBATCH --cpus-per-task=1                   # CPU threads per task (align tools to this)
#SBATCH --ntasks=1                          # tasks (1 for serial tasks)
#SBATCH --mem=5G                            # memory per node
#SBATCH --partition=<PARTITION>             # ASK the user: partition / QOS (e.g. batch)
#SBATCH --account=<ACCOUNT>                 # ASK the user — do not hardcode
#SBATCH --job-name=<YOUR_JOB_NAME>
#SBATCH --output=SLURM_LOGS/.slurm_%j.out   # SLURM stdout
#SBATCH --error=SLURM_LOGS/.slurm_%j.err    # SLURM stderr
#SBATCH --mail-type=ALL                     # BEGIN, END, FAIL, REQUEUE, ALL, NONE

# Load the IBEX toolchain (ASK the user for exact module versions):
module load nextflow                       # ASK exact version: >= 25.10 (recommend newest stable, e.g. 26.04.x)
module load singularity                    # SingularityCE; replaced on PATH by Apptainer below
module load tower-cli                      # Seqera Platform CLI; also provides wave (optional for a plain run)

# Apptainer 1.4.5 replaces SingularityCE 3.9.7 on PATH so Wave ORAS SIFs pull.
# See agent-resources/instructions/nf-core-pipeline-building.md §3.
eval "$(mamba shell hook --shell bash)"
mamba activate apptainer

# Runtime / cache locations -> shared IBEX scratch (ASK the user for <SCRATCH>):
export NXF_OPTS='-Xms3G -Xmx5G'                       # JVM heap for the driver
export NXF_SINGULARITY_CACHEDIR=<SCRATCH>/NXF_SINGULARITY_CACHEDIR
export NXF_APPTAINER_CACHEDIR=<SCRATCH>/NXF_APPTAINER_CACHEDIR
export NXF_WORK=<SCRATCH>/work

# (Optional) activate a conda env only if a module genuinely needs it:
# source "/ibex/user/<user>/mambaforge/etc/profile.d/conda.sh"
# conda activate "$(pwd)/env"

# Inputs / config / timestamped output dir
INPUT_FILE="samplesheet.csv"
CONFIG_FILE="nextflow.config"
NXF_OUTPUT_DIR="OUTPUTS/$(date -Iseconds | sed 's/-//g; s/://g; s/T/_/; s/+.*//')"
NXF_LOG_FILE="$NXF_OUTPUT_DIR/nextflow.log"

# Collect everything needed to reconstruct the run into the output dir
mkdir -p "$NXF_OUTPUT_DIR"
cp "$INPUT_FILE" "$NXF_OUTPUT_DIR"
cp "$CONFIG_FILE" "$NXF_OUTPUT_DIR"
cp "$0" "$NXF_OUTPUT_DIR/slurm_script.sbatch"
echo "$(pwd)" > "$NXF_OUTPUT_DIR/projectDir.txt"

# Run the job (IBEX profile: singularity + kaust)
nextflow -log "$NXF_LOG_FILE" run . -c "$CONFIG_FILE" -with-report \
    -profile singularity,kaust --input "$INPUT_FILE" --outdir "$NXF_OUTPUT_DIR"

# Examples:
# nextflow -log "$NXF_LOG_FILE" run nf-core/fetchngs -r 1.12.0 -c "$CONFIG_FILE" \
#     -with-report -profile singularity,kaust --input "$INPUT_FILE" --download_method sratools --outdir "$NXF_OUTPUT_DIR"
# nextflow -log "$NXF_LOG_FILE" run nf-core/rnaseq -r 3.20.0 -c "$CONFIG_FILE" -with-report \
#     --input "$INPUT_FILE" --gtf <GTF> --fasta <FASTA> -profile singularity,kaust \
#     --trimmer fastp --remove_ribo_rna true -resume
