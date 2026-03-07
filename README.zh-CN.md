# Claude Code Workflow

[English](README.md) | **中文**

经过实战检验的 AI 编程工作流基础设施。从 Claude Code 起步，已演化为支持 Antigravity、VS Code、Claude Code、Codex CLI、OpenCode、Cursor、Warp 等多目标的可移植 vibe coding 配置平台。

**不是教程，不是玩具配置。是一套真正能落地交付的生产工作流——现已具备跨工具的可移植核心规范。**

## 项目来源与 Fork 状态

本项目 fork 自 [runesleo/claude-code-workflow](https://github.com/runesleo/claude-code-workflow)，并进行了大量架构重构：

- **原作者**：[@runes_leo](https://x.com/runes_leo)
- **Fork 维护者**：[@nehcuh](https://github.com/nehcuh)
- **主要变更**：
  - 将 CLI 模块化为 6 个 Ruby 库模块（`lib/vibe/*.rb`）
  - 添加完整的单元测试套件（`test/`）
  - 添加中文文档（`README.zh-CN.md`）
  - 增强 overlay 系统，提供运行时偏好示例（`examples/`）
  - 改进路径安全和符号链接处理，提升 macOS 兼容性
  - 重构生成器架构，提升可维护性

本 fork 保持原始 MIT 许可证并致谢原作者，但代码库已通过重构和新功能产生显著差异。

## 为什么需要它

Claude Code 开箱即强大，但缺乏结构时它只是一个「每次重新开始」的智能助手。这套模板将它变成一个**持久化、可自我进化的开发伙伴**：

- 记住过去的错误并自动应用经验教训
- 跨长会话管理上下文而不偏离
- 按能力层级将任务路由到正确的模型
- 强制在声称完成前进行验证（不再有「应该可以了」）
- 自动保存进度——关闭窗口不会丢失任何工作

## 架构概览

```
┌─────────────────────────────────────────────────────┐
│                    项目 Overlay                       │
│  .vibe/overlay.yaml 或 --overlay FILE               │
│  项目级自定义: 配置映射 / 行为策略 / 原生配置补丁     │
└──────────────────────┬──────────────────────────────┘
                       │ 合并
┌──────────────────────▼──────────────────────────────┐
│                  可移植核心 (core/)                    │
│                                                      │
│  models/tiers.yaml      能力层级定义                  │
│  models/providers.yaml  目标/供应商配置映射            │
│  skills/registry.yaml   可移植技能注册表              │
│  security/policy.yaml   P0/P1/P2 安全策略             │
│  policies/behaviors.yaml 可移植行为策略               │
└──────────────────────┬──────────────────────────────┘
                       │ bin/vibe build
┌──────────────────────▼──────────────────────────────┐
│               目标适配器 (targets/)                    │
│                                                      │
│  antigravity.md claude-code.md  codex-cli.md         │
│  cursor.md      opencode.md     vscode.md            │
│  warp.md                                             │
└──────────────────────┬──────────────────────────────┘
                       │ 渲染
┌──────────────────────▼──────────────────────────────┐
│              生成输出 (generated/<target>/)            │
│                                                      │
│  Antigravity → AGENTS.md + .vibe/antigravity/*       │
│  Claude Code → CLAUDE.md + rules/ + settings.json    │
│  Codex CLI   → AGENTS.md + .vibe/codex-cli/*         │
│  Cursor      → AGENTS.md + .cursor/rules/*.mdc       │
│  OpenCode    → AGENTS.md + opencode.json             │
│  VS Code     → AGENTS.md + .vibe/vscode/*            │
│  Warp        → WARP.md   + .vibe/warp/*              │
└─────────────────────────────────────────────────────┘
```

### 数据分层

| 层级 | 目录 | 加载策略 | 用途 |
|------|------|----------|------|
| Layer 0 | `rules/` | 始终加载 | 核心行为规则、技能触发、自动保存 |
| Layer 1 | `docs/` | 按需加载 | 多模型协作、安全审查、路由参考 |
| Layer 2 | `memory/` | 热数据 | 每日进度、活跃任务、项目状态 |
| 技能 | `skills/` | 按触发条件 | 系统调试、完成验证、会话结束 |
| 代理 | `agents/` | 按需分派 | PR 审查、安全审计、性能分析 |

### 模块化 CLI 架构

`bin/vibe` 由 6 个 Ruby 模块组成：

| 模块 | 职责 |
|------|------|
| `Vibe::Utils` | 通用工具：深度合并、I/O、路径处理、格式化 |
| `Vibe::DocRendering` | Markdown 文档渲染：inspect 输出、行为/路由/安全文档 |
| `Vibe::OverlaySupport` | Overlay 解析、发现、策略合并 |
| `Vibe::NativeConfigs` | 原生配置构建：Claude settings.json、Cursor cli.json、OpenCode opencode.json |
| `Vibe::PathSafety` | 输出路径安全守卫、目标冲突检查、文件树复制 |
| `Vibe::TargetRenderers` | 7 个目标的文件渲染器 |

## 快速配置

### 方式一：直接使用 Claude Code（最快上手）

```bash
# 克隆仓库
git clone https://github.com/nehcuh/claude-code-workflow.git

# 复制到 Claude Code 配置目录
cp -r claude-code-workflow/* ~/.claude/
```

然后编辑 `~/.claude/CLAUDE.md`，填入你的信息：

```markdown
## User Info
- **Name**: 你的名字 | **Project dir**: /path/to/projects
- **Identity**: 全栈开发者
```

启动 Claude Code 即可：

```bash
claude
```

## 模型配置指南

本工作流使用**能力层级路由系统**，将任务复杂度与具体模型实现分离。理解如何为你的目标工具配置模型对于获得最佳性能至关重要。

### 理解能力层级

工作流在 `core/models/tiers.yaml` 中定义了 5 个抽象能力层级：

- **`critical_reasoner`**：关键逻辑、安全、密钥和架构决策的最高保障推理
- **`workhorse_coder`**：大多数实现和分析工作的默认日常编码层级
- **`fast_router`**：用于探索、分类和低风险子流程工作的快速廉价层级
- **`independent_verifier`**：用于交叉检查重要结论的第二模型验证层级
- **`cheap_local`**：用于离线、高容量和低风险任务的本地或接近零成本层级

### 层级到模型的映射机制

每个目标在 `core/models/providers.yaml` 中都有一个**提供者配置文件**，将这些抽象层级映射到具体的模型实现：

```yaml
claude-code-default:
  mapping:
    critical_reasoner: claude.opus-class
    workhorse_coder: claude.sonnet-class
    fast_router: claude.haiku-class
```

**重要提示**：这些映射是**语义提示**，而非可执行配置。实际的模型选择取决于你的目标工具的能力。

### 按目标配置模型

#### Claude Code（完全支持）

Claude Code 通过多种方法支持动态模型选择：

**方法 1：使用特定模型启动**
```bash
# 使用 Opus 启动（最高能力）
claude --model opus

# 使用 Sonnet 启动（平衡）
claude --model sonnet

# 使用 Haiku 启动（最快）
claude --model haiku
```

**方法 2：使用 Task 工具的 model 参数**
```markdown
委派给子代理时，Claude 可以指定模型层级：
- Task 工具使用 `model: "opus"` 进行关键推理
- Task 工具使用 `model: "sonnet"` 进行标准工作
- Task 工具使用 `model: "haiku"` 进行快速探索
```

**方法 3：在设置中配置默认值**
检查 `~/.claude/settings.json` 以配置默认模型偏好（如果你的 Claude Code 版本支持）。

#### Cursor（计划中）

Cursor 的模型选择通过其 UI 设置配置：

1. 打开 Cursor 设置（Cmd/Ctrl + ,）
2. 导航到"Models"部分
3. 为每个层级配置模型：
   - **Primary model** → 映射到 `critical_reasoner` 和 `workhorse_coder`
   - **Fast model** → 映射到 `fast_router`
   - **Review model** → 映射到 `independent_verifier`

生成的 `.cursor/rules/05-vibe-routing.mdc` 将引用这些为 `cursor.primary-frontier-model`、`cursor.default-agent-model` 等。

#### Codex CLI（计划中）

Codex CLI 使用通过环境或 CLI 标志配置的 OpenAI 模型：

```bash
# 通过环境设置默认模型
export CODEX_PRIMARY_MODEL="gpt-4"
export CODEX_FAST_MODEL="gpt-3.5-turbo"

# 或按调用指定
codex --model gpt-4 "你的任务"
```

生成的 `.vibe/codex-cli/routing.md` 将层级映射到 `openai.high-reasoning`、`openai.codex-workhorse` 等。

#### Warp（计划中）

Warp 的模型配置取决于其 AI 提供者集成：

1. 在 Warp 设置中配置你的 AI 提供者
2. 生成的 `WARP.md` 将引用 `warp.primary-frontier-model`、`warp.default-agent-model` 等
3. Warp 将对所有层级使用其配置的默认模型（Warp 内的模型切换可能受限）

#### OpenCode（计划中）

OpenCode 允许在 `opencode.json` 中灵活配置模型：

```json
{
  "models": {
    "primary": "claude-opus-4",
    "coder": "claude-sonnet-4",
    "fast": "claude-haiku-4"
  }
}
```

生成的配置将这些映射到工作流中定义的能力层级。

#### Antigravity（计划中）

Antigravity 的模型选择取决于内部路由和用户订阅：

1. Antigravity 根据任务复杂度和配置偏好选择模型
2. 生成的 `AGENTS.md` 将引用 `antigravity.primary-frontier-model`、`antigravity.default-agent-model` 等
3. Antigravity 原生支持多代理工作流，使路由指导直接可操作

#### VS Code / Copilot（计划中）

VS Code 的 AI 能力来自 GitHub Copilot 和 Copilot Chat：

1. 安装 GitHub Copilot 和 Copilot Chat 扩展
2. 生成的 `.vscode/settings.json` 包含引用工作流文档的工作区级别指令
3. 模型选择取决于你的 Copilot 订阅等级（Individual、Business、Enterprise）
4. Copilot 不支持按任务自动切换模型——路由指导主要是信息性的

### 项目特定的模型覆盖

你可以使用 overlay 为特定项目覆盖默认的层级到模型映射：

```yaml
# .vibe/overlay.yaml
profile:
  mapping:
    critical_reasoner: claude.opus-4-latest
    workhorse_coder: claude.sonnet-4-latest
```

然后使用 overlay 构建：
```bash
bin/vibe build claude-code --overlay .vibe/overlay.yaml
```

### 成本优化技巧

1. **使用正确的层级**：不要对简单任务使用 `critical_reasoner`（Opus）
2. **利用 `fast_router`**：对探索和快速查找使用 Haiku 级模型
3. **启用 `cheap_local`**：为提交消息和格式化配置 Ollama 或类似工具
4. **有选择地交叉验证**：仅对真正关键的决策使用 `independent_verifier`

详细的路由指南请参见 `docs/task-routing.md`。

### 方式二：使用生成器（推荐，支持多目标）

```bash
# 构建指定目标
bin/vibe build antigravity
bin/vibe build claude-code
bin/vibe build warp
bin/vibe build cursor
bin/vibe build codex-cli
bin/vibe build opencode
bin/vibe build vscode

# 应用到目标目录
bin/vibe use claude-code --destination ~/.claude
bin/vibe use cursor --destination /path/to/project

# 快速切换当前仓库的目标配置
bin/vibe switch antigravity
bin/vibe switch warp
bin/vibe switch cursor
bin/vibe switch vscode

# 查看当前状态
bin/vibe inspect
bin/vibe inspect --json
```

### 方式三：使用项目 Overlay（团队/项目定制）

在你的项目根目录创建 `.vibe/overlay.yaml`：

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
  claude-code:
    permissions:
      ask:
        - "Bash(docker:*)"
```

然后构建时会自动发现并应用：

```bash
bin/vibe switch cursor  # 自动应用 .vibe/overlay.yaml
```

**路径安全机制**：使用 `use` 或 `switch` 命令时，如果默认输出目录（`generated/<target>/`）与目标目录重叠，工具会自动使用外部暂存目录 `~/.vibe-generated/<目标名>-<哈希>/<target>/` 来避免冲突。这确保了即使将配置应用到仓库根目录也能安全操作。

```bash
bin/vibe build cursor                   # 自动发现 .vibe/overlay.yaml
bin/vibe build warp --overlay my.yaml   # 或显式指定
```

仓库已附带三个示例 overlay：

- `examples/python-uv-overlay.yaml` — Python/uv 项目偏好
- `examples/node-nvm-overlay.yaml` — Node/nvm 项目偏好
- `examples/project-overlay.yaml` — 严格审查流程示例

## 生成的配置文件

`bin/vibe build` 为每个目标生成不同的配置文件：

### Claude Code 目标
- `CLAUDE.md`, `rules/`, `docs/`, `skills/`, `agents/`, `commands/`, `memory/`, `patterns.md`
- `settings.json` — 权限基线
- `.vibe/claude-code/` — 行为策略、安全策略、任务路由、测试标准

### Antigravity 目标
- `AGENTS.md` — 工作流概述
- `.vibe/antigravity/` — 行为策略、安全策略、任务路由、测试标准

### Warp 目标
- `WARP.md` — Warp 项目规则入口
- `.vibe/warp/` — 行为策略、路由、安全、技能、任务路由、测试标准、工作流说明

### Cursor 目标
- `AGENTS.md` — 工作流概述
- `.cursor/rules/*.mdc` — Cursor 规则文件
- `.cursor/cli.json` — CLI 权限配置
- `.vibe/cursor/` — 行为策略、路由、安全、技能、任务路由、测试标准

### Codex CLI 目标
- `AGENTS.md` — 工作流概述
- `.vibe/codex-cli/` — 行为策略、路由、安全、执行策略、技能、任务路由、测试标准

### VS Code 目标
- `AGENTS.md` — 工作流概述
- `.vibe/vscode/` — 行为策略、路由、安全、技能、任务路由、测试标准

### 任务路由和测试标准

所有目标现在都包含：
- **任务路由** (`task-routing.md`) — 按复杂度分类任务（trivial/standard/critical），定义每个级别的流程要求
- **测试标准** (`test-standards.md`) — 按复杂度定义最低测试覆盖率要求，标识关键路径

这些策略帮助 AI 助手根据任务复杂度自动调整工作流程，在质量和效率之间取得平衡。

## 外部工具集成

本工作流支持可选的外部工具集成以增强能力：

### 初始化集成

```bash
# 交互式设置向导
bin/vibe init

# 验证现有安装
bin/vibe init --verify
```

### 支持的集成

#### Superpowers 技能包

提供设计优化、TDD 强制执行、系统化调试等高级技能包。

**安装方式**：
- Claude Code: `/plugin marketplace add obra/superpowers-marketplace`
- Cursor: `/plugin-add superpowers`
- 手动: 克隆并符号链接到 `~/.claude/skills/`
**本工作流暴露的可移植技能 ID**：
- `superpowers/tdd`
- `superpowers/brainstorm`
- `superpowers/refactor`
- `superpowers/debug`
- `superpowers/architect`
- `superpowers/review`
- `superpowers/optimize`

安装后的 Superpowers 技能包可能使用不同的原生命名。`core/skills/registry.yaml` 仍然是 `bin/vibe` 渲染这些可移植 ID 时的单一事实来源。

**来源**: [obra/superpowers](https://github.com/obra/superpowers)

#### RTK (Token 优化器)

通过智能上下文管理将 LLM token 消耗减少 60-90% 的 CLI 代理工具。

**安装方式**：
```bash
# Homebrew (macOS/Linux)
brew install rtk

# Cargo
cargo install --git https://github.com/rtk-ai/rtk

# 手动下载
# 参考 GitHub Releases: https://github.com/rtk-ai/rtk/releases

# 初始化 hook
rtk init --global
```
`bin/vibe init` 只会自动执行 Homebrew 和 Cargo 路径；如果选择手动安装，它会给出 release 下载指引，而不会执行远程安装脚本。

**来源**: [rtk-ai/rtk](https://github.com/rtk-ai/rtk)

**验证状态**：
- **Ready**：RTK 二进制已安装，且 Claude hook 已配置完成
- **Installed, hook not configured**：RTK 已安装，但还需要执行 `rtk init --global`
- **Hook configured, binary not found**：Claude 配置里残留了 hook，但当前并未找到 RTK 二进制

### 集成行为

- **条件性**: 所有集成都是可选的。工作流在没有它们的情况下正常运行。
- **动态检测**: 只有在检测到已安装 Superpowers 时，相关技能才会出现在生成的 manifest 和文档中。
- **可移植 SSOT**: 生成产物中的 Superpowers 引用使用 `core/skills/registry.yaml` 中的可移植 ID，而不是技能包自身的命名。
- **安全性**: 外部技能在注册到 `core/skills/registry.yaml` 之前会经过安全审查。

详细集成文档请参阅 `docs/integrations.md`。

## 目录结构

```
claude-code-workflow/
├── CLAUDE.md                     # 入口文件 — Claude 首先读取此文件
├── README.md                     # 英文说明
├── README.zh-CN.md               # 中文说明（本文件）
│
├── bin/
│   ├── vibe                      # 生成器 CLI（build/use/inspect/switch）
│   └── vibe-smoke                # 冒烟测试（所有目标 + overlay 构建）
│
├── lib/vibe/                     # CLI 模块化实现
│   ├── utils.rb                  # 通用工具
│   ├── doc_rendering.rb          # 文档渲染
│   ├── overlay_support.rb        # Overlay 支持
│   ├── native_configs.rb         # 原生配置构建
│   ├── path_safety.rb            # 路径安全
│   └── target_renderers.rb       # 目标渲染器
│
├── test/                         # 单元测试（minitest）
│   ├── test_vibe_utils.rb
│   ├── test_vibe_path_safety.rb
│   └── test_vibe_overlay.rb
│
├── core/                         # 可移植核心规范
│   ├── models/                   # 能力层级 + 供应商配置
│   ├── skills/                   # 技能注册表
│   ├── security/                 # 安全策略
│   └── policies/                 # 行为策略
│
├── targets/                      # 目标适配器契约文档
│   ├── antigravity.md
│   ├── claude-code.md
│   ├── codex-cli.md
│   ├── cursor.md
│   ├── opencode.md
│   ├── vscode.md
│   └── warp.md
│
├── generated/                    # 构建输出（默认 gitignore）
├── examples/                     # 示例 overlay 文件
│
├── rules/                        # Layer 0: 始终加载
│   ├── behaviors.md              # 核心行为规则
│   ├── skill-triggers.md         # 技能触发条件
│   └── memory-flush.md           # 自动保存触发器
│
├── docs/                         # Layer 1: 按需加载
│   ├── agents.md                 # 多模型协作框架
│   ├── task-routing.md           # 任务路由参考
│   ├── project-overlays.md       # Overlay 机制文档
│   └── ...
│
├── memory/                       # Layer 2: 工作状态（3层架构）
│   ├── session.md                # 热层：每日进度 + 进行中任务
│   ├── project-knowledge.md      # 温层：技术陷阱 + 模式
│   └── overview.md               # 冷层：目标 + 项目 + 基础设施
│
├── skills/                       # 可复用技能定义
│   ├── systematic-debugging/     # 五阶段系统调试
│   ├── verification-before-completion/
│   ├── session-end/
│   ├── planning-with-files/
│   └── experience-evolution/
│
├── agents/                       # 自定义代理
│   ├── pr-reviewer.md
│   ├── security-reviewer.md
│   └── performance-analyzer.md
│
├── commands/                     # 自定义斜杠命令
│   ├── debug.md                  # /debug — 启动系统调试
│   ├── deploy.md                 # /deploy — 部署前检查清单
│   ├── exploration.md            # /exploration — 编码前 CTO 挑战
│   └── review.md                 # /review — 准备代码审查
│
└── patterns.md                   # 跨项目可复用模式和陷阱记录
```
## Git 与提交边界

这个仓库有意把「共享工作流文件」和「一次性构建/本地状态」分开管理：

- 应提交：`core/`、`targets/`、`rules/`、`docs/`、`CLAUDE.md`、`WARP.md`，以及当前仓库中已纳入版本控制的 `.vibe/` 支撑文件。
- 不应提交：`generated/` 和 `.vibe-target.json` 这类 staging 输出与本地 apply marker。
- `.vibe/overlay.yaml` 只有在它代表团队共享的项目策略时才建议提交；如果只是个人或本地偏好，应放在仓库外部，或在消费仓库的 `.gitignore` 中忽略。

完整说明请参阅 `docs/git-workflow.md`，其中包含消费仓库的提交建议、`memory/` 目录策略，以及 secrets / 本地状态文件的处理原则。

## 核心概念

### SSOT（单一事实来源）

每条信息有且仅有一个规范位置。`CLAUDE.md` 中的 SSOT 表将信息类型映射到文件，Claude 在写入前会先检查 SSOT，防止「同一信息散落在 5 个地方，全部过时」的问题。

### 能力层级路由

按能力而非模型名称路由任务，然后映射到当前活跃的供应商配置：

| 层级 | 用途 | 典型场景 |
|------|------|----------|
| `critical_reasoner` | 关键推理 | 安全敏感逻辑、架构决策 |
| `workhorse_coder` | 日常开发 | 大部分编码任务、分析、重构 |
| `fast_router` | 快速响应 | 简单查询、子代理任务 |
| `independent_verifier` | 独立验证 | 交叉验证、代码审查 |
| `cheap_local` | 本地廉价 | 提交消息、格式化、离线工作 |

### 完成前验证

最具影响力的规则：Claude 在声称工作完成前，必须运行验证命令并读取输出。消除 AI 编码的头号失败模式——「应该可以了」但没有实际检查。

### 自动保存

Claude 在每次任务完成、每次提交和每次退出信号时自动保存进度。关闭窗口不会丢失任何工作。

### 项目 Overlay

消费仓库可以通过 `.vibe/overlay.yaml` 自定义：
- **配置映射覆盖** — 重定义能力层级到具体模型的映射
- **行为策略追加** — 添加项目级的行为规则
- **原生配置补丁** — 修改目标工具的权限设置
- **技术栈偏好** — 编码 `uv`、`nvm` 等运行时偏好

所有定制均不需要 fork 或修改 `core/`。

## 定制指南

### 添加新项目

1. 在 `memory/overview.md` 中添加项目条目
2. 在 `CLAUDE.md` 的 Sub-project Memory Routes 中添加路由
3. 在项目根目录创建 `PROJECT_CONTEXT.md`

### 添加新技能

创建 `skills/your-skill/SKILL.md`：

```yaml
---
name: your-skill
description: 技能描述
allowed-tools:
  - Read
  - Write
  - Bash
---

# 你的技能

[Claude 调用此技能时的执行指令]
```

然后在 `core/skills/registry.yaml` 中注册元数据。

### 调整模型路由

1. 编辑 `core/models/tiers.yaml` 和 `core/models/providers.yaml`
2. 同步 `rules/behaviors.md` 和 `docs/task-routing.md`
3. 或使用项目 overlay 局部覆盖，无需修改全局配置

### 运行验证

```bash
# 语法检查
ruby -c bin/vibe

# 单元测试
ruby test/test_vibe_utils.rb
ruby test/test_vibe_path_safety.rb
ruby test/test_vibe_overlay.rb

# 完整冒烟测试（包含所有目标构建 + overlay + 安全检查）
bin/vibe-smoke
```

## 设计哲学

1. **结构 > 提示词**：组织良好的配置文件胜过巧妙的一次性提示
2. **记忆 > 智能**：记住你过去错误的 AI 比更聪明但每次重新开始的 AI 更有价值
3. **验证 > 自信**：运行测试的成本永远低于发布 broken build 的成本
4. **分层加载 > 平铺配置**：不要把所有东西塞进上下文——规则始终加载、文档按需加载、数据在需要时加载
5. **自动保存 > 手动保存**：如果需要用户记住，就一定会被遗忘

## 环境要求

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI（Claude Max 或 API 订阅）
- Ruby（用于 `bin/vibe` 生成器，macOS 自带）
- 可选：Codex CLI 用于交叉验证
- 可选：Ollama 用于本地模型回退

## 贡献者

- **原作者**：[@runes_leo](https://x.com/runes_leo) - 初始工作流设计与实现
- **Fork 维护者**：[@nehcuh](https://github.com/nehcuh) - 模块化、测试和中文本地化

## 致谢

本项目基于 [@runes_leo](https://x.com/runes_leo) 的原始 claude-code-workflow 优秀基础构建。本 fork 旨在提升可维护性并扩展工作流以服务中文开发者，同时保留核心理念。

## 许可

MIT — 随意使用、fork、改造。

原始作品版权所有 (c) 2024 runes_leo
修改作品版权所有 (c) 2025 nehcuh

---

**原作者**：[@runes_leo](https://x.com/runes_leo) — 更多 AI 工具见 [leolabs.me](https://leolabs.me) — [Telegram 社区](https://t.me/runesgang)
**Fork 维护者**：[@nehcuh](https://github.com/nehcuh)
