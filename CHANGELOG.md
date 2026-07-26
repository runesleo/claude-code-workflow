# Changelog

本项目的重要变化记录在这里。版本遵循语义化版本。

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
