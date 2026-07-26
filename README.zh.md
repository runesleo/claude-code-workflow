# QuietHarness

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[English](README.md) · **中文**

### 给 Claude Code、Codex 和 Cursor 的低仪式感工作流重置方案。

面向那些已经把 AI 编程环境配得很强，却开始替这套配置打工的开发者。

QuietHarness 先盘点你机器上真实生效的指令面，提供把旧规则和固定仪式移出热路径的迁移指南，再以 dry-run、备份和回滚安装一套小型三端共享核心。

它仍然是一套工作流：规定请求、上下文、验证、状态写回和后台信号怎样协作；但它不是新的 Agent 编排器、Prompt 合集，也不会要求每次对话先走 Morning、Today 或 Session End。

> **前身是 Claude Code Workflow。** QuietHarness 是同一个仓库、同一段 Git 历史上的 v3 产品方向。为承接已有用户和搜索，仓库 URL 暂时保留旧名。迁移与回滚见 [MIGRATION-v3.md](MIGRATION-v3.md)。

## 主要面向谁

QuietHarness 首先服务独立开发者、AI 编程重度用户和小团队，尤其是这些人：

- 每天在真实项目里使用 Claude Code、Codex 或 Cursor；
- 已经积累全局规则、Hook、Skill、Memory、模型路由和收尾流程；
- AI 开始重复规划、误触无关流程、读取过期上下文；
- 想减负，但不愿连安全门、验证和回滚能力一起删掉。

它不是 Skill 市场、任务数据库、模型路由器、日报生成器或自主多 Agent 框架。想直接拿到一套大而全能力包的人，v2 更完整；v3 更适合已经开始承担配置维护成本的人。

## 到底改了什么

| 公开示例 | v2 | QuietHarness v3 |
|---|---:|---:|
| Claude 常驻配置 | 16,379 B | 1,772 B |
| 默认附带的工作流资产 | 25 个规则/文档/记忆/Skill/Agent/Command | 3 个客户端模板 |
| 迁移安全 | 手工复制或符号链接 | inventory + dry-run + backup + rollback |

这些是公开配置的字节数，不代表精确 token、回复速度或模型质量提升。

## 为什么要重做

前两版解决的是“AI 容易忘、容易乱来”，于是不断增加 Hook、Skill、模型路由、Morning、Today、Session End 和各种 P0 规则。

短期看更严密，长期却出现了一个反效果：每次只是想改一处东西，AI 先启动一整套系统；每天还要维护系统本身。工作流开始抢走真正工作的注意力。

这次真实减负后，留下三层就够了：

1. **极小常驻核心**：直接执行、证据、验证、少数不可逆边界；
2. **项目事实**：需要时再读仓库文档、状态和测试；
3. **后台信息产品**：迁移不主动停掉已有日报任务；是否仍正常生成单独核验，不再强迫每个对话先跑 Morning/Today。

旧 v2 的 Claude 示例在项目上下文之前就会加载 16,379 字节；QuietHarness 在 Claude 侧加载 1,772 字节（1,604 字节共享核心 + 168 字节入口）。三端模板合计 2,292 字节，但没有任何客户端会同时加载三份。这里比较的是文件字节，不冒充精确 token 节省量。

## 你能得到什么

- **一份共享核心**：最新请求优先、简单任务直做、没看过的证据不装看过、按风险验证。
- **三端薄适配**：Claude Code、Codex、Cursor 各自只留必要入口。
- **安全安装器**：默认只预览；明确 `--apply` 才写入；覆盖前自动备份。
- **可逆迁移**：旧 Skill、Hook、Command 先移到 disabled，不直接删除。
- **日报与工作解耦**：保留已有 scheduler 的独立性，单独核验产物；阅读方式由你选择，不再成为每日开工仪式。
- **可选连续性参考层**：用有边界的 readout、writeback 和 freshness 协议连接个人、工作区与任务状态，但不增大默认安装的 Core。

名字就是架构：模型外围的 **Harness** 仍然存在，但没有相关任务时保持 **Quiet**。

## 新流程怎么工作

