# Messaging Guidelines: Honest Feature Descriptions

> Keep user trust through accurate descriptions.

---

## Words to Avoid

| Avoid | Why | Example Fix |
|-------|-----|-------------|
| "automatic", "auto-" | Implies zero-user-action behavior that doesn't exist | "prompts", "guides", "structured" |
| "intelligent" | Suggests AI-driven decision making; we're just providing rules | "structured", "rule-based", "guided" |
| "remembers" | Implies persistent memory system; it's just files | "records to", "logs to markdown" |
| "applies" | Suggests automatic enforcement; user/LLM must act | "documents", "provides guidance for" |
| "suggests" (alone) | Ambiguous whether it's automatic or manual | "prompts", "provides rules for when to" |
| "on-demand loading" | All files are copied, not dynamically loaded | "layered documentation", "organized by access frequency" |
| "buildable" | Implies full functionality; many targets are partial | "has target adapter docs", "generator produces configs for" |
| "ready" | Unless thoroughly tested | "documented", "adapter drafted" |

---

## Words to Use Instead

| Use | When Describing |
|-----|-----------------|
| "prompts" | User or LLM should do something |
| "guides" | Provides direction but requires execution |
| "structured" | Organized format for manual use |
| "records to" | Writes information to files |
| "documents" | Captures information for reference |
| "provides rules" | Defines when actions should happen |
| "enforces" | Only when there's actual mechanism (e.g., git hooks) |
| "supports" | Capability exists but may require manual steps |
| "experimental" | Not fully tested or implemented |

---

## Template for Honest Feature Descriptions

### Bad (Marketing-style)
> "Automatically saves your progress and learns from your mistakes to improve future sessions."

### Good (Honest)
> "Provides structured templates for session wrap-up. When you signal session end (e.g., 'I'm heading out'), prompts you to record progress to `memory/session.md`. Past recordings are searchable but require manual review to apply."

### Template Structure
```
Provides [structure/format/mechanism] for [activity].
When [trigger condition], [what happens - usually prompts/records].
[Limitation caveat - what user must do].
```

---

## Examples by Feature

| Feature | Honest Description |
|---------|-------------------|
| **Memory system** | "Three-tier markdown file organization for session notes, project knowledge, and overview. Requires manual updates; no automatic capture." |
| **Skill triggers** | "Rule-based guidelines describing when to invoke skills. LLM interprets rules; no automatic invocation." |
| **Platform support** | "Claude Code: fully supported. OpenCode: fully supported. Other targets: adapter documentation exists, implementation varies." |
| **RTK integration** | "Optional CLI tool that filters command outputs. 60-90% reduction on supported commands only; does not reduce conversation token usage." |
| **Verification** | "Rule requiring test execution before completion claims. User must actually run tests; rule is a prompt, not enforcement." |
| **Model routing** | "Semantic hints for matching task complexity to model tiers. Actual model selection depends on tool capabilities and user choice." |
| **Session management** | "Structured templates for recording session progress. Triggered by explicit user signals, not automatic." |

---

## Red Flags to Check

Before claiming a feature, verify:

1. **Is there actual automation?**
   - ❌ "Automatic" → ✅ "Prompts when you say X"

2. **Is it tested?**
   - ❌ "Buildable" → ✅ "Configs generated, limited testing"

3. **Is the scope accurate?**
   - ❌ "Reduces tokens by 60-90%" → ✅ "Reduces command output tokens"

4. **Is 'memory' actually memory?**
   - ❌ "Remembers" → ✅ "Records to markdown files"

5. **Does 'suggests' mean automatic?**
   - ❌ "Suggests skills" → ✅ "Provides rules for when to use"

---

## Commitment to Honesty

Users prefer accurate descriptions over disappointed expectations.

When in doubt:
- **Under-promise, over-deliver**
- **Document limitations explicitly**
- **Distinguish between "provides structure" and "does automatically"**

---

## Review Checklist

Before publishing documentation:

- [ ] No "auto-" or "automatic" claims without programmatic mechanism
- [ ] Platform status is clear (production vs experimental)
- [ ] Limitations are documented, not hidden
- [ ] User action requirements are explicit
- [ ] Examples use honest template structure

---

*Part of the honest documentation initiative.*
