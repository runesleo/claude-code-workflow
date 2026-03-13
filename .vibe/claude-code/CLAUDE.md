# Vibe workflow for Claude Code

Generated from the portable `core/` spec with profile `claude-code-default`.## Optional Integrations

### Superpowers Skill Pack

**Status**: ❌ Not installed

Superpowers provides advanced skills for design refinement, TDD, debugging, and more.

**Installation for Claude Code**:
```bash
# Clone the repository
git clone https://github.com/obra/superpowers ~/.config/skills/superpowers

# For Claude Code, manually register the skills in your tool's skill system
# or use the skill files from ~/.config/skills/superpowers/skills/
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

# Or build from source
cargo install --git https://github.com/rtk-ai/rtk

# Then configure
rtk init --global
```


**Note**: RTK works best with Claude Code. For Claude Code, you may need to manually prefix commands with `rtk`.

Applied overlay: `none`

Keep repository files as the SSOT, verify before claiming completion, and follow the generated routing + safety rules.

## Non-negotiable rules

- `ssot-first` (`mandatory`) — Keep repository files as the single source of truth; tool-managed memory is cache.
- `verify-before-claim` (`mandatory`) — Never claim completion without fresh verification evidence.
- `capability-tier-routing` (`mandatory`) — Route by capability tier first, then resolve through the active provider profile.
- `reversible-small-batches` (`recommended`) — Prefer small, reversible, single-purpose changes over large mixed batches.
- `root-cause-debugging` (`mandatory`) — Investigate root cause before attempting fixes and reassess after repeated failures.
- `security-escalation` (`mandatory`) — Treat destructive commands, network egress, secret access, and obfuscation as security-sensitive actions.
- `record-reusable-learning` (`recommended`) — Record user corrections, repeated failures, and counter-intuitive discoveries for reuse.

## Capability routing

- `critical_reasoner` → `claude.opus-class`
- `workhorse_coder` → `claude.sonnet-class`
- `fast_router` → `claude.haiku-class`
- `independent_verifier` → `second-model.cross-family`
- `cheap_local` → `local.ollama-class`

## Mandatory portable skills

- `systematic-debugging` (`P0`, `mandatory`) — Find root cause before attempting fixes.
- `verification-before-completion` (`P0`, `mandatory`) — Require fresh verification evidence before claiming completion.
- `session-end` (`P0`, `mandatory`) — Capture handoff, memory, and wrap-up state before ending a session.



## Safety floor

- `P0` — Prefer hooks or permissions deny; otherwise stop with an explicit block message.
- `P1` — Prefer hook-mediated confirmation or manual approval.
- `P2` — Warn in output and continue with traceable reasoning.
