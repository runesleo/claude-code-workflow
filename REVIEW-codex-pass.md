# Independent release review — PASS

Date: 2026-07-26

Branch: `codex/v3-lean-workflow`

Reviewed base: `9c1f6ae8d5959be5fab496084f3fab017027a543`

## Decision

An independent read-only reviewer evaluated the current-system rewrite from scratch. After one repair pass, the release candidate is **PASS with zero blockers and zero warnings**.

Public push, tag, GitHub Release, repository rename, profile edits, and X publication remain separate maintainer gates.

## What this release now represents

QuietHarness v3 is not an anonymous workflow generated from a blank page. It is the sanitized public map of Leo's current AI work system:

- one 1,604-byte shared Core for Claude Code, Codex, and Cursor, with thin client adapters;
- nine stable business lines and workspaces;
- per-task truth, owner/worker separation, bounded readout, change-time writeback, freshness, and claims;
- one writer per mutable repository or task surface, with delivery and rollback receipts;
- reports, sync jobs, and monitors outside the interactive hot path;
- links to open-source branches that grew from prediction-market, research, content-ingest, video, health, and system-audit work.

The public version keeps the topology, lifecycle, contracts, and reasons behind the design. It removes absolute paths, thread identifiers, live task state, accounts, credentials, positions, health data, customers, schedulers, VPS details, and production controls.

Chinese is the source and default repository language in `README.md` and the default documentation files. English compatibility mirrors use `.en.md`. The English README deliberately reuses the Chinese system map rather than claiming a fully mirrored visual set.

## Findings resolved

1. The first sanitized task and readout mirrored the active release too closely. They now use an explicitly synthetic, historical research-freshness scenario with `example_only: true`, no live claim, no release gate, and no current task identifiers.
2. Two diagrams initially labeled the 2,292-byte three-template total as the Core size. They now distinguish the 1,604-byte shared Core from the 2,292-byte combined template total.
3. The system map now uses the full `Products & Growth` business-line name.
4. A rendered PNG happened to contain a random compressed byte sequence matching `T###`. It was re-encoded; the visible image and 1600×900 dimensions are unchanged, and the task-ID scanner is clear.
5. The uncertain `long-media-cli` link was checked through the GitHub API and confirmed public.
6. Repository instructions and the v3 migration guide were aligned with the Chinese-source decision. `MIGRATION-v3.md` is now Chinese, `MIGRATION-v3.en.md` is its compatibility mirror, and the verifier checks both directions.

## Verification evidence

- `./scripts/verify.sh` → `INVENTORY_SMOKE_OK`, `INSTALL_SMOKE_OK`, `VERIFY_OK template_bytes=2292`
- ShellCheck → pass for repository shell scripts and smoke tests
- `git diff --check` → pass
- default `templates/`, `scripts/install.sh`, `scripts/inventory.sh`, and `tests/` → unchanged from the reviewed base
- three synthetic example JSON files → parse successfully
- `xmllint --noout media/launch-v3/*.svg` → pass
- five PNG files → 1600×900; revised 00 and 04 cards visually inspected with no clipping or overlap
- public-copy scan → no private paths, task IDs, thread IDs, wallet-like strings, or secret-like tokens
- open-source preflight on a `.git`-free filesystem snapshot → pass after adding a temporary `README.zh.md` compatibility copy inside the snapshot only
- independent second-pass review → PASS, zero blockers and zero warnings
- independent language-alignment review → PASS; Chinese and English commands, safety semantics, links, and rollback instructions match

The preflight script still assumes `README.md` is English and requires a separate `README.zh.md`. This release intentionally reverses that convention: Chinese lives at `README.md`, English at `README.en.md`, and no duplicate `README.zh.md` is shipped. The temporary compatibility copy was used only to exercise the scanner's privacy, task-ID, license, and environment checks; it was not added to the repository.

## Remaining non-blocking limitation

The English README embeds the Chinese system-map image. This matches the Chinese-source / English-compatibility decision, but a fully localized English visual can be added later if actual usage justifies it.

## Gates

This review authorizes no public mutation. Push, tag, GitHub Release, repository rename, profile edits, and X publication require Leo's explicit approval.
