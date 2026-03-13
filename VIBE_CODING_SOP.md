# Vibe Coding SOP 介绍

## 什么是 Vibe Coding？

Vibe Coding 是一种**结构化 AI 辅助编程工作流**，它将 AI 从"每次重新开始的智能助手"转变为"持久化、可自我进化的开发伙伴"。

**核心理念**：
- 结构 > 提示词（组织良好的配置胜过巧妙的一次性提示）
- 记忆 > 智能（记住过去错误的 AI 比更聪明但每次重新开始的更有价值）
- 验证 > 自信（运行测试的成本永远低于发布 broken build）

---

## 项目架构

### 分层配置系统

```
┌─────────────────────────────────────────────────────┐
│                    项目 Overlay                       │
│  .vibe/overlay.yaml — 项目级自定义配置               │
└──────────────────────┬──────────────────────────────┘
                       │ 合并
┌──────────────────────▼──────────────────────────────┐
│                  可移植核心 (core/)                    │
│  - models/tiers.yaml      能力层级定义               │
│  - models/providers.yaml  供应商配置映射              │
│  - skills/registry.yaml   技能注册表                 │
│  - security/policy.yaml   安全策略                   │
│  - policies/behaviors.yaml 行为策略                  │
└──────────────────────┬──────────────────────────────┘
                       │ bin/vibe build
┌──────────────────────▼──────────────────────────────┐
│               目标适配器 (targets/)                    │
│  Claude Code / OpenCode / Cursor / Kimi Code ...    │
└──────────────────────┬──────────────────────────────┘
                       │ 渲染
┌──────────────────────▼──────────────────────────────┐
│              生成输出 (generated/<target>/)            │
│  特定 AI 工具的配置文件                              │
└─────────────────────────────────────────────────────┘
```

### 数据分层（3层架构）

| 层级 | 目录 | 加载策略 | 用途 |
|------|------|----------|------|
| **Layer 0** | `rules/` | 始终加载 | 核心行为规则、技能触发、自动保存 |
| **Layer 1** | `docs/` | 按需加载 | 多模型协作、安全审查、路由参考 |
| **Layer 2** | `memory/` | 热数据 | 每日进度、活跃任务、项目状态 |
| **技能** | `skills/` | 按触发条件 | 系统调试、完成验证、会话结束 |
| **代理** | `agents/` | 按需分派 | PR 审查、安全审计、性能分析 |

---

## 核心工作流规则

### 1. SSOT（单一事实来源）

**原则**：每条信息有且仅有一个规范位置。

- 避免"同一信息散落在 5 个地方，全部过时"的问题
- 写入前先检查 SSOT 表
- 工具管理的内存只是缓存，仓库文件才是真相

### 2. 能力层级路由

按**能力**而非模型名称路由任务：

| 层级 | 用途 | 典型场景 |
|------|------|----------|
| `critical_reasoner` | 关键推理 | 安全敏感逻辑、架构决策、密钥管理 |
| `workhorse_coder` | 日常开发 | 大部分编码任务、分析、重构 |
| `fast_router` | 快速响应 | 简单查询、子代理任务、探索 |
| `independent_verifier` | 独立验证 | 交叉验证、代码审查、复杂 bug 诊断 |
| `cheap_local` | 本地廉价 | 提交消息、格式化、离线工作 |

**映射示例**（OpenCode）：
- `critical_reasoner` → `configured.primary-high-reasoning`
- `workhorse_coder` → `configured.primary-coder`
- `fast_router` → `configured.fast-agent`

### 3. 完成前验证（Verify Before Claim）

**最具影响力的规则**：

```
在声称工作完成前，必须运行验证命令并读取输出
```

消除 AI 编码的头号失败模式——"应该可以了"但没有实际检查。

**验证清单**：
- [ ] 运行测试并确认通过
- [ ] 运行 lint/typecheck（如果有）
- [ ] 检查没有破坏现有功能
- [ ] 更新相关文档

### 4. 系统化调试（Systematic Debugging）

**五阶段调试流程**：

