# Lean AI Workflow

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**English** · [中文](README.zh.md)

A small, evidence-driven instruction layer for Claude Code, Codex, and Cursor.

No mandatory morning ritual. No automatic session closeout. No forced subagent choreography. Start with the request, load context when it is needed, and write durable state when it actually changes.

> **v3 release candidate:** the old v2 workflow is being replaced, not extended. See [MIGRATION-v3.md](MIGRATION-v3.md).

## Why v3

The first two versions optimized for control: more rules, more hooks, more routing, and more automatic memory. In real daily use, that eventually created a second job—maintaining the workflow itself.

The useful lesson was not “remove all safeguards.” It was to separate three things:

1. a tiny always-loaded core;
2. project facts and tests, read only when relevant;
3. background products such as daily reports, generated independently and read on demand.

The v2 example loaded 16,379 bytes from `CLAUDE.md` and three rule files before project context. The three v3 templates total 2,292 bytes, and each client loads only its own subset. These are byte counts, not token claims; actual context behavior varies by client and version.

This direction also matches current platform guidance: Anthropic recommends scoped `CLAUDE.md` memory, OpenAI describes a short `AGENTS.md` as a map instead of a manual, and Cursor supports small project rules with explicit attachment modes.

## What you get

- **One lean core** — direct execution, truthful evidence, proportional verification, and a short list of real confirmation boundaries.
- **Thin client adapters** — Claude Code import, Codex `AGENTS.md`, and a compact Cursor project rule.
- **Safe installer** — dry-run by default, explicit apply, backups before overwrite, no network calls.
- **Reversible migration** — disable old skills, hooks, and commands without deleting them.
- **Quiet daily reports** — leave an existing scheduler untouched, verify its output separately, and avoid forcing every chat through a morning or closeout pipeline.

## How it works

```text
current request
    ↓
small client core
    ↓
relevant project files + existing tests (only when needed)
    ↓
work → verify → write durable state at the point of change → stop

scheduled report
    ↓
dated artifact → read on demand / optional notification
```

The workflow deliberately does not prescribe a task database, note app, model router, or daily dashboard. If you already have one, keep it behind an explicit read/write boundary instead of loading it into every prompt.

## Repository layout

```text
templates/
├── shared/AGENTS.md              # portable core
├── claude/CLAUDE.md              # imports the shared core
└── cursor/lean-baseline.mdc      # compact project rule
docs/
└── DAILY-REPORTS.md              # reports without daily rituals
scripts/
├── inventory.sh                  # read-only config inventory
├── install.sh                    # dry-run/apply + backups
└── verify.sh                     # repository checks
tests/
├── inventory-smoke.sh            # file + directory-symlink fixtures
└── install-smoke.sh              # isolated-HOME installer test
MIGRATION-v3.md                   # v2 → v3, including rollback
```

## Setup

```bash
git clone https://github.com/runesleo/claude-code-workflow.git
cd claude-code-workflow

# Existing v2 users: inspect every active file and symlink first.
./scripts/inventory.sh

# Preview only. Writes nothing.
./scripts/install.sh --dry-run --claude --codex

# Apply after reviewing the plan.
./scripts/install.sh --apply --claude --codex
```

For a Cursor project:

```bash
./scripts/install.sh --dry-run --cursor-project /path/to/project
./scripts/install.sh --apply --cursor-project /path/to/project
```

The Cursor installer creates `.cursor/rules/lean-workflow.mdc` inside the selected project. For a global Cursor preference, paste the small baseline into **Cursor Settings → Rules** instead of copying project-specific state globally.

`--codex` respects `CODEX_HOME` and otherwise uses `~/.codex`. All selected targets pass preflight and staging before any file is replaced. An existing target symlink to a file is backed up as a symlink and replaced locally; the file it pointed to is not modified. A file target that resolves to a directory is rejected.

## Requirements

- macOS or Linux
- Bash 3.2+
- At least one supported client:
  - [Claude Code memory](https://code.claude.com/docs/en/memory)
  - [Codex and `AGENTS.md`](https://developers.openai.com/codex/guides/agents-md)
  - [Cursor Rules](https://docs.cursor.com/context/rules)

No API key is required. The installer does not log in, call a network service, install a package, or modify a scheduler.

**Privacy:** personal identity, account details, private paths, live priorities, and business runbooks do not belong in this repository. Keep them in an untracked private file and load them only when relevant.

## Quick start

After installation, restart the client or open a new session.

Then work normally:

```text
Fix the failing test in this repository and verify the result.
```

There is no required startup command. To persist something, ask for the specific writeback:

```text
Record this decision in the project's status file.
```

If you already generate a daily report, keep the generator independent and ask the agent to read today's artifact:

```text
Read inbox/daily/2026-07-26.md and give me the three items worth acting on.
```

See [Daily reports without daily rituals](docs/DAILY-REPORTS.md).

## Verified

`./scripts/verify.sh` checks:

- shell syntax;
- read-only inventory coverage for file and whole-directory symlinks;
- installer dry-run, multi-target preflight, and isolated apply behavior;
- regular-file and symlink backup/rollback behavior;
- custom `CODEX_HOME` support;
- required bilingual files and templates;
- absence of private-path patterns in shipped templates;
- a hard size ceiling for always-loaded templates;
- stale v2 trigger language in active templates;
- `git diff --check`.

| Case | Environment | Result |
|------|-------------|--------|
| Installer dry-run + transaction + symlink rollback | macOS, Bash 3.2 | Automated smoke test |
| Claude/Codex/Cursor template size | Any | 2,292 bytes combined |
| Network/account access | Any | None |

## Known limitations (v3 release candidate)

- The installer does not interpret or rewrite arbitrary existing hooks, skills, or custom commands. Follow the migration guide first.
- Cursor global User Rules are managed in Cursor settings; the installer only writes a project rule.
- Windows PowerShell installation is not included yet.
- This repository explains the report boundary but does not ship a news or daily-report generator.
- Already-open client sessions may cache old instructions until restarted.

## Roadmap

**Migration**

- [ ] Add a PowerShell installer.

**Compatibility**

- [ ] Track instruction-loading changes in Claude Code, Codex, and Cursor.
- [ ] Add more client adapters only when they remain thin.

**Evidence**

- [ ] Collect before/after reports from real repositories without importing private workflow state.

## Design principles

1. **Direct work beats ritual.** A workflow should reduce work, not become work.
2. **State at change time beats end-of-session cleanup.** Save the fact when it changes.
3. **Reports are products, not startup gates.** Generate quietly; read or push intentionally.
4. **Tests beat prompt rules.** Put mechanical guarantees in code where possible.
5. **Reversible beats destructive.** Disable first; delete only after real use proves it safe.

For the broader context-management rationale, see OpenAI's [Harness engineering](https://openai.com/index/harness-engineering/).

## About the author

*Leo ([@runes_leo](https://x.com/runes_leo)) — AI × Crypto independent builder. Trading on [Polymarket](https://polymarket.com/?via=runes-leo&r=runesleo&utm_source=github&utm_content=claude-code-workflow), building data and content pipelines with Claude Code and Codex.*

*[leolabs.me](https://leolabs.me) — writing · community · open-source tools · indie projects · all platforms.*

*[X Subscription](https://x.com/runes_leo/creator-subscriptions/subscribe) — paid content weekly, or just buy me a coffee 😁*

*Learn in public, Build in public.*

## License

MIT — see [LICENSE](LICENSE).
