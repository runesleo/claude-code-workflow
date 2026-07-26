# QuietHarness v3.0.0

v3 reverses the direction of v2.

QuietHarness is the new product name for the same repository and Git history previously published as **Claude Code Workflow**. The repository URL remains unchanged for continuity.

The target user is now explicit: developers who use coding agents across real projects and have accumulated enough rules, hooks, skills, memory, and session rituals that the configuration itself has become work.

Instead of adding more always-loaded rules, hooks, routing, and closeout steps, it ships a 1.6 KB shared core with thin adapters for Claude Code, Codex, and Cursor.

## Highlights

- Direct work by default; no mandatory Morning, Today, or session-end ritual.
- Durable state is written when it changes, not collected in a final sweep.
- Migration leaves an existing daily-report scheduler untouched; its output is verified separately and read on demand.
- Transactional installer: dry-run first, all-target preflight, exact symlink backups, rollback on failure, and `CODEX_HOME` support.
- Read-only inventory catches old rule files and symlinked `rules`, `commands`, or `skills` directories before migration.
- Complete v2-to-v3 migration and rollback guide.
- English default README plus an original Chinese edition.
- Four [launch visuals](media/launch-v3/) that explain the three-layer model, before/after workflow, and rule-placement test without repeating context-size marketing.

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
