# Wallpapers are pulled from `omarchy-NTE-wallpaper` by manifest

**Status:** accepted (2026-10-27)

`omarchy-NTE` must stay a small, clone-and-run config repo, while the wallpaper
collection should grow independently. `install.sh --wallpapers` therefore pulls images
from the separate `omarchy-NTE-wallpaper` repo through one manifest
(`manifests/wallpapers.tsv`): `<base>/<file>` is downloaded, verified with sha256, and
installed flat into `~/.config/omarchy/backgrounds/<theme>/`. The flag is off by
default, so a plain `./install.sh` never touches the network; exactly one wallpaper
stays bundled here so a fresh install has a desktop offline.

## Considered options

- **Bundle every wallpaper here** — rejected: each clone grows by the full collection,
  and git history cannot shrink when images are replaced.
- **Git LFS** — rejected: clients need `git-lfs`, and other people's downloads count
  against the owner's free bandwidth quota.
- **A manual download page only** — rejected: no idempotent, verifiable install path.
- **A separate config file listing URLs** — rejected: the manifest already carries
  paths, sizes and checksums, so a second list would drift.

## Consequences

- The manifest columns and paths are a public interface: changing them is a two-repo
  change (`omarchy-NTE/install.sh` in the same session).
- The installer is network-optional: `--dry-run` fetches nothing, and network or
  checksum failures are warnings so config deployment still completes.
- Moving images to GitHub Releases later only changes the base URL, not the manifest
  shape.
- Omarchy scans `backgrounds/<theme>/` with `find -maxdepth 1`, so installs stay flat
  and are indexed by `basename(file)`.
