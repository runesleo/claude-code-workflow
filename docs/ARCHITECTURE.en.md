# QuietHarness system architecture

[中文](ARCHITECTURE.md) · **English**

This document describes Leo's current AI work system. It is not a universal architecture invented from a blank page.

The public version preserves the business topology, task lifecycle, owner/worker split, readout/writeback boundaries, single-writer rule, and delivery receipts. It removes private paths, thread IDs, live tasks, accounts, positions, health records, and production controls.

## How it evolved

Claude Code Workflow v1/v2 accumulated always-loaded rules, skill routing, memory flush, model routing, Morning, Today, Session End, hooks, and completion gates. These mechanisms solved real model limitations at the time.

As model capability improved, loading every mechanism into every request began to create repeated planning and configuration maintenance. v3 does not erase the system; it changes where each part lives and when it loads.

## Current map

```text
Leo's real work
        │
        ▼
Claude Code · Codex · Cursor          replaceable clients and models
        │
        ▼
QuietHarness Core                     work · evidence · verify · hard gates
        │
        ├── Business Lines            stable workspaces and owners
        ├── Task Continuity           per-task SSOT and receipts
        ├── Background Systems        reports, sync, monitors
        └── Domain Workflows          PM, data, content, video, health
```

Complexity remains in the system boundaries instead of occupying every prompt.

## Three clients, one behavior boundary

Codex reads the shared 1,604-byte `AGENTS.md`; Claude Code imports it through a thin entrypoint; Cursor mirrors the same reliability boundaries in a project `.mdc` rule. Those boundaries keep direct execution, truthful evidence, proportional verification, and confirmation before irreversible actions.

The client, model, and conversation may change without changing ownership or task truth.

## Nine stable business lines

Leo's current topology is public because it is part of the design:

| Key | Line | Responsibility |
|---|---|---|
| `personal_ops` | Personal Ops | system, agents, gates, recovery |
| `pm_strategy` | Strategy Lab | strategy, validation, scale/kill |
| `pm_intel` | Data Platform | pipelines, indexes, profiles, quality |
| `portfolio` | Portfolio | allocation, risk, execution decisions |
| `content_writing` | Content Studio | X, articles, SEO, media assets |
| `product_distribution` | Products & Growth | products, monetization, distribution |
| `health_ops` | Health Ops | records, cadence, health research |
| `daily_rhythm` | Daily Rhythm | intake, routing, attention audit |
| `research_dd` | Research Desk | research, opportunities, knowledge |

Users may rename, merge, or remove these lines. Their value is the pattern: conversations are replaceable entrypoints, while responsibility and workspace ownership remain stable.

Startup loads a bounded summary for the current line only. An exact task record is read only when the task is named.

## Per-task truth

Each durable task has one canonical record. Dashboards and aggregate lists are derived views.

- `status` is the lifecycle authority.
- `owner_thread` is stable ownership.
- `primary_worker` and `claimed_by` describe the current batch.
- `next_action`, `artifacts`, and `updated_at` remain explicit.
- `state_revision` lets verified new facts supersede old narrative.
- A worker claim is not durable until an artifact, verification, and owner writeback exist.

```text
readout → source/freshness/claim → work → verify
        → artifact/receipt → owner writeback → read again
```

See [Task continuity](TASK-CONTINUITY.en.md).

## One writer per mutable surface

Agents may research and review in parallel. Writes to the same repository or task surface are serialized by default.

Acquisition records the repository, worktree, writer, allowed paths, validation, and next gate. Release records the artifact, validation, writeback, rollback, outcome, and remaining gate.

This contract came from real cross-model write collisions.

## Background systems

Reports, sync jobs, and monitors run independently. Success leaves a quiet artifact; missing, stale, or failed output raises an exception. An unrelated request does not need a Morning or closeout pipeline.

## Open-source branches

Parts of the private system became independently useful repositories:

- prediction and research: `polymarket-toolkit`, `asset-dd-and-opportunity-evaluation`;
- content intake: `x-reader`, `tg-reader-mcp`, `long-media-cli`;
- video: `claude-video-kit`;
- health: `ai-health-vault`;
- system audit: `claude-skill-audit`.

QuietHarness shows how these branches connect; it does not duplicate their implementations.

## Public and private boundary

Public: business-line structure, task contracts, owner/worker/writer rules, sanitized incidents, and the open-source map.

Private: thread UUIDs, absolute machine paths, live tasks, accounts, credentials, positions, health data, customers, schedulers, VPS, and production state.

Abstraction removes storage and private coupling. It does not remove the system's history or design choices.
