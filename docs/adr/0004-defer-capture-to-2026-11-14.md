# Defer the next capture to 2026-11-14: one sync, not piecemeal

**Status:** accepted (2026-11-01)

The tree in `config/`, `dsh/` and `bin/` was re-captured from the live machine at the
4.0 cut (2026-10-31), but the machine has kept moving since. Capturing each change as
it lands would produce a chain of capture PRs that are superseded within days, so the
next capture is deferred to **2026-11-14** and done as a single pass that also
re-captures `packages/`.

## Context

- `docs/omarchy-4.md` §2 already describes the capture procedure; `AGENTS.md` holds the
  criterion (a file belongs in `config/` when it differs from
  `$OMARCHY_PATH/config/<same path>`, or no template exists but it is deliberately
  maintained).
- [ADR-0002](0002-omarchy-4-cut.md) left `packages/` as a 3.8.2-era snapshot and made
  re-running `pacman -Qe` a separate, human-reviewed step. The 2026-10-31 retro recorded
  that re-capture as scheduled for 2026-11-14.
- On 2026-11-01 the machine is still being changed (terminal fonts, fcitx5 default input,
  bar clock format, DSH provider preference, four local hooks), and `./install.sh
  --dry-run` reports 15 files where repo and live differ.

## Considered options

- **Capture per change as it happens** — rejected: the machine is still settling, so each
  capture would be superseded within days, and reviewing a run of small PRs costs more
  than one pass.
- **Capture only the unrecorded drift now, the rest later** — rejected: the same files
  would be reviewed twice.
- **Wait for the next generation (ADR-0002's 5.x criterion)** — rejected: `packages/` and
  the drift would be stale for months, and ADR-0002 already gave packages an earlier date.

## Consequences

- Until 2026-11-14: **do not capture** live changes and **do not deploy** the repo tree
  (A1 stays paused). Deploying now would revert newer live values — fcitx5's
  `ActiveByDefault`, the bar clock format, and the terminal font.
- The deferral is tracked as issue #16 (child of map #4) plus a reminder on the same date;
  that ticket carries the drift baseline recorded on 2026-11-01.
- ADR-0002's "`packages/` stays a 3.8.2-era snapshot" is superseded in part: packages are
  re-captured in the same pass.
- The capture criterion does not change, and capture stays whole-file snapshot.
- 2026-11-14 is a deadline for "the machine has settled", not a hard wall: if it has not,
  say so on #16 and move the date rather than capturing a moving target.
