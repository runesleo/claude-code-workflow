# Context Management Guide

## Overview

This document explains how the workflow keeps Claude Code effective across long conversations, multi-file tasks, and multi-day work.

The key distinction is:

- **Repo-local hot state** lives in the 3-tier memory architecture:
  - `memory/session.md` — daily progress + in-flight tasks (hot layer)
  - `memory/project-knowledge.md` — technical pitfalls + patterns (warm layer)
  - `memory/overview.md` — goals + projects + infrastructure (cold layer)
- **Project-specific durable memory** may live in a routed `PROJECT_CONTEXT.md`, depending on how `CLAUDE.md` is configured

The goal is to preserve the right information in the right layer instead of loading everything into context at once.

## Understanding Context Compression

### What is Context Compression?

Claude Code automatically compresses earlier conversation turns as the session grows. In practice, that means:

- **Recent work stays available**
- **Older turns are summarized** to free space
- **Current file context is more likely to survive than old exploration**
- **You can keep working** without manually restarting the session

### When Does Compression Happen?

Compression is triggered by the system when the session becomes large enough that keeping the full raw history is inefficient.

**You cannot manually trigger compression**. The workflow should be resilient to it.

### What Tends to Survive?

After compression, Claude usually retains:

- Recent messages
- System and project instructions
- The current task framing
- Files that are still active in the working set

Details that are easier to lose:

- Earlier exploratory reads
- Long command outputs
- Intermediate debugging branches that no longer look active
- Older decisions that were never written back to repo files

## Layered Loading Architecture

The workflow uses layered loading so that only the minimum necessary context is active at any time.

### Layer 0: Entry Rules (`CLAUDE.md` + `rules/`)

Always loaded or assumed as the behavioral baseline:

- `CLAUDE.md` — entrypoint, SSOT table, loading index, memory routing
- `rules/behaviors.md` — core operating rules
- `rules/skill-triggers.md` — when to invoke reusable skills
- `rules/memory-flush.md` — auto-save and session-end behavior

This layer should stay compact and stable.

### Layer 1: Reference Docs (`docs/`)

Loaded on demand for a specific task:

- `docs/agents.md` — multi-model collaboration
- `docs/content-safety.md` — attribution and critical-content safeguards
- `docs/task-routing.md` — routing by capability and task complexity
- `docs/scaffolding-checkpoint.md` — stack and setup decisions
- `docs/behaviors-reference.md` — extended behavior details
- `docs/context-management.md` — compression recovery and memory strategy

This layer is where detail belongs. It should not all be loaded at once.

### Layer 2: Working State (3-tier `memory/` + project memory)

Updated frequently as work progresses:

**Hot Layer** (`memory/session.md`):
- Daily progress and handoff
- In-flight task registry (cross-session)
- Crash recovery anchor

**Warm Layer** (`memory/project-knowledge.md`):
- Technical pitfalls and gotchas
- Reusable patterns across tasks
- Architecture decisions (ADRs)

**Cold Layer** (`memory/overview.md`):
- Cross-project summaries and pointers
- Week/month/quarter goals
- Infrastructure and operational state

Optional project memory such as `PROJECT_CONTEXT.md` for project-level durable context.

This layer is the recovery surface after compression.

### Why This Matters

Without layering, every task pays the cost of loading rules, reference material, and historical state whether it is needed or not.

With layering:

- More room is left for the active task
- File reads are more targeted
- Recovery after compression is cheaper
- Long sessions degrade more gracefully

## RTK Integration: Command Output Compression

### What RTK Does

RTK (Reduce Toolkit) compresses **command outputs**, not the conversation itself.

Typical examples:

- `git status`, `git log`, `git diff`
- `npm test`, `pytest`, `cargo build`
- other long CLI outputs that would otherwise consume many tokens

### What RTK Does Not Do

RTK does **not**:

- replace Claude's own context compression
- compress file contents
- preserve lost reasoning automatically
- act as a memory system

Use RTK to reduce command-output cost, not as a substitute for writing decisions back to repo files.

## Post-Compression Recovery

### When to Recover

Recover context only when the current task becomes fuzzy. Signs include:

- You no longer remember why a file was opened
- A previous decision matters but is not in active context
- You know the work happened earlier in the session but cannot restate it confidently

### Recovery Ladder

#### Step 1: Search current task keywords

Use search first because it is the cheapest recovery method.

- `grep` exact names, errors, or symbols
- `file_glob` to find likely files
- read only the files that the search identifies

#### Step 2: Read `memory/session.md`

Use `memory/session.md` to recover:

- what was done in this session or day
- important decisions
- current blockers
- next steps
- in-flight tasks (cross-session)

#### Step 3: Read the smallest durable state file that matches the need

Choose the narrowest durable source:

- `memory/overview.md` for cross-project overview and goals
- `memory/project-knowledge.md` for reusable patterns and technical pitfalls
- `PROJECT_CONTEXT.md` for project-level status and architecture state

#### Step 4: Re-open only the specific files you still need

Once the narrative is recovered, go back to precise file reads instead of broad reloads.

### When Not to Recover

Do not spend tokens recovering context if:

