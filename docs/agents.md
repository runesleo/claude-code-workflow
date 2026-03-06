# Agent Configuration & Multi-Model Collaboration

> On-demand loading. Contains Agent assignment, Subagent dispatch, multi-model routing rules.

---

## Agent Task Assignment

### Opus Tier (Critical, highest quality)

| Agent | Scope | Core Duty |
|-------|-------|-----------|
| **your-critical-agent** | Critical business logic | Validation, quality control |

### Sonnet Tier (Complex tasks, balance quality/speed)

| Agent | Scope | Core Duty |
|-------|-------|-----------|
| **pr-reviewer** | Code review | PR quality, architecture consistency |
| **security-reviewer** | Security audit | Vulnerability detection, sensitive info |
| **performance-analyzer** | Performance analysis | Bottleneck identification, optimization |
| **your-custom-agent** | *Your domain* | *Customize to your project needs* |

### Haiku Tier (Quick tasks)

| Agent | Scope | Core Duty |
|-------|-------|-----------|
| **your-quick-agent** | *Quick tasks* | *Customize: e.g. build fixes, formatting* |

### Built-in Agents

| Agent | Model | Use |
|-------|-------|-----|
| general-purpose | sonnet | General multi-step tasks |
| Explore | haiku | Quick codebase exploration |
| Plan | inherit | Architecture design, implementation planning |
| claude-code-guide | haiku | Claude Code usage guide |

### Coordinator Agent (Main Agent = Claude Opus)

| Duty | Description |
|------|-------------|
| **Orchestrate** | Dispatch tasks to other Agents/Codex |
| **Decide** | Final judgment on critical matters |
| **Memory** | Maintain hot data layer (today.md) |
| **Align** | Daily status alignment |

---

## Subagent Dispatch Rules

> **Default parallel, unless there are dependencies**

**Trigger conditions (dispatch when any met)**:
- >=2 independent tasks
- P0 has multiple pending items
- User says "in parallel" / "simultaneously"
- Complex task can be split into independent modules

**Memory injection protocol (mandatory when dispatching subagent)**:
```
You are working on [project-name].

## Context Loading (must read first)
1. ~/.claude/memory/today.md — Today's work context
2. /path/to/project/PROJECT_CONTEXT.md — Project status

## Task
[Specific task description]

## Completion Requirements
1. Run lint + build yourself, confirm PASS
2. Update PROJECT_CONTEXT.md Session Handoff section
3. Report results
```

---

## Multi-Model Collaboration

> Main Agent focuses on orchestration, delegates execution

### Main Agent Duties (Claude Opus)

| Do | Don't |
|----|-------|
| Understand requirements, decompose tasks | Write large code blocks |
| Critical decisions | Simple CRUD |
| Verify external output | Document cleanup |
| Maintain memory system | Repetitive tasks |

### External Model Routing

| Task Type | Default Executor | Method |
|-----------|-----------------|--------|
| Critical logic | Codex | `codex exec "..."` |
| Frontend / docs | Alternative model | As configured |

### Sensitive Code (Never outsource)

- Critical execution logic (orders, state changes, settlements)
- Credential operations (signing, auth, key management)
- Secret/Token handling
- Core business calculations (metrics, risk assessment)

---

## Multi-Model Cross-Verification (Standard Practice)

> Important analyses/decisions get second-model verification to avoid single-point blind spots

### Trigger Conditions (Proactive)

| Scenario | Must Cross-Verify |
|----------|-------------------|
| **Critical business analysis** | Yes |
| **Architecture/system design** | Yes |
| **Strategy decisions** | Yes |
| **Risk assessment** | Yes |
| **Complex bug diagnosis** | Yes |

### Output Format

```
Multi-model cross-verification:
- Claude's view: [xxx]
- Codex/Other view: [xxx]
- Consensus: [xxx]
- Divergence: [xxx]
- Final conclusion: [xxx]
```

---

## Multi-Model SSOT Collaboration Contract

> All models use Claude as the hub, unified project state management.

### Data Layers

| Layer | Location | Writer | Purpose |
|-------|----------|--------|---------|
| **L0 Rules Layer** | ~/.claude/ | Claude only | Rules, memory, experience |
| **L1 Interface Layer** | PROJECT_CONTEXT.md | All models (restricted) | Project state |
| **L2 Archive Layer** | Knowledge vault | Claude + automation | Persistent knowledge |

### L1 Interface: PROJECT_CONTEXT.md Structure

Fixed structure, external models can only write to the Handoff block:

```markdown
# [Project Name] - Project Context

## Architecture (Claude maintains)
## Current Focus (Claude maintains)

<!-- handoff:start -->
## Session Handoff
- Last: [time] by [model-name]
- Task: [task ID/description]
- Did: [what was done]
- Next: [next steps]
- Blocker: [blockers]
<!-- handoff:end -->

## Tech Debt (Claude maintains)
```

### External Model Injection Template

```bash
codex exec "
# Project Contract (must follow)
1. Read PROJECT_CONTEXT.md first for status
2. Only modify code files + content between <!-- handoff:start/end -->
3. Never create/modify: ROADMAP.md, FOCUS.md, TODO.md, TASKS.md, STATUS.md
4. Never write to ~/.claude/ or knowledge vault (unless task explicitly requires)
5. After completion, write Handoff: Last: [time] by [model], Task: [description]

# Task
[specific task description]

# Verification
[verification commands]
"
```

### File Operation Whitelist

| Model | Can Create | Can Modify | Never Touch |
|-------|-----------|-----------|-------------|
| Claude | Anything (following behaviors.md) | Anything | - |
| External models | Code files | Code + Handoff block | ROADMAP/FOCUS/TODO/TASKS/.claude/vault/ |

### Violation Detection (Claude executes during review)

1. `git diff --name-only` — Check for modifications outside whitelist
2. Check PROJECT_CONTEXT.md changes are within `<!-- handoff:start/end -->` markers
3. Violation → `git checkout -- [file]` rollback + record in patterns.md

---

*Customize agent assignments and model routing based on your specific projects and needs.*
