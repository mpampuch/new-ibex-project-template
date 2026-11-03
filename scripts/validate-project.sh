#!/usr/bin/env bash
set -euo pipefail

target="${1:-.}"
if [[ ! -d "$target" ]]; then
  echo "ERROR: directory not found: $target" >&2
  exit 2
fi

errors=0
warnings=0

check_file() {
  local f="$1"
  if [[ -f "$target/$f" ]]; then
    printf 'OK      %s\n' "$f"
  else
    printf 'MISSING %s\n' "$f"
    errors=$((errors + 1))
  fi
}

warn_file() {
  local f="$1"
  if [[ -f "$target/$f" ]]; then
    printf 'PRESENT %s\n' "$f"
  else
    printf 'OPTIONAL %s\n' "$f"
    warnings=$((warnings + 1))
  fi
}

check_file "AGENTS.md"
warn_file "PROJECT.md"
warn_file "CLAUDE.md"
warn_file "GEMINI.md"
warn_file ".gitignore"
warn_file ".cursorignore"

if [[ -d "$target/instructions" ]]; then
  printf 'OK      instructions/ directory\n'
else
  printf 'MISSING instructions/ directory\n'
  errors=$((errors + 1))
fi

if [[ -f "$target/nextflow.config" || -f "$target/main.nf" || -d "$target/workflows" || -f "$target/nf-test.config" ]]; then
  printf 'INFO    looks like a Nextflow project\n'
  warn_file "instructions/nf-core-pipeline-building.md"
  warn_file "instructions/nextflow.md"
  warn_file "nf-test.config"
  warn_file "conf/test.config"
  warn_file "tests/lib/DebugUtils.groovy"
  warn_file "launch-job.sbatch"
  warn_file "launch-test.sbatch"
  # nf-core scaffolding
  warn_file "main.nf"
  warn_file "nextflow.config"
  warn_file "modules.config"
  warn_file "nextflow_schema.json"
  if [[ -d "$target/tests" || -d "$target/nf-test" ]]; then
    printf 'OK      test directory found\n'
  else
    printf 'WARNING no obvious tests/ or nf-test/ directory\n'
    warnings=$((warnings + 1))
  fi
fi

if [[ -f "$target/slurm.sh" || -d "$target/slurm" || -d "$target/jobs" ]]; then
  printf 'INFO    possible Slurm scripts found; inspect site-specific settings manually\n'
  warn_file "instructions/hpc.md"
fi

if [[ -d "$target/writing" ]]; then
  warn_file "writing/STYLE.md"
fi

printf '\nSummary: %d error(s), %d warning(s)\n' "$errors" "$warnings"
if (( errors > 0 )); then exit 1; fi
exit 0
