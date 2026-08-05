# QuietHarness: a reliable working layer for your AI coding agent

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[中文](README.md) · **English**

> Give the AI coding agent you already use a small, reversible operating boundary: inspect first, preserve unrelated work, verify in proportion to risk, and stop before irreversible actions.

**Claude Code, Codex, or Cursor on its own is enough to get the same core reliability boundaries.** Cross-client support lets those boundaries travel with you later; it is not an installation requirement.

QuietHarness does not turn every request into a ceremony, and it does not ask you to copy my private operating system. It compresses the behaviors that survived long-term real use into a 1,604-byte shared Core, with dry-run, backup, isolated tests, and reversible installation.

## Who it is for

QuietHarness is for people maintaining real projects with any supported AI coding agent who have seen failures such as:

- overwriting files without inspecting existing work;
- claiming completion without running the available test;
- expanding a small request into an unnecessary redesign or process;
- crossing a deletion, release, production, or credential boundary without confirmation;
- rewriting the same basic rules after changing agents.

QuietHarness does not include a task database, background automation, or a team orchestration platform. The larger Leo System later in this README is an optional reference, not a prerequisite.

## Try it inside one isolated project

```bash
git clone https://github.com/runesleo/claude-code-workflow.git
cd claude-code-workflow
./scripts/inventory.sh

demo_dir="$(mktemp -d "${TMPDIR:-/tmp}/quiet-harness-first-success.XXXXXX")"
./examples/first-success/setup.sh "$demo_dir"
```

Choose one of the three options below. Run dry-run before `--apply`; the trial writes only inside `$demo_dir` and leaves your user-level Claude/Codex configuration untouched.

### Claude Code

```bash
./scripts/install.sh --dry-run --claude-project "$demo_dir"
./scripts/install.sh --apply --claude-project "$demo_dir"
```

Writes `$demo_dir/AGENTS.md` and `$demo_dir/CLAUDE.md`.

### Codex

```bash
./scripts/install.sh --dry-run --codex-project "$demo_dir"
./scripts/install.sh --apply --codex-project "$demo_dir"
```

Writes only `$demo_dir/AGENTS.md`.

### Cursor

```bash
./scripts/install.sh --dry-run --cursor-project "$demo_dir"
./scripts/install.sh --apply --cursor-project "$demo_dir"
```

Writes only `$demo_dir/.cursor/rules/quiet-harness.mdc`.

The installer previews by default and writes only with explicit `--apply`. It makes no network or account calls and does not modify schedulers.

## Observe the first success

Open your chosen agent in `$demo_dir` and send only:

```text
Read TASK.md and complete the task.
```

A successful run discovers and preserves an unrelated user edit without being coached by the task, fixes only the discount calculation, runs the existing test, and reports real verification evidence.

This is an onboarding behavior check, not a causal experiment proving that QuietHarness always improves a model. It is designed for a ten-minute first success; automation currently proves only that the fixture is reproducible, while timing by a real non-author remains the next product gate.

[Open the complete first-success guide and acceptance criteria →](examples/first-success/README.en.md)

## Install for everyday use after the trial (optional)

```bash
# Claude Code user-level
./scripts/install.sh --dry-run --claude
./scripts/install.sh --apply --claude

# Codex user-level
./scripts/install.sh --dry-run --codex
./scripts/install.sh --apply --codex

# Or keep using --*-project for one real project only
```

Claude user-level installation targets `~/AGENTS.md` and `~/.claude/CLAUDE.md`; Codex targets `$CODEX_HOME/AGENTS.md`, defaulting to `~/.codex/AGENTS.md`. Before replacing an existing file, the installer creates a timestamped `.bak-ai-workflow-*` sibling. To restore, keep the current file and move the exact backup you selected back to its original path; see [v3 migration and rollback](MIGRATION-v3.en.md#rollback).

The installer prints one `INSTALLED <target>` entry per target; only a target that replaced an old file has an adjacent `BACKUP <backup>` entry. Uninstall per target: restore its exact backup when present; only a target without its own backup was created by QuietHarness. For a new target, confirm that it still matches the template before removing that exact path. If you changed it, move it aside instead of deleting it.

## Why it is called QuietHarness

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

### One core, whichever client you use

| Surface | File | Bytes |
|---|---|---:|
| Shared Core | `templates/shared/AGENTS.md` | 1,604 B |
| Claude Code adapter | `templates/claude/CLAUDE.md` | 168 B |
| Cursor project rule | `templates/cursor/quiet-harness.mdc` | 546 B |

You need to install only the client you use. Codex reads the shared `AGENTS.md` directly; Claude Code imports it through a thin entrypoint; the Cursor project rule mirrors the same reliability boundaries in `.mdc` form. The three files total 2,318 bytes, but no client loads all three. Adding a second client reuses the same behavior boundary; it does not unlock a hidden complete edition. These are file sizes, not token, latency, or model-quality claims.

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

## Extend only when you need it

The Core and first-success exercise above are enough to begin. The structures below are optional extensions, not prerequisite knowledge.

To adapt the larger system, begin with [examples/leo-system](examples/leo-system/). Keep or rename the business lines, choose stable owners, connect per-task records to your own storage, and add claims or writer locks only when real concurrency requires them.

Existing v2 users should follow [MIGRATION-v3.en.md](MIGRATION-v3.en.md) and disable old discovery paths reversibly before installing.

## Repository layout

```text
templates/                      # current three-client Core
docs/                           # architecture, task, overlay, report boundaries
examples/first-success/         # isolated single-client trial and behavior check
examples/leo-system/            # sanitized current-system examples
scripts/                        # inventory, install, verification
tests/                          # isolated-HOME smoke tests
media/launch-v3/                # system map and release media
MIGRATION-v3.md                 # v2 → v3 and rollback
```

## Verified

`./scripts/verify.sh` checks shell syntax, isolated installation, dry-run and rollback behavior, symlink inventory, custom `CODEX_HOME`, bilingual entrypoints, private-pattern leakage, template size, JSON/SVG integrity, and `git diff --check`.

The current three-client template baseline is 2,318 bytes. No API key is required.

These checks prove that installation and repository contracts are repeatable; they do not claim that an outside user has already received product value. The new first-success exercise makes activation observable. The next evidence must come from a non-author completing it, not from stars or views.

## Boundaries

- The repository exposes my architecture, not my live tasks, accounts, positions, health records, customers, or production control plane.
- It does not create a task database, nine pinned conversations, or a background scheduler.
- The task and writer-lock examples must be connected to your own storage and client.
- Cursor global User Rules remain an application setting; the installer writes project rules only.
- A Windows PowerShell installer is not included yet.

## Roadmap

The current productization sequence is deliberately small:

1. one non-author completes first success without a private walkthrough;
2. real failure points shorten setup, recovery, or acceptance;
3. expand to three users, repeat use, and one third-party integration.

Future features should still come from repeated real use or observable external adoption, not from a desire to make the repository look more complete.

## About

Leo ([@runes_leo](https://x.com/runes_leo)) is an AI × Crypto independent builder using Claude Code, Codex, and Cursor across trading, data, content, and open-source products.

[leolabs.me](https://leolabs.me) · [GitHub](https://github.com/runesleo) · [X](https://x.com/runes_leo)

## License

MIT — see [LICENSE](LICENSE).
