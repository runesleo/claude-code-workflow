# Warp Target

Warp should render the portable workflow through project rules rooted in `WARP.md`, with supporting repo-local docs for routing, safety, and reusable behavior.

## Minimum Common Primitives

- `WARP.md` as the project rule entrypoint
- repo-local SSOT files for durable project state
- supporting docs or templates for routing, safety, and skill-like flows
- optional workflows as wrappers around project commands, not as canonical state

## Portable Mapping

- `core/models/*.yaml` -> `WARP.md` plus `.vibe/warp/routing.md`
- `core/skills/registry.yaml` -> rule references, reusable checklists, or workflow guidance
- `core/security/policy.yaml` -> rule-backed escalation guidance and any future native enforcement bridge
- `core/policies/behaviors.yaml` -> `WARP.md` and `.vibe/warp/behavior-policies.md`

## Phase 6 Build Output

- `bin/vibe build --target warp` generates `WARP.md` and `.vibe/warp/*` support docs.
- `bin/vibe switch warp` applies Warp-oriented files into the current repo root by default.
- Project overlays can inject stack-specific preferences such as `uv` or `nvm` into the rendered Warp rule set without changing shared defaults.

## Notes

- Keep Warp support conservative and file-backed; do not assume direct management of Warp Drive state.
- Treat Warp workflows as optional wrappers over stable project commands such as `bin/vibe inspect`, `uv run ...`, `nvm use`, or repo-local scripts.
