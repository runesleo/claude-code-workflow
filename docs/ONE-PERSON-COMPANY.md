# AI 一人公司：能力地图与开源路线

**中文** · [English](ONE-PERSON-COMPANY.en.md) · [返回首页](../README.md)

## 为什么开源

一人公司的目标不是拥有尽可能多的 Agent，而是让一个人能够持续发现机会、生产内容、交付产品、服务用户和管理运营。AI 承担可委派的工作；创始人保留目标、商业判断与关键授权。

这里是我长期使用的工作方式的公开入口。不同模块独立演进，已经长成工具的能力继续由原仓库维护。这个仓库负责组织、说明、提供可复用的组合范例和验证方法，不复制另一套业务事实源。

## 公司如何运转

```text
创始人：目标、优先级、关键授权
    ↓
运营总控：理解任务 → 找到原责任方 → 选择执行者
    ↓
研究机会 → 判断价值 → 产品或内容交付 → 分发与用户反馈
    ↑                                      ↓
    └────────── 根据真实证据继续迭代 ────────┘

共享基础层：任务连续性、证据、单 Writer、权限、成本与故障恢复
执行层：现有 AI、Skills、CLI、MCP 和后台工具；可以替换
```

总控是职责，而不是一个必须安装的全能机器人。已有业务责任与事实归属保持不变；换模型、换客户端和换对话不改变任务本身。技术细节见[系统架构](ARCHITECTURE.md)和[任务连续性](TASK-CONTINUITY.md)。

## 业务模块

状态说明：**可试用**＝本仓库已有独立入口与演示；**独立仓库**＝已有公开项目，能力及安装范围以其文档为准；**实验**＝可运行的合成示例或早期治理实现；**待开放**＝已识别的工作流方向，完整可复用包尚未在本仓库交付。状态不是公司收入、用户规模或生产可靠性的证明。

