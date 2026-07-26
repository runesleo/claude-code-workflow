# QuietHarness launch draft — not published

## Main post

之前我开源 Claude Code Workflow 后，其实没有频繁维护。很多人 fork 之后，按自己的需要继续改。

这次重新动它，不是为了再造一套大而全的 AI OS。

最近我把 Claude Code、Codex、Cursor 三端配置彻底重构，并放回真实项目里继续使用。最大的感受不是“Prompt 变短了”，而是小任务可以直接开始，复杂任务也没有因此失去连续性。

所以我把这版整理成了 QuietHarness。

默认 Core 仍然很小，只负责直接执行、真实证据、按风险验证，以及不可逆动作前确认。

但瘦身以后，真正难的问题才出现：

如果不再把 Morning、Today、Memory 和任务状态塞进每次对话，跨项目、跨会话、跨客户端的连续性怎么保留？

这次新增的不是任务库，而是一套可选参考架构：

Personal → Workspace → Task

- Personal：稳定偏好与私人系统指针；
- Workspace：当前项目或业务范围的入口、测试和事实源；
- Task：状态、下一步、证据与更新时间。

三层都不会全量塞进每次对话。真正连接它们的是三个协议：

1. readout：只读取当前请求需要的那一小段事实；
2. writeback：状态发生变化时立即写回事实源，不等 Session End 再统一回忆；
3. freshness：缺失或过期状态必须回源核验，不能让旧状态冒充当前事实。

仓库现在交付三端 Core、安全迁移工具、连续性协议和脱敏示例；不交付我的任务库、身份、账号、私有路径、scheduler 或个人工作台。

这层架构完全可选，因此本次新增没有让默认热路径增加一个字节。

我暂时不把它想得太远。先让它继续在我自己的真实工作里接受检验；后面每次发现确实有用、也能被别人复用的更新，再持续写回公共版本。

真正想分享的不是我的文件夹，而是这件事：

一个很小的 Core，可以接入复杂系统，但不必让复杂系统重新占领热路径。

轻量和连续性，不需要二选一。

## Optional reply 1 — what is actually included

当前版本包含：

- Claude Code / Codex / Cursor 三端薄入口；
- inventory、dry-run、backup、rollback；
- Personal / Workspace / Task 双轴架构说明；
- readout / writeback / freshness 协议；
- 不含私人数据的 solo-builder 示例。

没有内置任务数据库，也不会自动修改 scheduler、发布内容或跨会话派工。

## Optional reply 2 — release boundary

这次最刻意的一点，是把“参考架构”和“默认运行时”分开。

你可以只安装 2,292 字节的三端模板，完全不用任务连续性示例；也可以把示例接到自己已有的文件、Issue Tracker 或数据库。

协议是公共的，存储和执行机制由使用者自己决定。

## Image order

1. `01-positioning.zh.png` — 瘦身以后，连续性怎么办？
2. `02-three-layers.zh.png` — Personal → Workspace → Task
3. `03-before-after.zh.png` — readout / freshness / writeback / receipt
4. `04-rule-placement.zh.png` — 仓库交付与私人边界
