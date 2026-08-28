# OPC Company Layer (experimental)

This is QuietHarness's company-scale governance lab, not another multi-agent framework.

QuietHarness focuses on reliable execution by one or a few agents. The OPC Company Layer focuses on durable ownership, canonical state, handoffs, acceptance, semantic ACKs, and worker failover across multiple long-lived agents.

## 10-minute first success

```bash
cd labs/opc-company
python3 scripts/opc.py status examples/synthetic-company

python3 scripts/opc.py verify \
  --task fixtures/false-completion/task.json \
  --receipt fixtures/false-completion/receipt.json
# expected: rejected

python3 scripts/opc.py verify \
  --task examples/synthetic-company/tasks/product-release.json \
  --receipt examples/synthetic-company/receipts/product-release.valid.json
# expected: PASS

python3 scripts/opc.py failover \
  --before fixtures/quota-failover/task.before.json \
  --after fixtures/quota-failover/task.after.json
# expected: same task, same owner, new worker, PASS

# A blocked leaf execution path does not stop the canonical task
python3 scripts/opc.py continuation \
  --before fixtures/continuation/before.json \
  --after fixtures/continuation/after.bad-leaf-stop.json
# expected: rejected with leaf_blocker_promoted_global / premature_global_stop

# An owner turn cannot drift to another scope without a semantic handoff
python3 scripts/opc.py continuation \
  --before fixtures/continuation/before.json \
  --after fixtures/continuation/after.bad-scope-drift.json
# expected: rejected with scope_drift_without_handoff
```

Public: protocols, schemas, synthetic fixtures, verifier.
Private: live business tasks, production topology, account bindings, schedulers, exact quota routing, trading alpha, credentials.
