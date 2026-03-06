# Start Systematic Debugging

When encountering a bug or test failure, start the systematic debugging flow.

## Debugging Principle

```
NO FIXES WITHOUT ROOT CAUSE FIRST
NO INVESTIGATION WITHOUT MEMORY RECALL FIRST
```

## Five-Phase Flow

### Phase 0: Memory Recall (MANDATORY FIRST STEP)

1. **Extract keywords from error** (error type, component, project)
2. **Query memory** for related past experiences
3. **Review results**:
   - Found relevant experience? → Apply directly, skip to Phase 4
   - Partial match? → Use as starting point
   - Nothing? → Proceed to Phase 1, remember to record solution later

### Phase 1: Root Cause Investigation

1. **Read error messages completely** — don't skip any warnings
2. **Reproduce consistently** — exact steps, every time?
3. **Check recent changes**
   ```bash
   git log --oneline -10
   git diff HEAD~5
   ```
4. **Trace data flow** — where does bad value come from? Trace to source

### Phase 2: Pattern Analysis

1. Find **working** similar code
2. Compare **working** vs **broken** differences
3. List every difference point

### Phase 3: Hypothesis Testing

1. Form clear hypothesis: "I think X is the root cause because Y"
2. Make **minimal change** to test hypothesis
3. Change one variable at a time

### Phase 4: Implementation

1. Write **failing test** first
2. Implement **single fix**
3. Verify tests pass
4. Confirm no regression

## 3-Attempt Rule

```
If 3 consecutive fix attempts fail:
  → STOP
  → Reassess architecture
  → Might be architecture issue, not code bug
```

## Output Requirements

After debugging, record:
- What was the root cause
- How it was found
- Fix approach
- How to prevent recurrence
