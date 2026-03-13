# Vibe workflow for Warp

Generated from the portable `core/` spec with profile `warp-default`.## Optional Integrations

### Superpowers Skill Pack

**Status**: ❌ Not installed

Superpowers provides advanced skills for design refinement, TDD, debugging, and more.

**Installation for Warp**:
```bash
# Clone the repository
git clone https://github.com/obra/superpowers ~/.config/skills/superpowers

# In Warp, manually add the skill paths or use as reference
```

**Available skills**:
- `superpowers/brainstorming` — Design refinement and feature exploration
- `superpowers/writing-plans` — Implementation planning for complex changes
- `superpowers/test-driven-development` — TDD enforcement and test-first workflow
- `superpowers/systematic-debugging` — Root cause analysis and structured debugging
- `superpowers/subagent-driven-development` — Parallel task execution with multiple agents
- `superpowers/using-git-worktrees` — Branch isolation using git worktrees
- `superpowers/requesting-code-review` — Code review preparation and workflow
- `superpowers/refactor` — Systematic code refactoring with safety checks
- `superpowers/architect` — System architecture design and documentation
- `superpowers/optimize` — Performance optimization and profiling guidance


### RTK Token Optimizer

**Status**: ❌ Not installed

RTK is a CLI proxy that reduces LLM token consumption by 60-90% on common development commands.

**Installation**:
```bash
# macOS/Linux with Homebrew
brew install rtk
```

**For Warp**: Manually prefix commands with `rtk`, e.g., `rtk git status`

Applied overlay: `none`

This file is intended as the Warp project rule entrypoint for the repository.

## Non-negotiable rules

- `ssot-first` (`mandatory`) — Keep repository files as the single source of truth; tool-managed memory is cache.
- `verify-before-claim` (`mandatory`) — Never claim completion without fresh verification evidence.
- `capability-tier-routing` (`mandatory`) — Route by capability tier first, then resolve through the active provider profile.
- `reversible-small-batches` (`recommended`) — Prefer small, reversible, single-purpose changes over large mixed batches.
- `root-cause-debugging` (`mandatory`) — Investigate root cause before attempting fixes and reassess after repeated failures.
- `security-escalation` (`mandatory`) — Treat destructive commands, network egress, secret access, and obfuscation as security-sensitive actions.
- `record-reusable-learning` (`recommended`) — Record user corrections, repeated failures, and counter-intuitive discoveries for reuse.

## Capability routing

- `critical_reasoner` → `warp.primary-frontier-model`
- `workhorse_coder` → `warp.default-agent-model`
- `fast_router` → `warp.fast-model`
- `independent_verifier` → `second-model.or.manual-review`
- `cheap_local` → `local.external-runner`

## Mandatory portable skills

- `systematic-debugging` (`P0`, `mandatory`) — Find root cause before attempting fixes.
- `verification-before-completion` (`P0`, `mandatory`) — Require fresh verification evidence before claiming completion.
- `session-end` (`P0`, `mandatory`) — Capture handoff, memory, and wrap-up state before ending a session.

## Supporting files

- Use `.vibe/warp/behavior-policies.md` for the full portable behavior baseline.
- Use `.vibe/warp/routing.md` for tier routing and profile mapping.
- Use `.vibe/warp/safety.md` for security-sensitive work and escalation policy.
- Use `.vibe/warp/skills.md` for portable skill references.
- Use `.vibe/warp/task-routing.md` for task complexity classification and process requirements.
- Use `.vibe/warp/test-standards.md` for test coverage standards by complexity.
- Use `.vibe/warp/workflow-notes.md` for conservative workflow guidance in Warp.


## Safety floor

- `P0` — Surface as a blocking Warp rule plus explicit stop guidance in the generated docs.
- `P1` — Require manual review or user confirmation before execution.
- `P2` — Warn in WARP.md or supporting guidance and continue with traceable reasoning.
