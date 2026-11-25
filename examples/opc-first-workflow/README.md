# OPC 首条业务闭环（离线实验）

**中文** · [English](README.en.md)

使用虚构机会样本，确定性地生成研究简报与待审内容。两个独立 Python 进程演示 Worker 接力，复用现有 OPC 验收器。无需联网、API Key、模型调用或真实账号，不发布内容。事实和草稿由样本预设；来源引用及文件完整性检查不等于语义事实核验。

从仓库根目录运行：

```bash
python3 examples/opc-first-workflow/run.py --out "$(mktemp -d)/opc-output"
python3 examples/opc-first-workflow/test.py
```

演示中断并恢复：

```bash
out="$(mktemp -d)/opc-output"
python3 examples/opc-first-workflow/run.py --out "$out" --phase prepare --simulate-failover
# 预期退出码 75；checkpoint/ 保留研究简报、任务、交接和校验信息。
python3 examples/opc-first-workflow/run.py --out "$out" --phase resume
# 预期退出码 0，输出 OPC_FIRST_WORKFLOW_PASS。
```

也可使用 `--simulate-failover`（不指定 phase）自动演示以上两步。首次运行的输出目录必须尚不存在。第二进程检查样本、研究文件哈希与任务身份，接受合成交接后生成研究简报、待审草稿、决策、产物哈希、接力快照、最终任务记录和回执。所有检查通过后才将暂存目录原子重命名为 `result/`。最终任务状态为 `archived`，完成仅表示准备任务的回执 outcome 为 `completed`，并非发布授权。

失败时可保留 checkpoint/，但不会提交 result/；已完成的结果不接受重复恢复。正常运行须退出 0 并输出 OPC_FIRST_WORKFLOW_PASS；测试须输出 FIRST_WORKFLOW_FOCUSED_TESTS_OK。

这是模拟 Worker 中断和交接确认的真实本地进程测试，不是两个 AI 模型的独立协作，确认也不是独立内容审查。Attention Inbox 已在离线案例中接入，真实 Agent 运行尚待验证。

## 创始人决策入口

在 OPC 验收通过后，案例复用现有 Attention Inbox 的 `batch` 命令。新增三个本地产物：`publish-gate.json`（模拟发布审核门，状态 OPEN）、`attention-events.jsonl`（四条合成事件）、`attention-output.txt`（原 CLI 输出）。审核门关联草稿 SHA256，不表示已授权发布。

预期输出：

```text
SUPPRESS reason=no_concrete_user_decision
SUPPRESS reason=routine_completion
ACTION_REQUIRED task=synthetic-ai-tool-trial gate=synthetic_publish_review
SUPPRESS reason=duplicate event=synthetic-ai-tool-trial:review-duplicate
```

仅演示内部等待、例行完成、模拟人工审核与同批次同 revision 去重。没有真实通知、审批执行或跨次持久去重；任何动作均不会发布内容。非法事件会使验收失败，保留检查点，不提交 `result/`。
