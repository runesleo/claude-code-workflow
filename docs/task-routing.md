# Task Routing Detailed Table (Capability Tiers + Target Profiles)

> On-demand loading. Portable routing SSOT lives in `core/models/tiers.yaml` and `core/models/providers.yaml`. Current first-class runtime target remains Claude Code, while project-specific remapping can be layered through `.vibe/overlay.yaml` or `--overlay FILE`.

## Capability Tiers

| Tier ID | Legacy label in this repo | Use for | Avoid for |
|---------|---------------------------|---------|-----------|
| `critical_reasoner` | Opus | Critical logic, architecture, secrets, security review | Docs-only edits, repetitive cleanup |
| `workhorse_coder` | Sonnet | Daily implementation, analysis, routine refactors | Highest-risk business logic |
| `fast_router` | Haiku | Exploration, classification, quick lookups | Final decisions, broad edits |
| `independent_verifier` | Codex / second model | Cross-checking critical conclusions | Trivial one-shot tasks |
| `cheap_local` | Local | Offline or low-risk bulk tasks | Long-context, high-assurance work |

## Current Default Profile: Claude Code

| Task Type | Portable route | Current executor hint | Notes |
|-----------|----------------|-----------------------|-------|
| Critical logic / secrets / credentials | `critical_reasoner` | Opus-class | Safety floor, never outsource blindly |
| Critical code review | `critical_reasoner` + `independent_verifier` | Opus lead → Codex audit | Multi-model cross-check |
| Daily feature work | `workhorse_coder` | Sonnet-class | Default implementation path |
| Complex non-sensitive refactor | `workhorse_coder` or `independent_verifier` | Sonnet → Codex | Good for >100 line refactors |
| Quick search / simple classification | `fast_router` | Haiku-class | Fastest and cheapest cloud tier |
| Commit messages / formatting / offline fallback | `cheap_local` | Local model | Prefer local if quality is enough |

## Other Target Profiles (Phase 1 Contract)

### Codex CLI

- Use the `codex-cli-default` profile from `core/models/providers.yaml`
- Treat `AGENTS.md` as the minimum common instruction surface
- Keep `independent_verifier` cross-family when possible

### Cursor

- Use the `cursor-default` profile from `core/models/providers.yaml`
- Render routing as rules and review conventions rather than assuming native skills
- Keep repo files as SSOT; tool-managed memory is only cache

### OpenCode

- Use the `opencode-default` profile from `core/models/providers.yaml`
- Prefer native permission controls and reusable agent or skill constructs
- Use this as an early proving ground for cross-target portability

### Warp

- Use the `warp-default` profile from `core/models/providers.yaml`
- Render routing into `WARP.md` and `.vibe/warp/*` support docs rather than assuming a separate native skill system
- Keep stack-specific preferences such as `uv` and `nvm` in overlays so they stay project-scoped

### Generic Open-Weight / GLM-family

- Use the `glm-family-default` profile from `core/models/providers.yaml`
- Re-benchmark every tier against your own tasks before enabling by default
- Keep local deployment and infra concerns outside the portable routing policy

## Local / Low-Cost Pool

**Principle: If a low-cost or local model can do it safely, do not burn premium quota.**

| Task Type | Portable route | Notes |
|-----------|----------------|-------|
| Commit message generation | `cheap_local` | Good default local workload |
| Simple formatting / translation | `cheap_local` | Replace the fastest cloud tier when acceptable |
| Diff classification (critical vs trivial) | `cheap_local` | Pre-filter before expensive review |
| Batch / non-critical tasks | `cheap_local` | Best zero-cost compute pool |

## Migration Rule

- Route by capability tier first, then resolve against the active target profile plus any applied overlay.
- Do not hard-code product names in new portable rules; keep them in `core/models/providers.yaml`.
- Use `.vibe/overlay.yaml` for repo-local remapping before changing shared defaults.
- Update `rules/behaviors.md` only after the portable model files are aligned.
