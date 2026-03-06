# Claude Code Target

Claude Code is the current first-class runtime target for this repository.

## Native Primitives

- `CLAUDE.md` for top-level instruction and memory entry
- `rules/` for always-loaded behavior guidance
- `docs/` for on-demand reference
- `skills/` for reusable native skills
- `agents/` and `commands/` for host-facing specialization
- hooks or permissions for stronger runtime safety enforcement

## Portable Mapping

- `core/models/*.yaml` -> `rules/behaviors.md` and `docs/task-routing.md`
- `core/skills/registry.yaml` -> `rules/skill-triggers.md` plus `skills/*/SKILL.md`
- `core/security/policy.yaml` -> `docs/content-safety.md` and any hook or permission policy
- future portable policy files -> `rules/` and `docs/` renderings

## Phase 1 Notes

- The current repository layout is already the Claude Code target.
- During migration, update `core/` first, then sync the Claude-facing markdown.
- Keep current skill names stable unless the portable registry changes first.

## Phase 2 Build Output

- `bin/vibe build --target claude-code` materializes a Claude-ready config tree.
- `bin/vibe use --target claude-code --destination ~/.claude` applies it to a Claude config directory.

## Phase 4 Additions

- The generated Claude output now includes a `settings.json` permission baseline derived from the portable safety policy.
- `.vibe/claude-code/behavior-policies.md` and `.vibe/claude-code/safety.md` mirror the portable behavior and safety schema for traceability.
