#!/usr/bin/env python3
"""Isolated positive and negative checks of the synthetic process handoff."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from unittest.mock import patch

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("workflow", ROOT / "run.py")
workflow = importlib.util.module_from_spec(spec)
spec.loader.exec_module(workflow)


def expect_reject(fn):
    try:
        fn()
    except (ValueError, subprocess.CalledProcessError):
        return
    raise AssertionError("invalid evidence or artifact accepted")


def cli(out, *args):
    return subprocess.run([sys.executable, str(ROOT / "run.py"), "--out", str(out), *args],
                          capture_output=True, text=True)


def assert_result(out):
    result = out / "result"
    assert {p.name for p in result.iterdir()} == {
        "artifact-manifest.json", "content-draft.md", "decision.json", "failover.after.json",
        "receipt.json", "research.md", "task.json", "publish-gate.json",
        "attention-events.jsonl", "attention-output.txt"}
    before = workflow.read_json(out / "checkpoint/task.json")
    after = workflow.read_json(result / "failover.after.json")
    task = workflow.read_json(result / "task.json")
    receipt = workflow.read_json(result / "receipt.json")
    assert before["status"] == "active" and before["primary_worker"] == "worker-a"
    assert after["primary_worker"] == task["primary_worker"] == "worker-b"
    assert before["id"] == after["id"] == task["id"] == receipt["task_id"]
    assert before["owner"] == after["owner"] == task["owner"]
    assert before["artifacts"] == after["artifacts"]
    assert task["status"] == "archived" and receipt["outcome"] == "completed"
    assert receipt["downstream_ack"]["status"] == "ADOPTED"
    assert receipt["downstream_ack"]["task_id"] == task["id"]
    assert receipt["downstream_ack"]["evidence"] == workflow.read_json(out / "checkpoint/handoff.json")["body"]
    manifest = workflow.read_json(result / "artifact-manifest.json")
    workflow.verify_artifacts(result, manifest)
    assert manifest["research.md"] == workflow.digest(out / "checkpoint/research.md")
    assert workflow.read_json(result / "decision.json")["release_authorized"] is False
    gate = workflow.read_json(result / "publish-gate.json")
    assert gate["kind"] == "publish" and gate["status"] == "OPEN"
    assert gate["evidence"] == ["content-draft.md sha256=" + workflow.digest(result / "content-draft.md")]
    events = [json.loads(line) for line in (result / "attention-events.jsonl").read_text().splitlines()]
    assert len(events) == 4 and all(e["task_ref"] == task["id"] and e["owner"] == task["owner"] for e in events)
    assert events[0]["decision"]["required"] is False and events[1]["decision"]["required"] is False
    assert events[2]["decision"]["gate_id"] == gate["gate_id"]
    assert events[2]["decision"]["allowed_actions"] == ["review_draft", "hold"]
    assert events[2]["source_revision"] == workflow.digest(result / "publish-gate.json")
    assert events[2]["dedupe_key"] == events[3]["dedupe_key"]
    assert events[2]["source_revision"] == events[3]["source_revision"]
    assert events[2]["event_id"] != events[3]["event_id"]
    for event in events:
        assert all((result / item["ref"]).is_file() for item in event["evidence"])
    lines = (result / "attention-output.txt").read_text().splitlines()
    assert lines == [
        "SUPPRESS reason=no_concrete_user_decision",
        "SUPPRESS reason=routine_completion",
        "ACTION_REQUIRED task=" + task["id"] + " gate=" + gate["gate_id"],
        "SUPPRESS reason=duplicate event=" + events[3]["event_id"],
    ], lines
    return result, manifest


def main():
    data = workflow.read_json(ROOT / "opportunity.json")
    with tempfile.TemporaryDirectory(prefix="opc-first-workflow-test-") as tmp:
        root = Path(tmp)
        normal = root / "normal"
        result = cli(normal)
        assert result.returncode == 0 and "OPC_FIRST_WORKFLOW_PASS" in result.stdout, result.stderr
        assert "OPC_VERIFY_PASS" in result.stdout and "OPC_FAILOVER_PASS" in result.stdout
        assert_result(normal)
        print("NORMAL_REPLAY_OK")
        print("ATTENTION_DECISION_AND_DEDUPE_OK")

        out = root / "interrupted"
        first = cli(out, "--phase", "prepare", "--simulate-failover")
        assert first.returncode == 75 and "OPC_CHECKPOINT_READY" in first.stdout
        assert not (out / "result").exists()
        second = cli(out, "--phase", "resume")
        assert second.returncode == 0 and "OPC_FIRST_WORKFLOW_PASS" in second.stdout, second.stderr
        final, manifest = assert_result(out)
        assert cli(out, "--phase", "resume").returncode == 1
        print("PROCESS_FAILOVER_OK")

        automatic = root / "automatic"
        result = cli(automatic, "--simulate-failover")
        assert result.returncode == 0 and "OPC_FIRST_WORKFLOW_PASS" in result.stdout, result.stderr
        assert "OPC_WORKER_A_INTERRUPTED" in result.stderr
        assert_result(automatic)
        print("ONE_COMMAND_FAILOVER_OK")

        (final / "research.md").write_text("tampered")
        expect_reject(lambda: workflow.verify_artifacts(final, manifest))
        (final / "research.md").unlink()
        expect_reject(lambda: workflow.verify_artifacts(final, manifest))

        bad = json.loads(json.dumps(data))
        bad["facts"][0]["source_ids"] = ["MISSING"]
        bad_out = root / "bad-out"
        expect_reject(lambda: workflow.prepare(bad, bad_out))
        assert not bad_out.exists()

        damaged = root / "damaged"
        workflow.prepare(data, damaged)
        (damaged / "checkpoint/research.md").write_text("tampered")
        expect_reject(lambda: workflow.resume(data, damaged))
        assert not (damaged / "result").exists()
        print("EVIDENCE_REJECTION_OK")

        no_ack = root / "no-ack"
        workflow.prepare(data, no_ack)
        with patch.object(workflow, "downstream_ack", return_value=None):
            expect_reject(lambda: workflow.resume(data, no_ack))
        assert not (no_ack / "result").exists()
        assert workflow.read_json(no_ack / "checkpoint/task.json")["status"] == "active"
        workflow.resume(data, no_ack)
        assert_result(no_ack)
        print("MISSING_ACK_REJECT_AND_RECOVER_OK")

        invalid_attention = root / "invalid-attention"
        workflow.prepare(data, invalid_attention)
        with patch.object(workflow, "attention_events", return_value=[{"kind": "decision_required"}]):
            expect_reject(lambda: workflow.resume(data, invalid_attention))
        assert not (invalid_attention / "result").exists()
        assert workflow.read_json(invalid_attention / "checkpoint/task.json")["status"] == "active"
        workflow.resume(data, invalid_attention)
        assert_result(invalid_attention)
        print("ATTENTION_INVALID_REJECT_AND_RECOVER_OK")
    print("FIRST_WORKFLOW_FOCUSED_TESTS_OK")


if __name__ == "__main__":
    main()
