# OPC Company Layer（实验性）

这是 QuietHarness 的公司级治理实验层，不是另一个“多 Agent 框架”。

QuietHarness 解决单个或少量 Agent 的可靠执行；OPC Company Layer 解决多个长期 Owner / Worker 如何共享事实、交接、验收，并在换模型或额度耗尽后继续同一任务。

## 10 分钟 First Success

运行前提：Git + Python 3。OPC Lab 只使用 Python 标准库，不需要额外安装 package。

从干净 checkout 开始：

```bash
git clone https://github.com/runesleo/claude-code-workflow.git
cd claude-code-workflow/labs/opc-company
python3 scripts/opc.py --help
```

First Success 的验收以「退出码 + 精确输出 token」为准。预期被拒绝的案例故意返回 `exit 1`；预期通过的案例返回 `exit 0`。

```bash
# 1) 查看 synthetic company 状态
python3 scripts/opc.py status examples/synthetic-company
# exit 0
# 输出包含："task_count": 2, "work_continuing": true

# 2) 假完成：自述 completed，但 proof / owner writeback 缺失
python3 scripts/opc.py verify   --task fixtures/false-completion/task.json   --receipt fixtures/false-completion/receipt.json
# exit 1
# 输出必须同时包含：
# OPC_VERIFY_REJECT missing_artifact
# OPC_VERIFY_REJECT missing_validation
# OPC_VERIFY_REJECT missing_owner_writeback

# 3) 合法 receipt
python3 scripts/opc.py verify   --task examples/synthetic-company/tasks/product-release.json   --receipt examples/synthetic-company/receipts/product-release.valid.json
# exit 0
# 精确 token：OPC_VERIFY_PASS

# 4) Worker failover：canonical task 与 owner 不变，只替换 worker
python3 scripts/opc.py failover   --before fixtures/quota-failover/task.before.json   --after fixtures/quota-failover/task.after.json
# exit 0
# 精确输出：
# OPC_FAILOVER_PASS task=product-release from=worker-a to=worker-b

# 5) 叶子执行面被阻塞，不得升级为整个 canonical task 停止
python3 scripts/opc.py continuation   --before fixtures/continuation/before.json   --after fixtures/continuation/after.bad-leaf-stop.json
# exit 1
# 输出必须同时包含：
# OPC_CONTINUATION_REJECT leaf_blocker_promoted_global
# OPC_CONTINUATION_REJECT premature_global_stop

# 6) owner turn 没有 semantic handoff，不允许漂到另一个 scope
python3 scripts/opc.py continuation   --before fixtures/continuation/before.json   --after fixtures/continuation/after.bad-scope-drift.json
# exit 1
# 精确 token：OPC_CONTINUATION_REJECT scope_drift_without_handoff

# 7) continuation 正向控制组
python3 scripts/opc.py continuation   --before fixtures/continuation/before.json   --after fixtures/continuation/after.good-leaf-continue.json
# exit 0
# 精确输出：
# OPC_CONTINUATION_PASS task=synthetic-content-task scope=opc-merge-milestone work_continuing=true

# 8) handoff 已发出但缺 semantic downstream ACK：不能算完成
python3 scripts/opc.py verify   --task fixtures/missing-ack/task.json   --receipt fixtures/missing-ack/receipt.json
# exit 1
# 精确 token：OPC_VERIFY_REJECT missing_semantic_ack

# 9) lint 接受 company 目录输入，并递归检查其中 JSON
python3 scripts/opc.py lint examples/synthetic-company
# exit 0
# 精确输出：OPC_LINT_OK files=5

# 可选：完整回归测试
python3 tests/run.py
# exit 0；精确 token：OPC_TEST_OK
```

以上 fixture 路径都相对于 `labs/opc-company`。如果 Agent 从仓库根目录执行，应先 `cd labs/opc-company`，或自行补齐路径前缀。

## 公开边界

公开的是协议、schema、synthetic fixture 和 verifier。

不公开真实业务任务、生产 Owner 拓扑、账号绑定、scheduler、MCPX production 配置、额度路由、交易策略和其他 operational alpha。