```text
你现在要做的事
    ↓
极小共享核心
    ↓
只读取相关项目文件与测试
    ↓
执行 → 验证 → 状态变化时当场写回 → 停止

定时日报
    ↓
按日期落盘 → 你需要时读 / 异常时通知 / 明确选择后再推送
```

它不再替你规定必须用哪个任务系统、笔记软件、模型档位或每日仪表盘。你已有的系统可以继续存在，但不应常驻在每个请求的上下文里。

## 系统可以变复杂，热路径不用

默认安装没有变重。对于真实工作已经横跨多个项目和会话的人，QuietHarness 现在补上第二条架构轴：

| 状态范围 | 应该放什么 | 什么时候读取 |
|---|---|---|
| Personal | 稳定偏好与私人系统指针 | 从一份极短、未跟踪的私人 overlay 读取 |
| Workspace | 当前仓库或业务工作区事实 | 进入该工作区后读取 |
| Task | 状态、下一步、证据与新鲜度 | 明确点名该任务时读取 |

连接它们的是协议，不是仓库捆绑的任务系统：

- **readout**：只读取当前请求需要的有限状态；
- **writeback**：持久变化发生时立即写回；
- **freshness**：缺失或过期状态不能冒充当前事实。

完整说明见[双轴架构](docs/ARCHITECTURE.md)、[私人 overlay 边界](docs/PRIVATE-OVERLAY.md)和[任务连续性协议](docs/TASK-CONTINUITY.md)。脱敏的 [solo-builder 示例](examples/solo-builder/)提供一次最小读取与写回闭环，不需要安装数据库、scheduler 或 Agent 编排器。

## 目录

```text
templates/
├── shared/AGENTS.md              # 三端共用核心
├── claude/CLAUDE.md              # Claude Code 薄入口
└── cursor/quiet-harness.mdc      # Cursor 项目规则
docs/
├── ARCHITECTURE.md               # 运行层 × 状态范围
├── PRIVATE-OVERLAY.md            # 未跟踪的私人指针
├── TASK-CONTINUITY.md            # readout/writeback/freshness
└── DAILY-REPORTS.md              # 日报生成与阅读解耦
examples/
└── solo-builder/                 # 脱敏的可选连续性示例
scripts/
├── inventory.sh                  # 只读盘点三端配置
├── install.sh                    # 预览、安装、备份
└── verify.sh                     # 完整验证
tests/
├── inventory-smoke.sh            # 文件与目录链接夹具
└── install-smoke.sh              # 隔离 HOME 安装测试
MIGRATION-v3.md                   # v2 → v3 与回滚
```

## 安装

```bash
git clone https://github.com/runesleo/claude-code-workflow.git
cd claude-code-workflow

# v2 老用户先盘点所有活跃文件与符号链接
./scripts/inventory.sh

# 先看会改什么，不写文件
./scripts/install.sh --dry-run --claude --codex

# 确认后再安装
./scripts/install.sh --apply --claude --codex
```

给某个 Cursor 项目安装：

```bash
./scripts/install.sh --dry-run --cursor-project /path/to/project
./scripts/install.sh --apply --cursor-project /path/to/project
```

Cursor 全局 User Rules 由应用设置管理；脚本不会冒险修改它，只会在目标项目写入 `.cursor/rules/quiet-harness.mdc`。

`--codex` 会尊重 `CODEX_HOME`，未设置时才使用 `~/.codex`。多个目标会先全部预检和暂存，再开始替换；目标若是指向文件的符号链接，会原样备份链接并在本地替换，不会改写链接指向的文件。指向目录的文件目标会被拒绝。

## 环境与隐私

- macOS 或 Linux
- Bash 3.2+
- Claude Code、Codex、Cursor 至少一个
- 不需要 API key

安装器不联网、不登录账号、不安装依赖，也不修改 scheduler。

身份、账号、实时优先级、私人路径和业务 runbook 应放在未跟踪的私人文件里，需要时才加载，不要跟公开模板混在一起。

## 最短使用方式

安装后重启客户端或开一个新会话，然后直接说要做什么：

```text
把这个失败测试修好，并跑验证。
```

