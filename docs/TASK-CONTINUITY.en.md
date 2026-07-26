# Task continuity in my current system

[中文](TASK-CONTINUITY.md) · **English**

QuietHarness does not treat chat history as task truth, and it does not let Claude, Codex, and Cursor maintain competing task states.

My current system keeps one canonical record per durable task. A business line is the stable owner; a model is a replaceable worker. Dashboards and daily views are derived from those records.

## Why per-task records

An earlier version used one shared task array. With multiple models and sessions, that created overwritten state, stale summaries replacing verified facts, and tasks idling behind old model labels.

The current design therefore uses one source-of-truth file per task.

## Lifecycle

| Status | Meaning |
|---|---|
| `active` | safe to continue now |
| `waiting` | waiting for a named person, condition, or date |
| `monitoring` | observe a signal without manufacturing work |
| `parked` | intentionally out of the daily queue |
| `archived` | lifecycle ended; no wake-up fields remain |

`status` is the lifecycle authority. Priority, dashboards, and chat narrative cannot override it.

## Owner, worker, and claim

- `owner_thread`: stable business ownership and accepting writeback surface;
- `primary_worker`: current default executor;
- `claimed_by / claimed_at`: short-lived heartbeat for the active batch.

A task belongs to a business line, not to Claude or Codex. A model label is not a permission lock.

## Readout

When a task is named:

1. read that exact record rather than the full task store;
2. report the source and `updated_at`;
3. inspect claim freshness;
4. surface status, next action, decision gate, and artifacts;
5. report `UNKNOWN` when state is missing, contradictory, or stale.

## Writeback

Persist durable changes when they happen, not through a mandatory end-of-session memory sweep.

A valid writeback identifies the task, changed fields, accepting owner, artifact, verification evidence, time, and remaining gate. A chat recap or worker claim is not durable until the owner source accepts it.

## State revision

When verified new evidence contradicts old narrative, a `state_revision` records the current facts and the claims they supersede. Old evidence remains auditable but cannot keep authorizing or blocking work.

## Negative result

`drop`, `watch`, `park`, `no_publish`, `no_change`, and `blocked` may all be valid results when they include a concrete reason and reuse value. This prevents the next model from repeating a disproved path.

See the realistic sanitized task and readout under [examples/leo-system](../examples/leo-system/).
