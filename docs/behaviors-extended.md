# Behavior Rules Extended (On-demand loading)

> Low-frequency rules split from rules/behaviors.md. Load when needed.

---

## Knowledge Base Write Strategy (Prevent chaos)

> **Core principle**: Judge confidence before AI writes, uncertain -> goes to Inbox

**Pre-write decision tree**:
```
Received content to record ->
|-- Clear precedent? (same directory has similar files, consistent format)
|   +-- File directly + update knowledge index
|-- Know the domain but no precedent?
|   +-- Write to Inbox, annotate suggested location
+-- Not sure about classification?
    +-- Write to Inbox
```

**"Clear precedent" criteria**:
1. Target directory already has same-type files
2. Knowledge index already has relevant section to append to
3. File naming and frontmatter format can reference existing files

**When filing directly**:
- Knowledge index = "index" not "content" — detailed analysis goes in separate files
- Follow existing naming conventions

**Banned**:
- Same content written to multiple files (SSOT violation)
- Inventing new directories without precedent
- Stuffing detailed analysis into index files
- Writing to old memory file paths (today.md, active-tasks.json, etc.)
- Skipping decision tree

---

## Proactive Association Rules (All scenarios)

> **Core principle**: Understand intent, don't just execute instructions

### Scenario 1: Receiving external content

When user shares URL / article / tweet, ask 4 dimensions:
1. What does the content say? (Surface)
2. Related to user's positions/investments? (Investment)
3. Related to user's projects? (Work)
4. What decision might user need to make? (Action)

### Scenario 2: Starting new task

Check memory/project-knowledge.md first:
- Any related pitfall records in the Technical Pitfalls section?
- Any related decision patterns in the Architecture Decisions section?

### Scenario 3: Completing code task

Self-check:
- Does this task have tweet/sharing value?
- Any pitfall experience to record in memory/project-knowledge.md?
- Need to update PROJECT_CONTEXT.md?

### Scenario 4: User mentions person/company/project

Associate:
- Previous interactions with this entity
- Relevant knowledge base entries

### Scenario 5: User expresses emotion (tired/frustrated/anxious)

Associate:
- Recent work intensity (memory/session.md)
- Don't take it literally

### Scenario 6: User asks "what do you think about X"

Check first:
- User's involvement in X domain
- User's projects in X domain
- Then analyze X itself

---

## Prompt Review Mode (L3+ Tasks)

```
User requirement -> Claude outputs "execution plan" -> User approves -> Claude executes + self-verifies -> Report
```

**Execution plan template**:
```
## Execution Plan
**Task**: [one sentence]
**Scope**: [files/modules]
**Verification**: [lint/build/test]
**Risk**: [potential issues]
```

---

*Split from behaviors.md for on-demand loading*
