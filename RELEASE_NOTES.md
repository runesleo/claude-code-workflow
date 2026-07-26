# QuietHarness v3.0.0

这是 Claude Code Workflow 同一仓库、同一段 Git 历史上的第三版。

公开仓库停在 v2 以后，我自己的工作系统仍在 Claude Code、Codex、Cursor 和多个真实业务里持续演进。随着最高推理档模型变强，旧版一部分原本有用的规则、Hook、Skill、Memory 和固定流程开始变成重复规划与维护负担。

v3 不再继续堆规则，而是公开我目前实际使用的结构。

## 主要变化

- 三端共用一个 1,604 字节 Core；加上 Claude Code 与 Cursor 薄入口，总计 2,292 字节。
- 默认直接执行，不要求先跑 Morning、Today 或 Session End。
- 状态发生变化时立即写回，不再依赖最后一次统一回忆。
- 已有日报、同步和监控保持独立；成功静默落盘，异常单独处理。
- 安装器默认 dry-run，覆盖前备份，支持回滚和自定义 `CODEX_HOME`。
- inventory 会发现普通文件和整目录符号链接，方便迁移旧规则、Skill 和 Command。

## 当前系统地图

这次公开的不只是 Core，也包括我真实系统的结构：

- 九条长期业务线与稳定 Owner；
- per-task SSOT 和五状态生命周期；
- Owner/Worker 分离与有时效的 claim；
- readout、writeback、freshness、state revision 和 negative result；
- 同一仓库/任务事实面单 Writer；
- artifact、validation、writeback、rollback 和 next gate 回执；
- Daily Rhythm 与各业务 Owner 的边界；
- 已开源业务分支之间的地图。

脱敏示例在 [examples/leo-system](examples/leo-system/)，完整说明在 [系统架构](docs/ARCHITECTURE.md)。

## 已连接的开源分支

- Prediction Market：`polymarket-toolkit`
- Asset Research：`asset-dd-and-opportunity-evaluation`
- Content Intake：`x-reader`、`tg-reader-mcp`、`long-media-cli`
- Video：`claude-video-kit`
- Health：`ai-health-vault`
- System Audit：`claude-skill-audit`

这些仓库不是 v3 的依赖。它们展示的是同一套个人工作系统里已经独立生长出去的分支。

## Breaking changes

- v2 的 rules、memory、skills、agents、commands 和 hooks 不再属于默认分支。
- 老用户应先运行 `./scripts/inventory.sh`，再按 `MIGRATION-v3.md` 可逆停用旧发现路径。
- Cursor 全局 User Rules 仍由应用设置管理；安装器只写项目规则。
- 业务线、任务和 writer-lock 示例是当前架构的公共参考，不会自动创建 Leo 的私人运行时。

## Privacy

公开版本保留真实架构和设计取舍，但不包含私人绝对路径、thread ID、实时任务、账号、凭证、仓位、健康记录、客户、scheduler、VPS 或生产状态。

## Verification

```bash
./scripts/verify.sh
```

在独立审查清除 blocker 之前，不创建 tag 或 GitHub Release。Push、Release、仓库改名和 X 发布仍是分别确认的公开动作。
