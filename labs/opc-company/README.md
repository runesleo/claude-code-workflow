# OPC Company Layer（实验性）

这是 QuietHarness 的公司级治理实验层，不是另一个“多 Agent 框架”。

QuietHarness 解决单个或少量 Agent 的可靠执行；OPC Company Layer 解决多个长期 Owner / Worker 如何共享事实、交接、验收，并在换模型或额度耗尽后继续同一任务。

## 10 分钟 First Success

```bash
cd labs/opc-company

./scripts/opc.py status examples/synthetic-company

# 1) Agent 自述完成，但没有 artifact / validation / owner writeback
./scripts/opc.py verify \
  --task fixtures/false-completion/task.json \
  --receipt fixtures/false-completion/receipt.json
# 预期：拒绝

# 2) 真实 receipt
./scripts/opc.py verify \
  --task examples/synthetic-company/tasks/product-release.json \
  --receipt examples/synthetic-company/receipts/product-release.valid.json
# 预期：PASS

# 3) Worker 额度耗尽，但任务不迁移
./scripts/opc.py failover \
  --before fixtures/quota-failover/task.before.json \
  --after fixtures/quota-failover/task.after.json
# 预期：同 task / 同 owner / 新 worker，PASS
```

## 公开边界

公开的是协议、schema、synthetic fixture 和 verifier。

不公开真实业务任务、生产 Owner 拓扑、账号绑定、scheduler、MCPX production 配置、额度路由、交易策略和其他 operational alpha。
