# QuietHarness 系统架构

[English](ARCHITECTURE.en.md) · **中文**

这份文档展示的是 Leo 当前真实使用的 AI 工作系统，不是一套从空白开始设计的通用架构。

公开版本保留业务拓扑、任务生命周期、Owner/Worker、readout/writeback、单 Writer 和验证回执；只移除私人路径、thread ID、实时任务、账号、仓位、健康记录与生产控制面。

## 它是怎么长出来的

Claude Code Workflow v1/v2 形成时，模型需要更多显式规则才能稳定工作。系统因此逐渐加入：

- 常驻行为规则；
- Skill 自动路由；
- Memory Flush；
- 多模型分工；
- Morning、Today、Session End；
- Hook 与完成门。

这些机制来自真实问题，但模型能力提升后，全部继续常驻反而让简单请求也要穿过整套系统。v3 的变化不是否定历史，而是重新确定每一层应该在什么时候出现。

## 当前系统地图

```text
┌──────────────────────────────────────────────────────────────────────┐
│                         Leo 的真实工作                               │
└────────────────────────────────┬─────────────────────────────────────┘
                                 │
                 ┌───────────────▼────────────────┐
                 │ Claude Code · Codex · Cursor   │
                 │ 模型与对话可替换                │
                 └───────────────┬────────────────┘
                                 │
                 ┌───────────────▼────────────────┐
                 │ QuietHarness Core              │
                 │ 执行 · 证据 · 验证 · Hard Gates │
                 └───────────────┬────────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
┌─────────▼─────────┐  ┌─────────▼─────────┐  ┌─────────▼─────────┐
│ Business Lines    │  │ Task Continuity   │  │ Background       │
│ 稳定工作区与 Owner │  │ per-task SSOT     │  │ 日报/同步/监控     │
│ 九条长期业务线      │  │ read/write/receipt│  │ 安静生成/异常提醒   │
└─────────┬─────────┘  └─────────┬─────────┘  └───────────────────┘
          │                      │
          └──────────────┬───────┘
                         │
        ┌────────────────▼─────────────────┐
        │ Domain Workflows / Open Repos    │
        │ PM · Data · Content · Video      │
        │ Health · Research · System Audit │
        └──────────────────────────────────┘
```

系统的关键不是“层数很多”，而是每层拥有不同的事实和加载时机。

## 第一层：三端只是入口

Claude Code、Codex、Cursor 不各自维护一套完整人格。Codex 读取共享 `AGENTS.md`，Claude Code 通过薄入口引用它，Cursor 用项目 `.mdc` 镜像同一组核心可靠性边界。

Core 只负责：

1. 最新请求优先，能直接做就直接做；
2. 没有读过的证据不装作读过；
3. 变更之后进行与风险相称的验证；
4. 不可逆或外部动作等待明确确认。

模型能力、客户端和会话都可以变化。核心边界保持稳定。

## 第二层：九条长期业务线

我的项目不是全部堆在一个“总对话”中，而是按长期责任划分为九条业务线：

| Key | 名称 | 长期责任 |
|---|---|---|
| `personal_ops` | Personal Ops | 系统、Agent、权限和恢复能力 |
| `pm_strategy` | Strategy Lab | 策略、验证、规模化与停止条件 |
| `pm_intel` | Data Platform | 数据管线、索引、画像和质量 |
| `portfolio` | Portfolio | 配置、风险和执行前决策 |
| `content_writing` | Content Studio | X、长文、SEO 与内容资产 |
| `product_distribution` | Products & Growth | 产品、变现、开源和分发 |
| `health_ops` | Health Ops | 健康记录、节律和研究 |
| `daily_rhythm` | Daily Rhythm | 输入登记、路由、Top 5 与审计 |
| `research_dd` | Research Desk | 调研、机会判断和知识沉淀 |

公开示例保留这些真实名称，因为它们就是系统的一部分。使用者可以改名、合并或删减。

### 为什么业务线比对话稳定

- 对话会变长、损坏或更换客户端；
- 模型会升级或改变分工；
- 项目可能跨越多个仓库；
- 业务责任和事实归属通常更稳定。

因此工作区/业务线是连续性表面，对话只是入口。

### 启动读取

进入一条业务线时，只读取：

- 这条线的身份与边界；
- 属于这条线的少量目标；
- `active / waiting / monitoring` 任务摘要；
- 已到期的 trigger。

不会自动读取其他八条线，也不会把完整任务数据库倒入上下文。

