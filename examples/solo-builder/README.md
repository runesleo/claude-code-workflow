# Solo-builder continuity example

This example connects the small QuietHarness core to private personal, workspace, and task state. It is reference material only: nothing here is installed, executed, scheduled, or loaded automatically.

## Files

```text
AGENTS.private.example.md        stable private preferences and pointers
workspaces.example.json         neutral workspace scopes
tasks/task-001.example.json     one canonical task record
```

## Minimal first success

1. Copy `AGENTS.private.example.md` to an untracked private location.
2. Replace its placeholders with the location of your own workspace registry and task adapter.
3. Copy `workspaces.example.json` and rename the sample scopes to match two real workspaces.
4. Copy `tasks/task-001.example.json` into your chosen private task store.
5. Ask your agent to read that one task, report its source and freshness, and return only the next action.
6. Change the task status through your own writeback path, then read it again to prove the change persisted outside the chat.

Success means one bounded readout and one verified writeback. It does not require importing an existing task database or enabling a scheduler.

## Safety boundary

Do not commit the copied private overlay, real task records, account data, or absolute personal paths. Public repositories should keep only sanitized examples like these.

For the reasoning behind the example, read [Architecture](../../docs/ARCHITECTURE.md), [Private overlay](../../docs/PRIVATE-OVERLAY.md), and [Task continuity](../../docs/TASK-CONTINUITY.md).
