# Generated target summary

- Target: `opencode`
- Profile: `opencode-default`
- Profile maturity: `planned`
- Generated at: `2026-03-09T03:02:08Z`
- Applied overlay: `none`

## Capability mapping

- `critical_reasoner` → `configured.primary-high-reasoning`
- `workhorse_coder` → `configured.primary-coder`
- `fast_router` → `configured.fast-agent`
- `independent_verifier` → `second-model.cross-family`
- `cheap_local` → `local.ollama-class`

## Overlay

- none

## Behavior policies

- `ssot-first` (`mandatory`) — Keep repository files as the single source of truth; tool-managed memory is cache.
- `verify-before-claim` (`mandatory`) — Never claim completion without fresh verification evidence.
- `capability-tier-routing` (`mandatory`) — Route by capability tier first, then resolve through the active provider profile.
- `reversible-small-batches` (`recommended`) — Prefer small, reversible, single-purpose changes over large mixed batches.
- `root-cause-debugging` (`mandatory`) — Investigate root cause before attempting fixes and reassess after repeated failures.
- `security-escalation` (`mandatory`) — Treat destructive commands, network egress, secret access, and obfuscation as security-sensitive actions.
- `record-reusable-learning` (`recommended`) — Record user corrections, repeated failures, and counter-intuitive discoveries for reuse.
- `sunday-rule` (`recommended`) — Batch workflow or system optimization separately from delivery work unless it blocks production.

## Skills

- `systematic-debugging` (`P0`, `mandatory`) — Find root cause before attempting fixes.
- `verification-before-completion` (`P0`, `mandatory`) — Require fresh verification evidence before claiming completion.
- `session-end` (`P0`, `mandatory`) — Capture handoff, memory, and wrap-up state before ending a session.
- `planning-with-files` (`P1`, `suggest`) — Use persistent files as working memory for complex multi-step tasks.
- `experience-evolution` (`P1`, `suggest`) — Capture reusable lessons and patterns from repeated work.
- `superpowers/tdd` (`P2`, `suggest`) — Test-driven development workflow with red-green-refactor cycle.
- `superpowers/brainstorm` (`P2`, `manual`) — Structured brainstorming and ideation sessions.
- `superpowers/refactor` (`P2`, `suggest`) — Systematic code refactoring with safety checks.
- `superpowers/debug` (`P2`, `suggest`) — Advanced debugging workflows beyond systematic-debugging.
- `superpowers/architect` (`P2`, `manual`) — System architecture design and documentation.
- `superpowers/review` (`P2`, `suggest`) — Code review with comprehensive quality checks.
- `superpowers/optimize` (`P2`, `manual`) — Performance optimization and profiling guidance.
