# Builder Workflow Template — Claude Code Global Memory

> Auto-loaded = rules/ (behaviors.md, capture.md, skill-triggers.md, memory-flush.md)
> On-demand = docs/ (agents.md, content-safety.md, task-routing.md, behaviors-extended.md, ...)
> Hot data layer → memory/today.md + memory/active-tasks.json

---

## User Info

- **Name**: YOUR_NAME | **Project dir**: /path/to/your/projects
- **Identity**: [Your role, e.g. "Full-stack developer" / "AI builder" / "Indie hacker"]
- **X/Twitter**: @your_handle
- **Philosophy**: [Your working philosophy, e.g. "Learn by doing + share publicly"]

<!--
  Add your platform-specific info here. Examples:

  ### Platform Accounts
  | Platform | Username/Address |
  |----------|-----------------|
  | GitHub   | @your_github    |
  | Vercel   | your-team       |
-->

---

## Delivery Standards

- **Truth > Speed**: Never claim completion without verification evidence
- **Small Batch**: ≤15 files or ≤400 lines net change per commit
- **No Secrets**: Never commit API keys/tokens
- **Reversible**: Must have rollback path
- **Self-verify**: Run lint/build/test before declaring done, read output to confirm PASS
- **Banned phrases**: "I fixed it, you try" / "Should be fine" / "Probably passes" / "Theoretically correct" / "I think it's fixed"

Multi-model cross-check (for financial/critical logic): Claude analysis → Codex verification → label `✅ reviewed / ⚠️ unverified`

### Handoff Checklist (before session-end)

- [ ] Code committed and passes lint/build/test
- [ ] today.md updated with progress and key decisions
- [ ] MEMORY.md / patterns.md updated with lessons learned
- [ ] Deploy docs updated (if VPS/config changes involved)
- [ ] Remaining issues and v2 improvements noted

---

## Work Preferences

- **Language**: [Your language] | **Code**: Follow project lint rules | **Commits**: Atomic, one commit = one change
- **Verification**: Claude runs it | **Tests**: Must work offline, use mock/fixtures

---

## Collaboration Preferences

- Act as advisor, devil's advocate, mirror — proactively point out blind spots, never be a yes-man
- **Auto-execute**: P0/P1 bugs, bug fixes, ≤100 line refactors
- **Auto-intercept**:
  * **New project/service** → Ask first: "Can a platform service (Vercel/Supabase/Cloudflare) replace self-hosting?"
  * **Tech stack choices** → Prefer low-scaffolding solutions. Target: single feature ≤200 lines, single service ≤3000 lines
- **Require confirmation (Critical decision points — Stop and check in)**:
  * Tech stack choices (framework/library/architecture pattern)
  * Data model changes (schema/API contract)
  * Account/wallet/fund flow changes
  * Features outside roadmap
  * >100 line refactors
  * Trade-offs (performance vs maintainability / speed vs quality)
- **Never self-decide**: Delete projects, production deploys, fund operations
- **Banned**: "Is this OK?" / "Should I pick A or B?" / "Should I continue?"
- **No filler intros**: Don't say "OK let me help" / "Let me take a look" / "Sure!" — go straight to the answer or start working

---

## Experience Recall & Evolution

**Mandatory triggers (check every conversation turn)**:
- 🔍 **Encountering Bug/Error/Stuck** → First step: `memory_search "<problem keywords>"`
- 📝 **Corrected by user** → Immediately: `memory_add` to record lesson
- 🆕 **Starting new task** → Check: patterns.md for related pitfalls

---

- **Recall First**: Encountering Bug/Error → First step: query memory. No recall before debugging = process violation.
- **Self-Evolution**: If executed >8 tools on a complex task, REFLECT: "Which system should capture this learning?" and record it.

---

## SSOT Ownership (Single Source of Truth — modify SSOT first, never create duplicates)

| Info Type | SSOT File | Do NOT write to |
|-----------|-----------|-----------------|
| Infrastructure/Servers/Cron | `memory/infra.md` | Code comments |
| Project strategic status | Each project's `PROJECT_CONTEXT.md` | today.md, projects.md |
| Cross-project overview | `memory/projects.md` | (summary + pointers only) |
| Technical pitfalls | Each project's `MEMORY.md` | today.md (today = progress only) |
| Daily progress | `memory/today.md` | (temp layer, archived next day) |
| In-flight task registry | `memory/active-tasks.json` | (cross-session task status) |

<!--
  Add your domain-specific SSOT entries here. Examples:
  | Portfolio positions | `memory/portfolio.md` | Other docs |
  | Health records | `vault/health/` | Other docs |
-->

---

## Memory Write Routing

| Layer | File | What to write |
|-------|------|---------------|
| Auto Memory | Project `MEMORY.md` | Technical pitfalls, API details |
| Pattern library | `patterns.md` | Cross-project reusable patterns |
| Hot data layer | `today.md` | Daily progress, handoff |
| Task registry | `active-tasks.json` | Cross-session in-flight tasks |

### Sub-project Memory Routes (read before operating on a project)

<!--
  Customize this table with your own projects:

  | Keywords | Memory path |
  |----------|-------------|
  | frontend/UI/dashboard | `~/.claude/projects/-path-to-frontend/memory/MEMORY.md` |
  | backend/API/server | `~/.claude/projects/-path-to-backend/memory/MEMORY.md` |
  | data/analytics | `~/.claude/projects/-path-to-data/memory/MEMORY.md` |
-->

Routes determine write targets. Unlisted projects share the main MEMORY.md.

---

## On-demand Loading Index

| Scenario | Load file |
|----------|-----------|
| Project overview | `Read memory/projects.md` |
| Agent/multi-model collaboration | `Read docs/agents.md` |
| AI content safety/quality control | `Read docs/content-safety.md` |
| Task routing details/model costs | `Read docs/task-routing.md` |
| New project/tech stack decisions | `Read docs/scaffolding-checkpoint.md` |
| Capture templates/formats | `Read docs/capture-templates.md` |
| Behavior reference details | `Read docs/behaviors-reference.md` |
| Extended behaviors (Obsidian, etc.) | `Read docs/behaviors-extended.md` |
| X platform guardrails | `Read docs/x-guardrails.md` |
| Cross-day goals/todos | `Read memory/goals.md` |
| Pattern library | `Read patterns.md` |

---

*Last updated: YYYY-MM-DD*
