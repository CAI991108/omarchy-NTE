# A second machine stays on 3.8, so the 3.8 line becomes a long-lived branch

**Status:** accepted (2026-11-01), supersedes the branch policy of
[ADR-0002](0002-omarchy-4-cut.md)

ADR-0002 assumed the 3.8 tree was history: freeze it as the tag `omarchy-3.8.2` and
never touch it again. That holds only if no machine keeps running 3.8. A second
machine does, and it will not be upgraded, so the 3.8 tree is a **second deployment
target**, not an archive. It now lives on the long-lived branch `legacy/3.8`, cut from
the tag `omarchy-3.8.2` (`4ec86de`) and never merged back into `main`.

## Considered options

- **Keep the tag only** — rejected: a tag cannot receive commits, and the 3.8 machine
  will occasionally need a fix (a terminal include, a package rename).
- **Dual-track directories inside `main`** (`config/` plus `config-3.8/`) — rejected,
  same reason as ADR-0002: one working copy would carry two installers and two sets of
  assumptions about `omarchy-refresh-config`, hooks, and theme state.
- **A separate repository** — rejected: the two machines share most of `config/` (git,
  fcitx5, nvim, mimeapps); a fork would drift silently and split the history.
- **Name the branch `omarchy-3.8.2`** — rejected: a branch and a tag sharing a name make
  `git checkout omarchy-3.8.2` ambiguous, and every script that names the tag would need
  `refs/tags/` disambiguation.

## Consequences

- Two deploy paths, deliberately not sharing code: `main` for the 4.0 machine,
  `legacy/3.8` for the 3.8 machine. A change that matters to both is cherry-picked,
  never merged across the cut.
- The tag `omarchy-3.8.2` stays as the cut-day snapshot, so the 4.0 docs keep pointing
  at a stable tree (`git show omarchy-3.8.2:config/...` still resolves).
- `install.sh` keeps its own assumptions on each branch. Nothing tries to be
  version-agnostic across the cut — that was the trap ADR-0002 was written to avoid.
- `legacy/3.8` does not track upstream releases. It changes only when that machine needs
  it, and its commits are the only commits there.
- Whatever is learned on the 3.8 machine that also applies to 4.0 arrives in `main` as a
  fresh commit, not as a merge, so the 4.0 docs never inherit 3.8-only history.
