# Attention Inbox Lab

A small, deterministic human-attention layer for AI agents.

The problem is not that agents cannot keep working. The problem is that humans get interrupted by the wrong things: routine completions, internal `waiting_for_user` flags, stale status changes, or duplicate alerts. Meanwhile real decisions and real risks can be buried.

Attention Inbox turns agent/task events into one of three outcomes:

```text
SUPPRESS
RISK_ALERT
ACTION_REQUIRED
```

It is deliberately **not** a task database, scheduler, queue, router, or new control plane. Canonical task state stays where it already lives. This lab is only a derived attention surface over existing task/receipt/event outputs.

## 10-minute first success

Requirements: Python 3 only.

From `labs/attention-inbox`:

```bash
python3 scripts/inbox.py check fixtures/decision-required.json
# exit 0
# ATTENTION_EVENT_VALID

python3 scripts/inbox.py render fixtures/internal-waiting.json
# exit 0
# SUPPRESS reason=no_concrete_user_decision

python3 scripts/inbox.py render fixtures/decision-required.json
# exit 0
# ACTION_REQUIRED task=synthetic-release gate=publish_release

python3 scripts/inbox.py render fixtures/risk-alert.json
# exit 0
# RISK_ALERT task=synthetic-worker-health severity=high

python3 scripts/inbox.py render fixtures/completion.json
# exit 0
# SUPPRESS reason=routine_completion

python3 scripts/inbox.py batch fixtures/events.jsonl
# exit 0
# output contains one duplicate suppression token

python3 tests/run.py
# exit 0
# ATTENTION_INBOX_TEST_OK
```

## Core rule

`waiting_for_user`, `blocked`, or similar internal statuses are not proof that a user decision exists.

An event becomes `ACTION_REQUIRED` only when `decision.required=true` **and** the event contains a concrete gate and a concrete question/action. Otherwise it stays suppressed unless it is a meaningful risk alert.

## Event shape

See [`schema/inbox-event.schema.json`](schema/inbox-event.schema.json).

The reference event has:

- stable `event_id`
- canonical `task_ref`
- source/owner
- event `kind`
- severity
- concise summary
- evidence references
- optional concrete `decision`
- deterministic `dedupe_key`
- source revision/freshness

The schema intentionally does not store credentials, private payloads, or execution tokens.

## Adapter contract

Any agent, CLI, daemon, MCP adapter, or workflow may emit this event shape. The adapter owns translation; Attention Inbox owns only validation, escalation, rendering, and dedupe.

Recommended flow:

```text
Agent / existing worker
        ↓
existing receipt / task writeback
        ↓
adapter → AttentionEvent
        ↓
Attention Inbox policy
   ├─ SUPPRESS
   ├─ RISK_ALERT
   └─ ACTION_REQUIRED
        ↓
existing notification / phone surface
        ↓
human decision
        ↓
existing owner/writeback/resume path
```

The final resume/writeback remains part of the existing system. This lab must not invent another execution path.

## Public boundary

Safe to open-source:

- schema
- policy
- synthetic fixtures
- reference CLI
- tests

Keep private:

- production routing
- push/relay credentials
- machine identities
- real task data
- account/wallet/trading execution
- private memory
