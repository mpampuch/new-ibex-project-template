#!/usr/bin/env bash


################################################################################
# Tower CLI Workflow Launcher for IBEX
#
# This script provides a flexible way to launch Nextflow workflows via
# Seqera Platform (Tower) on KAUST IBEX HPC.
#
# Usage:
#   sbatch launch-seqera-platform.sh [options]
#
# Environment variables can be set to override defaults:
#   PIPELINE_NAME_OR_URL  - GitHub URL or Tower pipeline name
#   PIPELINE_REVISION     - Git revision/branch/tag (default: master)
#   PARAMS_FILE           - Path to params JSON/YAML file
#   PROFILES              - Comma-separated list of profiles
#   WORKSPACE_ID          - Tower workspace ID
#   COMPUTE_ENV           - Tower compute environment name
#   WORK_DIR              - Launch work directory (overrides compute env default)
#   RUN_NAME              - Custom name for the workflow run
#   WAIT_FOR_COMPLETION   - Set to "true" to wait for workflow to complete
#   RETRIES               - Times to retry tw launch on failure (default: 10)
#   MAX_JOBS              - Max concurrent Tower runs RUNNING|SUBMITTED (default: 5)
#   CHECK_INTERVAL        - Seconds between concurrency checks (default: 60)
#   PRE_RUN_SCRIPT        - If this file exists, passed to tw launch --pre-run
#   RUN_LABELS_PREFIX     - Optional comma-separated prefix for Tower labels
################################################################################

################################################################################
# Pipeline to launch
################################################################################

PIPELINE_NAME_OR_URL="RNAseq"

################################################################################
# Setup
################################################################################

# Load modules
module load nextflow/25.04.2
module load singularity/3.9.7
module load tower-cli/0.15.0

# Configure Nextflow environment
export NXF_OPTS='-Xms3G -Xmx5G' # Allocate Java VM Heap memory range (for main process)
export NXF_SINGULARITY_CACHEDIR=/ibex/scratch/projects/c2303/NXF_SINGULARITY_CACHEDIR
export NXF_APPTAINER_CACHEDIR=/ibex/scratch/projects/c2303/NXF_APPTAINER_CACHEDIR
export NXF_WORK=/ibex/scratch/projects/c2303/work

# Activate your environment for your job (if necessary)
# source env.sh

# Activate Tower Credentials and Run the Tower Agent
source CONF/SEQERA-PLATFORM/run_tw_agent.sh

# Validate Tower credentials
if [ -z "${TOWER_ACCESS_TOKEN:-}" ]; then
    echo "Error: TOWER_ACCESS_TOKEN not set"
    echo "Please set it"
    exit 1
fi

################################################################################
# Common Configuration
################################################################################

RETRIES="${RETRIES:-10}"
MAX_JOBS="${MAX_JOBS:-5}"
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"

COMPUTE_ENV="IBEX"
PROFILES="singularity,kaust"
INPUT_FILE="$(pwd)/samplesheet.csv" # Comment this out if different runs have different inputs
TIMESTAMP=$(date -Iseconds | sed 's/-//g; s/://g; s/T/_/; s/+.*//')

export NXF_OUTPUT_DIR="$(pwd)/OUTPUTS/$TIMESTAMP"
NXF_LOG_FILE="$NXF_OUTPUT_DIR/nextflow.log"

PRE_RUN_SCRIPT="${PRE_RUN_SCRIPT:-$(pwd)/pre-run.sh}"
# Only pass --pre-run when the script exists (avoids failing tw launch on fresh checkouts).
PRE_RUN_TW_ARGS=()
if [ -f "$PRE_RUN_SCRIPT" ]; then
  PRE_RUN_TW_ARGS=(--pre-run "$PRE_RUN_SCRIPT")
fi

wait_for_available_slot() {
  # Throttle launches so we never exceed MAX_JOBS concurrently RUNNING in Tower
  while true; do
    local running_jobs
    running_jobs=$(tw runs list | rg -c 'RUNNING|SUBMITTED' || echo 0)
    if [ "$running_jobs" -lt "$MAX_JOBS" ]; then
      break
    fi
    echo "Currently $running_jobs runs active; waiting for a free slot (max $MAX_JOBS)..."
    sleep "$CHECK_INTERVAL"
  done
}

