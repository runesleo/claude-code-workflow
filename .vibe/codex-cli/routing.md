# Routing profile

Generated target: `codex-cli`
Active profile: `codex-cli-default`
Applied overlay: `none`

## Routing behavior policies

- `capability-tier-routing` (`mandatory`) — Route by capability tier first, then resolve through the active provider profile.

## Capability tiers

- `critical_reasoner` — Highest-assurance reasoning for critical logic, security-sensitive changes, secrets, and architecture decisions. (role: `maker_or_final_decider`)
  Route when:
    - Critical business logic or financial logic
    - Credential, auth, secret, or key-management flows
    - Data model, API contract, or architecture decisions
    - Security reviews and risk assessment
  Avoid when:
    - Docs-only edits
    - Repetitive mechanical cleanup

- `workhorse_coder` — Default daily coding tier for most implementation, analysis, and refactoring work. (role: `primary_executor`)
  Route when:
    - Standard feature work
    - Routine debugging after task framing is clear
    - Non-critical config, docs, UI, and glue code
    - Most cross-file implementation tasks
  Avoid when:
    - Highest-risk business logic or secrets
    - Trivial lookups that only need fast routing

- `fast_router` — Cheap and fast tier for exploration, triage, and low-stakes subprocess work. (role: `scout_or_triage`)
  Route when:
    - Codebase exploration
    - Quick questions and lookups
    - Lightweight classification or filtering
    - Subtasks with low downside if wrong
  Avoid when:
    - Final decisions
    - Cross-file edits with broad blast radius

- `independent_verifier` — Second-model verification tier used to challenge important conclusions from a different reasoning path or model family. (role: `checker`)
  Route when:
    - Critical reviews
    - Complex bug diagnosis cross-checks
    - Architecture review
    - Important content or decision verification
  Avoid when:
    - Single-source trivial changes
    - Work that does not justify multi-model cost

- `cheap_local` — Local or near-zero-cost tier for offline, high-volume, and low-risk tasks. (role: `low_cost_executor`)
  Route when:
    - Commit message generation
    - Simple formatting, translation, or classification
    - Offline fallback
    - Bulk non-critical tasks
  Avoid when:
    - Long-context reasoning
    - Security-sensitive or high-assurance tasks

## Active mapping

- `critical_reasoner` → `openai.high-reasoning`
- `workhorse_coder` → `openai.codex-workhorse`
- `fast_router` → `openai.fast-agent`
- `independent_verifier` → `second-model.cross-family`
- `cheap_local` → `local.ollama-class`

## Model configuration

**Important**: The mapping above shows semantic tier-to-model references. Actual model selection in Codex CLI is controlled by:

1. **Environment variables**: `CODEX_PRIMARY_MODEL`, `CODEX_WORKHORSE_MODEL`, `CODEX_FAST_MODEL`
2. **CLI flags**: `codex --model gpt-4-turbo "your task"`
3. **Config file**: `~/.codex/config.yaml` (if supported)

Example:
```bash
export CODEX_PRIMARY_MODEL="gpt-4-turbo"
export CODEX_FAST_MODEL="gpt-3.5-turbo"
codex --model gpt-4-turbo "review security implications"
```

See `targets/codex-cli.md` for detailed configuration instructions.

## Routing defaults

- `direct_handle_max_changed_lines` = `50`
- `outsource_refactor_min_changed_lines` = `100`
- `planning_file_threshold` = `5`
- `cross_verify_default_for`:
  - `critical_business_analysis`
  - `architecture_design`
  - `risk_assessment`
  - `complex_bug_diagnosis`
