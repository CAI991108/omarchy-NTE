# AGENTS.md

Agent-facing notes for `omarchy-NTE` — a personal Omarchy (Arch + Hyprland) desktop
configuration. The tracked content is three **trees**, each mirroring one directory in
`$HOME`: `config/` → `~/.config`, `dsh/` → `~/.dsh`, `bin/` → `~/.local/bin`. Plus
`install.sh` and the package lists under `packages/`.

`main` tracks the 4.0 machine. The 3.8 machine is still current somewhere, so the 3.8 line is a long-lived branch `legacy/3.8` (the tag `omarchy-3.8.2` is the cut-day snapshot). Fixes for that machine go on `legacy/3.8` only; nothing is merged across the cut.
4.0 replaced the Hyprland `.conf` files with Lua, `waybar`/`mako`/`walker`/`hypridle`
with one Quickshell process, and moved theme state to `~/.local/state/omarchy/current/`.
`docs/omarchy-4.md` holds the mapping and the capture procedure; `docs/adr/0002-omarchy-4-cut.md`
holds the reasoning.

Deployment is a **copy**, not a symlink: Omarchy's `omarchy-refresh-config` runs
`cp -f` without `--remove-destination`, so it writes *through* symlinks and would
overwrite files inside the repo (re-verified on 4.0's `/usr/bin/omarchy-refresh-config`).
`install.sh` copies instead, backs up first, and is idempotent.

Extra wallpapers are **pulled, not captured**: `install.sh --wallpapers[=<theme>|all]`
reads `manifests/wallpapers.tsv` from
[`omarchy-NTE-wallpaper`](https://github.com/CAI991108/omarchy-NTE-wallpaper), verifies
each sha256, and installs flat into `~/.config/omarchy/backgrounds/<theme>/`. The one
bundled wallpaper stays in `config/omarchy/backgrounds/catppuccin/` so a fresh install
still has a working desktop offline. `--wallpapers-only` runs just that part — bundled
image plus the optional pull — and skips every other deploy step, so wallpapers can be
refreshed without redeploying the desktop.

## What belongs in `config/`

A file belongs here when it **differs from `$OMARCHY_PATH/config/<same path>`**, or when
no shipped template exists and the file is deliberately maintained (`systemd/user/`,
`bin/`, `fontconfig/`). Two consequences worth stating outright:

- Anything that only reproduces a shipped default is **dropped** — `nvim/` (owned by the
  `omarchy-nvim` package), `btop.conf`, `herdr`'s upstream sample, `monitors.lua`
  (per-machine), `extensions/omarchy-menu.jsonc` while it matches the default.
- Runtime state written by an application is **never captured**: `user-dirs.*`,
  fcitx5's `cached_layouts`, auto-added `mimeapps.list` rows.

Capture is a whole-file **snapshot**; templates are not merged. That is what lets
`shell.json` — which `omarchy bar` rewrites wholesale — be restored, and it keeps
deployment copy-only.

## Capture convention: no absolute home paths

When capturing a config file, store home-relative paths as `~` (or `$HOME`), never
`/home/<user>/...`. `install.sh` deploys file *contents* verbatim — only symlink
*targets* are rewritten — so a hard-coded home path would break for any other
username. Example: the `SUPER+D` DSH binding is stored as
`~/.local/bin/dsh-web-open`; tilde expansion in Hyprland's `exec` is verified.

One deliberate deviation follows from Omarchy's own template: `config/git/config`
omits the `[user]` and `[credential]` sections (real name, school email, gh helper)
because the repo is public. Deploying it over a machine that already has them will
strip that identity — set it again after running `install.sh` on such a machine. The
same rule applies to capture: never copy the live `git/config` back into the repo.

## DSH

`dsh/` mirrors `~/.dsh` so the profile's relative `link:../../plugins/...` specs resolve
after deployment; `pnpm install` is a manual follow-up. The model provider in
`cordis.patch.yml` defaults to `deepseek-account` (the logged-in flow) — switching to an
API key means `deepseek-official`. `SUPER+D` runs `bin/dsh-web-open`, which starts the
headless `dsh-web.service` and opens the UI; see `dsh/README.md`.

## Agent skills

### Issue tracker

Issues and specs live as GitHub issues in this repo (via the `gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Five triage state roles (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`), each label string equal to its role name; `bug` and `enhancement` come from GitHub's defaults. See `docs/agents/triage-labels.md`.

### Domain docs

Domain docs use a **single-context** layout: one root `GLOSSARY.md` plus `docs/adr/`. See `docs/agents/domain.md`.
