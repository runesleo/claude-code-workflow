---
name: systematic-debugging
description: Systematic debugging - five-phase process, find root cause before fixing
---

# Systematic Debugging

## Overview

Random fixes waste time and create new bugs.

**Core principle:** ALWAYS find root cause before attempting fixes.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
NO INVESTIGATION WITHOUT MEMORY RECALL FIRST
```

## The Five Phases

### Phase 0: Memory Recall (MANDATORY FIRST STEP)

1. **Extract keywords from error** (error type, component, project)
2. **Query memory database** for related past experiences
3. **Review results**:
   - Found relevant experience? → Apply directly, skip to Phase 4
   - Partial match? → Use as starting point
   - Nothing? → Proceed to Phase 1, remember to record solution later

#### Memory Recall Exemptions

Memory Recall is **mandatory by default**, but can be skipped in these cases:

**Automatic Exemptions**:
1. **User Explicit Skip**
   - User says: "don't check history"
   - User says: "this is brand new"
   - User says: "skip memory recall"

2. **Obviously New Feature**
   - Feature name doesn't exist in codebase
   - No similar patterns in project
   - User confirms it's a new concept

3. **Time-Sensitive Emergency**
   - Production outage
   - Security hotfix
   - User explicitly marks as "urgent"

**Conditional Exemptions**:
4. **Trivial Task** (see `core/policies/task-routing.yaml`)
   - <20 lines changed
   - Single file
   - Low risk (docs, comments, etc.)

**When in Doubt**: If unsure whether to skip, **always do Memory Recall**. The cost is low (1-2 minutes) compared to the risk of duplicating work.

**Exemption Log**: When skipping Memory Recall, log the reason:
```markdown
# memory/session.md
## Skipped Memory Recall
- Task: Add new feature X
- Reason: User confirmed it's brand new, no similar patterns exist
- Time saved: ~2 minutes
```

### Phase 1: Root Cause Investigation

1. **Read error messages carefully** — don't skip, read completely
2. **Reproduce consistently** — exact steps, every time?
3. **Check recent changes** — git diff, new deps, config changes
4. **Gather evidence in multi-component systems** — log at each component boundary, run once to find WHERE it breaks
5. **Trace data flow** — where does bad value originate? Trace backward to source

### Phase 2: Pattern Analysis

1. **Find working examples** in same codebase
2. **Compare against references** — read completely, don't skim
3. **Identify every difference** between working and broken
4. **Understand dependencies** — settings, config, environment, assumptions

### Phase 3: Hypothesis and Testing

1. **Form single hypothesis**: "I think X is the root cause because Y"
2. **Test minimally** — smallest possible change, one variable at a time
3. **Verify before continuing** — worked? → Phase 4. Didn't? → New hypothesis

### Phase 4: Implementation

1. **Create failing test case** — simplest reproduction, automated if possible
2. **Implement single fix** — ONE change, no "while I'm here" improvements
3. **Verify fix** — test passes, no other tests broken
4. **If 3+ fixes failed** → STOP, question architecture, discuss before more attempts

## Red Flags - STOP and Follow Process

- "Quick fix for now, investigate later"
- "Just try changing X"
- Proposing solutions before tracing data flow
- "One more fix attempt" (when already tried 2+)

**ALL of these mean: STOP. Return to Phase 1.**

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **0. Memory Recall** | Extract keywords, query memory | Output recall summary |
| **1. Root Cause** | Read errors, reproduce, gather evidence | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare | Identify differences |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix, verify | Bug resolved, tests pass |