```text
进入 Products & Growth
        ↓
读取该线目标 + 有限任务摘要
        ↓
用户点名一个任务？
   ├─ 否 → 直接处理当前请求
   └─ 是 → 精确读取该任务记录
```

## 第三层：任务事实与跨模型接力

每个长期任务有一份权威记录。聚合列表、日报和 Dashboard 都是从任务记录生成的视图。

核心字段：

| 字段 | 作用 |
|---|---|
| `status` | 唯一生命周期状态 |
| `owner_thread` | 稳定业务归属与最终写回 Owner |
| `primary_worker` | 当前默认执行模型或 Agent |
| `claimed_by / claimed_at` | 当前批次心跳，避免重复接手 |
| `next_action` | 当前唯一明确下一步 |
| `artifacts` | 代码、报告、截图、commit 或 receipt |
| `updated_at` | 新鲜度判断 |
| `trigger` | 等待任务重新进入前台的条件 |
| `decision_gate` | 当前需要人做的决定 |
| `state_revision` | 新事实对旧叙事的显式覆盖 |

### Owner 与 Worker

`owner_thread` 管理任务事实；`primary_worker` 负责当前批次。

Worker 可以写代码、产出报告或完成审查，但不能因为说“做完了”就覆盖任务生命周期。Owner 接收 artifact 和验证证据后，才写回持久状态。

这让 Claude、Codex、Cursor 可以互相替换，而不把某个模型名字变成权限锁。

### 读取、执行、写回

```text
task readout
    ↓
来源 + updated_at + claim 检查
    ↓
执行当前 batch
    ↓
真实验证
    ↓
artifact / receipt
    ↓
Owner writeback
    ↓
重新读取确认状态已持久化
```

详见 [任务连续性](TASK-CONTINUITY.md)。

## 第四层：单 Writer 与可审计交付

多 Agent 可以并行做只读研究、方案和审查，但同一个可变更面默认只有一个 Writer。

仓库写锁至少说明：

- 目标仓库与 worktree；
- 当前 Writer；
- 允许和禁止的 pathspec；
- 需要执行的验证；
- 当前 Hard Gate 与下一闸门。

释放时必须留下：

- artifact；
- validation；
- writeback；
- rollback；
- outcome；
- next gate。

这条规则来自真实的跨模型双写和脏工作区事故。公开仓库提供可替换的 JSON 示例，不包含 Leo 当前真实仓库清单。

## 第五层：后台系统

日报、数据同步和监控不属于每次交互的启动流程。

```text
scheduler / monitor
        ↓
采集与处理
        ↓
按日期或任务落 artifact
        ↓
成功静默 · 异常提醒 · 需要时读取
```

这样后台能力可以继续运行，但不会因为 Agent 空闲就制造新任务，也不会强迫所有请求先过 Morning 或 Session End。

## 第六层：业务分支

有些能力最初属于这套个人系统，经过真实使用后长成独立开源仓库：

| 分支 | 公开实现 |
|---|---|
| Prediction / Strategy / Data | `polymarket-toolkit`、`asset-dd-and-opportunity-evaluation` |
| Content Intake | `x-reader`、`tg-reader-mcp`、`long-media-cli` |
| Video Production | `claude-video-kit` |
| Health Ops | `ai-health-vault` |
| Personal Ops / Audit | `claude-skill-audit` |

QuietHarness 不复制这些仓库的实现，只展示它们在整个系统里的位置。

## 什么公开，什么保留私有

| 公开 | 私有 |
|---|---|
| 业务线结构与职责 | thread UUID 和本机绑定 |
| 任务 schema 与生命周期 | 实时任务和优先级 |
| Owner/Worker/Writer 规则 | 账号、凭证和客户 |
| 脱敏案例与事故教训 | 仓位、策略参数和健康数据 |
| 开源分支之间的地图 | scheduler、VPS 和生产控制面 |

所谓抽象，只发生在存储路径、客户端绑定和私人数据层。系统的结构、判断和演进原因仍然保留。

## 使用方式

你可以只安装 Core，也可以 fork [Leo System 示例](../examples/leo-system/)：

1. 先用真实工作划分稳定责任，而不是先设计十个 Agent；
2. 每条线只保留一个 Owner；
3. 任务一项一份权威状态；
4. 只有出现跨会话或跨模型冲突时，才加入 claim 与 writer lock；
5. 新规则先经过真实事故或重复证据，再进入热路径。
