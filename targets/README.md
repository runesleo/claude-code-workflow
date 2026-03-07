# Target Adapters

This directory describes how the portable `core/` spec should map to specific agentic coding tools.

Phase 1 made the adapter contract explicit. Phase 2-3 added a minimal `bin/vibe` generator with `inspect` and `switch`. Phase 4 added portable behavior-policy rendering plus deeper native permission or config outputs where the host supports them. Phase 5 added project overlays so per-repo deltas can be merged without editing the shared core. Phase 6 adds a first-class Warp target and runtime-preference overlay examples.

## Adapter Contract

- `core/` owns portable semantics.
- `targets/*.md` explains how those semantics should be rendered for a host tool.
- Current host-facing runtime files remain in their native locations.
- Unsupported host features should degrade gracefully into rules, templates, or wrapper steps.

## Status

- `claude-code.md` — active first-class target, buildable, and permission-aware
- `codex-cli.md` — buildable with richer behavior / safety docs
- `cursor.md` — buildable with generated rules plus `.cursor/cli.json` permissions
- `kimi-code.md` — buildable with generated `.kimi/skills/` SKILL.md files
- `opencode.md` — buildable with generated instruction and permission config
- `warp.md` — buildable with `WARP.md` plus generated `.vibe/warp/*` support docs

## Common Rules

1. Keep repo files as the workflow SSOT. Tool-managed memory is cache, not canonical state.
2. Route by portable skill ID or capability tier first, then map to host-native primitives.
3. Prefer native enforcement for `P0/P1` security actions where the host supports it.
4. Use project overlays for repo-local deltas instead of forking shared target docs or core schema.
5. If a host lacks a native skill system, degrade to rules, AGENTS guidance, or wrapper commands instead of inventing fake parity.
6. Keep stack preferences such as `uv` and `nvm` in overlays so they remain optional and project-scoped.
