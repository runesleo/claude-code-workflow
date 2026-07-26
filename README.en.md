# QuietHarness: My AI Work System

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[中文](README.md) · **English**

> The current evolution of **Claude Code Workflow**: one small shared core for Claude Code, Codex, and Cursor, connected to the business lines, task source of truth, background reports, and open-source branches I use in real work.

This is not a generic workflow generated from first principles. It is a sanitized public snapshot of my current system. Private paths, accounts, live tasks, and production controls are removed; the architecture and its tradeoffs remain.

## Why I rebuilt it now

When I first open-sourced this workflow, models needed much more prompt-level help. I kept adding rules, hooks, skills, memory, model routing, Morning, Today, and Session End flows to reduce forgetting and missed verification.

Those choices solved real problems at the time. The public repository then stayed mostly unchanged while I continued evolving the system privately across Claude Code, Codex, Cursor, and newer models.

After using today's highest-reasoning modes in production work, I found that part of the old protection had become duplicated planning, accidental routing, and configuration maintenance. v3 therefore removes ceremony from the hot path while preserving the working system around it.

I call this version **QuietHarness**: the harness still exists, but it stays quiet until the current task needs it.

The repository URL and Git history remain `claude-code-workflow`. QuietHarness is v3 of the same system, not a replacement project.

## System map

![QuietHarness system map](media/launch-v3/00-system-map.zh.png)

```text
Leo's real work
    │
    ├── Claude Code / Codex / Cursor
    │       └── QuietHarness Core
    │             direct work · truthful evidence · verification · hard gates
    │
    ├── stable business lines
    │       Personal Ops · Strategy · Data · Portfolio · Content
    │       Products · Health · Daily Rhythm · Research
    │
    ├── task continuity
    │       per-task SSOT · owner/worker · readout/writeback
    │       freshness · claim · writer lock · artifacts/receipts
    │
    └── open-source branches
            Polymarket · content ingest · video · health · system audit
```

Complexity did not disappear. It moved out of every request's hot path.

## The current system

### One core, three thin client adapters

| Surface | File | Bytes |
|---|---|---:|
| Shared Core | `templates/shared/AGENTS.md` | 1,604 B |
| Claude Code adapter | `templates/claude/CLAUDE.md` | 168 B |
| Cursor project rule | `templates/cursor/quiet-harness.mdc` | 520 B |

Codex reads the shared `AGENTS.md` directly; Claude Code and Cursor add their thin adapters. The three files total 2,292 bytes, but no client loads all three. These are file sizes, not token, latency, or model-quality claims.

The core keeps only direct execution, truthful evidence, proportional verification, and confirmation before irreversible actions.

### Stable business lines

My work is organized into nine long-lived lines: Personal Ops, Strategy Lab, Data Platform, Portfolio, Content Studio, Products & Growth, Health Ops, Daily Rhythm, and Research Desk.

A conversation or model may change; the owning business line and workspace remain stable. Startup reads only a bounded summary for the current line. An exact task record is read only when that task is named. See [Architecture](docs/ARCHITECTURE.en.md).

### Per-task truth

Each durable task has one canonical record. `owner_thread` is stable ownership; `primary_worker` and `claimed_by` are replaceable execution state. A worker's statement is not durable until an artifact, verification, and owner writeback exist.

See [Task continuity](docs/TASK-CONTINUITY.en.md) and the sanitized [current-system example](examples/leo-system/).

### One writer per mutable surface

Research and review may run in parallel. Writes to the same repository or task surface are serialized by default. A repository lock identifies the worktree, writer, allowed paths, validation, and next gate. Release requires artifact, validation, writeback, rollback, outcome, and the remaining gate.

This boundary came from real cross-model write collisions, not from a theoretical org chart.

### Background reports stay in the background

Reports, sync jobs, and monitors may continue independently. Success writes an artifact quietly; missing, stale, or failed output raises an exception. An unrelated interactive request does not need to run a Morning or closeout pipeline first. See [Daily reports](docs/DAILY-REPORTS.en.md).

## Open-source branches on the map

| Branch | Repository | Role in the system |
|---|---|---|
| Prediction markets | [polymarket-toolkit](https://github.com/runesleo/polymarket-toolkit) | address profiling, CLI, and AI Skills |
| Asset research | [asset-dd-and-opportunity-evaluation](https://github.com/runesleo/asset-dd-and-opportunity-evaluation) | structured due diligence |
| Content ingest | [x-reader](https://github.com/runesleo/x-reader) | multi-platform reading and unified input |
| Telegram ingest | [tg-reader-mcp](https://github.com/runesleo/tg-reader-mcp) | Telegram channels, groups, and contacts |
| Long media | [long-media-cli](https://github.com/runesleo/long-media-cli) | video, podcast, and X Space transcription |
| Video production | [claude-video-kit](https://github.com/runesleo/claude-video-kit) | script, review, narration, and Remotion video |
| Health records | [ai-health-vault](https://github.com/runesleo/ai-health-vault) | private AI + Obsidian health workflow |
| System audit | [claude-skill-audit](https://github.com/runesleo/claude-skill-audit) | skill usage, conflicts, and dead configuration |

These repositories were extracted from real branches of the system after they became independently useful. New public projects can continue to attach to the same map.

## Quick start

```bash
git clone https://github.com/runesleo/claude-code-workflow.git
cd claude-code-workflow

./scripts/inventory.sh
./scripts/install.sh --dry-run --claude --codex
./scripts/install.sh --apply --claude --codex
```

For a Cursor project:

```bash
./scripts/install.sh --dry-run --cursor-project /path/to/project
./scripts/install.sh --apply --cursor-project /path/to/project
```

The installer previews by default, backs up before replacement, makes no network or account calls, and does not modify schedulers.

To adapt the larger system, begin with [examples/leo-system](examples/leo-system/). Keep or rename the business lines, choose stable owners, connect per-task records to your own storage, and add claims or writer locks only when real concurrency requires them.

Existing v2 users should follow [MIGRATION-v3.md](MIGRATION-v3.md) and disable old discovery paths reversibly before installing.

## Repository layout

```text
templates/                      # current three-client Core
docs/                           # architecture, task, overlay, report boundaries
examples/leo-system/            # sanitized current-system examples
scripts/                        # inventory, install, verification
tests/                          # isolated-HOME smoke tests
media/launch-v3/                # system map and release media
MIGRATION-v3.md                 # v2 → v3 and rollback
```

## Verified

`./scripts/verify.sh` checks shell syntax, isolated installation, dry-run and rollback behavior, symlink inventory, custom `CODEX_HOME`, bilingual entrypoints, private-pattern leakage, template size, JSON/SVG integrity, and `git diff --check`.

The current three-client template baseline is 2,292 bytes. No API key is required.

## Boundaries

- The repository exposes my architecture, not my live tasks, accounts, positions, health records, customers, or production control plane.
- It does not create a task database, nine pinned conversations, or a background scheduler.
- The task and writer-lock examples must be connected to your own storage and client.
- Cursor global User Rules remain an application setting; the installer writes project rules only.
- A Windows PowerShell installer is not included yet.

Future changes should come from repeated real use or observable external adoption, not from a desire to make the repository look more complete.

## About

Leo ([@runes_leo](https://x.com/runes_leo)) is an AI × Crypto independent builder using Claude Code, Codex, and Cursor across trading, data, content, and open-source products.

[leolabs.me](https://leolabs.me) · [GitHub](https://github.com/runesleo) · [X](https://x.com/runes_leo)

## License

MIT — see [LICENSE](LICENSE).
