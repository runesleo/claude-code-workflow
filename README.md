# Claude Code Workflow

A battle-tested workflow template for Claude Code — memory management, context engineering, and task routing from 3 months of daily usage across multiple projects.

**Not a tutorial. Not a toy config. A production workflow that actually ships.**

## Why This Exists

Claude Code is powerful out of the box, but without structure it becomes a smart assistant that forgets everything between sessions. This template turns it into a **persistent, self-improving development partner** that:

- Remembers past mistakes and applies lessons automatically
- Manages context across long sessions without drifting
- Routes tasks to the right model tier (Opus/Sonnet/Haiku/Codex/Local)
- Forces verification before claiming completion (no more "should work now")
- Auto-saves progress so closing the window doesn't lose work

## Architecture: Three Layers

```
┌─────────────────────────────────────────────────────────┐
│  Layer 0: Auto-loaded Rules (always in context)         │
│  ┌─────────────┐ ┌────────────┐ ┌───────────────┐     │
│  │ behaviors.md │ │skill-      │ │memory-flush.md│     │
│  │              │ │triggers.md │ │               │     │
│  └─────────────┘ └────────────┘ └───────────────┘     │
├─────────────────────────────────────────────────────────┤
│  Layer 1: On-demand Docs (loaded when needed)           │
│  agents.md · content-safety.md · task-routing.md        │
│  behaviors-extended.md · scaffolding-checkpoint.md ...   │
├─────────────────────────────────────────────────────────┤
│  Layer 2: Hot Data (your working memory)                │
│  today.md · projects.md · goals.md · active-tasks.json  │
└─────────────────────────────────────────────────────────┘
```

**Why three layers?** Context window is expensive. Loading everything wastes tokens and degrades quality. This system loads rules always (~2K tokens), docs only when relevant (~1-3K each), and keeps your daily state hot for instant recall.

## What's Inside

```
claude-code-workflow/
├── CLAUDE.md                     # Entry point — Claude reads this first
├── README.md                     # You are here
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
│   ├── scaffolding-checkpoint.md # "Do you really need to self-host?" checklist
│   └── task-routing.md           # Model tier routing + cost comparison
│
├── memory/                       # Layer 2: Your working state (templates)
│   ├── today.md                  # Daily session log
│   ├── projects.md               # Cross-project status overview
│   ├── goals.md                  # Week/month/quarter goals
│   └── active-tasks.json         # Cross-session task registry
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

### 1. Copy to your Claude Code config

```bash
# Clone the template
git clone https://github.com/runesleo/claude-code-workflow.git

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

- Start coding and notice the **task routing** ("🔀 Route: bug fix → Sonnet")
- Hit a bug and watch **systematic debugging** kick in
- Say "that's all for now" and see **session-end** auto-save everything
- Come back tomorrow and find your context preserved in `today.md`

## Key Concepts

### SSOT (Single Source of Truth)

Every piece of information has ONE canonical location. The SSOT table in CLAUDE.md maps info types to files. Claude is trained to check SSOT before writing, preventing the "same info in 5 places, all outdated" problem.

### Memory Flush

Claude auto-saves progress on every task completion, every commit, and every exit signal. You can close the window mid-sentence and nothing is lost. No more "I forgot to save my context."

### Verification Before Completion

The most impactful rule: Claude cannot claim work is done without running the verification command and reading the output. Eliminates the #1 AI coding failure mode — "should work now" without actually checking.

### Three-Tier Task Routing

Not every task needs Opus. The routing system automatically matches task complexity to model tier:
- **Opus**: Critical logic, security-sensitive, complex reasoning
- **Sonnet**: Daily development, analysis, most coding tasks
- **Haiku**: Simple queries, subagent tasks, quick lookups
- **Codex**: Cross-verification, code review, second opinions
- **Local**: Commit messages, formatting, offline work

### Sunday Rule

System optimization happens on Sundays. On other days, if you try to tweak your workflow instead of shipping, Claude will intercept and remind you to focus on output. Configurable to any cadence you prefer.

## Customization Guide

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

Edit `rules/behaviors.md` → "Task Routing" section, and `docs/task-routing.md` for detailed tier definitions.

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

## Prior Art & Credits

This template draws from:
- [Manus](https://manus.im/) file-based planning approach
- OWASP Top 10 for security review patterns
- Real-world experience from building [x-reader](https://github.com/runesleo/x-reader) (650+ stars) and other open-source projects

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=runesleo/claude-code-workflow&type=Date)](https://star-history.com/#runesleo/claude-code-workflow&Date)

## License

MIT — Use it, fork it, make it yours.

## About the author

*Leo ([@runes_leo](https://x.com/runes_leo)) — AI × Crypto independent builder. Trading on [Polymarket](https://polymarket.com/?r=githuball&via=runes-leo&utm_source=github&utm_content=claude-code-workflow), building data and trading systems with Claude Code and Codex.*

[leolabs.me](https://leolabs.me) — writing · community · open-source tools · indie projects · all platforms.

[X Subscription](https://x.com/runes_leo/creator-subscriptions/subscribe) — paid content weekly, or just buy me a coffee 😁

*Learn in public, Build in public.*
