# OPC Company Layer (experimental)

This is QuietHarness's company-scale governance lab, not another multi-agent framework.

QuietHarness focuses on reliable execution by one or a few agents. The OPC Company Layer focuses on durable ownership, canonical state, handoffs, acceptance, semantic ACKs, and worker failover across multiple long-lived agents.

## 10-minute first success

Requirements: Git and Python 3. The OPC lab uses only the Python standard library; there is no package-install step.

From a clean checkout:

```bash
git clone https://github.com/runesleo/claude-code-workflow.git
cd claude-code-workflow/labs/opc-company
python3 scripts/opc.py --help
```

The first-success contract is based on exit code + exact output tokens. Expected rejection cases intentionally exit `1`; expected success cases exit `0`.

```bash
# 1) Inspect the synthetic company
python3 scripts/opc.py status examples/synthetic-company
# exit 0
# output includes: "task_count": 2, "work_continuing": true

# 2) False completion: outcome says completed but proof/writeback are missing
python3 scripts/opc.py verify   --task fixtures/false-completion/task.json   --receipt fixtures/false-completion/receipt.json
# exit 1
# output must include all three:
# OPC_VERIFY_REJECT missing_artifact
# OPC_VERIFY_REJECT missing_validation
# OPC_VERIFY_REJECT missing_owner_writeback

# 3) Valid receipt
python3 scripts/opc.py verify   --task examples/synthetic-company/tasks/product-release.json   --receipt examples/synthetic-company/receipts/product-release.valid.json
# exit 0
# exact token: OPC_VERIFY_PASS

# 4) Worker failover preserves the canonical task and owner
python3 scripts/opc.py failover   --before fixtures/quota-failover/task.before.json   --after fixtures/quota-failover/task.after.json
# exit 0
# exact output:
# OPC_FAILOVER_PASS task=product-release from=worker-a to=worker-b

# 5) A blocked leaf execution path must not stop the canonical task
python3 scripts/opc.py continuation   --before fixtures/continuation/before.json   --after fixtures/continuation/after.bad-leaf-stop.json
# exit 1
# output must include BOTH:
# OPC_CONTINUATION_REJECT leaf_blocker_promoted_global
# OPC_CONTINUATION_REJECT premature_global_stop

# 6) An owner turn cannot drift to another scope without a semantic handoff
python3 scripts/opc.py continuation   --before fixtures/continuation/before.json   --after fixtures/continuation/after.bad-scope-drift.json
# exit 1
# exact token: OPC_CONTINUATION_REJECT scope_drift_without_handoff

# 7) Positive continuation control
python3 scripts/opc.py continuation   --before fixtures/continuation/before.json   --after fixtures/continuation/after.good-leaf-continue.json
# exit 0
# exact output:
# OPC_CONTINUATION_PASS task=synthetic-content-task scope=opc-merge-milestone work_continuing=true

# 8) A handoff without semantic downstream ACK is not completion
python3 scripts/opc.py verify   --task fixtures/missing-ack/task.json   --receipt fixtures/missing-ack/receipt.json
# exit 1
# exact token: OPC_VERIFY_REJECT missing_semantic_ack

# 9) lint accepts a company directory and checks its JSON files
python3 scripts/opc.py lint examples/synthetic-company
# exit 0
# exact output: OPC_LINT_OK files=5

# Optional full regression suite
python3 tests/run.py
# exit 0; exact token: OPC_TEST_OK
```

All fixture paths above are relative to `labs/opc-company`. If an agent runs from the repository root, either `cd labs/opc-company` first or prefix the paths accordingly.

Public: protocols, schemas, synthetic fixtures, verifier.
Private: live business tasks, production topology, account bindings, schedulers, exact quota routing, trading alpha, credentials.
