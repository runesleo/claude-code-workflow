# Codex CLI Target

Codex CLI should be treated as a separate target profile, not as a literal clone of the Claude layout.

## Minimum Common Primitives

- `AGENTS.md` as the shared instruction surface
- repo-local SSOT files for memory, handoff, and status
- approval, sandbox, or wrapper controls for high-risk actions
- optional helper scripts or templates for skill-like flows

## Portable Mapping

- `core/models/*.yaml` -> active provider profile and routing guidance inside `AGENTS.md`
- `core/skills/registry.yaml` -> explicit step sequences, reusable task templates, or wrapper commands
- `core/security/policy.yaml` -> approval policy, sandbox policy, or external guard layer

## Phase 1 Notes

- Do not assume native parity with Claude skills.
- Use portable skill IDs in prose and wrappers even if the host only exposes `AGENTS.md`.
- Keep `independent_verifier` cross-family when possible so review is genuinely independent.

## Phase 2 Build Output

- `bin/vibe build --target codex-cli` generates a Codex-oriented `AGENTS.md`.
- Additional generated docs under `.vibe/codex-cli/` carry routing, skills, and safety summaries.

## Phase 3 Additions

- `bin/vibe switch codex-cli` applies the generated Codex config into the current repo root by default.
- Generated `.vibe/codex-cli/execution-policy.md` now carries the maker-checker and safety execution flow.
- Generated `.vibe/codex-cli/behavior-policies.md` mirrors the portable behavior schema for Codex-oriented execution.

## Phase 5 Additions

- Codex-oriented builds now surface overlay-applied profile remapping and extra policy deltas in `AGENTS.md` and `.vibe/codex-cli/*`.
- This keeps Codex conservative: project-specific changes stay in the overlay, while the target still degrades cleanly to docs and execution guidance.
