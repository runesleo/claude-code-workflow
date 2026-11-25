# AI One-Person Company: module map and open-source roadmap

[中文](ONE-PERSON-COMPANY.md) · **English** · [Back to home](../README.en.md)

## Why open-source this

The goal of a one-person company is not to maximize the number of agents. It is to help one person keep discovering opportunities, producing content, delivering products, serving users, and operating the business. AI takes on delegable work; the founder retains goals, commercial judgment, and critical approvals.

This is the public entry point to a working approach built through long-term use. Modules evolve independently, and tools that have already grown into separate repositories remain maintained there. This repository organizes them, documents reusable compositions, and provides verification methods. It is not a duplicate business source of truth.

## How the company works

```text
Founder: goals, priorities, critical approvals
    ↓
Operations lead: understand → find the responsible owner → select a worker
    ↓
Discover → evaluate → deliver a product or content → distribution and feedback
    ↑                                                       ↓
    └──────────────── iterate on real evidence ──────────────┘

Shared foundation: task continuity, evidence, single writer, permissions,
cost awareness, and recovery
Execution layer: replaceable existing AI tools, skills, CLIs, MCPs, and background tools
```

The operations lead is a responsibility, not a mandatory all-powerful bot. Business ownership and authoritative state remain with their existing owners; changing a model, client, or conversation does not change the task. See the [architecture](ARCHITECTURE.en.md) and [task continuity](TASK-CONTINUITY.en.md) for technical detail.

## Business modules

Maturity: **Try now** = an independent entry point and demo in this repository; **Separate repo** = an existing public repository, whose own documentation defines supported features and installation; **Experimental** = a runnable synthetic example or early governance implementation; **Planned** = an identified workflow whose complete reusable package is not yet delivered here. These statuses do not demonstrate company revenue, user scale, or production reliability.

| Module | Problem it solves | Public entry and maturity |
|---|---|---|
| Opportunity discovery and research | Turn scattered signals into evidence-backed opportunities and next actions | [Asset and Opportunity Research](https://github.com/runesleo/asset-dd-and-opportunity-evaluation) (Separate repo); integrated opportunity radar workflow (Planned) |
| Information intake and data | Read links, social content, long videos, and podcasts while preserving sources | [X Reader](https://github.com/runesleo/x-reader), [TG Reader MCP](https://github.com/runesleo/tg-reader-mcp), [Long Media CLI](https://github.com/runesleo/long-media-cli) (Separate repos) |
| Written content and distribution | Select topics, verify facts, draft, review, distribute, and learn | Intake tools are independently reusable; complete content and growth workflow (Planned) |
| Video production | Turn research or product work into reviewable scripts and video | [Video Kit](https://github.com/runesleo/claude-video-kit) (Separate repo); composition workflow (Planned) |
| Product development | Scope needs, implement, test, and deliver verifiable results | [QuietHarness Core](../examples/first-success/README.en.md) (Try now); [OPC Company Layer](../labs/opc-company/README.en.md) (Experimental) |
| Commercial and user operations | Connect real needs, feedback, pricing, fulfillment, and acquisition | Reusable synthetic cases and module templates (Planned) |
| Investing and strategy research | Data, hypotheses, counterevidence, risk, and research records | [Polymarket Toolkit](https://github.com/runesleo/polymarket-toolkit), [Asset and Opportunity Research](https://github.com/runesleo/asset-dd-and-opportunity-evaluation) (Separate repos); no default live financial execution |
| Personal operations and health | Reduce routine information, reminder, and management burden | [AI Health Vault](https://github.com/runesleo/ai-health-vault) (Separate repo); [Attention Inbox](../labs/attention-inbox/README.md), [Session Hooks](../labs/session-hooks/README.en.md) (Experimental) |
| AI collaboration and reliability | Continuity, permissions, acceptance, context, resources, monitoring, and recovery | [Core](../examples/first-success/README.en.md) (Try now); [OPC Layer](../labs/opc-company/README.en.md), [Chat Export](../labs/chat-export/README.md) (Experimental); [Skill Audit](https://github.com/runesleo/claude-skill-audit) (Separate repo); complete operational reliability composition (Planned) |

## Start with one real problem

1. Use the existing [Core first-success exercise](../examples/first-success/README.en.md) to check basic execution boundaries.
2. When cross-agent handoffs or false completion become a problem, run the [OPC Lab](../labs/opc-company/README.en.md) synthetic cases; no real company task database is required.
3. Choose an independent business tool from the catalog that matches your actual need. Follow its own installation and permission instructions.
4. Run [OPC First Workflow Preview](../examples/opc-first-workflow/README.en.md) to see the offline loop from a fictional signal to an unpublished draft, process handoff, strict local verification, and human decision surfacing. Do not add a layer without an actual need.

## Staged open-source roadmap

Every new module should explain its problem, independent usage, dependencies, permissions, success conditions, and failure exit. Check licensing and privacy before releasing code.

| Stage | Deliverable | Acceptance gate |
|---|---|---|
| 1. Public entry point | Bilingual introduction, business map, navigation to existing tools and governance labs; unchanged installation | Working links, existing installation regressions pass, explicit maturity labels |
| 2. First business loop (offline Preview) | Fictional synthetic signal → evidence-backed research brief → content draft or product candidate; reuse existing components and keep human approvals | No private data or real external action; repeatable execution; source, decision, and delivery evidence |
| 3. Content and product workflows | Independently usable modules and sanitized cases for topic selection, writing, video, product validation, and distribution preparation | Each module has reproducible inputs and outputs, instructions, failure tests; human approval for publication |
| 4. Company-level collaboration | Composable demos of the existing OPC Lab, task continuity, and reliability capabilities; synthetic user-feedback and commercial cases | Verify handoffs, recovery, duplicate prevention, and real acceptance; at least one non-author completes a meaningful workflow without verbal guidance |

This is a delivery order, not a promise of completion dates, revenue, or full autonomy. New modules must earn their place through real work and user feedback. Do not create duplicate projects just to fill out a catalog.

## Public and private boundary

Publish stable responsibilities, workflow interfaces, sanitized skills, module code, synthetic data, reproducible experiments, and already-public real cases. Keep personal configurations, accounts and credentials, customers and live tasks, portfolio and execution strategies, health data, production deployment, and scheduling configurations private. Modules do not receive financial execution, public posting, or production write permissions by default. Public release requires a separate authorization and privacy review, not merely removing a few fields.

The value is reusable business capability, not a copy of the founder's computer. Every public module should be adoptable, replaceable, or optional.
