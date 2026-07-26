# Architecture: a small runtime with expandable continuity

QuietHarness separates two questions that are often mixed together:

1. **When should this information load?**
2. **Whose state is it?**

Keeping those questions independent lets the default runtime stay small while a real multi-project system can still preserve continuity.

## Axis 1: runtime placement

| Placement | Contains | Loaded when |
|---|---|---|
| Always-loaded core | direct work, truthful evidence, proportional verification, irreversible-action boundaries | every request |
| On-demand context | project facts, debugging guidance, review policy, current task state | the request needs it |
| Background system | reports, sync jobs, monitors | independently; the agent reads an artifact or exception |

## Axis 2: state scope

| Scope | Contains | Source of truth |
|---|---|---|
| Personal | stable preferences and pointers to private systems | an untracked private overlay |
| Workspace | the current product, business area, or repository facts | the workspace or repository |
| Task | status, next action, evidence, and freshness | one canonical task record or an external adapter |

These scopes are **not** three more systems that must load on startup. They are progressively narrower sources the agent reads only when the current request crosses their boundary.

```text
public QuietHarness core
        │
        ├── private personal overlay        optional, small, untracked
        │       │
        │       └── workspace profile       read after entering that scope
        │               │
        │               └── named task      exact readout + freshness check
        │
        └── existing background jobs        artifact on success, exception on failure

request → bounded readout → work → verify → change-time writeback → stop
```

## The four boundaries

### 1. Public core

The installed templates define portable behavior. They do not contain identity, priorities, private paths, task data, or a business taxonomy.

### 2. Private overlay

The overlay contains stable personal defaults and pointers. It should not become a live dashboard or a copy of every current task. See [Private overlay](PRIVATE-OVERLAY.md).

### 3. Workspace truth

A workspace owns its repository instructions, facts, tests, and continuation notes. A global file may point to the workspace, but it should not duplicate workspace truth.

### 4. Task continuity

Task state stays behind an explicit readout/writeback boundary. Named tasks are read exactly; durable changes are written when they happen; stale or missing state is reported instead of guessed. See [Task continuity](TASK-CONTINUITY.md).

## Adoption path

Each step is optional:

1. Install only the QuietHarness core.
2. Add a short untracked private overlay.
3. Register two or more workspaces when cross-project routing becomes useful.
4. Add task readout/writeback only when cross-session continuity becomes a real problem.
5. Connect existing reports or monitors through artifacts and exception notifications.

The [solo-builder example](../examples/solo-builder/) demonstrates steps 2–4 without installing a task database or scheduler.

## Non-goals

QuietHarness does not prescribe:

- a fixed folder hierarchy;
- business names or a number of workspaces;
- a task database, issue tracker, or note application;
- a particular model as owner or worker;
- automatic scheduling, cross-chat dispatch, or public actions;
- copying private state into a public repository.

The contract is portable because the storage and execution mechanisms remain replaceable.
