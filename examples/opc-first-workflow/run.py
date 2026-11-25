#!/usr/bin/env python3
"""Offline synthetic signal-to-deliverable replay with process-level handoff."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent
VERIFIER = ROOT.parent.parent / "labs/opc-company/scripts/opc.py"
INBOX = ROOT.parent.parent / "labs/attention-inbox/scripts/inbox.py"
STAMP = "2026-01-01T00:00:00Z"
INTERRUPTED = 75
NAMES = ("research.md", "content-draft.md", "decision.json")


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def validate_sample(data):
    if data.get("synthetic") is not True:
        raise ValueError("only explicitly synthetic samples are accepted")
    sources = {s["id"]: s["text"] for s in data["sources"]}
    if len(sources) != len(data["sources"]) or not sources:
        raise ValueError("missing or duplicate sources")
    facts = data["facts"]
    if not facts or len({f["id"] for f in facts}) != len(facts):
        raise ValueError("missing or duplicate facts")
    for fact in facts:
        refs = fact["source_ids"]
        if not refs or any(ref not in sources for ref in refs):
            raise ValueError("unknown or missing evidence reference: " + fact["id"])
    if not data["unknowns"] or not data["decision"] or not data["draft"]:
        raise ValueError("missing unknowns, decision, or draft")
    return sources


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sample_digest(data):
    return hashlib.sha256(json.dumps(data, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def verify_artifacts(out, manifest):
    for name, expected in manifest.items():
        path = out / name
        if not path.is_file() or digest(path) != expected:
            raise ValueError("missing or changed artifact: " + name)


def opc(*args):
    subprocess.run([sys.executable, str(VERIFIER), *map(str, args)], check=True)


def initial_task(data):
    return {"schema_version": 1, "id": data["signal_id"], "title": data["title"],
            "status": "active", "owner": "synthetic-research-owner", "primary_worker": "worker-a",
            "next_action": "Preserve research and hand off to worker-b.",
            "updated_at": STAMP, "artifacts": ["research.md"], "downstream_requires_ack": True}


def handoff(task, research_digest):
    return {"schema_version": 1, "handoff_id": "synthetic-handoff-1", "task_id": task["id"],
            "from": "worker-a", "to": "worker-b",
            "body": "Adopt research.md sha256=" + research_digest + "; prepare unpublished draft.",
            "created_at": STAMP, "receipt_ref": None}


def prepare(data, out):
    sources = validate_sample(data)
    out.mkdir(parents=True, exist_ok=False)
    checkpoint = out / "checkpoint"
    checkpoint.mkdir()
    brief = ["# Synthetic research brief", "", data["title"], "", "## Evidence"]
    brief += ["- " + sid + ": " + body for sid, body in sources.items()]
    brief += ["", "## Facts"]
    brief += ["- " + f["claim"] + " [" + ", ".join(f["source_ids"]) + "]" for f in data["facts"]]
    brief += ["", "## Unknowns"] + ["- " + item for item in data["unknowns"]]
    (checkpoint / "research.md").write_text("\n".join(brief) + "\n", encoding="utf-8")
    research_digest = digest(checkpoint / "research.md")
    task = initial_task(data)
    write_json(checkpoint / "task.json", task)
    write_json(checkpoint / "handoff.json", handoff(task, research_digest))
    write_json(checkpoint / "checkpoint.json",
               {"sample_sha256": sample_digest(data), "research_sha256": research_digest})
    opc("lint", checkpoint / "task.json")
    print("OPC_CHECKPOINT_READY")


def downstream_ack(task, adopted, manifest_sha256, handoff_sha256):
    return {"status": "ADOPTED", "by": "worker-b", "task_id": task["id"],
            "handoff_id": adopted["handoff_id"], "evidence": adopted["body"],
            "artifact_manifest_sha256": manifest_sha256,
            "handoff_sha256": handoff_sha256}


def attention_events(stage, task, receipt):
    """Derive a synthetic attention batch from the verified preparation result."""
    gate = {"schema_version": 1, "gate_id": "synthetic_publish_review",
            "kind": "publish", "status": "OPEN",
            "evidence": ["content-draft.md sha256=" + digest(stage / "content-draft.md")]}
    write_json(stage / "publish-gate.json", gate)
    task_id = task["id"]

    def event(event_id, kind, severity, summary, key, revision, evidence, decision):
        return {"schema_version": 1, "event_id": task_id + ":" + event_id,
                "task_ref": task_id, "source": "synthetic-offline-replay", "owner": task["owner"],
                "kind": kind, "severity": severity, "summary": summary, "occurred_at": STAMP,
                "dedupe_key": task_id + ":" + key, "source_revision": revision,
                "evidence": evidence, "decision": decision}

    receipt_ref = [{"type": "receipt", "ref": "receipt.json", "label": receipt["receipt_id"]}]
    revision = digest(stage / "receipt.json")
    internal = event("internal-wait", "blocked", "low", "Synthetic worker handoff; no founder decision.",
                     "internal-wait", revision, receipt_ref, {"required": False})
    routine = event("prepared", "completion", "low", "Synthetic preparation completed and verified.",
                    "prepared", revision, receipt_ref, {"required": False})
    review = event("review", "decision_required", "medium",
                   "Synthetic draft ready for human review; no real publication is possible.",
                   gate["gate_id"], digest(stage / "publish-gate.json"),
                   [{"type": "artifact", "ref": "content-draft.md"},
                    {"type": "artifact", "ref": "publish-gate.json"}],
                   {"required": True, "gate_id": gate["gate_id"],
                    "question": "Review the fictional draft for a hypothetical release, or hold?",
                    "allowed_actions": ["review_draft", "hold"]})
    duplicate = dict(review, event_id=task_id + ":review-duplicate")
    return [internal, routine, review, duplicate]


def render_attention(stage, task, receipt):
    events = attention_events(stage, task, receipt)
    path = stage / "attention-events.jsonl"
    path.write_text("".join(json.dumps(event, ensure_ascii=False) + "\n" for event in events),
                    encoding="utf-8")
    output = subprocess.run([sys.executable, str(INBOX), "batch", str(path)],
                            check=True, capture_output=True, text=True).stdout
    (stage / "attention-output.txt").write_text(output, encoding="utf-8")
    return output


def resume(data, out):
    validate_sample(data)
    checkpoint = out / "checkpoint"
    result = out / "result"
    if result.exists():
        raise ValueError("result already exists; use a new output directory")
    metadata = read_json(checkpoint / "checkpoint.json")
    if metadata["sample_sha256"] != sample_digest(data):
        raise ValueError("sample changed after checkpoint")
    verify_artifacts(checkpoint, {"research.md": metadata["research_sha256"]})
    before = read_json(checkpoint / "task.json")
    if before != initial_task(data):
        raise ValueError("checkpoint task identity or state changed")
    adopted_bytes = (checkpoint / "handoff.json").read_bytes()
    adopted = json.loads(adopted_bytes.decode("utf-8"))
    adopted_sha256 = hashlib.sha256(adopted_bytes).hexdigest()
    if adopted != handoff(before, metadata["research_sha256"]):
        raise ValueError("handoff does not match checkpoint")
    after = dict(before, primary_worker="worker-b", next_action="Produce and verify draft.")
    # No completed result is visible until all staged checks pass.
    with tempfile.TemporaryDirectory(prefix=".opc-stage-", dir=out) as tmp:
        stage = Path(tmp)
        write_json(stage / "failover.after.json", after)
        opc("failover", "--before", checkpoint / "task.json", "--after", stage / "failover.after.json")
        opc("lint", stage / "failover.after.json")
        (stage / "research.md").write_bytes((checkpoint / "research.md").read_bytes())
        (stage / "content-draft.md").write_text("# Unpublished synthetic draft\n\n" + data["draft"] + "\n", encoding="utf-8")
        write_json(stage / "decision.json", {"synthetic": True, "decision": data["decision"], "release_authorized": False})
        manifest = {name: digest(stage / name) for name in NAMES}
        if manifest["research.md"] != metadata["research_sha256"]:
            raise ValueError("research changed during handoff")
        verify_artifacts(stage, manifest)
        manifest_bytes = (json.dumps(manifest, indent=2, ensure_ascii=False) + "\n").encode("utf-8")
        (stage / "artifact-manifest.json").write_bytes(manifest_bytes)
        manifest_sha256 = hashlib.sha256(manifest_bytes).hexdigest()
        # OPC task lifecycle uses archived, not completed. Completion is a receipt outcome.
        task = dict(after, status="archived", artifacts=list(NAMES),
                    next_action="Separate human review of unpublished draft; no external action.")
        write_json(stage / "task.json", task)
        if read_json(stage / "task.json") != task:
            raise ValueError("synthetic task writeback mismatch")
        receipt = {"schema_version": 1, "receipt_id": "synthetic-replay-1", "task_id": task["id"],
                   "worker": task["primary_worker"], "outcome": "completed", "artifacts": list(NAMES),
                   "validation": ["source references resolve", "checkpoint and artifact digests match"],
                   "owner_writeback": True, "downstream_ack": downstream_ack(
                       task, adopted, manifest_sha256, adopted_sha256),
                   "created_at": STAMP}
        write_json(stage / "receipt.json", receipt)
        opc("lint", stage / "task.json")
        opc("verify", "--task", stage / "task.json", "--receipt", stage / "receipt.json",
            "--strict-proof", "--artifact-root", stage,
            "--manifest", stage / "artifact-manifest.json",
            "--handoff", checkpoint / "handoff.json")
        verify_artifacts(stage, manifest)
        attention_output = render_attention(stage, task, receipt)
        # Atomic rename on the same filesystem: consumers only accept result/.
        stage.rename(result)
    print(attention_output, end="")
    print("OPC_FIRST_WORKFLOW_PASS")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--sample", type=Path, default=ROOT / "opportunity.json")
    parser.add_argument("--phase", choices=("run", "prepare", "resume"), default="run")
    parser.add_argument("--simulate-failover", action="store_true")
    args = parser.parse_args()
    if args.phase == "resume" and args.simulate_failover:
        parser.error("--simulate-failover is only for run or prepare")
    try:
        data = read_json(args.sample)
        if args.phase == "prepare":
            prepare(data, args.out)
            if args.simulate_failover:
                print("OPC_WORKER_A_INTERRUPTED (synthetic exit 75)", file=sys.stderr)
                return INTERRUPTED
        elif args.phase == "resume":
            resume(data, args.out)
        else:
            base = [sys.executable, str(Path(__file__).resolve()), "--out", str(args.out), "--sample", str(args.sample)]
            first = subprocess.run(base + ["--phase", "prepare"] + (["--simulate-failover"] if args.simulate_failover else []))
            expected = INTERRUPTED if args.simulate_failover else 0
            if first.returncode != expected:
                raise ValueError("worker-a did not reach expected checkpoint outcome")
            subprocess.run(base + ["--phase", "resume"], check=True)
    except (ValueError, OSError, KeyError, TypeError, subprocess.CalledProcessError) as exc:
        print("OPC_FIRST_WORKFLOW_REJECT:", exc, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
