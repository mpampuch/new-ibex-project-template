# Agent resources

Playbooks, templates, and tool configs used while an AI agent builds this project. The pipeline itself stays at the repository root (`main.nf`, `modules/`, `subworkflows/`, `tests/`, `PROJECT.md`). This directory is safe to delete when that help is no longer needed.

Paths in `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md` in this directory are relative to `agent-resources/`.

## Layout

| Path | Role |
| --- | --- |
| `AGENTS.md` | Scientific-integrity baseline and completion-report format |
| `CLAUDE.md`, `GEMINI.md` | Full adapters for those harnesses |
| `instructions/` | Playbooks (nf-core pipeline building, Nextflow, HPC, scientific writing) |
| `templates/` | Reusable scaffolds for a new pipeline, analysis, or writing repo |
| `writing/STYLE.md` | Style profile referenced by the writing playbook |
| `examples/` | Worked examples, including lineage-chained module tests |
| `cursor/rules/pipeline_rules.mdc` | Full Cursor rule for Nextflow edits |
| `claude/settings.json` | Claude Code deny-list for large data and secrets |
| `scripts/validate-project.sh` | Checks this bundle plus the root pipeline scaffold |

## How agents find this during development

Root stubs point here so tools that only auto-load repo-root files still see the guidance:

- `AGENTS.md`
- `CLAUDE.md` (`@agent-resources/AGENTS.md`)
- `GEMINI.md`
- `.cursor/rules/pipeline_rules.mdc` (pointer; the full rule is `cursor/rules/pipeline_rules.mdc`)

Claude Code does not load a stub JSON. To apply the bundled read denylist during development, from the repository root:

```bash
cp -R agent-resources/claude .claude
# or, if you prefer a link:
ln -s agent-resources/claude .claude
```

Check the layout with:

```bash
./agent-resources/scripts/validate-project.sh .
```

## Remove this bundle

From the repository root:

```bash
./agent-resources/uninstall.sh
```

That deletes `agent-resources/`, the root stubs (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.cursor/rules/pipeline_rules.mdc`), and `.claude` when it is a symlink to `agent-resources/claude` or an unchanged copy of `claude/settings.json`. Empty `.cursor/` and `.claude/` directories are removed. Other files in those directories are left in place.

Manual equivalent:

```bash
rm -rf agent-resources
rm -f AGENTS.md CLAUDE.md GEMINI.md
rm -f .cursor/rules/pipeline_rules.mdc
rm -rf .claude   # only if you copied or linked it from agent-resources
```

Afterward, edit `PROJECT.md` if it still points at `agent-resources/instructions/nextflow.md`.
