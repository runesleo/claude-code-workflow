# Execution policy

Generated target: `opencode`
Active profile: `opencode-default`
Applied overlay: `none`

## Default execution flow

1. Classify the task by capability tier.
2. Pick the mapped executor from the active profile.
3. Apply mandatory portable skills before claiming completion.
4. If risk appears, follow the generated safety policy.
5. For critical work, prefer maker-checker flow with `independent_verifier`.

## Always-on behavior policies

- `ssot-first` (`mandatory`) — Keep repository files as the single source of truth; tool-managed memory is cache.
- `verify-before-claim` (`mandatory`) — Never claim completion without fresh verification evidence.
- `reversible-small-batches` (`recommended`) — Prefer small, reversible, single-purpose changes over large mixed batches.
- `root-cause-debugging` (`mandatory`) — Investigate root cause before attempting fixes and reassess after repeated failures.
- `record-reusable-learning` (`recommended`) — Record user corrections, repeated failures, and counter-intuitive discoveries for reuse.

## Mandatory portable skills

- `systematic-debugging` (`P0`, `mandatory`) — Find root cause before attempting fixes.
- `verification-before-completion` (`P0`, `mandatory`) — Require fresh verification evidence before claiming completion.
- `session-end` (`P0`, `mandatory`) — Capture handoff, memory, and wrap-up state before ending a session.

## Optional portable skills

- `planning-with-files` (`P1`, `suggest`) — Use persistent files as working memory for complex multi-step tasks.
- `experience-evolution` (`P1`, `suggest`) — Capture reusable lessons and patterns from repeated work.
- `superpowers/tdd` (`P2`, `suggest`) — Test-driven development workflow with red-green-refactor cycle.
- `superpowers/brainstorm` (`P2`, `manual`) — Structured brainstorming and ideation sessions.
- `superpowers/refactor` (`P2`, `suggest`) — Systematic code refactoring with safety checks.
- `superpowers/debug` (`P2`, `suggest`) — Advanced debugging workflows beyond systematic-debugging.
- `superpowers/architect` (`P2`, `manual`) — System architecture design and documentation.
- `superpowers/review` (`P2`, `suggest`) — Code review with comprehensive quality checks.
- `superpowers/optimize` (`P2`, `manual`) — Performance optimization and profiling guidance.

## Safety actions

- `P0` — Prefer native permission rules or wrapper deny.
- `P1` — Ask through configured permission flow.
- `P2` — Warn and continue.
