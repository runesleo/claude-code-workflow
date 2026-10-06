#!/usr/bin/env python3
import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "inbox.py"
spec = importlib.util.spec_from_file_location("attention_inbox", SCRIPT)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def load(name):
    return mod.load_json(str(ROOT / "fixtures" / name))


def expect(condition, message):
    if not condition:
        raise AssertionError(message)


def main():
    decision = load("decision-required.json")
    waiting = load("internal-waiting.json")
    risk = load("risk-alert.json")
    completion = load("completion.json")

    for event in (decision, waiting, risk, completion):
        expect(mod.validate_event(event) == [], f"invalid fixture: {event['event_id']}")

    expect(mod.render(decision) == "ACTION_REQUIRED task=synthetic-release gate=publish_release", "decision should escalate")
    expect(mod.render(waiting) == "SUPPRESS reason=no_concrete_user_decision", "internal waiting must not masquerade as approval")
    expect(mod.render(risk) == "RISK_ALERT task=synthetic-worker-health severity=high", "high risk should surface")
    expect(mod.render(completion) == "SUPPRESS reason=routine_completion", "routine completion should stay quiet")

    fake = dict(decision)
    fake["decision"] = {"required": True, "gate_id": "publish_release", "question": "Publish?", "allowed_actions": []}
    expect(mod.render(fake) == "SUPPRESS reason=no_concrete_user_decision", "decision without actions is not concrete")

    print("ATTENTION_INBOX_TEST_OK")


if __name__ == "__main__":
    main()
