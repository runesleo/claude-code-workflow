# QuietHarness v3.1.0

v3.1.0 不再扩充系统版图，而是补齐新用户最重要的一步：只选一个 AI 编程客户端，在隔离项目里完成一次可观察的首次成功。

## 主要变化

- README 默认入口改成单客户端路径：Claude Code、Codex 或 Cursor 任意一个都能开始，多端兼容只是可选扩展。
- 新增 Claude Code / Codex 项目级安装模式，首次试用无需覆盖用户级配置；Cursor 继续使用项目规则。
- 安装结束会明确指向首次成功练习，不再把新用户直接送进完整系统架构。
- 新增 `examples/first-success/`：一个隔离、可重复、目标十分钟完成的行为练习。
- 新增 `tests/first-success-smoke.sh`，验证 fixture、预期失败和无关用户改动可稳定复现。
- Cursor 规则补齐状态持久化、单 Writer、持续推进、验证回执和高风险确认边界。

## 首次成功是什么

练习要求 Agent 修复一个最小缺陷，同时保留无关用户改动、运行真实检查，并诚实报告结果。它用于验证 onboarding 行为是否可观察，不宣称 QuietHarness 必然提升模型能力。

入口见 [首次成功练习](examples/first-success/README.md)，英文版见 [first-success exercise](examples/first-success/README.en.md)。

## Breaking changes

没有。v3.1.0 保留 v3.0.0 的默认 Core、全局安装方式、仓库 URL 和 Git 历史。

## 安全与隐私

- 项目级安装会拒绝经中间 symlink 逃出所选项目的写入。
- 若自动回滚无法恢复原文件，会保留并明确报告 recovery backup。
- 安装器不执行网络、账号、凭证、scheduler、生产或公开发布操作。
- 首次成功 fixture 不包含私人路径、账号、凭证或真实业务数据。

## Verification

```bash
./scripts/verify.sh
```

产品与安装器安全独立审查均无 blocker。本版本对应 `v3.1.0`；仓库名称和 URL 继续保留 `claude-code-workflow`。
