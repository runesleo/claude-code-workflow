# OpenCode Target

OpenCode is a strong bridge target because it can work with repo rules, permission policies, and Claude-style assets with lighter adaptation.

## Minimum Common Primitives

- `AGENTS.md` or equivalent repo instructions
- OpenCode config and permission rules
- repo-local SSOT files
- reusable skills or agents where the host supports them

## Portable Mapping

- `core/models/*.yaml` -> configured target profile and routing guidance
- `core/skills/registry.yaml` -> native OpenCode skills, reused Claude-style skills, or agent templates
- `core/security/policy.yaml` -> permission rules and wrapper enforcement

## Phase 1 Notes

- Use OpenCode as an early cross-target proving ground after Claude Code.
- Keep the portable skill IDs stable even when the physical skill files are shared.
- Prefer host-native permission controls for `P0/P1` enforcement.

## Phase 2 Build Output

- `bin/vibe build --target opencode` generates `AGENTS.md`, `opencode.json`, and modular instruction files.
- The generated `opencode.json` uses the documented `instructions` field to load the rendered workflow docs.

## Phase 3 Additions

- `bin/vibe switch opencode` applies the generated OpenCode config into the current repo root by default.
- The generated OpenCode output now includes dedicated routing and execution modules in addition to general, skills, and safety guidance.
- Phase 4 also renders a `permission` block in `opencode.json` so safety policy influences OpenCode’s native permission layer.