```
┌─────────────────────────────────────────┐
│  Phase 0: Memory Recall（强制第一步）    │
│  - 提取错误关键词                        │
│  - 查询历史经验                          │
│  - 找到相关经验？直接应用                 │
└──────────────────┬──────────────────────┘
                   │ 无相关经验
┌──────────────────▼──────────────────────┐
│  Phase 1: Root Cause Investigation      │
│  - 完整阅读错误信息                      │
│  - 稳定复现问题                          │
│  - 检查近期变更                          │
│  - 追踪数据流                            │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│  Phase 2: Pattern Analysis              │
│  - 查找代码库中的工作示例                │
│  - 对比找出差异                          │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│  Phase 3: Hypothesis and Testing        │
│  - 形成单一假设                          │
│  - 最小化测试                            │
│  - 验证假设                              │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│  Phase 4: Implementation                │
│  - 创建失败测试用例                      │
│  - 实施单一修复                          │
│  - 验证修复                              │
└─────────────────────────────────────────┘
```

**铁律**：
```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
NO INVESTIGATION WITHOUT MEMORY RECALL FIRST
```

### 5. 自动保存

Claude 在以下时刻自动保存进度：
- 每次任务完成
- 每次提交
- 每次退出信号

**关闭窗口不会丢失任何工作**

---

## 快速开始

### 1. 安装

```bash
# 克隆工作流仓库
git clone https://github.com/nehcuh/claude-code-workflow.git
cd claude-code-workflow

# 安装 vibe 命令到系统 PATH
bin/vibe-install

# 验证安装
vibe --help
```

### 2. 初始化全局配置

```bash
# Claude Code
vibe init --platform claude-code

# OpenCode
vibe init --platform opencode

# Kimi Code
vibe init --platform kimi-code

# Cursor
vibe init --platform cursor
```

### 3. 应用到项目

```bash
cd /path/to/your/project

# 应用配置
vibe switch --platform opencode

# 启动 AI 工具
opencode
```

---

## 项目定制

### 使用 Overlay（推荐）

在项目根目录创建 `.vibe/overlay.yaml`：

```yaml
name: my-project
description: 项目级工作流定制

profile:
  mapping_overrides:
    workhorse_coder: openai.gpt-4o
  note_append:
    - 本项目使用 Python + uv 管理依赖

policies:
  append:
    - id: python-uv-preference
      category: project
      enforcement: recommended
      target_render_group: always_on
      summary: 优先使用 uv run、uv sync 管理 Python 环境

targets:
  opencode:
    permissions:
      ask:
        - "Bash(docker:*)"
```

然后构建时会自动应用：
```bash
vibe switch opencode  # 自动发现 .vibe/overlay.yaml
```

---

## 安全策略

### 安全等级

| 等级 | 行为 | 示例 |
|------|------|------|
| **P0** | 优先拒绝 | `rm -rf`、密钥外泄、破坏性操作 |
| **P1** | 询问确认 | 网络请求、认证流程、动态执行 |
| **P2** | 警告继续 | 合规性提示、模糊备份指令 |

### 信号类别

- **network_egress**（网络外泄）: `curl`, `requests.post`, `fetch(`
- **archive_then_send**（打包发送）: `zip`, `tar`, `upload`
- **destructive_operation**（破坏性操作）: `rm -rf`, `delete`, `shred`
- **obfuscation_or_dynamic_exec**（混淆/动态执行）: `base64`, `eval`, `exec`

---

## 技能系统

### 强制技能（P0）

- `systematic-debugging` — 系统化调试
- `verification-before-completion` — 完成前验证
- `session-end` — 会话结束处理

### 建议技能（P1）

- `planning-with-files` — 复杂任务文件化规划
- `experience-evolution` — 经验积累与复用

### Superpowers 技能包（P2）

- `superpowers/tdd` — 测试驱动开发
- `superpowers/brainstorm` — 设计优化
- `superpowers/refactor` — 系统化重构
- `superpowers/debug` — 高级调试
- `superpowers/architect` — 架构设计
- `superpowers/review` — 代码审查
- `superpowers/optimize` — 性能优化

