# 任务连续性：我的任务系统怎样跨模型工作

[English](TASK-CONTINUITY.en.md) · **中文**

QuietHarness 不把聊天记录当任务事实，也不让 Claude、Codex、Cursor 各自维护一套状态。

我的现行做法是：每个长期任务一份权威记录，业务线是稳定 Owner，模型只是当前 Worker；聚合列表、日报和 Dashboard 都由这些任务记录派生。

## 为什么从“大数组”改成一任务一文件

早期系统把任务放在一个共享 JSON 中。多模型和多会话同时工作后，中央数组容易出现：

- 两个 Worker 覆盖彼此的状态；
- 一条旧聊天总结把新事实改回去；
- 一个模型标签长期占着任务，实际已经无人执行；
- Dashboard 和原始状态互相漂移。

因此当前系统采用 per-task SSOT。

## 任务记录

```json
{
  "id": "workflow-v3-release",
  "title": "更新当前 AI 工作系统的公开版本",
  "status": "active",
  "owner_thread": "products",
  "primary_worker": "codex",
  "claimed_by": "codex-docs-batch",
  "claimed_at": "2026-07-26T09:00:00Z",
  "next_action": "完成本地验证并交给维护者审阅",
  "artifacts": ["./artifacts/release-review.md"],
  "updated_at": "2026-07-26T09:00:00Z"
}
```

适配器可以增加字段，但下面四项必须清楚：

1. 当前状态；
2. 唯一下一步；
3. 可核验产物；
4. 状态的新鲜度。

## 生命周期

我的任务系统使用五个状态：

| 状态 | 含义 |
|---|---|
| `active` | 现在可以继续推进 |
| `waiting` | 等明确的人、条件或日期 |
| `monitoring` | 只观察信号，不主动制造工作 |
| `parked` | 有意搁置，不进入日常拉取 |
| `archived` | 生命周期结束，不再带唤醒条件 |

`status` 是唯一生命周期事实。优先级、Dashboard 分组和聊天叙述都不能覆盖它。

## Owner、Worker 与 Claim

- `owner_thread`：稳定的业务归属，接受最终写回；
- `primary_worker`：当前默认执行者，可以随时替换；
- `claimed_by / claimed_at`：当前批次的短期心跳。

这解决了一个真实问题：任务属于产品线，不属于 Claude 或 Codex。模型名字不能成为权限锁。

Claim 只防止当前批次重复接手。过期后可以经过 readout 和 writer-lock 预检替换。

## Readout

用户点名任务时：

1. 精确读取这个任务，不读取全部任务库；
2. 返回文件来源和 `updated_at`；
3. 检查 claim 是否仍新鲜；
4. 检查状态、下一步、decision gate 和 artifacts；
5. 缺失、互相矛盾或过期时报告 `UNKNOWN`。

```text
task-read <task-id>
task-list --owner <business-line>
```

这些是接口名称，不代表 QuietHarness 安装了对应命令。

## Writeback

持久状态变化发生时立即写回，不等 Session End 再统一回忆。

一次有效写回应包含：

- 哪个任务；
- 哪些字段发生变化；
- 接受写回的 Owner；
- artifact 与验证证据；
- 写回时间；
- 仍然存在的 gate。

```text
task-writeback <task-id> --status waiting --next-action "等待维护者审阅"
task-sync --check
```

聊天总结、Worker 自述和本地草稿都不是持久状态，直到 Owner 事实源接受它。

## State Revision

当新证据否定旧状态时，不继续往任务卡后面追加互相冲突的历史，而是显式记录修订：

```json
{
  "state_revision": {
    "status": "corrected_current",
    "as_of": "2026-07-26T09:00:00Z",
    "source": "./artifacts/current-verification.md",
    "current_facts": ["当前事实"],
    "superseded_facts": [
      {
        "prior_claim": "旧说法",
        "replacement": "新事实",
        "reason": "真实验证结果发生变化"
      }
    ]
  }
}
```

修订让旧证据继续可审计，但不能继续授权或阻塞当前工作。

## Negative Result

不做、失败、否决和无变化也可以是有效结果：

```yaml
negative_result:
  decision: drop | watch | park | no_publish | no_change | blocked
  reason: "具体原因"
  reuse_value: "以后怎样避免重复劳动"
```

这能阻止下一个模型重新走一遍已经证伪的路径。

## 派生视图

Dashboard、每日列表和聚合索引应从 per-task 记录生成。它们用于阅读和排序，不与任务文件竞争事实权。

完整脱敏示例见 [examples/leo-system](../examples/leo-system/)。
