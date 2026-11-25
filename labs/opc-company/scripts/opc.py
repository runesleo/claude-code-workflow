#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json, re, sys
from pathlib import Path

VALID_STATUSES = {"active","waiting","monitoring","parked","archived"}

def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))

def lint_task(task):
    errors=[]
    for k in ("schema_version","id","status","owner","primary_worker","next_action","updated_at","artifacts"):
        if k not in task: errors.append(f"missing:{k}")
    if task.get("status") not in VALID_STATUSES: errors.append("invalid:status")
    if task.get("claimed_by") and not task.get("claimed_at"): errors.append("claim_without_time")
    if task.get("status") == "archived" and task.get("claimed_by"): errors.append("archived_but_claimed")
    return errors

def cmd_lint(args):
    errors=[]; files=[]
    for raw in args.files:
        path=Path(raw)
        if not path.exists():
            errors.append(f"{raw}:not_found")
            continue
        if path.is_dir():
            files.extend(sorted(path.rglob("*.json")))
        else:
            files.append(path)
    for path in files:
        try:
            obj=read_json(path)
        except (OSError, json.JSONDecodeError) as exc:
            errors.append(f"{path}:unreadable_json:{exc.__class__.__name__}")
            continue
        if isinstance(obj, dict) and "status" in obj and "id" in obj:
            errors += [f"{path}:{e}" for e in lint_task(obj)]
    if errors:
        for e in errors: print("OPC_LINT_ERROR", e)
        return 1
    print(f"OPC_LINT_OK files={len(files)}")
    return 0

def cmd_status(args):
    d=Path(args.company); tasks=[]
    for p in sorted((d/"tasks").glob("*.json")): tasks.append(read_json(p))
    active=[t for t in tasks if t.get("status")=="active"]
    out={"task_count":len(tasks),"active_tasks":[t["id"] for t in active],"active_owners":sorted(set(t.get("owner") for t in active)),"pending_ack_tasks":[t["id"] for t in tasks if t.get("downstream_requires_ack")],"work_continuing":bool(active)}
    print(json.dumps(out, indent=2)); return 0

def requires_handoff(args, task, receipt):
    return bool(task.get("downstream_requires_ack") or args.handoff is not None or receipt.get("downstream_ack") is not None)


def strict_proof_errors(args, task, receipt):
    """Check local artifact bytes and handoff linkage; does not attest external owner state."""
    errors=[]
    if receipt.get("outcome") != "completed": errors.append("strict_proof_requires_completed")
    if task.get("status") != "archived": errors.append("strict_task_not_archived")
    if any(not isinstance(value, str) or not value.strip()
           for value in (task.get("id"), task.get("owner"), task.get("primary_worker"),
                         receipt.get("task_id"), receipt.get("worker"))):
        errors.append("strict_identity_missing")
    if receipt.get("worker") != task.get("primary_worker"): errors.append("worker_mismatch")
    names=receipt.get("artifacts")
    if not isinstance(names, list) or not names or any(not isinstance(n, str) or not n for n in names):
        return errors + ["invalid_artifact_list"]
    if len(names) != len(set(names)) or set(names) != set(task.get("artifacts") or []):
        errors.append("artifact_list_mismatch")
    if not args.artifact_root or not args.manifest:
        return errors + ["strict_artifact_proof_missing"]
    root=Path(args.artifact_root).resolve()
    try:
        manifest_bytes=Path(args.manifest).read_bytes()
        manifest=json.loads(manifest_bytes.decode("utf-8"))
        manifest_sha256=hashlib.sha256(manifest_bytes).hexdigest()
    except (OSError, ValueError):
        return errors + ["manifest_unreadable"]
    if not isinstance(manifest, dict) or set(manifest) != set(names):
        return errors + ["manifest_entries_mismatch"]
    for name in names:
        relative=Path(name)
        if relative.is_absolute() or ".." in relative.parts:
            errors.append("artifact_path_unsafe:" + name)
            continue
        path=(root / relative).resolve()
        if path == root or root not in path.parents:
            errors.append("artifact_path_unsafe:" + name)
            continue
        if not path.is_file():
            errors.append("artifact_missing:" + name)
            continue
        expected=manifest.get(name)
        if not isinstance(expected, str) or not re.fullmatch(r"[0-9a-f]{64}", expected):
            errors.append("artifact_digest_invalid:" + name)
            continue
        actual=hashlib.sha256(path.read_bytes()).hexdigest()
        if actual != expected: errors.append("artifact_digest_mismatch:" + name)
    if requires_handoff(args, task, receipt):
        ack=receipt.get("downstream_ack")
        if not isinstance(ack, dict):
            errors.append("missing_semantic_ack")
        if not args.handoff:
            errors.append("handoff_proof_missing")
        else:
            try:
                handoff_bytes=Path(args.handoff).read_bytes()
                handoff=json.loads(handoff_bytes.decode("utf-8"))
                handoff_sha256=hashlib.sha256(handoff_bytes).hexdigest()
            except (OSError, ValueError):
                handoff=None
                errors.append("handoff_unreadable")
            if not isinstance(handoff, dict):
                errors.append("invalid_handoff_object")
            elif any(not isinstance(handoff.get(k), str) or not handoff[k].strip()
                     for k in ("handoff_id", "task_id", "from", "to", "body", "created_at")) or handoff.get("schema_version") != 1:
                errors.append("invalid_handoff_identity")
            if isinstance(ack, dict) and isinstance(handoff, dict):
                if any(not isinstance(ack.get(k), str) or not ack[k].strip()
                       for k in ("task_id", "handoff_id", "by")):
                    errors.append("invalid_ack_identity")
                if ack.get("status") != "ADOPTED":
                    errors.append("semantic_ack_not_adopted")
                if ack.get("task_id") != task.get("id") or handoff.get("task_id") != task.get("id"):
                    errors.append("semantic_ack_task_mismatch")
                if ack.get("handoff_id") != handoff.get("handoff_id"):
                    errors.append("semantic_ack_handoff_mismatch")
                if ack.get("by") != handoff.get("to"):
                    errors.append("semantic_ack_consumer_mismatch")
                if ack.get("artifact_manifest_sha256") != manifest_sha256:
                    errors.append("semantic_ack_manifest_mismatch")
                if ack.get("handoff_sha256") != handoff_sha256:
                    errors.append("semantic_ack_handoff_digest_mismatch")
    return errors


