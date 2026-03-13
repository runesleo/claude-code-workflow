# 文档索引

> 本文档提供项目所有文档的统一入口和导航。

## 快速开始

- [项目总览](../README.md) - 项目介绍、架构和快速开始指南
- [中文文档](../README.zh-CN.md) - 中文版项目文档

## 架构文档

### 核心架构
- [Portable Core](../core/README.md) - 可移植核心架构说明
  - [能力层级](../core/models/tiers.yaml) - 5 级能力路由定义
  - [提供商配置](../core/models/providers.yaml) - 8 个目标平台配置
  - [技能注册表](../core/skills/registry.yaml) - 可复用技能定义
  - [安全策略](../core/security/policy.yaml) - P0/P1/P2 安全严重度
  - [行为策略](../core/policies/behaviors.yaml) - 行为规则定义
  - [任务路由](../core/policies/task-routing.yaml) - 任务复杂度路由
  - [测试标准](../core/policies/test-standards.yaml) - 测试覆盖率标准

### 目标适配器
- [目标适配器概览](../targets/README.md) - 目标适配器契约和状态
- [Claude Code](../targets/claude-code.md) - Claude Code 目标（active）
- [Kimi Code](../targets/kimi-code.md) - Kimi Code 目标
- [Cursor](../targets/cursor.md) - Cursor 目标
- [Warp](../targets/warp.md) - Warp 目标
- [Antigravity](../targets/antigravity.md) - Antigravity 目标
- [VS Code](../targets/vscode.md) - VS Code 目标
- [Codex CLI](../targets/codex-cli.md) - Codex CLI 目标
- [OpenCode](../targets/opencode.md) - OpenCode 目标

## 参考文档

### 行为与工作流程
- [agents.md](agents.md) - 多模型协作框架
- [content-safety.md](content-safety.md) - AI 内容安全和幻觉预防
- [context-management.md](context-management.md) - 上下文管理和压缩恢复
- [task-routing.md](task-routing.md) - 任务路由和能力层级
- [git-workflow.md](git-workflow.md) - Git 工作流程
- [project-overlays.md](project-overlays.md) - 项目覆盖层机制

### 行为规则扩展
- [behaviors-extended.md](behaviors-extended.md) - 扩展行为规则（知识库、关联规则）
- [behaviors-reference.md](behaviors-reference.md) - 行为规则参考（浏览器冲突处理、内存搜索）

### 项目设置
- [scaffolding-checkpoint.md](scaffolding-checkpoint.md) - 技术栈选择检查清单
- [integrations.md](integrations.md) - 外部工具集成（RTK 等）

### 测试
- [testing/README.md](testing/README.md) - 测试文档总览
- [testing/config-effectiveness-test.md](testing/config-effectiveness-test.md) - 配置有效性测试
- [testing/improvement-proposals.md](testing/improvement-proposals.md) - 改进提案

## 运行时规则

> 这些规则在 Claude Code 运行时自动加载

- [behaviors.md](../rules/behaviors.md) - 核心行为规则
- [skill-triggers.md](../rules/skill-triggers.md) - 技能触发器
- [memory-flush.md](../rules/memory-flush.md) - 内存刷新规则

## 技能定义

- [session-end](../skills/session-end/SKILL.md) - 会话结束工作流
- [verification-before-completion](../skills/verification-before-completion/SKILL.md) - 完成前验证
- [systematic-debugging](../skills/systematic-debugging/SKILL.md) - 系统调试
- [planning-with-files](../skills/planning-with-files/SKILL.md) - 文件规划
- [experience-evolution](../skills/experience-evolution/SKILL.md) - 经验进化

## 示例配置

- [project-overlay.yaml](../examples/project-overlay.yaml) - 项目覆盖层示例
- [python-uv-overlay.yaml](../examples/python-uv-overlay.yaml) - Python uv 覆盖层
- [node-nvm-overlay.yaml](../examples/node-nvm-overlay.yaml) - Node.js nvm 覆盖层

## 生成器 CLI

- [bin/vibe](../bin/vibe) - 主 CLI 工具（支持 build/use/switch/inspect/init）

### 支持的命令
```bash
bin/vibe build <target>    # 生成目标配置
bin/vibe use <target>      # 应用到项目
bin/vibe switch <target>   # 切换目标
bin/vibe inspect           # 检查配置
bin/vibe init              # 初始化项目
```

## 内存层

- [session.md](../memory/session.md) - 会话内存（热层）
- [project-knowledge.md](../memory/project-knowledge.md) - 项目知识（温层）
- [overview.md](../memory/overview.md) - 概览（冷层）

## 按场景查找文档

### 我想了解项目架构
→ [README.md](../README.md) → [core/README.md](../core/README.md)

### 我想添加新目标支持
→ [targets/README.md](../targets/README.md) → 参考现有目标适配器

### 我想了解工作流规则
→ [rules/behaviors.md](../rules/behaviors.md) → [docs/task-routing.md](task-routing.md)

### 我想配置我的项目
→ [README.md](../README.md) 快速开始 → [examples/](../examples/)

### 我想运行测试
→ `make validate` 或 `make generate`

## 维护

- **最后更新**: 2026-03-07
- **维护者**: [@nehcuh](https://github.com/nehcuh)
- **许可证**: MIT
