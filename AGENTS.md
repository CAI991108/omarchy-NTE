# AGENTS.md

Agent-facing notes for `omarchy-NTE` — a personal Omarchy (Arch + Hyprland) desktop
configuration. The tracked content is `config/` (a mirror of `~/.config`, holding only
deliberate local changes), plus `install.sh` and the package lists under `packages/`.

Deployment is a **copy**, not a symlink: Omarchy's `omarchy-refresh-config` runs
`cp -f` without `--remove-destination`, so it writes *through* symlinks and would
overwrite files inside the repo. `install.sh` copies instead, backs up first, and is
idempotent.

## Agent skills

### Issue tracker

Issues and specs live as GitHub issues in this repo (via the `gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Five triage state roles (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`), each label string equal to its role name; `bug` and `enhancement` come from GitHub's defaults. See `docs/agents/triage-labels.md`.

### Domain docs

Domain docs use a **single-context** layout: one root `GLOSSARY.md` plus `docs/adr/`. See `docs/agents/domain.md`.
