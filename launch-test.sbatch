#!/usr/bin/env bash
#SBATCH --time=00:30:00                     # Set your job walltime (D-HH:MM:SS)
#SBATCH --nodes=1                           # Set how many compute nodes / machines to request
#SBATCH --cpus-per-task=1                   # Set how many CPU's / threads you need
#SBATCH --ntasks=1                          # Set how many tasks / processes you need (generally 1 for serial tasks)
#SBATCH --mem=1G                            # Set how much memory should be allocated per node
#SBATCH --partition=batch                   # Set which partition / queue your job will run in.
#SBATCH --output=SLURM_LOGS/.slurm_%j.out   # Set where SLURM stdout will go
#SBATCH --error=SLURM_LOGS/.slurm_%j.err    # Set where SLURM stderr will go
#SBATCH --mail-type=ALL                     # Set emailing rules for this job (options: BEGIN, END, FAIL, REQUEUE, ALL, NONE)
#SBATCH --job-name=TEST-PIPELINE            # Set your job name

# Load modules
module load nextflow/25.04.2
module load singularity/3.9.7

# Configure up environment variables
export NXF_OPTS='-Xms3G -Xmx5G' # Allocate Java VM Heap memory range (for main process)
export NXF_SINGULARITY_CACHEDIR=/ibex/scratch/projects/c2303/NXF_SINGULARITY_CACHEDIR 
export NXF_APPTAINER_CACHEDIR=/ibex/scratch/projects/c2303/NXF_APPTAINER_CACHEDIR
export NXF_WORK=/ibex/scratch/projects/c2303/work

# Activate your environment for your job (if necessary)
# source env.sh -e

# Activate a conda enviroment (if necessary)
# source "/ibex/user/pampum/mambaforge/etc/profile.d/conda.sh" # Initialize Conda for use in this script
# conda activate "$(pwd)/env" # Activate the conda environment

# Put in your file paths
# E.g.
INPUT_FILE="samplesheet.test.csv"
CONFIG_FILE="nextflow.config"
NXF_OUTPUT_DIR="TESTS/TEST_OUTPUTS/$(date -Iseconds | sed 's/-//g; s/://g; s/T/_/; s/+.*//')"
NXF_LOG_FILE="$NXF_OUTPUT_DIR/nextflow.log"

# Create output directory and copy useful files there for an easier time decipher the pipeline execution afterwards
mkdir -p "$NXF_OUTPUT_DIR"
cp "$INPUT_FILE" "$NXF_OUTPUT_DIR"
cp "$CONFIG_FILE" "$NXF_OUTPUT_DIR"
cp "$0" "$NXF_OUTPUT_DIR/slurm_script.sbatch" # Copy the script to the output directory
echo "$(pwd)" > "$NXF_OUTPUT_DIR/projectDir.txt"

# Run your job script here
nextflow -log "$NXF_LOG_FILE" run . -c "$CONFIG_FILE" -with-report -profile singularity,test --outdir "$NXF_OUTPUT_DIR"

# Examples
# nextflow -log "$NXF_LOG_FILE" run nf-core/fetchngs  -r 1.12.0 -c "$CONFIG_FILE" -with-report -profile singularity,test --input "$INPUT_FILE" --download_method sratools --outdir "$NXF_OUTPUT_DIR";
# nextflow -log "$NXF_LOG_FILE" run nf-core/rnaseq \
#     -r 3.20.0 \
#     -c "$CONFIG_FILE" \
#     -with-report \
#     --input "$INPUT_FILE" \
#     --outdir "$NXF_OUTPUT_DIR" \
#     --gtf /ibex/project/c2303/20250805_Cm-RNASeq-Analysis-For-High-Expressing-Promoters/DATA/REFERENCE-GENOME/annotations/GCF_000091205.1_ASM9120v1_genomic.gtf.gz \
#     --fasta /ibex/project/c2303/20250805_Cm-RNASeq-Analysis-For-High-Expressing-Promoters/DATA/REFERENCE-GENOME/genomes/GCF_000091205.1_ASM9120v1_genomic.fna.gz \
#     -profile kaust,test \
#     --trimmer fastp \
#     --remove_ribo_rna true \
#     -resume