# Create output directory and copy useful files there for an easier time decipher the pipeline execution afterwards
mkdir -p "$NXF_OUTPUT_DIR"
cp "$INPUT_FILE" "$NXF_OUTPUT_DIR"
cp "$0" "$NXF_OUTPUT_DIR/slurm_script.sbatch" # Copy the script to the output directory
echo "$(pwd)" > "$NXF_OUTPUT_DIR/projectDir.txt"
export LOG_FILE="$NXF_OUTPUT_DIR/launch.log"

# Extract the launch directory from the compute environment configuration to be used in the post run script to copy the run output back to the project directory
NXF_LAUNCH_DIR=$(jq -r '.launchDir' CONF/SEQERA-PLATFORM/seqera-platform-IBEX-compute-env.json)
echo "NXF_LAUNCH_DIR: $NXF_LAUNCH_DIR"

################################################################################

# Launch Runs

# You can get the basic pipeline configuration using the following commands to help you modify pipeline configurations
# source ~/.secrets/seqera-platform.sh
# tw pipelines list
# tw pipelines export --name RNAseq

################################################################################

################################################################################
# Launch Run 1
################################################################################

wait_for_available_slot

# Launch with configuration 1
RUN_NAME="RUN_1"
if [ -n "${RUN_LABELS_PREFIX:-}" ]; then
  RUN_LABELS="${RUN_LABELS_PREFIX},${RUN_NAME},time_${TIMESTAMP}"
else
  RUN_LABELS="${RUN_NAME},time_${TIMESTAMP}"
fi
echo "RUN_LABELS: $RUN_LABELS"
RUN_NAME_FULL="${RUN_NAME}_${TIMESTAMP}"
NXF_OUTPUT_DIR_RUN_SPECIFIC="${NXF_OUTPUT_DIR}/${RUN_NAME}"
# Configs
CONFIG_FILE="nextflow.config"
CONFIG_FILE_RUN_SPECIFIC="$(basename "$CONFIG_FILE" .config).$RUN_NAME.config"
cp "$CONFIG_FILE" "$CONFIG_FILE_RUN_SPECIFIC"

# Modify your arguments here
cat << EOF >> "$CONFIG_FILE_RUN_SPECIFIC"
params.input = "$INPUT_FILE"
params.outdir = "$NXF_OUTPUT_DIR_RUN_SPECIFIC"

// process {
//   withName: '.*MULTIQC.*' {
//       ext.args = '--max-size 100g'
//   }
// }
EOF

RUN_POST_RUN_SCRIPT="$(pwd)/TMP/${RUN_NAME_FULL}.post_run_script.sh"
RUN_POST_RUN_SCRIPT_CALLBACK="$(pwd)/TMP/${RUN_NAME_FULL}.post_run_script_callback.sh"
echo "RUN_POST_RUN_SCRIPT_CALLBACK: $RUN_POST_RUN_SCRIPT_CALLBACK"

# Build the callback script that will execute the post-run script
"$(pwd)/UTILS/build_post_run_callback_script.sh" "$RUN_POST_RUN_SCRIPT" "$RUN_POST_RUN_SCRIPT_CALLBACK"

# Launch the run (retry on transient tw launch failures)
echo "Launching run: $RUN_NAME_FULL"
attempt=1
while true; do
  echo "Launching run: $RUN_NAME_FULL, attempt $attempt of $RETRIES"
  if tw launch "$PIPELINE_NAME_OR_URL" \
    --name "$RUN_NAME_FULL" \
    --labels "$RUN_LABELS" \
    --compute-env="$COMPUTE_ENV" \
    --profile "$PROFILES" \
    --config "$CONFIG_FILE_RUN_SPECIFIC" \
    "${PRE_RUN_TW_ARGS[@]}" \
    --post-run "${RUN_POST_RUN_SCRIPT_CALLBACK}"; then
    break
  fi
  if [ "$attempt" -ge "$RETRIES" ]; then
    echo "tw launch failed after $RETRIES attempts. Giving up."
    break
  fi
  echo "tw launch failed (attempt $attempt of $RETRIES). Retrying..."
  attempt=$((attempt + 1))
  sleep 1
done

# Capture the workflow run ID of the latest run
WORKFLOW_RUN_ID=$(tw runs list --max 1 | awk 'NF' | tail -n 1 | awk '{print $1}')

# Build the post run script to copy the run output back to the project directory
"$(pwd)/UTILS/build_post_run_script.sh" "$NXF_LAUNCH_DIR" "$WORKFLOW_RUN_ID" "$NXF_OUTPUT_DIR_RUN_SPECIFIC" "$RUN_POST_RUN_SCRIPT"
