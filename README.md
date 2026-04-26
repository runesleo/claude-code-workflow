# Claude Code 工作流

[English](README.en.md) | **中文**

从多项目日常使用中提炼的 Claude Code 工作流模板——涵盖记忆管理、上下文工程与任务路由。

**不是教程、不是玩具配置。这是一套能真正上线交付的产线工作流。**

> **v2 新特性**：相对 v1 已迭代约 50 天。新增：PreToolUse Hook 层（在工具调用时强制执行规则，而不仅是会话开头）、复杂任务的计划门禁、强制子 Agent 分派检查清单（基于 30 天路由数据），以及将 10 条 P0 规则改写为事件驱动硬规则。完整说明见 [CHANGELOG.md](./CHANGELOG.md)。

## 为什么需要它

Claude Code 本身很强，但没有结构时，很容易变成「会话一断就忘光」的聪明助手。本模板把它变成**可持续、会自我改进的开发搭档**，能：

- 记住过去的错误并自动应用教训
- 在长会话中管理上下文、减少漂移
- 将任务路由到合适档位（Opus / Sonnet / Haiku / Codex / Local）
- 在宣称完成前强制验证（告别「应该好了吧」）
- 自动保存进度，关窗也不丢活

## 架构：三层

```
┌─────────────────────────────────────────────────────────┐
│  Layer 0: 自动加载规则（始终驻留上下文）                  │
│  ┌─────────────┐ ┌────────────┐ ┌───────────────┐     │
│  │ behaviors.md │ │skill-      │ │memory-flush.md│     │
│  │              │ │triggers.md │ │               │     │
│  └─────────────┘ └────────────┘ └───────────────┘     │
├─────────────────────────────────────────────────────────┤
│  Layer 1: 按需文档（需要时加载）                         │
│  agents.md · content-safety.md · task-routing.md        │
│  behaviors-extended.md · scaffolding-checkpoint.md ...  │
├─────────────────────────────────────────────────────────┤
│  Layer 2: 热数据（你的工作记忆）                        │
│  today.md · projects.md · goals.md · active-tasks.json   │
└─────────────────────────────────────────────────────────┘
```

**为什么分三层？** 上下文成本很高。全量塞入会浪费 token、拉低质量。本设计：始终加载规则（约 2K token）、仅按需读文档（各约 1–3K）、日常状态常热、随取随用。

## 内容结构

```
claude-code-workflow/
├── CLAUDE.md                     # 入口，Claude 先读
├── README.md                     # 你在这里
│
├── rules/                        # Layer 0：常载
│   ├── behaviors.md              # 行为规则（排错、提交、路由）
│   ├── skill-triggers.md         # 自动触发 skill 条件
│   └── memory-flush.md           # 自动保存（避免丢进度）
│
├── docs/                         # Layer 1：按需
│   ├── agents.md                 # 多模型协作框架
│   ├── behaviors-extended.md     # 拓展规则
│   ├── behaviors-reference.md    # 操作细则
│   ├── content-safety.md         # 防幻觉
│   ├── scaffolding-checkpoint.md # 自建前检清单
│   └── task-routing.md           # 模型档位与成本
│
├── memory/                       # Layer 2：工作态模板
│   ├── today.md
│   ├── projects.md
│   ├── goals.md
│   └── active-tasks.json
│
├── skills/
│   ├── session-end/SKILL.md
│   ├── verification-before-completion/SKILL.md
│   ├── systematic-debugging/SKILL.md
│   ├── planning-with-files/SKILL.md
│   └── experience-evolution/SKILL.md
│
├── agents/
│   ├── pr-reviewer.md
│   ├── security-reviewer.md
│   └── performance-analyzer.md
│
└── commands/
    ├── debug.md
    ├── deploy.md
    ├── exploration.md
    └── review.md
```

## 快速开始

### 1. 复制到 Claude Code 配置

