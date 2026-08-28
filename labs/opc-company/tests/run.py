#!/usr/bin/env python3
from pathlib import Path
import subprocess, sys, json
ROOT=Path(__file__).resolve().parents[1]; OPC=ROOT/"scripts/opc.py"
def run(args, expected):
    p=subprocess.run([sys.executable,str(OPC),*args],text=True,capture_output=True)
    if p.returncode != expected:
        print("TEST_FAIL",args,"expected",expected,"got",p.returncode); print(p.stdout,p.stderr); raise SystemExit(1)
    return p.stdout
for p in ROOT.rglob("*.json"): json.loads(p.read_text())
out=run(["status",str(ROOT/"examples/synthetic-company")],0); assert '"work_continuing": true' in out
out=run(["verify","--task",str(ROOT/"fixtures/false-completion/task.json"),"--receipt",str(ROOT/"fixtures/false-completion/receipt.json")],1); assert "missing_artifact" in out and "missing_validation" in out and "missing_owner_writeback" in out
out=run(["verify","--task",str(ROOT/"fixtures/missing-ack/task.json"),"--receipt",str(ROOT/"fixtures/missing-ack/receipt.json")],1); assert "missing_semantic_ack" in out
out=run(["verify","--task",str(ROOT/"examples/synthetic-company/tasks/product-release.json"),"--receipt",str(ROOT/"examples/synthetic-company/receipts/product-release.valid.json")],0); assert "OPC_VERIFY_PASS" in out
out=run(["failover","--before",str(ROOT/"fixtures/quota-failover/task.before.json"),"--after",str(ROOT/"fixtures/quota-failover/task.after.json")],0); assert "OPC_FAILOVER_PASS" in out
out=run(["continuation","--before",str(ROOT/"fixtures/continuation/before.json"),"--after",str(ROOT/"fixtures/continuation/after.bad-leaf-stop.json")],1); assert "leaf_blocker_promoted_global" in out and "premature_global_stop" in out
out=run(["continuation","--before",str(ROOT/"fixtures/continuation/before.json"),"--after",str(ROOT/"fixtures/continuation/after.bad-scope-drift.json")],1); assert "scope_drift_without_handoff" in out
out=run(["continuation","--before",str(ROOT/"fixtures/continuation/before.json"),"--after",str(ROOT/"fixtures/continuation/after.good-leaf-continue.json")],0); assert "OPC_CONTINUATION_PASS" in out
task_files=[str(p) for p in (ROOT/"examples/synthetic-company/tasks").glob("*.json")]; out=run(["lint",*task_files],0); assert "OPC_LINT_OK" in out
out=run(["lint",str(ROOT/"examples/synthetic-company")],0); assert "OPC_LINT_OK" in out
print("OPC_TEST_OK")
