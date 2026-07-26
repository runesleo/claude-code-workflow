# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses semantic versioning for tagged releases.

## [Unreleased]

### Changed

- Introduced the **QuietHarness** product name for the same repository and history formerly published as Claude Code Workflow.
- Rebuilt the project as a low-ceremony workflow for Claude Code, Codex, and Cursor.
- Replaced the rule-heavy hot path with a 1.6 KB shared core and thin client adapters.
- Changed persistence from mandatory end-of-session cleanup to writeback at the point of state change.
- Separated scheduled daily-report generation from interactive startup and closeout rituals.
- Made `README.md` the English default and kept an original Chinese `README.zh.md`.

### Added

- Dry-run-first transactional installer with preflight, exact symlink backups, rollback, and `CODEX_HOME` support.
- Read-only inventory command that includes ordinary instruction files and whole-directory symlinks.
- Isolated installer smoke test and repository verification script.
- v2-to-v3 migration and rollback guide.
- Daily-report delivery guide covering pull, exception notification, and opt-in push.
- Optional Personal → Workspace → Task reference architecture that leaves the installed core unchanged.
- Sanitized solo-builder examples for private overlays, workspace scopes, per-task records, bounded readout, change-time writeback, and freshness checks.
- MIT license file.

### Removed

- Mandatory subagent dispatch and multi-model cross-verification rules.
- Automatic skill routing, memory flush, Morning, Today, and session-end assumptions.
- Bundled daily state templates, custom agent definitions, and slash-command pipelines.
- Duplicate `README.en.md` entrypoint.

### Security

- The installer performs no network, account, credential, scheduler, or production operations.
- Private paths and live personal state are explicitly excluded from shipped templates.
- Continuity examples contain neutral placeholders only and are never installed or loaded automatically.

## [2.0.0] - 2026-04-05

### Added

- Hook-driven enforcement, plan gating, mandatory subagent routing, daily memory, and session closeout.

### Deprecated

- v2 is retained in Git history for users who intentionally want the old workflow. It is not the default direction after v3.

## [1.0.0] - 2026-02-22

### Added

- Initial public Claude Code workflow template.
