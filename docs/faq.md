# Frequently Asked Questions

> Honest answers about capabilities and limitations.

---

## Q: Does this workflow automatically save my progress?

**A: No.** The workflow provides structured templates and prompts for saving progress, but you must:
- Explicitly signal session end (say "I'm heading out" or similar)
- Or manually update `memory/session.md`
- Or invoke the session-end skill

Nothing happens automatically when you close your terminal.

---

## Q: Will Claude automatically learn from my mistakes?

**A: No.** The workflow provides:
- Guidelines for recording lessons to `memory/project-knowledge.md`
- Structure for organizing patterns and pitfalls
- Prompts to review past recordings

But recording and applying lessons requires manual action or explicit LLM tool use.

---

## Q: Can I use this with Cursor/Warp/VS Code/etc.?

**A: Partially.** We have target adapter documentation for multiple platforms, but:

- **Claude Code**: ✅ Fully supported and tested
- **OpenCode**: ✅ Fully supported and tested
- **All others**: ⏸️ Planned; configs are generated but integration is incomplete

Check [targets/README.md](targets/README.md) for current status.

---

## Q: Does the workflow automatically route tasks to the right model?

**A: No.** We provide:
- Semantic capability tiers (critical_reasoner, workhorse_coder, etc.)
- Guidelines for which tier fits which tasks
- Model mapping suggestions per platform

But actual model selection depends on your tool's capabilities and your explicit choices.

---

## Q: Will skills trigger automatically?

**A: No.** Skill triggers are rules written in markdown. The LLM must:
1. Read the rules
2. Recognize the scenario match
3. Decide to invoke the skill

There is no automatic invocation mechanism.

---

## Q: Does RTK reduce my Claude Code token usage by 60-90%?

**A: Partially.** RTK filters command outputs (git status, test results, etc.) before they reach Claude. This reduces tokens from command outputs, but:
- Not your conversation history
- Not file contents you read
- Only commands RTK recognizes

---

## Q: Is the memory system a database?

**A: No.** "Memory" is markdown files in your repository:
- `memory/session.md` — daily notes
- `memory/project-knowledge.md` — patterns and pitfalls
- `memory/overview.md` — goals and project list

You read and write these files manually or via LLM tool calls.

---

## Q: What's actually automatic then?

**A: Very little.** The workflow primarily provides:
- Structured file organization
- Written rules and guidelines
- Templates for common activities
- A generator CLI for copying configs

Most "automation" is actually you or your LLM reading rules and deciding to follow them.

---

## Q: Why would I use this if it's not automatic?

**A: Structure and consistency.** Even without automation, the workflow provides:
- Organized approach to AI-assisted development
- Checklists and procedures to follow
- Place to record and find past decisions
- Common vocabulary for task types

Think of it as a well-organized playbook, not a robotic assistant.

---

## Q: How do I know what's real vs marketing?

**A: Check this FAQ and the [Known Limitations](../README.md#known-limitations) section. We're committed to honest documentation. If something sounds too good to be true, it probably is — check the FAQ.

---

## Q: What platforms are fully supported?

**A: Two platforms:**

| Platform | Status | Notes |
|----------|--------|-------|
| **Claude Code** | ✅ Production | Fully tested, actively maintained |
| **OpenCode** | ✅ Production | Fully tested, actively maintained |

Other platforms (Cursor, Warp, VS Code, Kimi Code, Codex CLI, Antigravity) have generated configs but limited testing.

---

## Q: How do I save my session progress?

**A: Three ways:**

1. **Say exit phrases**: "I'm heading out", "Done for today", "结束了", "保存一下"
2. **Invoke session-end skill**: Ask Claude to run the session-end skill
3. **Manual update**: Directly edit `memory/session.md`

The workflow provides prompts, but you must initiate the save.

---

## Q: Can I customize the workflow for my project?

**A: Yes.** Use `.vibe/overlay.yaml` in your project:

```yaml
schema_version: 1
profile:
  mapping_overrides:
    critical_reasoner: claude.opus-4-latest
policies:
  append:
    - id: my-project-rule
      category: workflow
      enforcement: recommended
      summary: "My project-specific rule"
```

See `examples/project-overlay.yaml` for a full example.

---

## Q: What if Claude doesn't follow the rules?

**A: Remind it.** The rules are prompts, not enforcement:
- Point Claude to `rules/behaviors.md`
- Ask it to "check memory for past lessons"
- Remind it to "verify before claiming completion"

The workflow provides structure; you provide the oversight.

---

## Q: How do I report misleading documentation?

**A: Open an issue.** We are committed to honest documentation. If you find claims that don't match reality, please let us know so we can fix them.

---

*Last updated: 2026-03-12*
