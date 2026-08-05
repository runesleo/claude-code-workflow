# QuietHarness v3 launch draft — not published

## Main post

几个月前，我开源过一套 Claude Code Workflow。

后来公开仓库没怎么更新，但我自己的系统一直没停：Claude Code、Codex、Cursor，各种模型，交易、数据、内容、视频、开源项目，全都在里面继续迭代。

最近用了一段时间最高推理档的模型，我回头看 v2，发现它有点过度设计了。

当时模型容易忘、容易乱跑，我就不断往里加规则、Hook、Skill、Memory、模型路由、Morning、Today、Session End。

这些东西不是瞎设计的，当时都解决过真实问题。但模型变强以后，一部分保护开始变成重复规划、误触流程和维护负担。

所以我把三端配置重新瘦了一遍：

- 共用 Core：1,604 字节；
- Claude Code 入口：168 字节；
- Cursor 项目规则：546 字节；
- 三端模板合计：2,318 字节。

但我的工作系统并没有因此变成一条 Prompt。

它现在是一张地图：

1. Claude Code / Codex / Cursor 共用一个小 Core；
2. 九条长期业务线负责稳定归属；
3. 每个长期任务有自己的事实源，Owner 稳定，Worker 可以替换；
4. 同一个仓库或任务事实面默认只有一个 Writer；
5. 日报、同步和监控在后台继续运行，成功时安静，异常时提醒；
6. 已经长成独立能力的分支，继续放在自己的开源仓库里。

比如：

- 预测市场 → polymarket-toolkit；
- 内容摄入 → x-reader / tg-reader-mcp / long-media-cli；
- 视频制作 → claude-video-kit；
- 健康资料 → ai-health-vault；
- 系统体检 → claude-skill-audit。

这次我更新旧仓库，不是想再造一个人人通用的 AI OS。

我只是把自己目前真实在用的 AI 工作系统重新整理出来：保留业务结构、任务系统、失败后长出来的边界和各个开源分支，只拿掉私人路径、实时任务、账号和生产控制面。

新版本叫 QuietHarness。

Harness 还在，但没有相关任务时，它应该安静。

仓库仍然是原来的 claude-code-workflow，Git 历史也继续保留。以后我在真实工作里验证出新的东西，再继续往这张地图上更新。

仓库链接放在 1F。

## Optional reply 1 — repository and what ships

仓库：
https://github.com/runesleo/claude-code-workflow

实际包含：

- Claude Code / Codex / Cursor 三端小 Core；
- inventory、dry-run、backup、rollback；
- 我的业务线和任务系统地图；
- per-task SSOT、readout/writeback、claim 和 writer-lock 的脱敏示例；
- 日报与交互工作流的边界；
- 已开源业务分支的入口。

不包含我的实时任务、账号、仓位、健康记录、thread ID、scheduler 或生产环境。

## Optional reply 2 — current map

我的九条长期业务线：

⌘0 Personal Ops
⌘1 Strategy Lab
⌘2 Data Platform
⌘3 Portfolio
⌘4 Content Studio
⌘5 Products & Growth
⌘6 Health Ops
⌘8 Daily Rhythm
⌘9 Research Desk

它们不是九个常驻 Agent，而是九个稳定的业务 Owner。模型、客户端和对话都可以换，事实归属不跟着漂移。

## Image order

1. `00-system-map.zh.png` — 整套真实系统地图
2. `01-positioning.zh.png` — 瘦身以后，连续性怎么办
3. `03-before-after.zh.png` — 任务读取、验证与写回
4. `04-rule-placement.zh.png` — 公开结构与私人运行态边界

`02-three-layers.zh.png` 可作为 README 深入图，不占主帖四图。
