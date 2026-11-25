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
out=run(["verify","--task",str(ROOT/"examples/synthetic-company/tasks/product-release.json"),"--receipt",str(ROOT/"examples/synthetic-company/receipts/product-release.valid.json")],0); assert out.strip() == "OPC_VERIFY_PASS scope=declarations_only"
out=run(["failover","--before",str(ROOT/"fixtures/quota-failover/task.before.json"),"--after",str(ROOT/"fixtures/quota-failover/task.after.json")],0); assert "OPC_FAILOVER_PASS" in out
out=run(["continuation","--before",str(ROOT/"fixtures/continuation/before.json"),"--after",str(ROOT/"fixtures/continuation/after.bad-leaf-stop.json")],1); assert "leaf_blocker_promoted_global" in out and "premature_global_stop" in out
out=run(["continuation","--before",str(ROOT/"fixtures/continuation/before.json"),"--after",str(ROOT/"fixtures/continuation/after.bad-scope-drift.json")],1); assert "scope_drift_without_handoff" in out
out=run(["continuation","--before",str(ROOT/"fixtures/continuation/before.json"),"--after",str(ROOT/"fixtures/continuation/after.good-leaf-continue.json")],0); assert "OPC_CONTINUATION_PASS" in out
task_files=[str(p) for p in (ROOT/"examples/synthetic-company/tasks").glob("*.json")]; out=run(["lint",*task_files],0); assert "OPC_LINT_OK" in out
out=run(["lint",str(ROOT/"examples/synthetic-company")],0); assert "OPC_LINT_OK" in out
# Strict proof is opt-in; the legacy receipt checker only validates declarations.
import tempfile, hashlib
with tempfile.TemporaryDirectory(prefix="opc-proof-test-") as tmp:
    d=Path(tmp)
    proof=d/"proof.txt"
    proof.write_text("synthetic evidence",encoding="utf-8")
    task={"schema_version":1,"id":"synthetic-proof-task","title":"Synthetic",
          "status":"archived","owner":"synthetic-owner","primary_worker":"worker-b",
          "next_action":"Review only","updated_at":"2026-01-01T00:00:00Z",
          "artifacts":["proof.txt"],"downstream_requires_ack":True}
    handoff={"schema_version":1,"handoff_id":"synthetic-handoff","task_id":task["id"],
             "from":"worker-a","to":"worker-b","body":"Synthetic handoff",
             "created_at":"2026-01-01T00:00:00Z"}
    receipt={"schema_version":1,"receipt_id":"synthetic-receipt","task_id":task["id"],
             "worker":"worker-b","outcome":"completed","artifacts":["proof.txt"],
             "validation":["synthetic local check"],"owner_writeback":True,
             "downstream_ack":{"status":"ADOPTED","task_id":task["id"],
                               "handoff_id":handoff["handoff_id"],"by":"worker-b"},
             "created_at":"2026-01-01T00:00:00Z"}
    for name,value in (("task.json",task),("handoff.json",handoff),("receipt.json",receipt)):
        (d/name).write_text(json.dumps(value),encoding="utf-8")
    (d/"manifest.json").write_text(json.dumps({"proof.txt":hashlib.sha256(proof.read_bytes()).hexdigest()}),encoding="utf-8")
    base=["verify","--task",str(d/"task.json"),"--receipt",str(d/"receipt.json")]
    strict=base+["--strict-proof","--artifact-root",str(d),"--manifest",str(d/"manifest.json"),"--handoff",str(d/"handoff.json")]
    assert "scope=declarations_only" in run(base,0)
    assert "scope=local_artifacts_and_ack" in run(strict,0)
    proof.write_text("tampered",encoding="utf-8")
    assert "artifact_digest_mismatch" in run(strict,1)
    proof.unlink()
    assert "artifact_missing" in run(strict,1)
    proof.write_text("synthetic evidence",encoding="utf-8")
    receipt["downstream_ack"]["task_id"]="wrong-task"
    (d/"receipt.json").write_text(json.dumps(receipt),encoding="utf-8")
    assert "semantic_ack_task_mismatch" in run(strict,1)
    receipt["downstream_ack"]["task_id"]=task["id"]
    (d/"receipt.json").write_text(json.dumps(receipt),encoding="utf-8")
    handoff["to"]="wrong-worker"
    (d/"handoff.json").write_text(json.dumps(handoff),encoding="utf-8")
    assert "semantic_ack_consumer_mismatch" in run(strict,1)
    handoff["to"]="worker-b"
    (d/"handoff.json").write_text(json.dumps(handoff),encoding="utf-8")
    for not_adopted in ("REJECTED", "DEFERRED", "DUPLICATE"):
        receipt["downstream_ack"]["status"]=not_adopted
        (d/"receipt.json").write_text(json.dumps(receipt),encoding="utf-8")
        assert "semantic_ack_not_adopted" in run(strict,1), not_adopted
    receipt["downstream_ack"]["status"]="ADOPTED"
    (d/"receipt.json").write_text(json.dumps(receipt),encoding="utf-8")
    assert "scope=local_artifacts_and_ack" in run(strict,0)
    (d/"handoff.json").write_text("[]",encoding="utf-8")
    assert "invalid_handoff_object" in run(strict,1)
    incomplete=dict(handoff); incomplete.pop("handoff_id"); incomplete.pop("to")
    ack=receipt["downstream_ack"]; ack.pop("handoff_id"); ack.pop("by")
    (d/"handoff.json").write_text(json.dumps(incomplete),encoding="utf-8")
    (d/"receipt.json").write_text(json.dumps(receipt),encoding="utf-8")
    rejected=run(strict,1)
    assert "invalid_handoff_identity" in rejected and "invalid_ack_identity" in rejected
    ack.update({"handoff_id":handoff["handoff_id"],"by":handoff["to"]})
    (d/"handoff.json").write_text(json.dumps(handoff),encoding="utf-8")
    (d/"receipt.json").write_text(json.dumps(receipt),encoding="utf-8")
    assert "scope=local_artifacts_and_ack" in run(strict,0)
print("OPC_STRICT_PROOF_TEST_OK")
print("OPC_TEST_OK")
