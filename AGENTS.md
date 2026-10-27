# AGENTS.md

Agent-facing notes for `omarchy-NTE` — a personal Omarchy (Arch + Hyprland) desktop
configuration. The tracked content is `config/` (a mirror of `~/.config`, holding only
deliberate local changes), plus `install.sh`, the package lists under `packages/`, and
`bin/` (scripts installed to `~/.local/bin`).

Deployment is a **copy**, not a symlink: Omarchy's `omarchy-refresh-config` runs
`cp -f` without `--remove-destination`, so it writes *through* symlinks and would
overwrite files inside the repo. `install.sh` copies instead, backs up first, and is
idempotent.

Extra wallpapers are **pulled, not captured**: `install.sh --wallpapers[=<theme>|all]`
reads `manifests/wallpapers.tsv` from
[`omarchy-NTE-wallpaper`](https://github.com/CAI991108/omarchy-NTE-wallpaper), verifies
each sha256, and installs flat into `~/.config/omarchy/backgrounds/<theme>/`. The one
bundled wallpaper stays in `config/omarchy/backgrounds/catppuccin/` so a fresh install
still has a working desktop offline.

## Capture convention: no absolute home paths

When capturing a config file, store home-relative paths as `~` (or `$HOME`), never
`/home/<user>/...`. `install.sh` deploys file *contents* verbatim — only symlink
*targets* are rewritten — so a hard-coded home path would break for any other
username. Example: the `SUPER+D` DSH binding is stored as
`~/.local/bin/dsh-web-open`; tilde expansion in Hyprland's `exec` is verified.

One deliberate deviation follows from Omarchy's own template: `config/git/config`
omits the `[user]` and `[credential]` sections (real name, school email, gh helper)
because the repo is public. Deploying it over a machine that already has them will
strip that identity — set it again after running `install.sh` on such a machine.

## Agent skills

### Issue tracker

Issues and specs live as GitHub issues in this repo (via the `gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Five triage state roles (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`), each label string equal to its role name; `bug` and `enhancement` come from GitHub's defaults. See `docs/agents/triage-labels.md`.

### Domain docs

Domain docs use a **single-context** layout: one root `GLOSSARY.md` plus `docs/adr/`. See `docs/agents/domain.md`.
