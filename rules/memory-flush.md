# Memory Management

> Optimize token usage by centralizing memory logging. Use 3 core layers.

## Core Memory Layers

1. **`memory/session.md`** (Hot layer: replaces today.md and active-tasks.json)
   - Purpose: Active tasks, progress, crash recovery.
   - Trigger: Non-trivial task starts or is completed. Auto-save frequently.

2. **`memory/project-knowledge.md`** (Warm layer: replaces MEMORY.md and patterns.md)
   - Purpose: Technical pitfalls, cross-project patterns, and project-specific architecture decisions.
   - Trigger: Counter-intuitive discoveries, architecture shifts, important external analysis.

3. **`memory/overview.md`** (Cold layer: replaces projects.md, goals.md, infra.md)
   - Purpose: High-level infrastructure, roadmap goals, and cross-project status.
   - Trigger: Low-frequency manual maintenance or major project milestones.

## Trigger Conditions
- **Non-trivial task starts** → Write to `session.md` immediately.
- Each code commit → Update `session.md` and (if project-level shifts occurred) `project-knowledge.md`.
- Architecture/strategy decision → Immediately record in `project-knowledge.md`.

## Exit Signals / 退出信号 (Execute full Flush immediately)

Trigger session-end flush when user indicates session completion using:

### English Phrases / 英文短语
- "That's all for now"
- "Done for today"
- "I'm heading out"
- "Going out"
- "Talk later"
- "Closing window"
- "Save session"
- "Wrap up"

### Chinese Phrases / 中文短语
- "我要走了" / "我先走了"
- "今天就到这里" / "今天先到这"
- "结束了" / "搞定了" / "完成了"
- "保存一下" / "保存进度"
- "先这样吧" / "就这样吧"
- "退下了" / "撤了"
- "去吃饭了" / "先忙了"

### Semantic Indicators / 语义指示
- User mentions leaving, completing, or wrapping up
- User asks to save progress or record current state
- Natural end of conversation flow
- User says they need to go / have to leave

→ **Immediately run session-end flush when ANY of the above are detected**

Banned: Writing to 7+ splintered files. Keep token usage lean and consistent.
