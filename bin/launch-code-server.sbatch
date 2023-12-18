#!/bin/bash --login
#SBATCH --time=8:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
# --gpus-per-node=v100:1
# --cpus-per-gpu=6  
#SBATCH --mem=32G
#SBATCH --partition=batch
# --partition=debug 
#SBATCH --job-name=launch-code-server
#SBATCH --mail-type=ALL
#SBATCH --output=bin/%x-%j-slurm.out
#SBATCH --error=bin/%x-%j-slurm.err

# Get the directory from which the script was submitted
SUBMIT_DIR=$SLURM_SUBMIT_DIR

# Find the path to the launch-code-server.sbatch file
LAUNCH_CODE_SERVER_PATH=$(find "${SUBMIT_DIR}" -type f -name "launch-code-server.sbatch" -print -quit)

if [ -n "${LAUNCH_CODE_SERVER_PATH}" ]; then
    # Extract the directory containing launch-code-server.sbatch
    SCRIPT_DIR=$(dirname "${LAUNCH_CODE_SERVER_PATH}")
    echo "${SCRIPT_DIR}"
else
    echo "Error: launch-code-server.sbatch not found."
fi

# Remove previous output and error files, excluding the current job's files
for file in "${SCRIPT_DIR}"/launch-code-server*.out "${SCRIPT_DIR}"/launch-code-server*.err; do
    if [[ "${file}" != "${SCRIPT_DIR}"/launch-code-server-"${SLURM_JOB_ID}"-slurm.out && "${file}" != "${SCRIPT_DIR}"/launch-code-server-"${SLURM_JOB_ID}"-slurm.err ]]; then
        rm -v "${file}"
    fi
done

# use srun to launch code server in order to reserve a port
chmod +x ./bin/launch-code-server.srun
srun --resv-ports=1 ./bin/launch-code-server.srun
