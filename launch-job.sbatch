#!/bin/bash --login
# Set your job walltime (D-HH:MM:SS)
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=100
#SBATCH --ntasks=1
#SBATCH --mem=32G
#SBATCH --partition=batch
#SBATCH --output=.slurm_%j.out
#SBATCH --error=.slurm_%j.err
#SBATCH --mail-type=ALL
#SBATCH --job-name=YOUR_JOB_NAME

# Activate your environment for your job
source env.sh 

# Activate a conda enviroment (if necessary)
# source "$(conda info --base)/etc/profile.d/conda.sh" # Initialize Conda for use in this script
# conda activate "$(pwd)/env" # Activate the conda environment

# Put in your file paths
# E.g.
# INPUT_FILE="ids.csv"
# NXF_OUTPUT_DIR="outputs/$(date -Iseconds | sed 's/-//g; s/://g; s/T/_/; s/+.*//')"
# NXF_LOG_FILE="$NXF_OUTPUT_DIR/nextflow.log"

# Run your job script here
srun YOUR_JOB_SCRIPT

# E.g.
# nextflow -log "$NXF_LOG_FILE" run nf-core/fetchngs -r 1.12.0 -c nextflow.config -profile singularity --input "$INPUT_FILE" --download_method sratools --outdir "$NXF_OUTPUT_DIR";
