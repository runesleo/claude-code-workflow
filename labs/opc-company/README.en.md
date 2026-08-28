# OPC Company Layer (experimental)

This is QuietHarness's company-scale governance lab, not another multi-agent framework.

QuietHarness focuses on reliable execution by one or a few agents. The OPC Company Layer focuses on durable ownership, canonical state, handoffs, acceptance, semantic ACKs, and worker failover across multiple long-lived agents.

## 10-minute first success

```bash
cd labs/opc-company
./scripts/opc.py status examples/synthetic-company

./scripts/opc.py verify \
  --task fixtures/false-completion/task.json \
  --receipt fixtures/false-completion/receipt.json
# expected: rejected

./scripts/opc.py verify \
  --task examples/synthetic-company/tasks/product-release.json \
  --receipt examples/synthetic-company/receipts/product-release.valid.json
# expected: PASS

./scripts/opc.py failover \
  --before fixtures/quota-failover/task.before.json \
  --after fixtures/quota-failover/task.after.json
# expected: same task, same owner, new worker, PASS
```

Public: protocols, schemas, synthetic fixtures, verifier.
Private: live business tasks, production topology, account bindings, schedulers, exact quota routing, trading alpha, credentials.