不需要先运行 Morning 或 Today。需要保存时说清楚保存对象：

```text
把这次决定写进项目状态文件。
```

如果你已有定时日报：

```text
读取 inbox/daily/2026-07-26.md，只告诉我今天值得行动的三件事。
```

详细说明见 [日报可以继续，但不必成为仪式](docs/DAILY-REPORTS.md)。

如果你已经有个人文件夹、业务工作区或任务系统，可以从 [solo-builder 连续性示例](examples/solo-builder/)开始接入。该目录不会被安装器写入，也不会自动加载。

## 已验证

`./scripts/verify.sh` 会检查：

- Shell 语法；
- 只读盘点是否覆盖普通文件与整目录符号链接；
- 安装器 dry-run、多目标预检与隔离安装；
- 普通文件和符号链接的备份与回滚；
- 自定义 `CODEX_HOME`；
- 中英文 README 与三端模板是否齐全；
- 架构文档与脱敏连续性示例是否齐全；
- 公开模板是否混入私人路径；
- 常驻模板是否超过体积上限；
- 活跃模板是否重新出现 v2 强制触发词；
- `git diff --check`。

| 场景 | 环境 | 结果 |
|------|------|------|
| dry-run、事务安装、符号链接回滚 | macOS · Bash 3.2 | 自动冒烟测试 |
| 三端模板体积 | 任意 | 合计 2,292 字节 |
| 网络与账号操作 | 任意 | 无 |

## 当前限制

- 不会自动理解并改写你所有历史 Hook、Skill 和 Command；先按迁移指南做可逆停用。
- v2 的 Skill、Agent、Command 与 Memory 示例仍在 Git 历史里，但 v3 默认不再安装。
- Cursor 全局规则需要你在设置里管理；脚本只装项目规则。
- 暂无 Windows PowerShell 安装器。
- 本仓库只定义“日报边界”，不内置新闻抓取或日报生成器。
- 连续性示例只定义协议和中性记录，不提供 `task-read`、`task-writeback`、任务数据库或跨会话派发器。
- 已打开的旧会话可能缓存旧配置，需要重启或开新会话。

## 路线图

**配置体检**

- [ ] 识别重复指令、冲突规则、符号链接发现路径和三端漂移。
- [ ] 自动把配置分成常驻核心、按需能力和后台系统。

**连续性**

- [x] 说明可选的 Personal → Workspace → Task 参考架构。
- [x] 提供不改变默认安装的脱敏 readout、writeback 与 freshness 示例。
- [ ] 只有真实外部使用证明协议有价值后，再增加厂商无关的 validator。

**迁移与兼容**

- [ ] 增加 PowerShell 安装器。
- [ ] 增加配置快照、diff 和一键恢复，但不做宽范围破坏性清理。
- [ ] 跟踪 Claude Code、Codex、Cursor 的指令加载方式变化。
- [ ] 提供显式安装的可选能力包，不让它们重新常驻热路径。

**证据**

- [ ] 收集更多真实仓库的前后对比，但不带入私人运行态。

## 五条原则

1. **直接工作比流程表演重要。**
2. **状态变化时写回，比最后统一收尾可靠。**
3. **日报是信息产品，不是开工门禁。**
4. **机械正确性放进测试，不要堆在提示词里。**
5. **先停用再删除，永远保留回滚。**

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=runesleo/claude-code-workflow&type=Date)](https://star-history.com/#runesleo/claude-code-workflow&Date)

## 关于作者

*Leo（[@runes_leo](https://x.com/runes_leo)）— AI × Crypto 独立构建者。在 [Polymarket](https://polymarket.com/?via=runes-leo&r=runesleo&utm_source=github&utm_content=claude-code-workflow) 做量化，用 Claude Code 和 Codex 搭数据与内容管线。*

*[leolabs.me](https://leolabs.me) — 写作 · 社群 · 开源工具 · 独立项目*

*[X 订阅](https://x.com/runes_leo/creator-subscriptions/subscribe) — 付费内容周刊*

*Learn in public, Build in public.*

## License

MIT — 见 [LICENSE](LICENSE)。
