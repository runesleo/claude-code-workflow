# QuietHarness launch draft — not published

## Main post

AI 工作流最常见的技术债，不是 Prompt 写得差，而是所有能力都住进了 hot path。

我把之前开源的 Claude Code Workflow 重做了，也给它起了一个能长期演进的名字：**QuietHarness**。

它面向的不是第一次打开 Claude Code 的人，而是已经用 Claude Code / Codex / Cursor 做了几个月真实项目，规则、Hook、Skill、Memory 和收尾流程越积越多，最后开始替工作流打工的人。

我以前的问题也不是配置不够强，而是把不同生命周期的东西全塞进每次对话：Morning、Today、Router、Review、日报、同步、收尾……真正的请求还没得到处理，注意力已经消耗在路由和仪式上。

QuietHarness 把工作流拆回三层：

1. **常驻核心**：只留大多数任务都会用到的行为，以及忘了会造成不可逆后果的边界。
2. **按需能力**：把你原来已有的项目事实、Debug、Review、研究和发布能力移到按需层，用到才加载。
3. **后台系统**：你原来已有的日报、同步和监控继续独立运行，产出 Artifact 或异常通知，不再挡在开工前。

当前仓库交付的是小型共享核心、三端薄适配、盘点脚本、安装器和迁移指南，不捆绑一套新的能力大礼包。

它的好处不是一个模糊的“更快”，而是这些可观察的变化：

- 小任务可以直接开始；
- Claude Code、Codex、Cursor 共享同一套底层原则；
- 你已有的专业能力可以保留在 Skill 或项目文档里，按需加载；
- 测试、权限和脚本能保证的事，不再反复写进 Prompt；
- 迁移先盘点、再 dry-run、自动备份，失败可回滚。

现在我判断一条规则该住哪，只问三件事：

1. 大多数任务都会用到吗？
2. 忘了它，后果是否不可逆或代价很高？
3. 能否用测试、权限或脚本机械保证？

真正好的 AI 工作流，不是规则越多越稳，也不是删得越狠越高级，而是让每种能力待在正确的运行层。

这就是 QuietHarness 接下来会持续演进的方向。四张图把架构、前后体验和判断方法都画清楚了。

## Optional reply 1 — who it is not for

QuietHarness 不是 Skill 大礼包，也不是新的多 Agent 编排框架。

如果你要的是开箱即用的任务库、模型路由、自动 Morning/Today/Session End，旧 v2 反而更完整。

v3 服务的是另一类人：系统已经很强，但配置债开始反过来拖累真实工作。

## Optional reply 2 — repository boundary

当前版本会盘点 Claude / Codex / Cursor 的配置面，安装一份小型共享核心，并提供 dry-run、备份和回滚。

它不会一键理解并重写你所有历史 Skill、Hook 和 Command；这些仍然先按迁移指南逐项停用。公开指标只描述配置字节，不冒充速度或质量 benchmark。
