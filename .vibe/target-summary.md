# Generated target summary

- Target: `warp`
- Profile: `warp-default`
- Profile maturity: `planned`
- Generated at: `2026-03-07T02:18:35Z`
- Applied overlay: `example-regulated-project` from `examples/project-overlay.yaml`

## Capability mapping

- `critical_reasoner` → `openai.high-reasoning`
- `workhorse_coder` → `warp.default-agent-model`
- `fast_router` → `warp.fast-model`
- `independent_verifier` → `second-model.cross-family`
- `cheap_local` → `local.external-runner`

## Overlay

- Name: `example-regulated-project`
- Path: `examples/project-overlay.yaml`
- Profile mapping overrides: `critical_reasoner`, `independent_verifier`
- Extra profile notes: `2`
- Policy patches: `2`
- Native patch keys: `none`

## Behavior policies

- `ssot-first` (`mandatory`) — Keep repository files as the single source of truth; tool-managed memory is cache.
- `verify-before-claim` (`mandatory`) — Never claim completion without fresh verification evidence.
- `capability-tier-routing` (`mandatory`) — Route by capability tier first, then resolve through the active provider profile.
- `reversible-small-batches` (`recommended`) — Prefer small, reversible, single-purpose changes over large mixed batches.
- `root-cause-debugging` (`mandatory`) — Investigate root cause before attempting fixes and reassess after repeated failures.
- `security-escalation` (`mandatory`) — Treat destructive commands, network egress, secret access, and obfuscation as security-sensitive actions.
- `record-reusable-learning` (`recommended`) — Record user corrections, repeated failures, and counter-intuitive discoveries for reuse.
- `sunday-rule` (`recommended`) — Batch workflow or system optimization separately from delivery work unless it blocks production.
- `project-context-is-release-log` (`recommended`) — Keep `PROJECT_CONTEXT.md` current for release blockers, migrations, and rollback notes.
- `regulated-data-review` (`mandatory`) — Treat customer-data exports, redaction, and retention changes as review-required work.

## Skills

- `systematic-debugging` (`P0`, `mandatory`) — Find root cause before attempting fixes.
- `verification-before-completion` (`P0`, `mandatory`) — Require fresh verification evidence before claiming completion.
- `session-end` (`P0`, `mandatory`) — Capture handoff, memory, and wrap-up state before ending a session.
- `planning-with-files` (`P1`, `suggest`) — Use persistent files as working memory for complex multi-step tasks.
- `experience-evolution` (`P1`, `suggest`) — Capture reusable lessons and patterns from repeated work.
