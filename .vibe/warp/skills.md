# Portable skills

Generated target: `warp`
Applied overlay: `none`

- `systematic-debugging` (`builtin`, `P0`, `mandatory`, support: `rule-or-manual-invocation`) — Find root cause before attempting fixes.
- `verification-before-completion` (`builtin`, `P0`, `mandatory`, support: `rule-or-checklist`) — Require fresh verification evidence before claiming completion.
- `session-end` (`builtin`, `P0`, `mandatory`, support: `checklist-or-rule`) — Capture handoff, memory, and wrap-up state before ending a session.
- `planning-with-files` (`builtin`, `P1`, `suggest`, support: `manual-or-template`) — Use persistent files as working memory for complex multi-step tasks.
- `experience-evolution` (`builtin`, `P1`, `suggest`, support: `manual`) — Capture reusable lessons and patterns from repeated work.
- `superpowers/tdd` (`superpowers`, `P2`, `suggest`, support: `manual`) — Test-driven development workflow with red-green-refactor cycle.
- `superpowers/brainstorm` (`superpowers`, `P2`, `manual`, support: `manual`) — Structured brainstorming and ideation sessions.
- `superpowers/refactor` (`superpowers`, `P2`, `suggest`, support: `manual`) — Systematic code refactoring with safety checks.
- `superpowers/debug` (`superpowers`, `P2`, `suggest`, support: `manual`) — Advanced debugging workflows beyond systematic-debugging.
- `superpowers/architect` (`superpowers`, `P2`, `manual`, support: `manual`) — System architecture design and documentation.
- `superpowers/review` (`superpowers`, `P2`, `suggest`, support: `manual`) — Code review with comprehensive quality checks.
- `superpowers/optimize` (`superpowers`, `P2`, `manual`, support: `manual`) — Performance optimization and profiling guidance.


## When to Use External Skills

The following external skills are automatically suggested in relevant scenarios:

| Scenario | Skill | Notes |
|----------|-------|-------|
| When implementing new functionality | `superpowers/tdd` | Auto-suggested when applicable |
| When refactoring code for better structure or maintainability | `superpowers/refactor` | Auto-suggested when applicable |
| When encountering bugs (note - builtin equivalent exists) | `superpowers/debug` | Auto-suggested when applicable |
| Before creating pull requests | `superpowers/review` | Auto-suggested when applicable |
