#!/usr/bin/env bash
# Set your job walltime (D-HH:MM:SS)
#SBATCH --time=48:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --mem=32G
#SBATCH --partition=batch
#SBATCH --output=SLURM_LOGS/.slurm_%j.out
#SBATCH --error=SLURM_LOGS/.slurm_%j.err
#SBATCH --mail-type=ALL
#SBATCH --job-name=YOUR_JOB_NAME

# Load modules
module load nextflow/25.04.2
module load singularity/3.9.7

# Configure up environment variables
export NXF_OPTS='-Xms3G -Xmx5G' # Allocate Java VM Heap memory range (for main process)
export NXF_SINGULARITY_CACHEDIR=/ibex/scratch/projects/c2303/NXF_SINGULARITY_CACHEDIR 
export NXF_APPTAINER_CACHEDIR=/ibex/scratch/projects/c2303/NXF_APPTAINER_CACHEDIR
export NXF_WORK=/ibex/scratch/projects/c2303/work

# Activate your environment for your job (if necessary)
# source env.sh 

# Activate a conda enviroment (if necessary)
# source "/ibex/user/pampum/mambaforge/etc/profile.d/conda.sh" # Initialize Conda for use in this script
# conda activate "$(pwd)/env" # Activate the conda environment

# Put in your file paths
# E.g.
INPUT_FILE="ids.csv"
CONFIG_FILE=""$CONFIG_FILE""
NXF_OUTPUT_DIR="OUTPUTS/$(date -Iseconds | sed 's/-//g; s/://g; s/T/_/; s/+.*//')"
NXF_LOG_FILE="$NXF_OUTPUT_DIR/nextflow.log"

# Create output directory and copy useful files there for an easier time decipher the pipeline execution afterwards
mkdir -p "$NXF_OUTPUT_DIR"
cp "$INPUT_FILE" "$NXF_OUTPUT_DIR"
cp "$CONFIG_FILE" "$NXF_OUTPUT_DIR"
cp "$0" "$NXF_OUTPUT_DIR/slurm_script.sbatch" # Copy the script to the output directory

# Run your job script here
srun YOUR_JOB_SCRIPT

# Examples
# nextflow -log "$NXF_LOG_FILE" run nf-core/fetchngs  -r 1.12.0 -c "$CONFIG_FILE" -with-report -profile singularity --input "$INPUT_FILE" --download_method sratools --outdir "$NXF_OUTPUT_DIR";
# nextflow -log "$NXF_LOG_FILE" run nf-core/rnaseq \
#     -r 3.20.0 \
#     -c "$CONFIG_FILE" \
#     -with-report \
#     --input "$INPUT_FILE" \
#     --outdir "$NXF_OUTPUT_DIR" \
#     --gtf /ibex/project/c2303/20250805_Cm-RNASeq-Analysis-For-High-Expressing-Promoters/DATA/REFERENCE-GENOME/annotations/GCF_000091205.1_ASM9120v1_genomic.gtf.gz \
#     --fasta /ibex/project/c2303/20250805_Cm-RNASeq-Analysis-For-High-Expressing-Promoters/DATA/REFERENCE-GENOME/genomes/GCF_000091205.1_ASM9120v1_genomic.fna.gz \
#     -profile kaust \
#     --trimmer fastp \
#     --remove_ribo_rna true \
#     -resume
