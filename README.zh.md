# Lean AI Workflow｜AI 工作流减负版

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[English](README.md) · **中文**

一套给 Claude Code、Codex 和 Cursor 共用的极简工作流：保留真正有用的边界，拿掉每天必须启动、必须收尾、必须规划、必须分派 Agent 的流程负担。

> **v3 候选版：**这不是在 v2 上继续叠规则，而是一次方向修正。迁移与回滚见 [MIGRATION-v3.md](MIGRATION-v3.md)。

## 为什么要重做

前两版解决的是“AI 容易忘、容易乱来”，于是不断增加 Hook、Skill、模型路由、Morning、Today、Session End 和各种 P0 规则。

短期看更严密，长期却出现了一个反效果：每次只是想改一处东西，AI 先启动一整套系统；每天还要维护系统本身。工作流开始抢走真正工作的注意力。

这次真实减负后，留下三层就够了：

1. **极小常驻核心**：直接执行、证据、验证、少数不可逆边界；
2. **项目事实**：需要时再读仓库文档、状态和测试；
3. **后台信息产品**：迁移不主动停掉已有日报任务；是否仍正常生成单独核验，不再强迫每个对话先跑 Morning/Today。

旧 v2 示例在项目上下文之前就会加载 16,379 字节；v3 三个公开模板合计 2,292 字节，而且每个客户端只加载自己的部分。这里比较的是文件字节，不冒充精确 token 节省量。

## 你能得到什么

- **一份共享核心**：最新请求优先、简单任务直做、没看过的证据不装看过、按风险验证。
- **三端薄适配**：Claude Code、Codex、Cursor 各自只留必要入口。
- **安全安装器**：默认只预览；明确 `--apply` 才写入；覆盖前自动备份。
- **可逆迁移**：旧 Skill、Hook、Command 先移到 disabled，不直接删除。
- **日报与工作解耦**：保留已有 scheduler 的独立性，单独核验产物；阅读方式由你选择，不再成为每日开工仪式。

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

## 目录

```text
templates/
├── shared/AGENTS.md              # 三端共用核心
├── claude/CLAUDE.md              # Claude Code 薄入口
└── cursor/lean-baseline.mdc      # Cursor 项目规则
docs/
└── DAILY-REPORTS.md              # 日报生成与阅读解耦
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

Cursor 全局 User Rules 由应用设置管理；脚本不会冒险修改它，只会在目标项目写入 `.cursor/rules/lean-workflow.mdc`。

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

## 已验证

`./scripts/verify.sh` 会检查：

- Shell 语法；
- 只读盘点是否覆盖普通文件与整目录符号链接；
- 安装器 dry-run、多目标预检与隔离安装；
- 普通文件和符号链接的备份与回滚；
- 自定义 `CODEX_HOME`；
- 中英文 README 与三端模板是否齐全；
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
- Cursor 全局规则需要你在设置里管理；脚本只装项目规则。
- 暂无 Windows PowerShell 安装器。
- 本仓库只定义“日报边界”，不内置新闻抓取或日报生成器。
- 已打开的旧会话可能缓存旧配置，需要重启或开新会话。

## 路线图

- [ ] PowerShell 安装器
- [ ] 跟踪三端指令加载方式的变化
- [ ] 收集更多真实仓库的前后对比，但不带入私人运行态

## 五条原则

1. **直接工作比流程表演重要。**
2. **状态变化时写回，比最后统一收尾可靠。**
3. **日报是信息产品，不是开工门禁。**
4. **机械正确性放进测试，不要堆在提示词里。**
5. **先停用再删除，永远保留回滚。**

## 关于作者

*Leo（[@runes_leo](https://x.com/runes_leo)）— AI × Crypto 独立构建者。在 [Polymarket](https://polymarket.com/?via=runes-leo&r=runesleo&utm_source=github&utm_content=claude-code-workflow) 做量化，用 Claude Code 和 Codex 搭数据与内容管线。*

*[leolabs.me](https://leolabs.me) — 写作 · 社群 · 开源工具 · 独立项目*

*[X 订阅](https://x.com/runes_leo/creator-subscriptions/subscribe) — 付费内容周刊*

*Learn in public, Build in public.*

## License

MIT — 见 [LICENSE](LICENSE)。
