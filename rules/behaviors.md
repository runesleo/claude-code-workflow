# Behavior Rules for Claude Code

> **NOTICE**: This file is a specific target rendering execution adapter for Claude Code.
> General policies (Task Routing, Debugging Protocols) are now defined strictly in `core/policies/behaviors.yaml` and `core/policies/task-routing.yaml`.

## Critical Local Rules

### VPS Code Deployment Rule (if applicable)

**Never `git commit` / `cherry-pick` / SSH-edit code files (.ts/.mjs/.py) on VPS.**
Only flow: `local edit → local commit → push → VPS pull`. Runtime config (.env/state.json) excepted.
Violating this = branch divergence → pull conflicts → 10x cleanup time. **No exceptions.**

### Quality Control Triggers

**Core triggers (kept here to avoid missing)**:
- Processing external URLs / citing others → must annotate source, warn if unverifiable
- Critical code → think from attacker's perspective + list 3 risk points
- >20 conversation turns / >50 tool calls → suggest fresh session
- Discovered error/hallucination → immediately isolate context, don't write to memory
- Citing content for sharing → force multi-model cross-verification

## Local Execution Adapter
- Always load project-specific `.env.local` when executing Node scripts.
- For `memory_add` tool calls, format the input to target ONLY one of the 3 active memory layers:
  1. `memory/session.md`
  2. `memory/project-knowledge.md`
  3. `memory/overview.md`
- When completing a task, output the result cleanly and prompt the user if they'd like a git commit immediately.

## Portable Core SSOT
- Provider-neutral workflow spec lives under `core/`
- `core/policies/behaviors.yaml` is the portable source for behavior-level policy that target renderers consume.
- Repo-specific deviations should prefer `.vibe/overlay.yaml` or `bin/vibe --overlay ...` instead of mutating shared defaults.
- When changing routing, skills, safety, or behavior policy: update `core/` first, then run `make generate` to sync target-facing files.

## Documentation Structure (Local Target overrides)
- Project-level: only keep `PROJECT_CONTEXT.md` + `CHANGELOG.md` (optional)
- Banned files: ROADMAP/FOCUS/TODO/TASKS/STATUS
