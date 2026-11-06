#!/usr/bin/env bash

# Example
set -euo pipefail
cd "$(dirname "$0")"
set -a
source "${HOME}/.secrets/seqera-platform.sh"
set +a
commit="$(git rev-parse --short=7 HEAD)"
wave -f Dockerfile \
  --platform linux/amd64 \
  --freeze \
  --build-repo "mpampuch/kmerord_${commit}_linux_amd64" \
  --output json \
  --await 90m \
  --log-level DEBUG
