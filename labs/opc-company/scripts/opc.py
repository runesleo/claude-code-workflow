#!/usr/bin/env python3
from __future__ import annotations
import argparse, json
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
    errors=[]
    for p in args.files:
        obj=read_json(p)
        if isinstance(obj, dict) and "status" in obj and "id" in obj:
            errors += [f"{p}:{e}" for e in lint_task(obj)]
    if errors:
        for e in errors: print("OPC_LINT_ERROR", e)
        return 1
    print(f"OPC_LINT_OK files={len(args.files)}")
    return 0

def cmd_status(args):
    d=Path(args.company); tasks=[]
    for p in sorted((d/"tasks").glob("*.json")): tasks.append(read_json(p))
    active=[t for t in tasks if t.get("status")=="active"]
    out={"task_count":len(tasks),"active_tasks":[t["id"] for t in active],"active_owners":sorted(set(t.get("owner") for t in active)),"pending_ack_tasks":[t["id"] for t in tasks if t.get("downstream_requires_ack")],"work_continuing":bool(active)}
    print(json.dumps(out, indent=2)); return 0

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
    if errors:
        for e in errors: print("OPC_VERIFY_REJECT", e)
        return 1
    print("OPC_VERIFY_PASS"); return 0

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

def main():
    ap=argparse.ArgumentParser(prog="opc"); sp=ap.add_subparsers(dest="cmd",required=True)
    p=sp.add_parser("lint"); p.add_argument("files",nargs="+"); p.set_defaults(fn=cmd_lint)
    p=sp.add_parser("status"); p.add_argument("company"); p.set_defaults(fn=cmd_status)
    p=sp.add_parser("verify"); p.add_argument("--task",required=True); p.add_argument("--receipt",required=True); p.set_defaults(fn=cmd_verify)
    p=sp.add_parser("failover"); p.add_argument("--before",required=True); p.add_argument("--after",required=True); p.set_defaults(fn=cmd_failover)
    args=ap.parse_args(); raise SystemExit(args.fn(args))

if __name__=="__main__": main()