| 模块 | 解决什么问题 | 公开入口与成熟度 |
|---|---|---|
| 机会雷达与研究 | 把分散信号变成有来源、有判断、有下一步的机会 | [资产与机会研究](https://github.com/runesleo/asset-dd-and-opportunity-evaluation)、[Signal Digest Loop](https://github.com/runesleo/x-signal-digest)（独立仓库）；综合雷达流程（待开放） |
| 信息摄入与数据 | 读取链接、社交内容、长视频、播客并保留来源 | [X Reader](https://github.com/runesleo/x-reader)、[TG Reader MCP](https://github.com/runesleo/tg-reader-mcp)、[Long Media CLI](https://github.com/runesleo/long-media-cli)（独立仓库） |
| 文字内容与分发 | 选题、来源核实、草稿、审稿、分发和复盘 | [Content Pipeline Skill](https://github.com/runesleo/content-pipeline-skill)、[Talk Human](https://github.com/runesleo/talk-human)（独立仓库）；完整内容与增长流程（待开放） |
| 视频制作 | 将研究或产品成果做成可审核的脚本与视频 | [Video Kit](https://github.com/runesleo/claude-video-kit)（独立仓库）；组合工作流（待开放） |
| 产品研发 | 需求取舍、实现、回归、可验证交付 | [QuietHarness Core](../examples/first-success/README.md)（可试用）；[OPC Company Layer](../labs/opc-company/README.md)（实验） |
| 商业与用户运营 | 把真实需求、反馈、定价、履约与获客连接起来 | 可复用的合成案例与模块模板（待开放） |
| 投资与策略研究 | 数据、假设、反证、风险与研究记录 | [Polymarket Toolkit](https://github.com/runesleo/polymarket-toolkit)、[资产与机会研究](https://github.com/runesleo/asset-dd-and-opportunity-evaluation)（独立仓库）；不提供默认真钱执行 |
| 个人运营与健康 | 降低日常信息整理、提醒和管理负担 | [AI Health Vault](https://github.com/runesleo/ai-health-vault)（独立仓库）；[Attention Inbox](../labs/attention-inbox/README.md)、[Session Hooks](../labs/session-hooks/README.md)（实验） |
| AI 协作与可靠性 | 任务接续、权限、验收、上下文、资源、监控和故障处理 | [Core](../examples/first-success/README.md)（可试用）；[OPC Layer](../labs/opc-company/README.md)、[Chat Export](../labs/chat-export/README.md)（实验）；[Skill Audit](https://github.com/runesleo/claude-skill-audit)、[Multi AI Sync](https://github.com/runesleo/multi-ai-sync)、[AI Handoff Check](https://github.com/runesleo/ai-handoff-check)、[Skill Drift](https://github.com/runesleo/skill-drift)（独立仓库）；完整运行保障组合（待开放） |

## 新成果归到哪里

QuietHarness 是统一的公开入口，不是所有代码的单体仓库。新增成果先按它解决的问题归入现有业务模块，再判断维护位置：

| 成果类型 | 归属与处理 |
|---|---|
| 跨业务、跨 Agent 都需要的最小可靠性边界 | 在有重复实际需求和验证的前提下更新既有 Core；不让常驻模板承担业务细节 |
| 任务、协作、验收、注意力与恢复方法 | 更新已有 `docs/`、对应 `labs/` 或 `examples/`；未验证的机制明确标为实验 |
| 有独立用户、安装入口和维护需求的工具 | 保留原独立仓库、版本和 Issues；在本页链接，必要时提供组合案例，不复制源码或另立事实源 |
| 可复用的真实经验、失败和修复 | 先在原模块修正并验证，再向本页补充案例入口；引用原产物、PR 或文档，不复制私人运行记录 |

没有独立需求时不新建仓库。案例至少说明问题、可复用步骤、输入与输出、实际验证和未验证边界；公开前检查授权、许可证及隐私。没有新成果时不为了每日更新而制造提交。

## 案例索引

| 案例 | 可以如何复用 | 证据与边界 |
|---|---|---|
| 任务已提交，成功回执却丢失（真实开源改进，合成故障验证） | 保留原输出路径；检查点完整才恢复；已有结果先严格复验，不换目录重复执行 | [PR #27](https://github.com/runesleo/claude-code-workflow/pull/27) · [恢复说明](../examples/opc-first-workflow/README.md#提交后回执丢失先对账不重跑)；验证本地产物与交接确认，不认证外部副作用或真实模型执行 |
| 从机会信号到待审交付（离线合成实验） | 运行现有示例，观察证据、进程接力、严格验收与人工决策入口 | [OPC First Workflow Preview](../examples/opc-first-workflow/README.md)；不调用真实 AI、不自动发布 |
| 从公开来源到个人观点（真实公开产物） | 阅读来源，结合自身工作形成观点；可借用 [X Reader](https://github.com/runesleo/x-reader) 的来源读取与缺口标记方法 | [公开来源](https://x.com/xiaohuiyuan/status/2125549864239136986) · [公开回应](https://x.com/runes_leo/status/2125928807949369633)；链接只证明公开产物，不提供整条私人工作流的可复现性或自动化证明 |

未来有新的可复用交付时，优先把证据和步骤落到原模块，再更新本索引。用户反馈与公开复现结果应回到原仓库 Issues，不另造队列。

## 先从一个业务问题开始

1. 用现有 [Core 首次成功练习](../examples/first-success/README.md) 验证最基本的执行边界。
2. 如果遇到跨 Agent 接力和假完成，运行 [OPC Lab](../labs/opc-company/README.md) 的合成案例，不需要复制真实公司的任务库。
3. 从目录选择最贴近当前需求的独立业务工具，按该项目自身的安装说明和权限使用。
4. 运行 [OPC First Workflow Preview](../examples/opc-first-workflow/README.md)，观察虚构信号到待审交付、进程接力、严格本地验收和人工决策呈现的离线闭环。没有真实需求时不加层。

## 分阶段开放

每次新增模块都应能说明它解决哪个问题、如何独立使用、需要哪些依赖和权限、什么结果算成功、如何失败退出。开放代码之前先核验许可证及隐私边界。

| 阶段 | 可交付范围 | 验收门 |
|---|---|---|
| 1. 公开总入口 | 双语介绍、业务地图、现有工具与治理实验的导航；原有安装保持可用 | 链接可访问、既有安装回归通过、明确标注成熟度 |
| 2. 第一条业务闭环（离线 Preview） | 虚构合成信号 → 证据化研究简报 → 待审内容或产品候选；采用现有组件，保留人工授权 | 无私人数据或真实外发；可重复执行；有来源、决策和交付回执 |
| 3. 内容与产品工作流 | 逐步整理选题、文字、视频、产品验证和分发准备的独立模块及脱敏案例 | 每个模块有可复现的输入/输出、运行说明和失败测试；发布保持人工授权 |
| 4. 公司级协作 | 原 OPC Lab、任务接续与可靠性能力的可组合演示；用户反馈与商业化的合成案例 | 能验证交接、失败恢复、重复执行防护和真实验收；至少一位非作者在无口头指导下完成一次有意义的流程 |

这是交付顺序，而不是对完成日期、收入或全自动运行的承诺。新增模块以真实工作价值和外部使用反馈为准；不为凑目录创造重复项目。

## 公开与私有边界

公开稳定职责、工作流接口、脱敏 Skill、模块代码、合成数据、可复现实验及已经公开的真实案例。保留个人配置、账号与凭证、客户和实时任务、投资仓位与执行策略、健康数据、生产部署和调度配置。任何模块默认没有交易、公开发布或生产写入权限。对外发布需另行核验授权与隐私，不能仅靠删除几个字段。

整个系统的价值在于可复用的业务能力，而不是把创始人的电脑打包给别人。每个公开模块都应该能被采用、替换或不用。
