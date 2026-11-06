#!/usr/bin/env bash

# Example
set -euo pipefail
cd "$(dirname "$0")"
set -a
source "${HOME}/.secrets/seqera-platform.sh"
set +a
wave -i mpampuch/kmerord_ca6126d_linux-amd64:1370912b6f11bb2a \
  --singularity \
  --platform linux/amd64 \
  --freeze \
  --build-repo mpampuch/kmerord_ca6126d_linux-amd64_sif \
  --output json \
  --await 90m \
  --log-level DEBUG