# Claude Code Workflow

**English** | [中文](README.zh-CN.md)

A battle-tested workflow foundation for Claude Code today, evolving into a portable vibe coding config base for Claude Code, Codex CLI, OpenCode, Cursor, Warp, and similar agentic tools.

**Not a tutorial. Not a toy config. A production workflow that actually ships — now with a provider-neutral core spec in phase 1.**

## Origin & Fork Status

This project is a fork of [runesleo/claude-code-workflow](https://github.com/runesleo/claude-code-workflow) with substantial architectural refactoring:

- **Original Author**: [@runes_leo](https://x.com/runes_leo)
- **Fork Maintainer**: [@nehcuh](https://github.com/nehcuh)
- **Major Changes**:
  - Modularized CLI into 6 Ruby library modules (`lib/vibe/*.rb`)
  - Added comprehensive unit test suite (`test/`)
  - Added Chinese documentation (`README.zh-CN.md`)
  - Enhanced overlay system with runtime preference examples (`examples/`)
  - Improved path safety and symlink handling for macOS compatibility
  - Refactored generator architecture for better maintainability

While this fork maintains the original MIT license and credits the original author, the codebase has diverged significantly through refactoring and new features.

## Why This Exists

Claude Code is powerful out of the box, but without structure it becomes a smart assistant that forgets everything between sessions. This template turns it into a **persistent, self-improving development partner** that:

- Remembers past mistakes and applies lessons automatically
- Manages context across long sessions without drifting
- Routes tasks to the right capability tier and active provider profile
- Forces verification before claiming completion (no more "should work now")
- Auto-saves progress so closing the window doesn't lose work

## Phase 1-6 Direction: Portable Core + Target Adapters + Generator + Project Overlays + Warp

This repo now has two layers of concern:

- `core/` — provider-neutral workflow semantics (model tiers, skill registry, safety policy)
- current runtime files (`rules/`, `docs/`, `memory/`, `skills/`) — the first-class Claude Code target that remains fully usable today
- `targets/` — mapping notes for Claude Code, Codex CLI, Cursor, and OpenCode

Phase 1 established the portable SSOT and adapter contract. Phase 2-3 added a minimal `bin/vibe` generator with build/use/inspect/switch ergonomics. Phase 4 added portable behavior policies plus deeper native config rendering. Phase 5 added project-level overlays so consuming repos can customize profile mapping, behavior deltas, and native target config without forking `core/`. Phase 6 adds a first-class Warp target plus reusable runtime-preference overlay examples for `uv` and `nvm`.

## Architecture: Portable Core + Runtime Layers

```text
Portable core
  core/models      -> capability tiers + provider profiles
  core/skills      -> portable skill registry
  core/security    -> severity policy + signal taxonomy
  core/policies    -> portable behavior policies

Project overlay
  .vibe/overlay.yaml or --overlay FILE -> project-specific profile / policy / native config patch

Target adapters
  targets/*.md     -> Claude Code / Codex CLI / Cursor / OpenCode mapping docs

Current first-class runtime target: Claude Code
  Layer 0: rules/  (always loaded)
  Layer 1: docs/   (on demand)
  Layer 2: memory/ (hot data)
  skills/, agents/, commands/ remain host-facing assets during transition

Generator
  bin/vibe         -> build/use portable targets into generated/<target>/
```

**Why this split?** `core/` keeps the semantics portable, while the existing runtime layers keep Claude Code productive right now. That lets you generalize the workflow without throwing away the current working setup.

## What's Inside

```
claude-code-workflow/
├── CLAUDE.md                     # Entry point — Claude reads this first
├── README.md                     # You are here
│
├── bin/
│   ├── vibe                      # Phase-6 generator CLI (build/use/inspect/overlay-aware targets)
│   └── vibe-smoke                # Smoke test for generator target builds + overlays
│
├── core/                         # Portable SSOT (phase 1)
│   ├── README.md                 # Portable architecture + migration rules
│   ├── models/
│   │   ├── tiers.yaml            # Capability tiers (portable)
│   │   └── providers.yaml        # Target/provider mappings
│   ├── skills/
│   │   └── registry.yaml         # Skill registry + namespace rules
│   ├── security/
│   │   └── policy.yaml           # P0/P1/P2 semantics + target actions
│   └── policies/
│       └── behaviors.yaml        # Portable behavior policy schema
│
├── targets/                      # Target adapter contracts
│   ├── README.md                 # Shared adapter rules
│   ├── claude-code.md            # Current first-class target mapping
│   ├── codex-cli.md              # Planned Codex CLI mapping
│   ├── cursor.md                 # Planned Cursor mapping
│   ├── opencode.md               # Planned OpenCode mapping
│   └── warp.md                   # Planned Warp mapping
│
├── generated/                    # Build output (ignored by default)
│   └── <target>/                 # Materialized target-specific config
│
├── examples/
│   ├── node-nvm-overlay.yaml     # Example Node/npm overlay preferring nvm
│   ├── project-overlay.yaml      # Example regulated/review-heavy overlay
│   └── python-uv-overlay.yaml    # Example Python overlay preferring uv
│
├── rules/                        # Layer 0: Always loaded
│   ├── behaviors.md              # Core behavior rules (debugging, commits, routing)
│   ├── skill-triggers.md         # When to auto-invoke which skill
│   └── memory-flush.md           # Auto-save triggers (never lose progress)
│
├── docs/                         # Layer 1: On-demand reference
│   ├── agents.md                 # Multi-model collaboration framework
│   ├── behaviors-extended.md     # Extended rules (knowledge base, associations)
│   ├── behaviors-reference.md    # Detailed operation guides
│   ├── content-safety.md         # AI hallucination prevention system
│   ├── project-overlays.md       # Project-level overlay schema + merge rules
│   ├── scaffolding-checkpoint.md # "Do you really need to self-host?" checklist
│   └── task-routing.md           # Model tier routing + target profiles
│
├── memory/                       # Layer 2: Your working state (templates)
│   ├── infra.md                  # Infrastructure SSOT template
│   ├── today.md                  # Daily session log
│   ├── projects.md               # Cross-project status overview
│   ├── goals.md                  # Week/month/quarter goals
│   ├── sunday-backlog.md         # System optimization backlog template
│   └── active-tasks.json         # Cross-session task registry
│
├── patterns.md                   # Cross-project reusable patterns and pitfalls
│
├── skills/                       # Reusable skill definitions
│   ├── session-end/SKILL.md              # Auto wrap-up: save progress + commit + record
│   ├── verification-before-completion/SKILL.md  # "Run the test. Read the output. THEN claim."
│   ├── systematic-debugging/SKILL.md     # 5-phase debugging (recall → root cause → fix)
│   ├── planning-with-files/SKILL.md      # File-based planning for complex tasks
│   └── experience-evolution/SKILL.md     # Auto-accumulate project knowledge
│
├── agents/                       # Custom agent definitions
│   ├── pr-reviewer.md            # Code review agent
│   ├── security-reviewer.md      # OWASP security scanning agent
│   └── performance-analyzer.md   # Performance bottleneck analysis agent
│
└── commands/                     # Custom slash commands
    ├── debug.md                  # /debug — Start systematic debugging
    ├── deploy.md                 # /deploy — Pre-deployment checklist
    ├── exploration.md            # /exploration — CTO challenge before coding
    └── review.md                 # /review — Prepare code review
```

## Quick Start

### 1. Copy to your Claude Code config (current first-class target)

```bash
# Clone the template
git clone https://github.com/nehcuh/claude-code-workflow.git

# Copy to your Claude Code config directory
cp -r claude-code-workflow/* ~/.claude/

# Or symlink if you want to keep it as a git repo
ln -sf ~/claude-code-workflow/rules ~/.claude/rules
ln -sf ~/claude-code-workflow/docs ~/.claude/docs
# ... etc
```

### 2. Customize CLAUDE.md

Open `~/.claude/CLAUDE.md` and fill in:

- **User Info**: Your name, project directory, social handles
- **Sub-project Memory Routes**: Map your projects to memory paths
- **SSOT Ownership Table**: Define where each type of info lives
- **On-demand Loading Index**: Adjust doc paths if needed

### 3. Start a session

```bash
claude
```

Claude will automatically load your rules and start following the workflow. Try:

- Start coding and notice the **task routing** (`🔀 Route: bug fix → workhorse_coder (Sonnet-class)`)
- Hit a bug and watch **systematic debugging** kick in
- Say "that's all for now" and see **session-end** auto-save everything
- Come back tomorrow and find your context preserved in `today.md`

Portable note: `core/` and `targets/` define the cross-tool contract, but Claude Code remains the directly runnable target in phase 1.

## Model Configuration Guide

This workflow uses a **capability-tier routing system** that separates task complexity from specific model implementations. Understanding how to configure models for your target is essential for optimal performance.

### Understanding Capability Tiers

The workflow defines 5 abstract capability tiers in `core/models/tiers.yaml`:

- **`critical_reasoner`**: Highest-assurance reasoning for critical logic, security, secrets, and architecture
- **`workhorse_coder`**: Default daily coding tier for most implementation and analysis work
- **`fast_router`**: Cheap and fast tier for exploration, triage, and low-stakes subprocess work
- **`independent_verifier`**: Second-model verification tier for cross-checking important conclusions
- **`cheap_local`**: Local or near-zero-cost tier for offline, high-volume, and low-risk tasks

### How Tier-to-Model Mapping Works

Each target has a **provider profile** in `core/models/providers.yaml` that maps these abstract tiers to concrete model implementations:

```yaml
claude-code-default:
  mapping:
    critical_reasoner: claude.opus-class
    workhorse_coder: claude.sonnet-class
    fast_router: claude.haiku-class
```

**Important**: These mappings are **semantic hints**, not executable configuration. The actual model selection depends on your target tool's capabilities.

### Configuring Models by Target

#### Claude Code (Fully Supported)

Claude Code supports dynamic model selection through multiple methods:

**Method 1: Launch with specific model**
```bash
# Start with Opus (highest capability)
claude --model opus

# Start with Sonnet (balanced)
claude --model sonnet

# Start with Haiku (fastest)
claude --model haiku
```

**Method 2: Use Task tool with model parameter**
```markdown
When delegating to subagents, Claude can specify the model tier:
- Task tool with `model: "opus"` for critical reasoning
- Task tool with `model: "sonnet"` for standard work
- Task tool with `model: "haiku"` for quick exploration
```

**Method 3: Configure default in settings**
Check `~/.claude/settings.json` for default model preferences (if supported by your Claude Code version).

#### Cursor (Planned)

Cursor's model selection is configured through its UI settings:

1. Open Cursor Settings (Cmd/Ctrl + ,)
2. Navigate to "Models" section
3. Configure models for each tier:
   - **Primary model** → maps to `critical_reasoner` and `workhorse_coder`
   - **Fast model** → maps to `fast_router`
   - **Review model** → maps to `independent_verifier`

The generated `.cursor/rules/05-vibe-routing.mdc` will reference these as `cursor.primary-frontier-model`, `cursor.default-agent-model`, etc.

#### Codex CLI (Planned)

Codex CLI uses OpenAI models configured via environment or CLI flags:

```bash
# Set default models via environment
export CODEX_PRIMARY_MODEL="gpt-4"
export CODEX_FAST_MODEL="gpt-3.5-turbo"

# Or specify per-invocation
codex --model gpt-4 "your task"
```

The generated `.vibe/codex-cli/routing.md` maps tiers to `openai.high-reasoning`, `openai.codex-workhorse`, etc.

#### Warp (Planned)

Warp's model configuration depends on its AI provider integration:

1. Configure your AI provider in Warp settings
2. The generated `WARP.md` will reference `warp.primary-frontier-model`, `warp.default-agent-model`, etc.
3. Warp will use its configured default model for all tiers (model switching within Warp may be limited)

#### OpenCode (Planned)

OpenCode allows flexible model configuration in `opencode.json`:

```json
{
  "models": {
    "primary": "claude-opus-4",
    "coder": "claude-sonnet-4",
    "fast": "claude-haiku-4"
  }
}
```

The generated config will map these to the capability tiers defined in the workflow.

### Project-Specific Model Overrides

You can override the default tier-to-model mapping for a specific project using overlays:

```yaml
# .vibe/overlay.yaml
profile:
  mapping:
    critical_reasoner: claude.opus-4-latest
    workhorse_coder: claude.sonnet-4-latest
```

Then build with the overlay:
```bash
bin/vibe build claude-code --overlay .vibe/overlay.yaml
```

### Cost Optimization Tips

1. **Use the right tier**: Don't use `critical_reasoner` (Opus) for simple tasks
2. **Leverage `fast_router`**: Use Haiku-class models for exploration and quick lookups
3. **Enable `cheap_local`**: Configure Ollama or similar for commit messages and formatting
4. **Cross-verify selectively**: Only use `independent_verifier` for truly critical decisions

See `docs/task-routing.md` for detailed routing guidelines.

## External Tool Integrations

This workflow supports optional external tool integrations to enhance capabilities:

### Initialize Integrations

```bash
# Interactive setup wizard
bin/vibe init

# Verify existing installations
bin/vibe init --verify
```

### Supported Integrations

#### Superpowers Skill Pack

Advanced skill pack providing design refinement, TDD enforcement, systematic debugging, and more.

**Installation**:
- Claude Code: `/plugin marketplace add obra/superpowers-marketplace`
- Cursor: `/plugin-add superpowers`
- Manual: Clone and symlink to `~/.claude/skills/`
**Portable skill IDs exposed by this workflow**:
- `superpowers/tdd`
- `superpowers/brainstorm`
- `superpowers/refactor`
- `superpowers/debug`
- `superpowers/architect`
- `superpowers/review`
- `superpowers/optimize`

The installed Superpowers pack may use different native skill names. `core/skills/registry.yaml` remains the SSOT for the portable IDs rendered by `bin/vibe`.

**Source**: [obra/superpowers](https://github.com/obra/superpowers)

#### RTK (Token Optimizer)

CLI agent tool that reduces LLM token consumption by 60-90% through intelligent context management.

**Installation**:
```bash
# Homebrew (macOS/Linux)
brew install rtk

# Install script
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh

# Initialize hook
rtk init --global
```

**Source**: [rtk-ai/rtk](https://github.com/rtk-ai/rtk)

**Verification states**:
- **Ready**: RTK binary is installed and the Claude hook is configured
- **Installed, hook not configured**: RTK is present but `rtk init --global` still needs to run
- **Hook configured, binary not found**: stale Claude hook exists, but RTK is not currently installed

### Integration Behavior

- **Conditional**: All integrations are optional. The workflow operates normally without them.
- **Dynamic Detection**: Superpowers skills only appear in generated manifests/docs when the pack is actually installed.
- **Portable SSOT**: Generated Superpowers references use the portable IDs from `core/skills/registry.yaml`, not pack-specific command names.
- **Security**: External skills undergo security review before registration in `core/skills/registry.yaml`.

See `docs/integrations.md` for detailed integration documentation.

## Phase 2-6: Build / Use / Inspect Generator

The repository now ships a minimal generator CLI:

```bash
bin/vibe build --target claude-code
bin/vibe build --target codex-cli
bin/vibe build --target cursor
bin/vibe build --target opencode
bin/vibe build --target warp
bin/vibe inspect
bin/vibe-smoke
```

By default, each build goes to `generated/<target>/`.

Examples:

```bash
# Build a Claude Code config tree
bin/vibe build --target claude-code
# Positional shorthand also works
bin/vibe build cursor

# Build an OpenCode project config into a custom directory
bin/vibe build --target opencode --output /tmp/vibe-opencode

# Apply a generated Claude target into ~/.claude
bin/vibe use --target claude-code --destination ~/.claude

# Apply a generated Cursor target into a project root
bin/vibe use --target cursor --destination /path/to/project

# Quick-switch repo-local targets into the current repo
bin/vibe switch cursor
bin/vibe switch codex-cli
bin/vibe switch opencode
bin/vibe switch warp

# Quick-switch Claude Code into ~/.claude
bin/vibe switch claude-code

# Inspect current defaults, generated outputs, and repo target state
bin/vibe inspect
bin/vibe inspect --json

# Preview a project overlay without applying it
bin/vibe inspect --overlay examples/project-overlay.yaml

# Build or apply with a project overlay
bin/vibe build cursor --overlay examples/project-overlay.yaml
bin/vibe use --target opencode --destination /path/to/project --overlay /path/to/project/.vibe/overlay.yaml

# Run smoke checks (all targets + overlay builds)
bin/vibe-smoke
```

Current phase-6 behavior:

- `claude-code` → materializes `CLAUDE.md`, `rules/`, `docs/`, `skills/`, `agents/`, `commands/`, and a generated `settings.json` permission baseline, plus task routing and test standards under `.vibe/claude-code/`
- `codex-cli` → materializes `AGENTS.md` plus generated behavior / routing / safety / execution / task-routing / test-standards docs under `.vibe/codex-cli/`
- `cursor` → materializes `AGENTS.md`, `.cursor/rules/*.mdc`, `.cursor/cli.json`, and supporting `.vibe/cursor/*` notes including task routing and test standards
- `opencode` → materializes `AGENTS.md`, `opencode.json`, and modular behavior / routing / safety / execution instruction files with generated permissions
- `warp` → materializes `WARP.md` plus generated behavior / routing / safety / task-routing / test-standards / workflow support docs under `.vibe/warp/`
- `inspect` → can preview overlay-aware profile resolution and generated target state
- `use` / `switch` → auto-discover `.vibe/overlay.yaml` in the destination project when present

**Path Safety**: When using `use` or `switch`, if the default output directory (`generated/<target>/`) would overlap with the destination directory, the tool automatically uses an external staging directory at `~/.vibe-generated/<destination-name>-<hash>/<target>/` to prevent conflicts. This ensures safe operation even when applying configurations to the repository root.
- overlays → let a consuming repo remap capability tiers, add behavior deltas, patch native target config, and encode stack preferences like `uv` or `nvm` without editing `core/`

`bin/vibe` is intentionally conservative: it only renders the parts that are already modeled in `core/` and documented in `targets/`.
## Git & tracked files

This repository intentionally separates shared workflow files from disposable staging output:

- Commit the portable spec and checked-in target-facing files: `core/`, `targets/`, `rules/`, `docs/`, `CLAUDE.md`, `WARP.md`, and the tracked `.vibe/` support files that describe the active Warp target.
- Do not commit staging output or local apply markers: `generated/` and `.vibe-target.json` are intentionally ignored.
- Treat `.vibe/overlay.yaml` as project policy only when it should be shared. Keep personal or local-only overlays outside the repo, or ignore them in the consuming project's `.gitignore`.

See `docs/git-workflow.md` for the full commit policy, including consuming-repo guidance, `memory/` handling, and secrets/local-state rules.

## Key Concepts

### SSOT (Single Source of Truth)

Every piece of information has ONE canonical location. The SSOT table in CLAUDE.md maps info types to files. Claude is trained to check SSOT before writing, preventing the "same info in 5 places, all outdated" problem.

### Memory Flush

Claude auto-saves progress on every task completion, every commit, and every exit signal. You can close the window mid-sentence and nothing is lost. No more "I forgot to save my context."

### Verification Before Completion

The most impactful rule: Claude cannot claim work is done without running the verification command and reading the output. Eliminates the #1 AI coding failure mode — "should work now" without actually checking.

### Capability-Tier Task Routing

Route by capability first, then map it to the active provider profile:
- **critical_reasoner**: Critical logic, security-sensitive, complex reasoning
- **workhorse_coder**: Daily development, analysis, most coding tasks
- **fast_router**: Simple queries, subagent tasks, quick lookups
- **independent_verifier**: Cross-verification, code review, second opinions
- **cheap_local**: Commit messages, formatting, offline work

### Sunday Rule

System optimization happens on Sundays. On other days, if you try to tweak your workflow instead of shipping, Claude will intercept and remind you to focus on output. Configurable to any cadence you prefer.

## Customization Guide

### Portable-first workflow

1. Update the portable SSOT in `core/`
2. Sync the active Claude-facing files in `rules/`, `docs/`, and `skills/`
3. Keep the target adapter docs in `targets/` accurate
4. Use a project overlay (`.vibe/overlay.yaml`) for repo-specific deviations
5. Prefer example overlays such as `examples/python-uv-overlay.yaml` or `examples/node-nvm-overlay.yaml` for stack-specific defaults
6. Extend `bin/vibe` only after the portable schema stabilizes

### Adding a new project

1. Add to `memory/projects.md`
2. Add memory route in CLAUDE.md's "Sub-project Memory Routes"
3. Create `PROJECT_CONTEXT.md` in the project root

### Adding a new skill

Create `skills/your-skill/SKILL.md` with:

```yaml
---
name: your-skill
description: What it does
allowed-tools:
  - Read
  - Write
  - Bash
---

# Your Skill

[Instructions for Claude when this skill is invoked]
```

Then register its portable metadata in `core/skills/registry.yaml` before adding trigger rules.

### Adding an external skill pack (e.g. Superpowers)

1. Import the skill files under your preferred layout
2. Register the namespace and skill metadata in `core/skills/registry.yaml`
3. Review it against `core/security/policy.yaml`
4. Only then add trigger rules in `rules/skill-triggers.md`

### Adding a new agent

Create `agents/your-agent.md` with:

```yaml
---
name: your-agent
description: What it does
tools: Read, Grep, Glob, Bash
---

# Your Agent

[Agent personality, review dimensions, output format]
```

### Adjusting model routing

Edit `core/models/tiers.yaml` and `core/models/providers.yaml` first, then sync `rules/behaviors.md` and `docs/task-routing.md` for the active target.

## Philosophy

This template encodes several principles learned from daily AI-assisted development:

1. **Structure > Prompting**: A well-organized config file beats clever one-off prompts every time.
2. **Memory > Intelligence**: An AI that remembers your past mistakes is more valuable than a smarter AI that starts fresh each session.
3. **Verification > Confidence**: The cost of running `npm test` is always less than the cost of shipping a broken build.
4. **Layered Loading > Flat Config**: Don't dump everything into context. Load rules always, docs on demand, data when needed.
5. **Auto-save > Manual Save**: If it requires the user to remember, it will be forgotten. Make it automatic.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI (Claude Max or API subscription)
- Optional: Codex CLI for cross-verification
- Optional: Ollama for local model fallback
- Optional: other targets via `targets/` adapter docs

## Prior Art & Credits

This template draws from:
- [Manus](https://manus.im/) file-based planning approach
- OWASP Top 10 for security review patterns
- Real-world experience from building [x-reader](https://github.com/runesleo/x-reader) (650+ stars) and other open-source projects

## Contributors

- **Original Author**: [@runes_leo](https://x.com/runes_leo) - Initial workflow design and implementation
- **Fork Maintainer**: [@nehcuh](https://github.com/nehcuh) - Modularization, testing, and Chinese localization

## Acknowledgments

This project builds upon the excellent foundation laid by [@runes_leo](https://x.com/runes_leo)'s original claude-code-workflow. The fork aims to enhance maintainability and extend the workflow to serve Chinese-speaking developers while preserving the core philosophy.

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=runesleo/claude-code-workflow&type=Date)](https://star-history.com/#runesleo/claude-code-workflow&Date)

## License

MIT — Use it, fork it, make it yours.

Original work Copyright (c) 2024 runes_leo
Modified work Copyright (c) 2025 nehcuh

---

**Original Author**: [@runes_leo](https://x.com/runes_leo) — more AI tools at [leolabs.me](https://leolabs.me) — [Telegram Community](https://t.me/runesgang)
**Fork Maintainer**: [@nehcuh](https://github.com/nehcuh)
