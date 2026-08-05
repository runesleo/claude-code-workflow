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

---

## First-success productization review — PASS

Date: 2026-08-05

Branch: `codex/quietharness-first-success-20260805`

### Decision

The single-agent onboarding slice is **PASS with zero blockers** after independent product and installer-safety reviews. The default first experience now stays inside an isolated project, supports one client at a time, exercises observable behavior, and leaves user-level configuration untouched.

Public push, tag, release, external tester recruitment, and publication remain separate maintainer gates.

### Product changes reviewed

- The repository entrypoint now targets a maintainer using any one supported AI coding agent instead of requiring a three-client setup.
- Claude Code, Codex, and Cursor each have a project-scoped trial path with dry-run before apply.
- `examples/first-success/` creates an isolated failing checkout fixture with an unrelated user draft that must survive the repair.
- The fixture task describes only the business defect; it does not coach the reliability behaviors being observed.
- The first-success check covers inspection, preservation of unrelated work, a minimal repair, real validation, and truthful reporting.
- Cursor now mirrors the same core reliability boundaries, including proportional verification and confirmation before money or wallet actions.

### Findings resolved

1. The first fixture originally revealed the behaviors under evaluation. The task was reduced to the user-visible defect, and a regression test prevents coaching language from returning.
2. The first trial originally risked replacing user-level instruction files. Project-scoped Claude Code and Codex modes now join the existing Cursor project mode, and smoke tests prove that user-level paths remain untouched.
3. The Cursor adapter initially omitted several shared reliability boundaries. It now includes continuation, one-writer discipline, durable state, proportional verification, uncertainty reporting, and the full confirmation boundary.
4. Project-local intermediate symlinks could redirect a Cursor install outside the selected project. Physical-root containment is now checked before and after target-directory creation, with a regression reproducing the original escape attempt and proving zero outside writes.
5. An incomplete automatic restore could delete the surviving recovery backup. Cleanup now preserves and reports that backup, and a fault-injection test exercises the actual rollback failure branch.
6. Two rendered README images initially retained the old template total after their SVG sources changed. Both PNGs were regenerated at 1600×900 and visually checked; they now show the current 2,318-byte total.
7. One regenerated PNG randomly matched the task-ID scanner in compressed bytes. It was losslessly re-encoded; pixel comparison reports zero changed pixels and the full public-copy scan is clear.

### Verification evidence

- `./scripts/verify.sh` → `INVENTORY_SMOKE_OK`, `INSTALL_SMOKE_OK`, `FIRST_SUCCESS_SMOKE_OK`, `VERIFY_OK template_bytes=2318`
- ShellCheck → pass for the installer, verifier, demo scripts, and smoke tests
- installer failure injection → recovery backup preserved and reported when restore is forced to fail
- project-containment regression → intermediate Cursor symlink rejected with no outside file or directory created
- `git diff --check` → pass
- `xmllint --noout media/launch-v3/*.svg` → pass
- revised PNG files → 1600×900; direct visual inspection confirms `2,318 B` and no clipping
- lossless PNG re-encode comparison → `0 (0)` differing pixels
- `.git`-free public snapshot preflight → no private paths and no task IDs; license, README, and environment-ignore checks pass
- independent product review → approve, zero blockers
- independent installer-safety review → the two medium findings are closed; one narrow same-directory race remains low and non-blocking

### Remaining limitations

- The “ten-minute” first-success label is a target, not measured evidence. It must be timed by at least one real non-author before becoming a performance claim.
- The installer still uses predictable sidecar names. Exploitation requires another process with write access to the same target directory and winning a narrow race; exclusive-create staging can harden this later.
- A repeatable SVG-to-PNG consistency check would prevent stale rendered numbers from recurring. Current assets were manually and visually verified for this candidate.

### Gates

This review authorizes no public mutation. Push, tag, GitHub Release, repository rename, profile edits, tester outreach, and publication require Leo's explicit approval.
