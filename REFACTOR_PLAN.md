# Architecture Optimization Plan

Based on the AI coding agent governance framework review, this plan addresses the key architecture and engineering issues to improve reliability and reduce maintenance overhead.

## Phase 1: P0 Critical Fixes

### 1. Address CLAUDE.md Duplication ✅ COMPLETED
- **Issue:** Project-level `CLAUDE.md` and global `~/.claude/CLAUDE.md` overlap significantly, violating SSOT.
- **Action:** Refactor `CLAUDE.md` in the project root. Make it an overlay/entrypoint that references the global template where appropriate, removing duplicated boilerplate.
- **Result:** Reduced from ~190 lines to ~21 lines. Now references `~/.claude/CLAUDE.md` for base configuration.

### 2. Introduce Automated Validation Pipeline ✅ COMPLETED
- **Issue:** No CI or local checks to ensure `core/` YAML files are valid or that generated Markdown matches the source.
- **Action:** Create a `Makefile` with a `validate` target. Use `bin/vibe inspect` and lightweight YAML schema checks (via ruby or bash) to prevent configuration drift.
- **Result:** `Makefile` created with `validate`, `generate`, `inspect`, and `clean` targets.

## Phase 2: P1 Architecture Improvements

### 3. Fix Abstraction Leakage in `rules/behaviors.md` ✅ COMPLETED
- **Issue:** `rules/behaviors.md` contains cross-target general policies (e.g., Task Complexity Routing, Debugging Protocol) that belong in `core/`.
- **Action:** Move general policies from `rules/behaviors.md` to `core/policies/behaviors.yaml` and `core/policies/task-routing.yaml`. Keep only Claude-specific adapters in `rules/behaviors.md`.
- **Result:** Reduced from ~263 lines to ~22 lines. References `core/policies/` for general policies.

### 4. Simplify the Memory Layer ✅ COMPLETED
- **Issue:** Writing to 7 different memory files per session is token-heavy and error-prone.
- **Action:** Consolidate memory targets in `rules/memory-flush.md` and related files into 3 levels:
  - `session.md` (combines today.md + active-tasks.json)
  - `project-knowledge.md` (combines MEMORY.md + patterns.md)
  - `overview.md` (combines projects.md + goals.md + infra.md)
- **Result:** Deleted 7 template files, created 3 new files with proper documentation headers.

### 5. Executable Render Pipeline ✅ COMPLETED
- **Issue:** Lack of transparent script to enforce rendering from `core/` to target outputs like `AGENTS.md`.
- **Action:** Add `make generate` to the `Makefile` utilizing the existing `bin/vibe build` capability.
- **Result:** `make generate` builds all 9 supported targets.

## Phase 3: P2 Cleanup

### 6. Refine Skill Triggers ✅ COMPLETED
- **Issue:** `rules/skill-triggers.md` mixes universal rules with domain-specific logic (e.g., URL Fetch Routing was removed but may need relocation rather than deletion).
- **Action:** Extract domain-specific routing into a project-specific overlay or restore if still needed.
- **Result:** URL Fetch Routing restored as a local overlay comment block (lines 56-82). Universal rules remain in `core/`, local mappings stay in `rules/`.

---

## Summary

| Phase | Status | Items | Progress |
|-------|--------|-------|----------|
| P0 Critical | ✅ Complete | 2/2 | 100% |
| P1 Architecture | ✅ Complete | 3/3 | 100% |
| P2 Cleanup | ✅ Complete | 1/1 | 100% |

**All planned refactoring items have been completed.**
