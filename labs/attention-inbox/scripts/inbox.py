#!/usr/bin/env python3
import argparse
import json
import sys

KINDS = {"decision_required", "blocked", "failure", "risk_alert", "completion", "info"}
SEVERITIES = {"low", "medium", "high", "critical"}
REQUIRED = {
    "schema_version", "event_id", "task_ref", "source", "owner", "kind",
    "severity", "summary", "occurred_at", "dedupe_key", "source_revision"
}


def load_json(path: str):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def validate_event(event):
    errors = []
    missing = sorted(REQUIRED - set(event))
    if missing:
        errors.append("missing=" + ",".join(missing))
    if event.get("schema_version") != 1:
        errors.append("schema_version")
    if event.get("kind") not in KINDS:
        errors.append("kind")
    if event.get("severity") not in SEVERITIES:
        errors.append("severity")
    for key in ("event_id", "task_ref", "source", "owner", "summary", "occurred_at", "dedupe_key"):
        if key in event and (not isinstance(event[key], str) or not event[key].strip()):
            errors.append(key)
    decision = event.get("decision")
    if decision is not None:
        if not isinstance(decision, dict) or "required" not in decision or not isinstance(decision.get("required"), bool):
            errors.append("decision")
    return errors


def concrete_decision(event):
    decision = event.get("decision") or {}
    if decision.get("required") is not True:
        return False
    if not str(decision.get("gate_id", "")).strip():
        return False
    if not str(decision.get("question", "")).strip():
        return False
    actions = decision.get("allowed_actions")
    return isinstance(actions, list) and len(actions) > 0 and all(isinstance(a, str) and a.strip() for a in actions)


def classify(event):
    if concrete_decision(event):
        return "ACTION_REQUIRED", "concrete_decision"

    if event.get("kind") == "risk_alert" and event.get("severity") in {"high", "critical"}:
        return "RISK_ALERT", "meaningful_risk"

    if event.get("kind") == "failure" and event.get("severity") in {"high", "critical"}:
        return "RISK_ALERT", "meaningful_failure"

    if event.get("kind") == "completion":
        return "SUPPRESS", "routine_completion"

    if event.get("kind") in {"blocked", "decision_required"}:
        return "SUPPRESS", "no_concrete_user_decision"

    return "SUPPRESS", "no_attention_needed"


def render(event):
    outcome, reason = classify(event)
    task = event["task_ref"]
    if outcome == "ACTION_REQUIRED":
        gate = event["decision"]["gate_id"]
        return f"ACTION_REQUIRED task={task} gate={gate}"
    if outcome == "RISK_ALERT":
        return f"RISK_ALERT task={task} severity={event['severity']}"
    return f"SUPPRESS reason={reason}"


def cmd_check(path):
    event = load_json(path)
    errors = validate_event(event)
    if errors:
        for err in errors:
            print(f"ATTENTION_EVENT_INVALID {err}")
        return 1
    print("ATTENTION_EVENT_VALID")
    return 0


def cmd_render(path):
    event = load_json(path)
    errors = validate_event(event)
    if errors:
        for err in errors:
            print(f"ATTENTION_EVENT_INVALID {err}")
        return 1
    print(render(event))
    return 0


def cmd_batch(path):
    seen = set()
    invalid = 0
    with open(path, "r", encoding="utf-8") as f:
        for lineno, line in enumerate(f, 1):
            if not line.strip():
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                print(f"ATTENTION_EVENT_INVALID line={lineno} json")
                invalid += 1
                continue
            errors = validate_event(event)
            if errors:
                print(f"ATTENTION_EVENT_INVALID line={lineno} {';'.join(errors)}")
                invalid += 1
                continue
            dedupe_identity = (event["dedupe_key"], str(event["source_revision"]))
            if dedupe_identity in seen:
                print(f"SUPPRESS reason=duplicate event={event['event_id']}")
                continue
            seen.add(dedupe_identity)
            print(render(event))
    return 1 if invalid else 0


def main():
    parser = argparse.ArgumentParser(description="Reference Attention Inbox policy CLI")
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("check", "render", "batch"):
        p = sub.add_parser(name)
        p.add_argument("path")
    args = parser.parse_args()
    if args.command == "check":
        return cmd_check(args.path)
    if args.command == "render":
        return cmd_render(args.path)
    return cmd_batch(args.path)


if __name__ == "__main__":
    sys.exit(main())