def cmd_verify(args):
    task=read_json(args.task); receipt=read_json(args.receipt); errors=[]
    if receipt.get("task_id") != task.get("id"): errors.append("task_id_mismatch")
    if receipt.get("outcome") == "completed":
        if not receipt.get("artifacts"): errors.append("missing_artifact")
        if not receipt.get("validation"): errors.append("missing_validation")
        if receipt.get("owner_writeback") is not True: errors.append("missing_owner_writeback")
        if task.get("downstream_requires_ack"):
            ack=receipt.get("downstream_ack")
            if not isinstance(ack, dict) or ack.get("status") not in {"ADOPTED","REJECTED","DEFERRED","DUPLICATE"}: errors.append("missing_semantic_ack")
    if args.strict_proof:
        errors.extend(strict_proof_errors(args,task,receipt))
    if errors:
        for e in errors: print("OPC_VERIFY_REJECT", e)
        return 1
    if args.strict_proof:
        scope="local_artifacts_and_ack" if requires_handoff(args,task,receipt) else "local_artifacts_only"
        print("OPC_VERIFY_PASS scope=" + scope)
    else:
        # Preserve the documented legacy stdout token for exact-match consumers.
        print("OPC_VERIFY_PASS")
        print("OPC_VERIFY_SCOPE declarations_only", file=sys.stderr)
    return 0

def cmd_failover(args):
    before=read_json(args.before); after=read_json(args.after); errors=[]
    if before.get("id") != after.get("id"): errors.append("task_id_changed")
    if before.get("owner") != after.get("owner"): errors.append("owner_changed")
    if before.get("artifacts") != after.get("artifacts"): errors.append("artifacts_changed_during_failover")
    if before.get("primary_worker") == after.get("primary_worker"): errors.append("worker_not_changed")
    if errors:
        for e in errors: print("OPC_FAILOVER_REJECT", e)
        return 1
    print(f"OPC_FAILOVER_PASS task={before.get('id')} from={before.get('primary_worker')} to={after.get('primary_worker')}"); return 0

def cmd_continuation(args):
    before=read_json(args.before); after=read_json(args.after); errors=[]
    if before.get("canonical_task_id") != after.get("canonical_task_id"):
        errors.append("canonical_task_changed")
    scope_changed = before.get("scope_id") != after.get("scope_id")
    handoff = after.get("scope_handoff")
    if scope_changed:
        if not isinstance(handoff, dict) or handoff.get("status") != "ADOPTED":
            errors.append("scope_drift_without_handoff")
    if after.get("blocker_level") == "leaf" and after.get("global_status") == "blocked":
        errors.append("leaf_blocker_promoted_global")
    remaining = after.get("remaining_work") or []
    if after.get("work_continuing") is False and remaining:
        errors.append("premature_global_stop")
    if errors:
        for e in errors: print("OPC_CONTINUATION_REJECT", e)
        return 1
    print(f"OPC_CONTINUATION_PASS task={after.get('canonical_task_id')} scope={after.get('scope_id')} work_continuing={str(bool(after.get('work_continuing'))).lower()}")
    return 0

def main():
    ap=argparse.ArgumentParser(prog="opc"); sp=ap.add_subparsers(dest="cmd",required=True)
    p=sp.add_parser("lint"); p.add_argument("files",nargs="+"); p.set_defaults(fn=cmd_lint)
    p=sp.add_parser("status"); p.add_argument("company"); p.set_defaults(fn=cmd_status)
    p=sp.add_parser("verify"); p.add_argument("--task",required=True); p.add_argument("--receipt",required=True)
    p.add_argument("--strict-proof",action="store_true"); p.add_argument("--artifact-root"); p.add_argument("--manifest"); p.add_argument("--handoff"); p.set_defaults(fn=cmd_verify)
    p=sp.add_parser("failover"); p.add_argument("--before",required=True); p.add_argument("--after",required=True); p.set_defaults(fn=cmd_failover)
    p=sp.add_parser("continuation"); p.add_argument("--before",required=True); p.add_argument("--after",required=True); p.set_defaults(fn=cmd_continuation)
    args=ap.parse_args(); raise SystemExit(args.fn(args))

if __name__=="__main__": main()