---

## 多模型协作

### 主代理职责（Claude Opus）

| 应该做 | 不应该做 |
|--------|----------|
| 理解需求、分解任务 | 编写大量代码块 |
| 关键决策 | 简单 CRUD |
| 验证外部输出 | 文档清理 |
| 维护记忆系统 | 重复性任务 |

### 子代理分派规则

**触发条件**（满足任一即分派）：
- >=2 个独立任务
- P0 有多个待处理项
- 用户说"并行"/"同时"
- 复杂任务可拆分为独立模块

**记忆注入协议**（分派子代理时必须）：
```markdown
You are working on [project-name].

## Context Loading (must read first)
1. ~/.claude/memory/session.md — Today's work context
2. /path/to/project/PROJECT_CONTEXT.md — Project status

## Task
[Specific task description]

## Completion Requirements
1. Run lint + build yourself, confirm PASS
2. Update PROJECT_CONTEXT.md Session Handoff section
3. Report results
```

---

## 记忆管理

### 三层记忆架构

```
┌─────────────────────────────────────────┐
│  Hot Layer（热层）                      │
│  memory/session.md                      │
│  - 每日进度                             │
│  - 进行中任务                           │
│  - 会话交接                             │
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│  Warm Layer（温层）                     │
│  memory/project-knowledge.md            │
│  - 技术陷阱                             │
│  - 最佳实践                             │
│  - 项目模式                             │
└─────────────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│  Cold Layer（冷层）                     │
│  memory/overview.md                     │
│  - 战略目标                             │
│  - 项目概览                             │
│  - 基础设施                             │
└─────────────────────────────────────────┘
```

### 文件操作白名单

| 模型 | 可创建 | 可修改 | 禁止操作 |
|------|--------|--------|----------|
| Claude | 任何文件 | 任何文件 | - |
| 外部模型 | 代码文件 | 代码 + Handoff 块 | ROADMAP/FOCUS/TODO/.claude/ |

---

## 最佳实践

### 1. 小批量、可逆的变更

- 优先小批量、单一目的、可逆的变更
- 避免大而全的混合批次修改

### 2. 记录可复用的学习

- 记录用户纠正
- 记录重复失败
- 记录反直觉的发现

### 3. 任务路由决策树

```
任务复杂度评估
    │
    ├── 简单（<20 行，单文件）
    │   └── fast_router / cheap_local
    │
    ├── 标准（日常功能）
    │   └── workhorse_coder
    │
    └── 关键（安全、架构、核心业务）
        └── critical_reasoner
            └── 需要时 + independent_verifier
```

### 4. 成本优化技巧

1. **使用正确的层级**：不要对简单任务使用 `critical_reasoner`
2. **利用 `fast_router`**：对探索和快速查找使用轻量级模型
3. **启用 `cheap_local`**：为提交消息和格式化配置本地模型
4. **有选择地交叉验证**：仅对真正关键的决策使用 `independent_verifier`

---

## 常用命令速查

```bash
# 初始化平台配置
vibe init --platform <platform>

# 应用到当前项目
vibe switch --platform <platform>

# 查看当前状态
vibe inspect

# 构建配置（不安装）
vibe build <platform> --output ./dist

# 使用 overlay 构建
vibe build <platform> --overlay my-overlay.yaml

# 验证安装
vibe init --platform <platform> --verify

# 获取安装建议
vibe init --platform <platform> --suggest

# 完整验证
make validate

# 运行测试
make test
```

---

## 总结

Vibe Coding 不是简单的 AI 提示词集合，而是一套**生产级的工作流基础设施**：

1. **结构化配置** — 通过分层系统和 overlay 实现可定制性
2. **能力路由** — 根据任务复杂度选择适当的处理方式
3. **强制验证** — 消除"应该可以了"的侥幸心理
4. **记忆系统** — 让 AI 记住过去的错误和成功经验
5. **安全基线** — 防止破坏性操作和敏感信息泄露

这套工作流的目标是让 AI 成为**可靠的开发伙伴**，而不是每次都需要重新培训的临时工。
