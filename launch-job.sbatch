#!/bin/bash --login
# Set your job walltime (D-HH:MM:SS)
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=100
#SBATCH --ntasks=1
#SBATCH --mem=32G
#SBATCH --partition=batch
#SBATCH --job-name=YOUR_JOB_NAME
#SBATCH --mail-type=ALL

# Activate your conda environment for your job
conda activate "$(pwd)"/env

# Run your job script here
srun YOUR_JOB_SCRIPT