```bash
git clone https://github.com/runesleo/claude-code-workflow.git
cp -r claude-code-workflow/* ~/.claude/

# 或符号链接
ln -sf ~/claude-code-workflow/rules ~/.claude/rules
ln -sf ~/claude-code-workflow/docs ~/.claude/docs
# …
```

### 2. 自定义 CLAUDE.md

打开 `~/.claude/CLAUDE.md`，补全：

- **用户信息**、主项目目录、社交
- **子项目记忆路由**
- **SSOT 归属表**、各类型信息存放位置
- **按需加载索引**（可调整 doc 路径）

### 3. 启动会话

```bash
claude
```

Claude 会加载规则并按工作流执行。可尝试：写代码时观察**任务路由**、遇到 bug 时看**系统化排错**、说收工看 **session-end** 自动保存、次日从 `today.md` 接上下文。

## 关键概念

### SSOT（单一事实源）

每条信息有且仅有一个规范位置。`CLAUDE.md` 中的 SSOT 表将信息类型映射到文件，先查再写，避免五处各写一版、全部过期。

### Memory Flush

任务完成、每次提交、退出信号时都会自动落盘。半句话关窗也不丢。告别「我忘了保存上下文」。

### 完成前验证

核心规则：未运行验证命令并读输出，就不得声称完成。消灭头号失败模式：没检查就说「应该可以了」。

### 三档（多档）任务路由

不是每件事都需要 Opus。系统按任务复杂度自动匹配模型档位：Opus（关键逻辑/安全/复杂推理）、Sonnet（日常开发）、Haiku（轻量/子任务）、Codex（交叉验证/二阅）、Local（提交信息/格式化/离线）。

### 周日原则

系统优化放在周日。若平日想调工作流而不交付，Claude 会提醒优先产出。周期可改。

## 定制指南

### 新项目

1. 在 `memory/projects.md` 登记  
2. 在 `CLAUDE.md` 的「子项目记忆路由」里加路由  
3. 在仓库根建 `PROJECT_CONTEXT.md`

### 新 skill

在 `skills/your-skill/SKILL.md` 中写 frontmatter 与说明（同英文模板）。

### 新 agent

在 `agents/your-agent.md` 中定义（同英文模板）。

### 调整模型路由

编辑 `rules/behaviors.md` 的「任务路由」与 `docs/task-routing.md` 的档位说明。

## 设计哲学

1. **结构 > 单条神 Prompt**：可维护的目录胜过一次性的聪明话术。  
2. **记忆 > 智商**：会记错的模型比每轮重开的天才更有用。  
3. **验证 > 感觉**：跑一遍 `npm test` 比上线坏构建便宜。  
4. **分层加载 > 平铺配置**：常载规则、按需读文档、热数据当需。  
5. **自动保存 > 靠人记得**：人总会忘，自动化才可靠。

## 环境要求

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI（Claude Max 或 API 订阅）  
- 可选：Codex CLI 做交叉验证  
- 可选：Ollama 作本地回退

## 致谢与来源

- [Manus](https://manus.im/) 的文件化规划思路  
- OWASP Top 10 安全审查模式  
- [x-reader](https://github.com/runesleo/x-reader) 等开源项目实战经验

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=runesleo/claude-code-workflow&type=Date)](https://star-history.com/#runesleo/claude-code-workflow&Date)

## 许可

MIT — 随便用、随便改。

## 关于作者

*Leo ([@runes_leo](https://x.com/runes_leo)) — AI × Crypto 独立构建者。在 [Polymarket](https://polymarket.com/?r=githuball&via=runes-leo&utm_source=github&utm_content=claude-code-workflow) 交易，用 Claude Code 与 Codex 做数据与交易系统。*

[leolabs.me](https://leolabs.me) — 写作 · 社区 · 开源小工具 · 独立产品 · 全平台。

[X 会员](https://x.com/runes_leo/creator-subscriptions/subscribe) — 每周付费内容，或请杯咖啡

*公开学、公开做（Learn in public, Build in public）。*
