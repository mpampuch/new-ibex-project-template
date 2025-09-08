#!/usr/bin/env bash

# Parse flags manually (robust for sourced scripts)
SKIP_INIT=false
for arg in "$@"; do
  if [[ "$arg" == "-e" ]]; then
    SKIP_INIT=true
  fi
done

# Load required modules
module load nextflow/25.04.2
module load singularity/3.9.7
module load github-cli/2.46/binary

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
ln -s "$NXF_WORK" work_symlink
echo "Nextflow WORK directory SymLink generated at ./work_symlink"

# Make additional folders
mkdir -p DATA OUTPUTS TESTS/{TEST_DATA,TEST_OUTPUTS}
echo "DATA, OUTPUTS and TEST data directories (TESTS/TEST_DATA, TESTS/TEST_OUTPUTS) generated."

# Reset README.md
echo -e "# README.md\n" > README.md

# Make this a safe directory
# git config --add safe.directory .


# Create an nf-core pipeline and initialize nf-test unless skipped
if [ "$SKIP_INIT" = false ]; then
  nf-core pipelines create --template-yaml pipeline-template.yml
  sleep 3
  rm nf-core-pipeline/.gitignore # Don't copy this to prevent it from overwriting my own
  cp -r nf-core-pipeline/{*,.*} . 
  rm -rf nf-core-pipeline
  nf-test init
  nf-test generate pipeline main.nf
  # test to make sure everything ran correctly
  OUTDIR=TESTS/TEST_OUTPUTS/PIPELINE-GENERATION-TEST
  nextflow -log "$OUTDIR/nextflow.log" run . -profile singularity,test --outdir $OUTDIR && echo "Nextflow pipeline ran successfully. Pipeline boilerplate generation worked and is ready for modification"

  # Push to GitHub
  # Get Authentication
  echo "Creating a git repository at $ORG_NAME/$REPO_NAME"
  source ~/.secrets/github.sh # Loads the GITHUB_TOKEN
  ORG_NAME="mpampuch-bioinformatics-pipelines"
  REPO_NAME=$(basename "$(pwd)")
  gh repo create "$ORG_NAME/$REPO_NAME" --public --source=. --remote=origin
  echo "Remote endpoints set to:" ; git remote -v
  # Make the remote ssh
  echo "Modifying the remote endpoints to be ssh endpoints (recommended for HPC workflows)"
  git remote set-url origin git@github.com:$ORG_NAME/$REPO_NAME.git # For personal projects use: git remote set-url origin git@github.com:$(gh api user --jq .login)/$REPO_NAME.git
  echo "New remote endpoints set to:" ; git remote -v
  git push -u origin master
  unset GITHUB_TOKEN # Remove the GITHUB token from your environmental variables

  else
  echo "Skipping nf-core and nf-test initialization (flag -e passed)."
fi
