# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Architecture improvements: dependency injection container, enhanced error handling, thread-safe YAML loading
- SimpleCov test coverage enforcement (50% threshold, currently 62.76%)
- Performance benchmarks for critical operations (`test/benchmark/`)
- Command registry pattern for better CLI extensibility
- 5 new test files: `test_vibe_container.rb`, `test_vibe_utils_validation.rb`, and 3 benchmark scripts
- Cross-module dependency documentation to `lib/vibe/init_support.rb`
- CHANGELOG.md following Keep a Changelog format

### Changed
- Modularized CLI from 9 to 10 Ruby modules (added `lib/vibe/container.rb`)
- Enhanced `lib/vibe/errors.rb` with context support for better debugging
- Updated `lib/vibe/utils.rb` with documented lenient mode for `deep_merge`
- Improved CI workflow with SimpleCov integration and coverage checks
- Updated README files to reflect architecture improvements (English + Chinese)

### Fixed
- Fixed `bin/vibe-smoke` missing `kimi-code` target in TARGETS array
- Fixed `test/test_vibe_overlay.rb` missing `antigravity` and `vscode` in SUPPORTED_TARGETS
- Fixed `rtk_hook_configured?` type safety by adding String type guard before `include?` call
- Fixed `validate-schemas` YAML loading to use `YAML.safe_load` with aliases support
- Fixed SimpleCov output format compatibility (support both `line` and `covered_percent` keys)
- Updated model name examples in `doc_rendering.rb` to use current Claude 4.6/4.5 model IDs
- Updated copyright year to 2026 in README files

## Phase 7 — Kimi Code Integration (2026-03)

### Added
- Kimi Code target support with native Chinese documentation
- Comprehensive CI drift protection for all 8 targets
- Parameterized snapshot testing framework
- Integration detection for all targets

### Changed
- Consolidated renderers and implemented quickstart command
- Repaired CI drift protection steps

## Phase 6 — Multi-Target Expansion (2026-02)

### Added
- Antigravity target support
- VS Code target support
- Warp terminal target support
- OpenCode target support
- Cursor target support
- Codex CLI target support

### Changed
- Refactored to portable core + target rendering architecture
- Unified skill registry system across all targets

## Phase 5 — Overlay System (2026-01)

### Added
- Overlay system for project-specific customization
- Profile mapping overrides
- Target-specific permission patches
- Policy append/merge capabilities

## Phase 4 — Skill System (2025-12)

### Added
- Portable skill registry (`core/skills/registry.yaml`)
- Skill security audit framework
- External skill pack integration support
- Namespace support for third-party skills

## Phase 3 — Policy Framework (2025-11)

### Added
- Behavior policy system (`core/policies/behaviors.yaml`)
- Task routing by complexity tiers
- Testing standards by task complexity
- Delivery standards and quality gates

## Phase 2 — Core Architecture (2025-10)

### Added
- Portable core specification under `core/`
- Provider-neutral workflow definitions
- Model tier abstraction layer
- Target adapter pattern

## Phase 1 — Foundation (2025-09)

### Added
- Initial Claude Code workflow template
- Memory system (auto memory + patterns)
- SSOT ownership model
- Basic documentation structure

---

This project is a fork of [@runes_leo](https://x.com/runes_leo)'s original claude-code-workflow, enhanced for maintainability and extended to serve Chinese developers.
