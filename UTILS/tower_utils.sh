#/bin/bash

# Activate Tower Credentials
# Make sure you have a secrets file in ~/.secrets/ that looks like this:
# export TOWER_ACCESS_TOKEN="your_tower_access_token" and that this has chmod 600 permissions
source ~/.secrets/seqera-platform.sh 

# View all pipelines in user workspace
tw pipelines list

# Export the pipeline configuration to help you modify pipeline configurations
tw pipelines export --name RNAseq

# Update the pipeline once you have modified the pipeline configuration or compute environment
tw pipelines update --name "<PIPELINE_NAME>" --compute-env IBEX

# View all running and submitted runs
tw runs list | grep "RUNNING\|SUBMITTED" | awk '{print $1}'

# Cancel all running and submitted runs
tw runs list | grep "RUNNING\|SUBMITTED" | awk '{print $1}' | xargs -I{} tw runs cancel --id {}