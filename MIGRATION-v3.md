# 从 Claude Code Workflow v2 迁移到 QuietHarness v3

**中文** · [English](MIGRATION-v3.en.md)

v3 是一次有意的 breaking change。它取消了“每个 AI 对话都必须经过自动路由、每日 Memory 和收尾流程”这个前提。

迁移应该可逆：先停用，用 QuietHarness 做真实工作，只恢复那些你确实缺失的能力。

QuietHarness 是这个仓库 v3 的新名字。仓库 URL、Git 历史和过去的署名都继续保留。

## 1. 先做只读盘点

改动任何内容前，先记录每个客户端当前可发现的指令面：

```bash
./scripts/inventory.sh
```

这个 inventory 脚本只读。它会列出已知指令文件和所有符号链接，包括整目录链接，例如 `rules`、`commands` 和 `skills`。需要检查非默认根目录时，显式传入路径。

已有的日报或定时生成任务另外记录。报告任务和交互 Agent 工作流是两个系统。

## 2. 可逆停用 v2 热路径

把旧工作流资产移到发现路径之外的带日期目录中。暂时不要删除。

常见 v2 资产包括：

- 常驻行为和 Skill 触发规则；
- 自动 Memory Flush 规则；
- Morning、Today、Session End、Today End、Weekly End 等 Skill 或 Command；
- 负责提醒、路由或持久化这些流程的 Hook；
- 优先级高于 QuietHarness baseline 的 `AGENTS.override.md` 或本地指令；
- 指向其他活跃目录的 rules、skills 和 commands 符号链接；
- 多个客户端里的同一 Skill 副本。

每次移动都使用明确的源路径和目标路径，不要使用宽泛通配符。条目不存在时就跳过。

示例（先显式设置客户端配置目录）：

```bash
CLIENT_CONFIG="${CLIENT_CONFIG:?set this to the client config directory}"
mkdir -p "$CLIENT_CONFIG/skills_disabled/v3-migration"
mv "$CLIENT_CONFIG/skills/session-end" "$CLIENT_CONFIG/skills_disabled/v3-migration/session-end"
```

只处理你已经确认存在的条目。阻止凭证泄漏、危险命令、公开或生产动作的安全边界应继续保留，除非你已经有等价的机械保护。

## 3. 让日报保持独立

如果 scheduler 已经每天生成有用的 artifact，不要改它，另外检查最新输出。

只去掉“交互对话必须先跑 Morning 或 Today 才能工作”的绑定。交付方式单独选择：

- **安静拉取：**写入 `inbox/daily/YYYY-MM-DD.md`，需要时再读；
- **异常提醒：**成功时安静，失败或降级时提醒；
- **明确选择后推送：**固定时间只发短摘要或 artifact 链接。

不要为了迁移 Agent 指令而停止或修改 scheduler。

## 4. 预览 v3 安装

```bash
./scripts/install.sh --dry-run --claude
./scripts/install.sh --dry-run --codex
./scripts/install.sh --dry-run --cursor-project /path/to/project
```

检查所有目标和备份路径。确认后，只安装你实际使用的客户端：

```bash
./scripts/install.sh --apply --claude
./scripts/install.sh --apply --codex
./scripts/install.sh --apply --cursor-project /path/to/project
```

上面是三个独立选项，不是必须全部执行。先只安装你正在使用的一个客户端；以后增加客户端时，再单独复用同一组核心可靠性边界。

## 5. 重启后正常使用

打开一个新对话，给它一个真实任务。没有必须执行的启动命令。

接下来一两周，只记录具体缺口：

- 状态确实丢失了；
- 风险动作缺少有用的停止点；
- Agent 反复需要同一个项目事实；
- 报告变得难以找到。

只恢复最小缺失能力。不要因为其中一个行为有用，就把整条 pipeline 全部搬回来。

## 回滚

安装器会在每个被覆盖文件旁边创建同级备份：

```text
CLAUDE.md.bak-ai-workflow-<timestamp>
AGENTS.md.bak-ai-workflow-<timestamp>
quiet-harness.mdc.bak-ai-workflow-<timestamp>
```

回滚时，先把当前文件移开，再恢复你明确选中的备份。旧 Skill 和 Command 也按同样方式，从带日期的 disabled 目录逐个恢复。

恢复完成后，重启受影响的客户端。
