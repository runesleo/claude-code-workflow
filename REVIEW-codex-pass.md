# Independent release review — PASS

Date: 2026-07-26

Branch: `codex/v3-lean-workflow`

Base: `origin/main` at `c014a5aeaba60b18525b8c8d58790b91a7433677`

## Decision

Independent read-only reviewers completed the final brand, optional-continuity, visual, and release rechecks: **PASS, zero blockers and zero warnings**. Public push, tag, GitHub Release, repository rename, and X publication remain separate maintainer gates.

This is intentionally one coherent breaking-release slice. Most of the large diff is deletion of the v2 rule, memory, skill, agent, and command bundles. v2 remains recoverable from Git history, and `MIGRATION-v3.md` documents a disable-first migration.

## Engineering findings resolved

1. The original migration inventory omitted active `rules`, `commands`, `AGENTS.override.md`, and symlinks. It was replaced with a tested read-only inventory command that includes ordinary files, nested rules/commands, and whole-directory symlinks.
2. The first installer followed a target-file symlink and could overwrite the linked file. The installer now preserves a file symlink as a symlink backup, removes the target entry, and installs locally.
3. The first multi-target flow could modify Claude/Codex before discovering an invalid Cursor target. All targets now pass preflight, staging, and backup before replacement begins; failures roll back applied targets.
4. A macOS-specific `mv` behavior could move a staged file into a symlinked directory. File targets resolving to directories are now rejected, with a fixture proving the external directory stays untouched.
5. The final non-blocking warning about nested `rules/team/*.md` and `commands/team/*.md` was fixed and independently rechecked.

## Product identity and boundary

The cross-client v3 product name is **QuietHarness**, with the positioning line “a low-ceremony workflow reset for Claude Code, Codex, and Cursor.” It is the next major version of the same repository and Git history formerly published as **Claude Code Workflow**; prior attribution is preserved and the existing repository URL remains unchanged for continuity.

The primary user is an independent developer, AI coding power user, or small team already maintaining enough global rules, hooks, skills, memory, routing, and closeout flows that configuration debt has become part of the work.

The release ships a small shared core, thin Claude/Codex/Cursor adapters, read-only inventory, a transactional installer, verification, a migration guide, and an optional Personal → Workspace → Task reference architecture. The reference layer consists of contracts, documentation, and sanitized examples; it does **not** install a task database, adapter CLI, scheduler, cross-chat dispatcher, optional capability pack, or private state. Existing systems remain replaceable and outside the interactive hot path.

Initial exact-name and package screening found no direct AI product named QuietHarness. This is collision screening, not trademark clearance; `Harness` remains a common agent-engineering term.

## Brand follow-up findings resolved

1. The previous review still described the release as “Claude Code Workflow v3” and retained a stale byte count. This review now reflects QuietHarness and the measured 2,292-byte three-template total.
2. The first X draft implied that the repository preserved or shipped all professional capabilities. It now states that users can keep their existing capabilities on demand and explicitly names the smaller set this release actually ships.
3. The first launch draft repeated the maintainer's recent configuration-slimming argument. It was replaced with a continuation story: how bounded readout, freshness, change-time writeback, and receipts preserve continuity after slimming.
4. The official preflight scanner found a random task-ID-shaped byte sequence inside one compressed PNG. The image was re-encoded, the visible content and dimensions were rechecked, and the same scanner then returned exit 0 on a filesystem snapshot.
5. The four visuals now cover the continuity problem, optional Personal → Workspace → Task scopes, protocol flow and owner/worker boundary, and the exact public/private delivery boundary.

## Optional continuity follow-up

The new reference layer was independently reviewed from scratch. Final result: **PASS, zero blockers and zero warnings**.

- `AGENTS.md`, `CLAUDE.md`, all installed templates, `scripts/install.sh`, `scripts/inventory.sh`, and installer tests are byte-for-byte unchanged from the accepted QuietHarness brand commit.
- The public examples contain neutral scopes and relative placeholders only. They do not contain maintainer paths, task IDs, identity, account data, business names, or live priorities.
- Conceptual `task-read`, `task-writeback`, and `task-sync` interfaces are explicitly labeled as examples that QuietHarness does not install.
- The initial unmeasured “ten-minute” wording was removed. The final copy promises only a minimal first-success walkthrough.
- The revised X draft's completion claims match the files in the release tree, and its continuity angle is materially different from the maintainer's recent slimming posts.

## Verification evidence

- `./scripts/verify.sh` → `INVENTORY_SMOKE_OK`, `INSTALL_SMOKE_OK`, `VERIFY_OK template_bytes=2292`
- ShellCheck → pass for all scripts and smoke tests
- Bash 3.2 syntax and execution → pass
- `git diff --check` → pass
- `xmllint --noout media/launch-v3/*.svg` → pass
- Both sanitized JSON examples parse successfully
- Four rendered PNGs → 1600×900; visual inspection found no overlap, clipping, private path, or misleading performance claim
- Open-source preflight on a filesystem snapshot excluding the worktree's private `.git` pointer → exit 0; no private paths or task IDs
- Strong-pattern Git history secret scan in the worktree → pass
- v2 Claude byte baseline → 16,379 bytes; QuietHarness Claude path → 1,772 bytes; all three public templates → 2,292 bytes
- First-party X timeline comparison → recent 48-hour posts reviewed; launch draft now focuses on post-slimming continuity, three state scopes, three protocols, and the delivery boundary instead of repeating the earlier metrics

The direct preflight command cannot be used on a linked Git worktree without a false positive because its `.git` pointer is a file containing the local absolute path; the public filesystem snapshot is the release-tree check. The Git history secret scan was therefore run separately in the real worktree.

## Remaining limitations and gates

- Naming research is an initial collision screen, not legal trademark advice.
- The installer backs up files it overwrites; disabling older Skills, Hooks, Commands, and duplicate discovery paths is still a guided migration rather than a one-click cleanup.
- Four 16:9 visuals are available in a tested publication order; their SVG sources remain editable.
- No public mutation is covered by this review. Push, tag, GitHub Release, repository rename, and X publication require explicit maintainer approval.
