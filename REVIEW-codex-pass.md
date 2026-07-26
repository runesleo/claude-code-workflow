# Independent release review — PASS

Date: 2026-07-26

Branch: `codex/v3-lean-workflow`

Base: `origin/main` at `c014a5aeaba60b18525b8c8d58790b91a7433677`

## Decision

An independent read-only reviewer evaluated the v3 release candidate without editing the branch. Final result: **PASS, zero blockers**.

This is intentionally one coherent breaking-release slice. The large file count is mostly deletion of the v2 rule, memory, skill, agent, and command bundles. v2 remains recoverable from Git history and `MIGRATION-v3.md` documents a disable-first migration.

## Findings resolved during review

1. The original migration inventory omitted active `rules`, `commands`, `AGENTS.override.md`, and symlinks. It was replaced with a tested read-only inventory command that includes ordinary files, nested rules/commands, and whole-directory symlinks.
2. The first installer followed a target-file symlink and could overwrite the linked file. The installer now preserves a file symlink as a symlink backup, removes the target entry, and installs locally.
3. The first multi-target flow could modify Claude/Codex before discovering an invalid Cursor target. All targets now pass preflight, staging, and backup before replacement begins; failures roll back applied targets.
4. A macOS-specific `mv` behavior could move a staged file into a symlinked directory. File targets resolving to directories are now rejected, with a fixture proving the external directory stays untouched.
5. The final non-blocking warning about nested `rules/team/*.md` and `commands/team/*.md` was fixed and independently rechecked: `PASS`.

## Product identity correction

After maintainer feedback, the release title was restored to **Claude Code Workflow v3**. This is a major version of the existing `claude-code-workflow` project, not a new product named “Lean AI Workflow.” The lighter default runtime remains the substantive v3 change; the repository identity and history remain continuous.

An independent follow-up review checked the corrected titles, continuity statement, links, file layout, and measured template size. Result: **PASS, zero blockers and zero warnings**.

## Verification evidence

- `./scripts/verify.sh` → `INVENTORY_SMOKE_OK`, `INSTALL_SMOKE_OK`, `VERIFY_OK template_bytes=2287`
- ShellCheck → pass for all scripts and smoke tests
- Bash 3.2 syntax and execution → pass
- `git diff --check` → pass
- Open-source preflight snapshot → no private paths, task IDs, or missing public baseline files
- Strong-pattern Git history secret scan → pass
- v2 byte baseline → 16,379 bytes; v3 public templates → 2,287 bytes

Push, tag, GitHub Release, and public posting remain outside this review and require the maintainer's explicit approval.
