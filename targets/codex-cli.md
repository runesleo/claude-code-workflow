# Codex CLI Target

Codex CLI should be treated as a separate target profile, not as a literal clone of the Claude layout.

## Minimum Common Primitives

- `AGENTS.md` as the shared instruction surface
- repo-local SSOT files for memory, handoff, and status
- approval, sandbox, or wrapper controls for high-risk actions
- optional helper scripts or templates for skill-like flows

## Portable Mapping

- `core/models/*.yaml` -> active provider profile and routing guidance inside `AGENTS.md`
- `core/skills/registry.yaml` -> explicit step sequences, reusable task templates, or wrapper commands
- `core/security/policy.yaml` -> approval policy, sandbox policy, or external guard layer

## Phase 1 Notes

- Do not assume native parity with Claude skills.
- Use portable skill IDs in prose and wrappers even if the host only exposes `AGENTS.md`.
- Keep `independent_verifier` cross-family when possible so review is genuinely independent.

## Phase 2 Build Output

- `bin/vibe build --target codex-cli` generates a Codex-oriented `AGENTS.md`.
- Additional generated docs under `.vibe/codex-cli/` carry routing, skills, and safety summaries.

## Phase 3 Additions

- `bin/vibe switch codex-cli` applies the generated Codex config into the current repo root by default.
- Generated `.vibe/codex-cli/execution-policy.md` now carries the maker-checker and safety execution flow.
- Generated `.vibe/codex-cli/behavior-policies.md` mirrors the portable behavior schema for Codex-oriented execution.

## Phase 5 Additions

- Codex-oriented builds now surface overlay-applied profile remapping and extra policy deltas in `AGENTS.md` and `.vibe/codex-cli/*`.
- This keeps Codex conservative: project-specific changes stay in the overlay, while the target still degrades cleanly to docs and execution guidance.

## Phase 6 Additions

- Task routing and test standards are now generated under `.vibe/codex-cli/task-routing.md` and `.vibe/codex-cli/test-standards.md`.
- These policies provide complexity-based workflow guidance for Codex CLI agents.

## Model Configuration

Codex CLI uses OpenAI models configured via environment variables or CLI flags. The capability-tier routing system maps to OpenAI's model offerings.

### Capability Tier Mapping

The default `codex-cli-default` profile maps capability tiers to OpenAI models:

```yaml
critical_reasoner: openai.high-reasoning          # GPT-4, GPT-4 Turbo, or o1
workhorse_coder: openai.codex-workhorse           # GPT-4, GPT-3.5 Turbo
fast_router: openai.fast-agent                    # GPT-3.5 Turbo
independent_verifier: second-model.cross-family   # Claude or other non-OpenAI model
cheap_local: local.ollama-class                   # Local Ollama model
```

### Configuration Methods

**Method 1: Environment variables**

```bash
# Set default models for different tiers
export CODEX_PRIMARY_MODEL="gpt-4-turbo"
export CODEX_WORKHORSE_MODEL="gpt-4"
export CODEX_FAST_MODEL="gpt-3.5-turbo"

# Then use Codex CLI normally
codex "implement user authentication"
```

**Method 2: CLI flags per invocation**

```bash
# Use GPT-4 for critical reasoning
codex --model gpt-4-turbo "review security implications of this auth flow"

# Use GPT-3.5 for quick exploration
codex --model gpt-3.5-turbo "list all API endpoints"

# Use o1 for complex reasoning
codex --model o1-preview "design the architecture for distributed caching"
```

**Method 3: Configuration file**

Create `~/.codex/config.yaml` (if supported):

```yaml
models:
  critical: gpt-4-turbo
  workhorse: gpt-4
  fast: gpt-3.5-turbo
```

### Generated Routing Guidance

The generated `AGENTS.md` and `.vibe/codex-cli/routing.md` will contain:

```markdown
## Active mapping

- `critical_reasoner` → `openai.high-reasoning`
- `workhorse_coder` → `openai.codex-workhorse`
- `fast_router` → `openai.fast-agent`
```

These guide you to select appropriate models for different task types.

### Project-Specific Overrides

Use a project overlay to document project-specific model preferences:

```yaml
# .vibe/overlay.yaml
profile:
  mapping:
    critical_reasoner: openai.o1-preview
    workhorse_coder: openai.gpt-4-turbo
  note_append:
    - "This project uses o1-preview for critical reasoning"
```

Then build with the overlay:
```bash
bin/vibe build codex-cli --overlay .vibe/overlay.yaml
```

### Cross-Family Verification

For `independent_verifier` tier, use a different model family:

```bash
# Primary analysis with Codex (OpenAI)
codex --model gpt-4 "analyze this security vulnerability"

# Cross-verify with Claude
claude "review the security analysis from GPT-4: [paste analysis]"
```

This ensures truly independent verification from a different reasoning approach.

### Cost Optimization

- Use GPT-3.5 Turbo for `fast_router` tasks (exploration, quick lookups)
- Use GPT-4 for `workhorse_coder` tasks (standard implementation)
- Reserve GPT-4 Turbo or o1 for `critical_reasoner` tasks (security, architecture)
- Consider local Ollama models for `cheap_local` tasks (commit messages, formatting)

### OpenAI Model Recommendations

| Tier | Recommended Model | Use Case |
|------|-------------------|----------|
| `critical_reasoner` | o1-preview, GPT-4 Turbo | Complex reasoning, security reviews |
| `workhorse_coder` | GPT-4, GPT-4 Turbo | Daily implementation, analysis |
| `fast_router` | GPT-3.5 Turbo | Quick exploration, lookups |
| `independent_verifier` | Claude Opus (cross-family) | Independent verification |
| `cheap_local` | Ollama (local) | Offline tasks, commit messages |

