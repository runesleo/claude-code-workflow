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
