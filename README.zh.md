# Claude Code Workflow

一份从日常使用中沉淀下来的 Claude Code workflow 模板 — 涵盖记忆管理、context 工程、任务路由。

**不是教程，不是玩具配置，是一套真正在跑生产任务的 workflow。**

> **v2 更新**：v1 release 后实战 ~50 天的迭代。主要变化：加了 PreToolUse Hook 拦截层、Plan Gating 复杂任务工作流、基于 30 天实测数据的强制 Subagent 分派清单，并把 v1 的抽象规则改写成 10 条事件驱动的 P0 铁律。完整变更 → [CHANGELOG.md](./CHANGELOG.md)。

## 它解决什么

Claude Code 开箱即用很强，但没有结构的话，它就是一个"每个 session 都失忆"的助手。这份模板把它变成一个**有持久记忆、能自我进化的开发伙伴**：

- 记住过去踩过的坑，自动避开
- 在长 session 里管理 context 不漂移
- 把任务路由到合适的模型档位（Opus / Sonnet / Haiku / Codex / 本地）
- 完成前强制验证（不再有"应该没问题"）
- 自动保存进度，关窗口也不丢

## 架构：三层 + Hook 拦截

```
┌─────────────────────────────────────────────────────────┐
│  Layer 0: 自动加载 rules/（每个 session 启动即在 context）│
│  behaviors.md · skill-triggers.md · memory-flush.md      │
├─────────────────────────────────────────────────────────┤
│  Layer 1: 按需加载 docs/（关键词命中才 Read）             │
│  agents · task-routing · url-routing · content-safety    │
├─────────────────────────────────────────────────────────┤
│  Layer 2: 热数据（你的工作记忆）                          │
│  today.md · projects.md · active-tasks.json              │
├─────────────────────────────────────────────────────────┤
│  🆕 Layer 3: Hook 拦截（动作前硬性注入）                  │
│  PreToolUse → 检测危险 tool call → 注入对应铁律提醒        │
└─────────────────────────────────────────────────────────┘
```

**为什么这样分层？** Context 窗口很贵。全部加载浪费 token 还会降低质量。这套系统让规则常驻（~2K tokens）、文档按需加载（~1-3K each）、当天状态保持热度方便快速回忆。

**Hook 层是 v2 的核心新增** — Layer 0/1/2 都是"读出来的记忆"，依赖模型主动想起来。Hook 是"做之前被打断"，不依赖记性。

## 12 条实战铁律

日常使用中事件驱动沉淀下来的核心规则（每条都来自真实踩坑）：

**上下文与记忆**
1. **Memory 召回** — 用户提"之前/上次/记得吗" → 必须先 search
2. **产出前 verify** — 引用数字/他人观点/断言用户行为前必须跑 tool
3. **写入前查 SSOT** — 写任何持久化文件前先查路由表，禁止建副本

**执行与验证**

4. **完成前 verify** — 宣称完成前必须跑 lint/build/test，禁"应该没问题"
5. **Session-end 必走 skill** — 离开信号触发后强制调收尾 skill
6. **P0 tool 证据** — 所有"P0 强制"步骤必须贴 tool 返回原文
7. **惯性红旗词** — "我一直这么做/按惯性" = 暂停信号

**文件与输出**

8. **文件输出路径** — 禁止无脑 `-d ~/Desktop`，按上下文选目录
9. **跨语言禁直译** — 中↔英必须本地化重写
10. **URL 抓取走路由** — 用专用工具替代盲目 WebFetch（按平台/数据源做映射表）

**协作与节奏**

11. **Sunday Rule** — 周日 = 建设日，其他日子做系统优化会被拦截
12. **4 门过滤器（开源更新）** — 自用/顺手/值得分享/有内容钩子，缺一不更新

每条详细版见 `rules/behaviors.md` 对应章节。

> 这是模板里的通用铁律。你自己使用过程中长出的 domain-specific 铁律（如跨物理位置审计、长期任务初始化、特定环境变量加载顺序），属于个人配置层，不入此模板。

## 目录结构