- the task is self-contained
- the user already gave exact instructions
- the needed files are already open and sufficient
- the new request is unrelated to earlier work

**Principle**: recover only the missing piece, not the whole session.

## Best Practices

### For Users

#### 1. Keep each file doing one job

- `memory/session.md` = daily progress, handoff, and in-flight tasks
- `memory/project-knowledge.md` = technical pitfalls, patterns, architecture decisions
- `memory/overview.md` = cross-project summaries, goals, infrastructure
- `PROJECT_CONTEXT.md` = project status and architecture state

#### 2. Prefer durable write-back for durable knowledge

If a fact will matter tomorrow, write it to the right repo file instead of assuming the conversation will keep it alive.

#### 3. Let docs load on demand

Do not preload all docs for every task. Load the one document that fits the current question.

#### 4. Keep task boundaries clear

Starting a new topic with a short restatement of goal and constraints reduces future recovery cost.

### For Claude

#### 1. Write to the correct layer

- update `memory/session.md` for progress, handoff, and active tasks
- update `memory/project-knowledge.md` for reusable patterns and technical discoveries
- update `memory/overview.md` for goals and cross-project status changes
- update `PROJECT_CONTEXT.md` for project-level durable context

#### 2. Read efficiently

- search before reading large files
- prefer targeted reads and line ranges
- avoid re-reading unchanged files without a reason

#### 3. Recover cheaply first

Start with search, then `memory/session.md`, then the smallest durable state file that fits the question.

#### 4. Respect layer boundaries

Do not duplicate stable rules into daily memory, and do not turn daily logs into long-term archives.

## Common Scenarios

### Scenario 1: Long Debugging Session

**Problem**: a long debugging thread gets compressed and you lose the earlier branches of investigation.

**Good recovery pattern**:

1. Keep the current debugging trail summarized in `memory/session.md`
2. Move reusable findings into `memory/project-knowledge.md`
3. After compression, recover from those notes instead of re-reading every command output

### Scenario 2: Multi-Day Feature Development

**Problem**: a feature spans several sessions and the same context has to be restored repeatedly.

**Good recovery pattern**:

1. End each session with an update to `memory/session.md`
2. Update `PROJECT_CONTEXT.md` when project-level status changes
3. Move stable technical context into `memory/project-knowledge.md` if it will matter again

### Scenario 3: Context-Heavy Code Review

**Problem**: a large diff is too expensive to hold in active context all at once.

**Good recovery pattern**:

1. Use RTK to compress large `git diff` output when available
2. Review files in logical groups
3. Summarize conclusions in `memory/session.md` or the relevant `PROJECT_CONTEXT.md`
4. Recover from those summaries instead of re-reading the full diff

### Scenario 4: Switching Between Projects

**Problem**: you move between multiple repos or sub-projects in one session.

**Good recovery pattern**:

1. Use `memory/overview.md` for the cross-project overview
2. Follow `CLAUDE.md` memory routes to the correct project files if configured
3. Read the relevant `PROJECT_CONTEXT.md` for project state
4. Keep only reusable cross-project lessons in `memory/project-knowledge.md`

## Practical Budgeting

The biggest token costs usually come from:

- always-loaded rules and instructions
- long conversations
- large file reads
- long command outputs

The workflow reduces that cost by:

- keeping Layer 0 compact
- loading reference docs only on demand
- writing durable context back to repo files
- using search before broad file reads

## Memory File Hygiene

Keep the recovery surface tidy:

- `memory/session.md` can grow during the day, but should be archived periodically
- `memory/overview.md` should stay summary-only
- `memory/project-knowledge.md` should be concise and technical
- `PROJECT_CONTEXT.md` should track active project state, not become a dump of every historical detail

If a memory file is getting large, split stable knowledge into better-scoped durable files rather than expanding one hot file forever.

## Troubleshooting

### "I lost context after compression"

Check in this order:

1. Search by task keywords
2. Read `memory/session.md`
3. Read `memory/overview.md`, `memory/project-knowledge.md`, or `PROJECT_CONTEXT.md` as appropriate

### "Claude keeps re-reading the same files"

Common cause:

- the file location or prior decision was never written back to a durable repo file

Fix:

- note key file locations in `memory/project-knowledge.md`
- summarize task state in `memory/session.md`
- prefer targeted reads instead of broad reloading

### "Memory files are getting too large"

Fix:

1. move summaries to `memory/overview.md`
2. keep `memory/session.md` focused on active work
3. move reusable lessons to `memory/project-knowledge.md`
4. keep project-specific technical context in the project's own durable files

### "RTK is not reducing the cost enough"

Check:

1. whether the output is actually coming from a supported command
2. whether the real problem is conversation history rather than command output
3. whether important conclusions should be written back to repo files instead of repeatedly re-derived

## Related Documentation

- `CLAUDE.md` — loading index, SSOT ownership, memory routing
- `rules/behaviors.md` — core behavior and recovery triggers
- `rules/memory-flush.md` — auto-save triggers
- `docs/agents.md` — multi-model collaboration and project handoff
- `docs/integrations.md` — RTK setup and integration behavior

---

*Last updated: 2026-03-07*
