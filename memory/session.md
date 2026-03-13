# Session Memory

> **Hot Layer**: Active tasks, session progress, crash recovery.
> 
> This file replaces the previous `today.md` + `active-tasks.json` combination.
> Updated automatically during non-trivial tasks.

## Current Session

### S1 (~21:40) Project optimization based on review feedback
- Addressed review findings from review/review-with-workflow.md
- Created docs/README.md as unified documentation index
- Added Documentation Map section to README.md
- Created GitHub Actions CI/CD workflow (.github/workflows/ci.yml)
- Created JSON Schema files for YAML validation (schemas/)
- Created bin/validate-schemas script for schema validation
- Updated Makefile with schema validation target
- Next: verify all changes and commit
- Experience recorded: yes (see project-knowledge.md)

## In-Flight Tasks (Cross-Session)

<!-- 
  Tasks that span multiple sessions are tracked here.
  Format:
  - [ ] **T001**: [Title] ([Project]) — Status: active/blocked/waiting
    - Context: [current state]
    - Next action: [specific step]
    - Blocker: [if any]
    - Created: YYYY-MM-DD | Updated: YYYY-MM-DD
-->

- [ ] **T001**: Optimize project based on review feedback (claude-code-workflow) — Status: active
  - Context: Review identified documentation scattering and need for CI/CD
  - Next action: Verify all changes and commit
  - Blocker: none
  - Created: 2026-03-07 | Updated: 2026-03-07

