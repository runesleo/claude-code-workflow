# Private overlay in my current system

[中文](PRIVATE-OVERLAY.md) · **English**

The public QuietHarness core is intentionally free of live personal state. In my current system, a short private overlay connects it to my stable preferences, business-line registry, and task sources without publishing private details or loading live state into every request.

## What belongs here

- preferred language or response style;
- a small number of stable working preferences;
- pointers to workspace and task sources;
- additional personal confirmation boundaries that are not already in the public core.

## What does not belong here

- current priorities or a full task list;
- account details, credentials, wallet data, or customer information;
- copied project documentation;
- transcripts, daily reports, or generated dashboards;
- rules that can be enforced more reliably by tests, permissions, or scripts.

## Keep it as a map

A useful overlay is usually closer to this:

```markdown
# Private working context

- Preferred language: <preferred language>.
- Workspace registry: <private workspace registry path>.
- When a task is explicitly named, read only its canonical record.
- If task state is missing or stale, report UNKNOWN and verify the source.
- Persist durable task changes through the configured writeback path.
```

It should not contain the current contents of every workspace and task.

## Storage and loading

Use a private, untracked location supported by your client or operating environment. The QuietHarness installer does not create, discover, or modify this file.

The example at [`examples/leo-system/AGENTS.private.example.md`](../examples/leo-system/AGENTS.private.example.md) is deliberately inert. Copy it to a private location, replace the placeholders, and connect it using your client's supported private/global instruction mechanism.

Before committing any project, verify that the private overlay and generated state are ignored. Public repositories should contain only neutral examples.

## Size discipline

If the overlay starts accumulating current tasks, project facts, model routing tables, or daily procedures, move those details behind a workspace or task readout. The private overlay is still part of the hot path, so it should remain short and stable.
