# Task continuity without a mandatory task system

QuietHarness does not ship a task database. It defines a small contract that an existing file store, issue tracker, database, or script can implement.

The goal is to preserve continuity without copying the full task system into every prompt.

## Canonical record

Prefer one canonical record per task over a shared mutable array. A minimal record contains:

```json
{
  "id": "task-001",
  "title": "Ship a verified release candidate",
  "status": "active",
  "owner_scope": "product",
  "primary_worker": "agent",
  "next_action": "Run the clean-environment verification",
  "artifacts": ["./artifacts/release-review.md"],
  "updated_at": "2026-07-26T00:00:00Z"
}
```

The storage adapter may add fields, but it should preserve one authoritative lifecycle state and one explicit next action.

## Readout contract

When a request names a task:

1. Read that exact task record, not the full task database.
2. Report the source and `updated_at` value.
3. If the record is missing, contradictory, or older than the adapter's freshness policy, treat current state as unknown.
4. Load linked artifacts only when they are relevant to the request.

A conceptual adapter may expose:

```text
task-read <task-id>
task-list --scope <workspace-id>
```

These commands are interface examples; QuietHarness does not install them.

## Writeback contract

Write back when durable state changes, not during a mandatory end-of-session sweep.

A valid writeback should identify:

- the task;
- the changed fields;
- the accepting owner scope;
- the artifact or verification evidence;
- the write time.

Conceptually:

```text
task-writeback <task-id> --status waiting --next-action "Await maintainer review"
task-sync --check
```

Again, the user's adapter owns the implementation. A chat recap or worker claim is not durable state until the owner source accepts it.

## Owner and worker

The owner scope controls task truth. A worker may produce code, a report, a receipt, or a review, but it does not become the lifecycle authority merely because it completed a turn.

This boundary prevents two clients or agents from independently overwriting the same task state.

## Derived views

Dashboards, daily lists, and aggregate indexes should be generated from canonical task records. They are useful read models, but they are not competing sources of truth.

## Status vocabulary

QuietHarness does not require one universal taxonomy. Common states include `active`, `waiting`, `monitoring`, `parked`, and `archived`; an adapter may map an issue tracker or project system into those meanings.

The important invariant is that status, next action, evidence, and freshness remain explicit.

See the neutral [workspace registry](../examples/solo-builder/workspaces.example.json) and [task record](../examples/solo-builder/tasks/task-001.example.json).
