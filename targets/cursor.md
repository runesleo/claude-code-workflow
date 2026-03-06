# Cursor Target

Cursor should render the portable workflow through rules and project-scoped context, not through a fake Claude-style skill layer.

## Minimum Common Primitives

- `.cursor/rules/` for always-on, auto-attached, or manually attached rules
- project memories or sidecar context as cache
- repo-local SSOT files for durable project state
- manual or rule-triggered review flows for skill-like behavior

## Portable Mapping

- `core/models/*.yaml` -> rule guidance for routing and model selection
- `core/skills/registry.yaml` -> rule bundles, manual prompts, or reusable review checklists
- `core/security/policy.yaml` -> blocking or warning rules plus external wrapper enforcement where needed

## Phase 1 Notes

- Treat Cursor memories as convenience, not as the canonical workflow memory.
- Encode portable mandatory behavior in always-on rules first.
- Degrade optional skills into attached rules or manual invocation patterns.

## Phase 2 Build Output

- `bin/vibe build --target cursor` generates root `AGENTS.md` and `.cursor/rules/*.mdc`.
- The phase-2 generator currently splits always-on behavior from optional skill reference rules.

## Phase 3 Additions

- `bin/vibe switch cursor` applies Cursor-oriented files into the current repo root by default.
- The generated Cursor output now separates core, routing, safety, and optional-skill rules, with supporting notes under `.vibe/cursor/`.
- Phase 4 also generates `.cursor/cli.json` with a conservative permission baseline derived from the portable safety policy.

## Phase 5 Additions

- Cursor builds can now merge a project overlay into `.cursor/cli.json`, profile mapping, and the generated support docs.
- Destination repos with `.vibe/overlay.yaml` get that overlay automatically when using `bin/vibe use` or `bin/vibe switch`.

## Phase 6 Additions

- Task routing and test standards are now generated under `.vibe/cursor/task-routing.md` and `.vibe/cursor/test-standards.md`.
- These policies enable complexity-aware workflow adaptation for AI assistants working in Cursor.
