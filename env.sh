#!/usr/bin/env bash

# Parse flags
SKIP_INIT=false
while getopts "e" opt; do
  case $opt in
    e)
      SKIP_INIT=true
      ;;
    *)
      echo "Usage: $0 [-e]"
      echo "  -e   Skip nf-core and nf-test initialization"
      return 1
      ;;
  esac
done

# Load required modules
module load nextflow/25.04.2
module load singularity/3.9.7

# Configure your environment variables
export NXF_OPTS='-Xms3G -Xmx5G'
echo "Java VM Heap memory allocated to a range of $(echo $NXF_OPTS | grep -oP '(?<=-Xms)\S+') and $(echo $NXF_OPTS | grep -oP '(?<=-Xmx)\S+') using the Nextflow ENV variable NXF_OPTS"

export TMOUT=172800
echo "tmux timeout ENV variable (TMOUT) changed to $TMOUT seconds"

export NXF_SINGULARITY_CACHEDIR=/ibex/scratch/projects/c2303/NXF_SINGULARITY_CACHEDIR
export NXF_APPTAINER_CACHEDIR=/ibex/scratch/projects/c2303/NXF_APPTAINER_CACHEDIR
mkdir -p $NXF_SINGULARITY_CACHEDIR $NXF_APPTAINER_CACHEDIR 
echo "Created Nextflow Singularity cache directory at $NXF_SINGULARITY_CACHEDIR" 
echo "Created Nextflow Apptainer cache directory at $NXF_APPTAINER_CACHEDIR" 


export NXF_WORK=/ibex/scratch/projects/c2303/work
mkdir -p $NXF_WORK 
echo "Nextflow WORK directory will be outputted at $NXF_WORK"

# Make additional folders
mkdir -p DATA OUTPUTS TESTS/{TEST_DATA,TEST_OUTPUTS}

# Reset README.md
echo -e "# README.md\n" > README.md

# Create an nf-core pipeline and initialize nf-test unless skipped
if [ "$SKIP_INIT" = false ]; then
  nf-core pipelines create --template-yaml pipeline-template.yml
  mv nf-core-pipeline/* .
  mv nf-core-pipeline/.* .
  rmdir nf-core-pipeline
  nf-test init
  nf-test generate pipeline main.nf
else
  echo "Skipping nf-core and nf-test initialization (flag -e passed)."
fi
