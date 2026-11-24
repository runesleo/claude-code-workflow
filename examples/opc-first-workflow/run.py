#!/usr/bin/env python3
"""Offline synthetic signal-to-deliverable replay; no model or network calls."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
VERIFIER = ROOT.parent.parent / "labs/opc-company/scripts/opc.py"
STAMP = "2026-01-01T00:00:00Z"


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


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


def verify_artifacts(out, manifest):
    for name, expected in manifest.items():
        path = out / name
        if not path.is_file() or digest(path) != expected:
            raise ValueError("missing or changed artifact: " + name)


def replay(data, out):
    sources = validate_sample(data)
    out.mkdir(parents=True, exist_ok=False)
    brief = ["# Synthetic research brief", "", data["title"], "", "## Evidence"]
    brief += ["- " + sid + ": " + body for sid, body in sources.items()]
    brief += ["", "## Facts"]
    brief += ["- " + f["claim"] + " [" + ", ".join(f["source_ids"]) + "]" for f in data["facts"]]
    brief += ["", "## Unknowns"] + ["- " + item for item in data["unknowns"]]
    (out / "research.md").write_text("\n".join(brief) + "\n", encoding="utf-8")
    (out / "content-draft.md").write_text("# Unpublished synthetic draft\n\n" + data["draft"] + "\n", encoding="utf-8")
    write_json(out / "decision.json", {"synthetic": True, "decision": data["decision"], "release_authorized": False})
    names = ["research.md", "content-draft.md", "decision.json"]
    manifest = {name: digest(out / name) for name in names}
    verify_artifacts(out, manifest)
    write_json(out / "artifact-manifest.json", manifest)
    task = {"schema_version": 1, "id": data["signal_id"], "title": data["title"],
            "status": "completed", "owner": "synthetic-research-owner", "primary_worker": "offline-replay",
            "next_action": "Separate human review of unpublished draft; no external action.",
            "updated_at": STAMP, "artifacts": names, "downstream_requires_ack": False}
    write_json(out / "task.json", task)
    if json.loads((out / "task.json").read_text(encoding="utf-8")) != task:
        raise ValueError("synthetic task writeback mismatch")
    receipt = {"schema_version": 1, "receipt_id": "synthetic-replay-1", "task_id": task["id"],
               "worker": task["primary_worker"], "outcome": "completed", "artifacts": names,
               "validation": ["source references resolve", "artifact digest readback"],
               "owner_writeback": True, "downstream_ack": None, "created_at": STAMP}
    write_json(out / "receipt.json", receipt)
    verify_artifacts(out, manifest)
    subprocess.run([sys.executable, str(VERIFIER), "verify", "--task", str(out / "task.json"),
                    "--receipt", str(out / "receipt.json")], check=True)
    print("OPC_FIRST_WORKFLOW_PASS")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--sample", type=Path, default=ROOT / "opportunity.json")
    args = parser.parse_args()
    try:
        replay(json.loads(args.sample.read_text(encoding="utf-8")), args.out)
    except (ValueError, OSError, KeyError, TypeError, subprocess.CalledProcessError) as exc:
        print("OPC_FIRST_WORKFLOW_REJECT:", exc, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