```
claude-code-workflow/
├── CLAUDE.md                     # 入口 — Claude 启动先读这个
│
├── rules/                        # Layer 0: 自动加载
│   ├── behaviors.md              # 核心行为规则
│   ├── skill-triggers.md         # Skill 自动触发规则
│   └── memory-flush.md           # 自动保存触发器
│
├── docs/                         # Layer 1: 按需加载
│   ├── agents.md                 # 多模型协作框架
│   ├── content-safety.md         # AI 幻觉防护
│   ├── task-routing.md           # 模型路由 + 成本对比
│   ├── url-routing.md            # URL 抓取路由表
│   ├── daily-workflow.md         # 每日工作流
│   └── scaffolding-checkpoint.md # "真的需要自建吗" checklist
│
├── memory/                       # Layer 2: 工作状态（模板）
│   ├── today.md
│   ├── projects.md
│   └── active-tasks.json
│
├── hooks/                        # 🆕 v2 新增: PreToolUse 拦截
│   └── infra-context-guard.sh    # 跨机器操作前注入 infra 拓扑
│
├── skills/                       # 可复用 skill 定义
├── agents/                       # 自定义 agent 定义
└── commands/                     # 自定义 slash 命令
```

## 快速开始

### 1. 复制到 Claude Code 配置目录

```bash
git clone https://github.com/runesleo/claude-code-workflow.git
cp -r claude-code-workflow/* ~/.claude/
```

或用 symlink 保持随仓库更新：

```bash
ln -sf ~/claude-code-workflow/rules ~/.claude/rules
ln -sf ~/claude-code-workflow/docs ~/.claude/docs
```

### 2. 自定义 CLAUDE.md

打开 `~/.claude/CLAUDE.md`，填入：

- **User Info**：你的名字、项目目录、社交账号
- **Sub-project Memory Routes**：把你的项目映射到 memory 路径
- **SSOT Ownership**：定义每类信息的归属文件
- **On-demand Loading Index**：调整 docs 路径

### 3. 注册 Hook（v2 新增）

在 `~/.claude/settings.json` 添加：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "command": "~/.claude/hooks/infra-context-guard.sh"
      }
    ]
  }
}
```

### 4. 启动 session

```bash
claude
```

Claude 会自动加载规则并执行 workflow。试试：

- 写代码看任务路由（"🔀 路由：bug 修复 → Sonnet"）
- 遇到 bug 看 systematic debugging 自动启动
- 说"先这样"看 session-end 自动保存
- 第二天回来发现 context 已在 `today.md` 里完整保留

## 从 v1 迁移

- `rules/behaviors.md` 几乎重写，建议 diff 后手工合并你自己的部分
- `hooks/` 是 v2 新增，需要在 `settings.json` 注册 PreToolUse
- Layer 1 的 `docs/` 重组过，旧版 `behaviors-extended.md` 部分内容拆进了 `url-routing.md` 和 `scaffolding-checkpoint.md`

完整 changelog：[CHANGELOG.md](./CHANGELOG.md)

## 核心理念

1. **Structure > Prompting** — 一份组织良好的 config 永远比一次性聪明的 prompt 强
2. **Memory > Intelligence** — 一个记得你过去错误的 AI 比每次重启的更聪明 AI 更有用
3. **Verification > Confidence** — 跑 `npm test` 的代价永远小于发了 broken build 的代价
4. **Layered Loading > Flat Config** — 不要全塞 context，规则常驻、文档按需、数据热点
5. **Hook 拦截 > 启动读文档** — 动作前打断比期待 Claude 记得规则更可靠

## 系统要求

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI（Claude Max 或 API 订阅）
- 可选：Codex CLI 用于交叉验证
- 可选：本地模型用于 commit message 等离线任务

## 致谢

模板借鉴自：

- [Manus](https://manus.im/) 的 file-based planning
- OWASP Top 10 安全审查模式
- 来自 [x-reader](https://github.com/runesleo/x-reader)（650+ ⭐）等开源项目的实战经验

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=runesleo/claude-code-workflow&type=Date)](https://star-history.com/#runesleo/claude-code-workflow&Date)

## License

MIT — 拿去用，fork 它，改成你自己的。

---

Built by [@runes_leo](https://x.com/runes_leo) — 更多 AI 工具在 [leolabs.me](https://leolabs.me) — [Telegram 社群](https://t.me/runesgang)
