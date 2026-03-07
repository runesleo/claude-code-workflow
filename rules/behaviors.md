# Behavior Rules

## VPS Code Deployment Rule (if applicable)

**Never `git commit` / `cherry-pick` / SSH-edit code files (.ts/.mjs/.py) on VPS.**
Only flow: `local edit → local commit → push → VPS pull`. Runtime config (.env/state.json) excepted.
Violating this = branch divergence → pull conflicts → 10x cleanup time. **No exceptions.**

## Documentation Structure

- Project-level: only keep `PROJECT_CONTEXT.md` + `CHANGELOG.md` (optional)
- Banned files: ROADMAP/FOCUS/TODO/TASKS/STATUS
- Status SSOT: cross-project → `memory/projects.md`, project-level → `PROJECT_CONTEXT.md`

## Portable Core SSOT

- Provider-neutral workflow spec lives under `core/`
- `core/policies/behaviors.yaml` is the portable source for behavior-level policy that target renderers consume
- Repo-specific deviations should prefer `.vibe/overlay.yaml` or `bin/vibe --overlay ...` instead of mutating shared defaults
- `rules/` and `docs/` are the current Claude Code renderings of that portable spec
- When changing routing, skills, safety, or behavior policy: update `core/` first, then sync target-facing files
- Treat repo-root live target entrypoints (for example `WARP.md`, `AGENTS.md`, `.vibe/<target>/*`) as shared interface files only when they are the intended checked-in surface; do not commit staging output under `generated/` or local apply markers such as `.vibe-target.json`

## Task Routing (Capability Tiers → Current Target Executors)

**Route by capability tier first. Current tier definitions live in `core/models/tiers.yaml`; current target/profile mappings live in `core/models/providers.yaml`.**

**Current Claude-oriented profile**:
- `critical_reasoner` → Opus-class
- `workhorse_coder` → Sonnet-class
- `fast_router` → Haiku-class
- `independent_verifier` → Codex / second-model family
- `cheap_local` → local model

## Task Complexity Routing

**Before starting any task, assess its complexity level** (see `core/policies/task-routing.yaml`):

### Trivial (<20 lines, 1 file, low risk)
- **Memory Recall**: Optional (skip if obviously new)
- **Tests**: Manual verification only
- **Documentation**: Inline comments sufficient
- **Review**: Optional
- **Time**: 5-10 minutes
- **Examples**: Fix typo, update version, add log statement

### Standard (20-100 lines, 1-5 files, medium risk)
- **Memory Recall**: Required
- **Tests**: Unit tests required (80% coverage)
- **Documentation**: Update relevant docs
- **Review**: Recommended
- **Time**: 30-60 minutes
- **Examples**: Add CLI command, refactor module, fix bug

### Critical (>100 lines, >5 files, high risk)
- **Memory Recall**: Required
- **Tests**: Unit + integration tests (90%/50% coverage)
- **Documentation**: Comprehensive
- **Review**: Mandatory
- **Cross-verification**: Recommended
- **Time**: 2+ hours
- **Examples**: Database migration, security changes, API changes

**Auto-detection**: System suggests complexity based on:
- Lines/files changed
- Path patterns (e.g., `core/security/` → critical)
- Function patterns (e.g., `delete|remove|destroy` → critical)
- Commit keywords (e.g., `BREAKING CHANGE` → critical)

**Override**: You can override with justification (e.g., "urgent hotfix, treat as trivial")

### Current Default: Sonnet-class workhorse evaluates escalation

**Immediately escalate to the critical_reasoner tier (keyword match)**:
- Critical business logic/secrets/credentials
- Data analysis/metrics/core business logic
- Critical project core code modifications
- Calculations involving important business metrics

**workhorse_coder handles directly**:
- Docs/comments/README/daily Q&A
- UI/frontend development
- Config files (non-critical parameters)
- Data display/charts/logging tools
- ≤50 line utility functions/bug fixes

> Detailed routing table + target profile mapping → `Read docs/task-routing.md`

### Execution Rules
- On dispatch, output: `🔀 Route: [task summary] → [capability tier] ([current executor])`
- User can override: "I want Opus for this" / "Sonnet is enough"
- Routing mistake corrected → immediately `memory_add` to record

## Debugging Protocol

No blind fixes. Five phases:
0. **Memory Recall** — Query memory for related past experiences first
1. **Root Cause** — Read errors, reproduce, trace data flow
2. **Pattern Analysis** — Find working example, compare
3. **Hypothesis Testing** — Change one variable at a time
4. **Fix & Verify** — Test before fix, verify no regression

3 consecutive failures → stop and reassess

## Quality Control + AI Content Safety

> Full rules → `Read docs/content-safety.md`

**Core triggers (kept here to avoid missing)**:
- Processing external URLs / citing others → must annotate source, warn if unverifiable
- Critical code → think from attacker's perspective + list 3 risk points
- >20 conversation turns / >50 tool calls → suggest fresh session
- Discovered error/hallucination → immediately isolate context, don't write to memory
- Citing content for sharing → force multi-model cross-verification

