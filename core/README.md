# Core Spec

This directory is the canonical, tool-agnostic workflow layer for the repository.

Phase 1 established the portable source of truth for routing, skills, and safety without breaking the current Claude Code workflow. Phase 2-3 added `bin/vibe`, which can materialize target-specific outputs from the portable spec. Phase 4 extended the portable layer with behavior policies and deeper host-native config rendering. Phase 5 added a project-overlay mechanism so consuming repositories can customize target behavior without editing the shared portable defaults. Phase 6 adds a first-class Warp target plus curated runtime-preference overlays for Python and Node projects.

## Responsibilities

- `models/` — capability tiers and target/provider profiles
- `skills/` — portable skill registry, namespaces, and trigger metadata
- `security/` — severity semantics, signal taxonomy, and runtime actions
- `policies/` — portable behavior policies that can be rendered into host-specific rules

## Invariants

1. `core/` defines intent and policy, not host-specific syntax.
2. `targets/` explains how each host tool should render or interpret the portable spec.
3. Existing Claude Code files remain usable and are treated as the active rendered target.
4. When a target has native enforcement, prefer it. When it does not, fall back to explicit instructions and review steps.
5. Cross-target SSOT should live here before being copied, rendered, or adapted elsewhere.
6. Project-specific deviations should prefer `.vibe/overlay.yaml` or `--overlay FILE` rather than mutating shared `core/` defaults.

## Phase 1 Workflow

1. Update the portable spec in `core/`.
2. Sync the current Claude-oriented files in `rules/`, `docs/`, and `skills/`.
3. Update `targets/*.md` so the adapter contract stays accurate.
4. Extend the generator conservatively as the portable schema stabilizes.

## Current Files

- `models/tiers.yaml` — capability-tier definitions
- `models/providers.yaml` — target/provider mapping profiles
- `skills/registry.yaml` — portable skill IDs and metadata
- `security/policy.yaml` — `P0/P1/P2` semantics and target actions
- `policies/behaviors.yaml` — portable behavior policies grouped for rendering

## Project overlays

Phase 5 keeps overlay data out of `core/` on purpose. `core/` remains the shared baseline, while a consuming project can place `.vibe/overlay.yaml` in its own root or pass `--overlay FILE` to merge project-specific deltas at render time. See `docs/project-overlays.md`, `examples/project-overlay.yaml`, `examples/python-uv-overlay.yaml`, and `examples/node-nvm-overlay.yaml`.

## Future Expansion

Likely next additions after phase 6:

- `memory/` for target-neutral SSOT and memory routing
- richer renderers and validation for host-specific enforcement
- multiple named overlay stacks or environment-specific composition when the single-file model becomes too limiting
