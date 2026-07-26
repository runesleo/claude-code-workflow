# v3.0.0 — Lean AI Workflow

v3 reverses the direction of v2.

Instead of adding more always-loaded rules, hooks, routing, and closeout steps, it ships a 1.6 KB shared core with thin adapters for Claude Code, Codex, and Cursor.

## Highlights

- Direct work by default; no mandatory Morning, Today, or session-end ritual.
- Durable state is written when it changes, not collected in a final sweep.
- Migration leaves an existing daily-report scheduler untouched; its output is verified separately and read on demand.
- Transactional installer: dry-run first, all-target preflight, exact symlink backups, rollback on failure, and `CODEX_HOME` support.
- Read-only inventory catches old rule files and symlinked `rules`, `commands`, or `skills` directories before migration.
- Complete v2-to-v3 migration and rollback guide.
- English default README plus an original Chinese edition.

## Breaking changes

- v2 rule, memory, skill, agent, and command bundles are removed from the default branch.
- Existing users should follow `MIGRATION-v3.md` and disable old discovery paths before installing v3.
- Cursor global rules remain a manual application setting; the installer writes project rules only.

## Verification

Run:

```bash
./scripts/verify.sh
```

No push, tag, or GitHub Release should be created until the release review has zero blockers.