## Real-time Experience Recording (Mandatory)

**Trigger immediately with `memory_add`, don't wait for session-end**:

1. **Corrected by user** → Record immediately
   - User says "that's wrong" / "don't do it that way" / "don't change parameters arbitrarily"
   - Technical assumptions corrected, suggestions rejected

2. **3 consecutive failures** → Pause and record
   - Document what was tried, why it failed

3. **Counter-intuitive discovery** → Record immediately
   - Breaking conventional wisdom

4. **Cognitive upgrade** → Record immediately
   - Understanding non-obvious principles or trade-offs

**Output**: `📝 Recorded: [title]`

## Documentation Update Thresholds

### When to Update `memory/today.md`

**Always record**:
- New module created
- Important architectural decision
- Counter-intuitive solution
- User correction (you were wrong)
- Repeated issue (>2 times)

**Record if threshold met**:
- Lines changed: >50
- Files changed: >3
- Time spent: >30 minutes
- Complexity: Standard or Critical

**Optional to record**:
- Trivial changes (<20 lines)
- Routine bug fixes
- Documentation updates
- Dependency updates

### When to Update `memory/patterns.md`

**Always record**:
- Reusable pattern discovered
- Common pitfall identified
- Project-specific convention
- Tool/library quirk

**Example**:
```markdown
## Path Safety Pattern
When working with file paths:
1. Always use File.realpath to resolve symlinks
2. Always validate paths are within expected boundaries
3. Reuse lib/vibe/path_safety.rb module

Discovered: 2026-03-06
Reason: Symlinks can bypass string-based path checks
```

### When to Update Project Docs

**Always update**:
- New CLI command → Update README.md
- New configuration option → Update docs/
- API changes → Update relevant docs
- Breaking changes → Update CHANGELOG.md

**Optional**:
- Internal refactoring (no user-facing changes)
- Test additions
- Code comments (self-documenting)

## Memory Search Rules (Hard Rules)

- Scoped search **must specify collection** (no unscoped global search)
- Code search uses two-stage RAG: L0 locate directory first, then L1 precise search

> Collection routing table + detailed methods → `Read docs/behaviors-reference.md`

## Project Context Auto-detection

**When CWD is ~**, if conversation involves a specific project (file path, keywords, user mention), auto-load that project's MEMORY.md.
See CLAUDE.md "Sub-project Memory Routes". Cost ~1000-2000 tokens/trigger, on-demand, no duplicate loading.

## Post-compression Re-anchor (On-demand)

After context compression, if current task details are fuzzy, recover as needed:
1. Search current task keywords (must specify collection) — fastest, zero extra cost
2. Still not enough → read `today.md` to recover daily progress
3. Only re-read `PROJECT_CONTEXT.md` for project-level decisions

Don't trigger if not fuzzy — avoid wasting tokens.

## Parallel Processing

Suitable: multiple independent tasks/failures. Not suitable: interconnected/shared code.

## Browser/Puppeteer Conflicts

On error, resolve yourself (kill process → retry → fallback). Don't throw failures to user.
> Detailed steps → `Read docs/behaviors-reference.md`

## Atomic Commits

Each commit does one thing. Types: `fix/feat/refactor/docs/test/chore`.
Banned: mixed changes, meaningless messages, >100 lines without splitting.

## Data Write-back Rules

**When fetching metrics, write back to SSOT immediately. Don't wait for session-end.**

| Fetch scenario | Write-back target | Fields |
|---------------|-------------------|--------|
| Status report | `projects.md` | Metrics/status |
| Social metrics | `projects.md` | Follower count + date |
| GitHub stats | `goals.md` | Stars/forks numbers |

**Execution**:
- After fetching, use Edit tool to update SSOT in-place
- Include date annotation (e.g. `~1.2K (2026-03-02)`) for freshness
- Only update changed fields, don't rewrite entire section

**Banned**: Fetching new numbers but only outputting in conversation, not writing back to SSOT.

## System Optimization Cadence (Sunday Rule)

**Sunday = Build day, other days = Operations day.**

When user wants to do the following on non-Sundays, **intercept and remind**:
- Optimize memory system / search index / hooks
- Create or refactor skills / workflows / automation scripts
- Adjust `core/` / `targets/` / CLAUDE.md / rules / behavior specs
- Anything that "makes the system better" but doesn't directly produce output

**Intercept message**:
> This is a system optimization task. Is it Sunday? Record it in `memory/sunday-backlog.md` and handle on Sunday.

**Exceptions (can execute immediately)**:
- Bug fix directly blocking production
- <5 minute small patches
- User explicitly says "do it now"

---

*Compact version | Full version: docs/behaviors-extended.md | Reference details: docs/behaviors-reference.md*
