---
name: session-end
description: Session wrap-up - update handoff + commit + auto-record experience
version: 2.0.0
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

# Session End — Wrap-up Workflow

> Trigger: `/session-end` or exit signals ("that's all for now" / "heading out")

## Core Steps (5 steps)

### 1. Experience Recording

Review the session for valuable learnings:

**Recording threshold (must meet at least one)**:
- Reusability: Next time encountering similar problem, can look it up directly
- Counter-intuitive: Violates common assumptions
- High cost: Took >10 minutes cumulative

**Don't record**:
- One-shot small fixes
- Project-specific temporary config
- Issues already in project-knowledge.md

**Write target**:
- Technical pitfalls → `memory/project-knowledge.md` (Technical Pitfalls section)
- Reusable patterns → `memory/project-knowledge.md` (Reusable Patterns section)
- Architecture decisions → `memory/project-knowledge.md` (Architecture Decisions section)

### 2. session.md Hot Data Layer

Append to `memory/session.md` under `## Current Session`:

```markdown
### SN (HH:MM~) [project/topic]
- [1-2 sentences of what was done]
- [Important decisions/discoveries]
- [Next steps]
- [Recorded: yes/no - brief description]
```

Also update `## In-Flight Tasks (Cross-Session)` if applicable:
- Tasks progressed → Update context/next_action/updated
- New multi-session tasks → Append new entry
- Completed tasks → Remove (session.md already has the completion record)
- Blocker resolved → Change status from blocked to active

### 3. overview.md Status Refresh (if needed)

**Identify projects touched in this session** (from session.md, changed files, conversation content).

**Goals section update**:
- **Completed** → Remove entry (session.md already has the record)
- **Progress made** → Update description
- **New important item discovered** → Add to current week (max 5 items)

**Projects Summary update** (only rows for touched projects):
- Metric changes → Update (e.g. follower count, stars, metrics)
- Status changes → Update (e.g. "not started" → "first version shipped")

### 4. PROJECT_CONTEXT.md Handoff

Update `<!-- handoff:start/end -->` block.

**Auto-trim (every execution)**:
- Keep only **latest + 1 previous** handoff block within markers
- Delete older handoffs (git history has full record)
- Target: SESSION_HANDOFF section ≤80 lines

### 5. Git Commit (when there are changes)

```bash
git add [specific files]  # Never git add .
git commit -m "[type]: [description]"
```

### 6. Content Mining (Optional)

**Condition**: session.md has ≥3 session records for the day.

Quick scan session.md for 1-2 findings with sharing potential (counter-intuitive / data-driven / pitfall-to-solution).

**Output (when found)**:
```
Content material: Found N shareable discoveries today
  1. [Title] — [one-line angle]
  2. [Title] — [one-line angle]
```

**Nothing found**: Skip silently.

## Output Format

```
Experience: [Recorded N items / None needed]
session.md updated
overview.md: [goals updated / projects updated / no changes]
Handoff updated
Committed [N] files
Content material: [N items / none (<3 sessions)]
```

## Migration Notes

> This skill was updated for the 3-tier memory architecture (v2.0.0).
> 
> Old files replaced:
> - `memory/today.md` → `memory/session.md`
> - `memory/active-tasks.json` → inline in `memory/session.md`
> - `memory/goals.md` + `memory/projects.md` + `memory/infra.md` → `memory/overview.md`
> - `patterns.md` → `memory/project-knowledge.md` (Reusable Patterns section)
