# Changelog

本项目的重要变化记录在这里。版本遵循语义化版本。

## [Unreleased]

### Changed

- 将默认入口从“Claude Code + Codex 多端组合”改为任选一个客户端即可开始；多端兼容降为可选扩展。
- 安装完成后给出明确的首次成功下一步，而不是直接把新用户送进九业务线架构说明。
- 新增 Claude Code / Codex 项目级安装模式；首次试用不再要求覆盖用户级配置。
- Cursor 项目规则补齐状态持久化、单 Writer、持续推进、验证回执和完整高风险确认边界。
- 安装器拒绝经中间 symlink 逃出所选项目的写入；若自动回滚无法恢复原文件，会保留并明确报告 recovery backup。

### Added

- `examples/first-success/`：隔离、可重复、目标十分钟完成的首次成功体验，检查 Agent 是否保留无关改动、做最小修复、运行真实检查并诚实报告结果。
- `tests/first-success-smoke.sh`：验证 demo 初始化、预期失败和无关用户改动均可稳定复现。

## [3.0.0] - 2026-07-26

### Changed

- 将同一仓库和 Git 历史上的 v3 命名为 **QuietHarness**；仓库 URL 暂时继续使用 `claude-code-workflow`。
- 从“通用低仪式工作流”改为 Leo 当前真实 AI 工作系统的公开地图。
- `README.md` 恢复为中文原创默认入口，英文镜像移动到 `README.en.md`。
- 把旧 v2 的重规则热路径收敛为 1,604 字节共享 Core 和 Claude Code / Cursor 薄适配。
- 持久状态从强制 Session End 收尾改为状态变化时写回。
- 日报、同步和监控与交互启动流程解耦。

### Added

- Leo 当前九条长期业务线的公开拓扑：Personal Ops、Strategy Lab、Data Platform、Portfolio、Content Studio、Products & Growth、Health Ops、Daily Rhythm、Research Desk。
- per-task SSOT、Owner/Worker、claim、readout/writeback、state revision 与 negative result 说明。
- 仓库单 Writer 和 acquire/release receipt 的脱敏示例。
- 当前公开系统分支地图，连接 `polymarket-toolkit`、`x-reader`、`claude-video-kit`、`ai-health-vault` 等已有仓库。
- 可编辑的 1600×900 中文系统总览图。
- dry-run 优先的事务安装器、只读 inventory、备份与回滚验证。
- v2 → v3 迁移指南。

### Removed

- 默认安装中的强制子 Agent 分派、全量多模型复核和固定计划门。
- Morning、Today、Session End、Today End、Weekly End 等自动日常仪式。
- 默认安装中的任务库、Memory 模板、自定义 Agent、Slash Command 与 Skill 集合。
- 虚构的 `Product / Research` solo-builder 示例。
- 重复的中文 README 入口。

### Security

- 安装器不执行网络、账号、凭证、scheduler、生产或公开发布操作。
- 公开系统地图不包含绝对私人路径、thread ID、实时任务、账号、仓位、健康记录、客户或生产控制面。
- 所有系统示例只使用中性相对路径，不会被默认安装或自动加载。

## [2.0.0] - 2026-04-05

### Added

- Hook 强制层、计划门、子 Agent 路由、每日 Memory 与 Session Closeout。

### Deprecated

- v2 继续保留在 Git 历史中，供明确需要旧完整工作流的人参考；不再是 v3 默认方向。

## [1.0.0] - 2026-02-22

### Added

- 第一版 Claude Code Workflow。
