#!/usr/bin/env bash

# Load required modules
module load nextflow/24.10.2
module load singularity/3.9.7

# Configure your environment variables
export NXF_OPTS='-Xms3G -Xmx5G'
echo "Java VM Heap memory allocated to a range of $(echo $NXF_OPTS | grep -oP '(?<=-Xms)\S+') and $(echo $NXF_OPTS | grep -oP '(?<=-Xmx)\S+') using the Nextflow ENV variable NXF_OPTS"

export TMOUT=172800
echo "tmux timeout ENV variable (TMOUT) changed to $TMOUT seconds"

export SINGULARITY_CACHEDIR=$(pwd)/CACHE 
export NXF_SINGULARITY_CACHEDIR=$(pwd)/NFCACHE 
mkdir -p $SINGULARITY_CACHEDIR $NXF_SINGULARITY_CACHEDIR 
echo "Created Singularity cache directory at $SINGULARITY_CACHEDIR" 
echo "Created Nextflow Singularity cache directory at $NXF_SINGULARITY_CACHEDIR" 

export NXF_WORK=/ibex/scratch/projects/c2303/work
echo "Nextflow WORK directory will be outputted at $NXF_WORK"