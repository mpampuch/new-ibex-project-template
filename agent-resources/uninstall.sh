#!/usr/bin/env bash
# Remove agent scaffolding once the pipeline no longer needs it.
# Deletes agent-resources/ and the root discovery stubs.
set -euo pipefail

bundle="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$bundle/.." && pwd)"

if [[ "$(basename "$bundle")" != "agent-resources" ]]; then
  echo "ERROR: expected this script to live in agent-resources/" >&2
  exit 2
fi

# A symlink into the bundle should be removed as a link, not by deleting
# the files it points at (those go away with the bundle).
if [[ -L "$root/.claude" ]]; then
  claude_target="$(readlink "$root/.claude")"
  case "$claude_target" in
    agent-resources/claude|*/agent-resources/claude|"$bundle/claude")
      rm -f "$root/.claude"
      ;;
  esac
elif [[ -f "$root/.claude/settings.json" && -f "$bundle/claude/settings.json" ]] && cmp -s "$bundle/claude/settings.json" "$root/.claude/settings.json"; then
  rm -f "$root/.claude/settings.json"
fi
if [[ -d "$root/.claude" && ! -L "$root/.claude" ]] && [[ -z "$(ls -A "$root/.claude")" ]]; then
  rmdir "$root/.claude"
fi

rm -f "$root/AGENTS.md" "$root/CLAUDE.md" "$root/GEMINI.md"
rm -f "$root/.cursor/rules/pipeline_rules.mdc"
if [[ -d "$root/.cursor/rules" ]] && [[ -z "$(ls -A "$root/.cursor/rules")" ]]; then
  rmdir "$root/.cursor/rules"
fi
if [[ -d "$root/.cursor" ]] && [[ -z "$(ls -A "$root/.cursor")" ]]; then
  rmdir "$root/.cursor"
fi

rm -rf "$bundle"

cat <<EOF
Removed agent-resources/ and the root agent stubs.
If PROJECT.md still links to agent-resources/instructions/nextflow.md, replace that line with a project-local note.
EOF
