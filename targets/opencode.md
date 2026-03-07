# OpenCode Target

OpenCode is a strong bridge target because it can work with repo rules, permission policies, and Claude-style assets with lighter adaptation.

## Minimum Common Primitives

- `AGENTS.md` or equivalent repo instructions
- OpenCode config and permission rules
- repo-local SSOT files
- reusable skills or agents where the host supports them

## Portable Mapping

- `core/models/*.yaml` -> configured target profile and routing guidance
- `core/skills/registry.yaml` -> native OpenCode skills, reused Claude-style skills, or agent templates
- `core/security/policy.yaml` -> permission rules and wrapper enforcement

## Phase 1 Notes

- Use OpenCode as an early cross-target proving ground after Claude Code.
- Keep the portable skill IDs stable even when the physical skill files are shared.
- Prefer host-native permission controls for `P0/P1` enforcement.

## Phase 2 Build Output

- `bin/vibe build --target opencode` generates `AGENTS.md`, `opencode.json`, and modular instruction files.
- The generated `opencode.json` uses the documented `instructions` field to load the rendered workflow docs.

## Phase 3 Additions

- `bin/vibe switch opencode` applies the generated OpenCode config into the current repo root by default.
- The generated OpenCode output now includes dedicated routing and execution modules in addition to general, skills, and safety guidance.
- Phase 4 also renders a `permission` block in `opencode.json` so safety policy influences OpenCode’s native permission layer.

## Phase 5 Additions

- OpenCode builds can now deep-merge project overlays into `opencode.json`, including permission deltas and other supported native config additions.
- Overlay-applied profile and behavior deltas are also reflected in the generated `.vibe/opencode/*` instructions.

## Phase 6 Additions

- Task routing and test standards are now generated under `.vibe/opencode/task-routing.md` and `.vibe/opencode/test-standards.md`.
- These policies enable complexity-aware workflow adaptation for OpenCode agents.

## Model Configuration

OpenCode allows flexible model configuration in its `opencode.json` file. The capability-tier routing system can map to any AI provider OpenCode supports.

### Capability Tier Mapping

The default `opencode-default` profile maps capability tiers to configurable model slots:

```yaml
critical_reasoner: configured.primary-high-reasoning    # Your strongest configured model
workhorse_coder: configured.primary-coder               # Your default coding model
fast_router: configured.fast-agent                      # Your fast exploration model
independent_verifier: second-model.cross-family         # Cross-family verification model
cheap_local: local.ollama-class                         # Local model for offline tasks
```

### Configuration in opencode.json

**Basic configuration:**

```json
{
  "models": {
    "primary": "claude-opus-4",
    "coder": "claude-sonnet-4",
    "fast": "claude-haiku-4"
  },
  "instructions": [
    "AGENTS.md",
    ".vibe/opencode/behavior-policies.md",
    ".vibe/opencode/routing.md"
  ]
}
```

**Advanced configuration with multiple providers:**

```json
{
  "models": {
    "critical": {
      "provider": "anthropic",
      "model": "claude-opus-4",
      "temperature": 0.2
    },
    "workhorse": {
      "provider": "anthropic",
      "model": "claude-sonnet-4",
      "temperature": 0.5
    },
    "fast": {
      "provider": "anthropic",
      "model": "claude-haiku-4",
      "temperature": 0.7
    },
    "verifier": {
      "provider": "openai",
      "model": "gpt-4-turbo",
      "temperature": 0.3
    }
  }
}
```

### Generated Routing Guidance

The generated `.vibe/opencode/routing.md` will contain:

```markdown
## Active mapping

- `critical_reasoner` → `configured.primary-high-reasoning`
- `workhorse_coder` → `configured.primary-coder`
- `fast_router` → `configured.fast-agent`
```

These map to the model slots you define in `opencode.json`.

### Project-Specific Overrides

Use a project overlay to customize model configuration:

```yaml
# .vibe/overlay.yaml
profile:
  mapping:
    critical_reasoner: configured.claude-opus-4-latest
    workhorse_coder: configured.claude-sonnet-4-latest

targets:
  opencode:
    models:
      primary: claude-opus-4-20250514
      coder: claude-sonnet-4-20250514
      fast: claude-haiku-4-20250514
```

Then build with the overlay:
```bash
bin/vibe build opencode --overlay .vibe/overlay.yaml
bin/vibe use opencode --destination /path/to/project
```

The overlay will be merged into the generated `opencode.json`.

### Model Selection Strategy

OpenCode's flexibility allows you to:

1. **Use a single provider** (e.g., all Anthropic Claude models)
2. **Mix providers** (e.g., Claude for coding, GPT-4 for verification)
3. **Include local models** (e.g., Ollama for commit messages)

**Example mixed-provider configuration:**

```json
{
  "models": {
    "primary": "claude-opus-4",
    "coder": "claude-sonnet-4",
    "fast": "gpt-3.5-turbo",
    "verifier": "gpt-4-turbo",
    "local": "ollama:codellama"
  }
}
```

### Cost Optimization

- Use your strongest model only for `critical_reasoner` tasks
- Configure a balanced model for `workhorse_coder` (most tasks)
- Use a fast/cheap model for `fast_router` (exploration)
- Enable local models for `cheap_local` (commit messages, formatting)

### Provider Recommendations

| Tier | Anthropic | OpenAI | Local |
|------|-----------|--------|-------|
| `critical_reasoner` | Claude Opus 4 | GPT-4 Turbo, o1 | - |
| `workhorse_coder` | Claude Sonnet 4 | GPT-4 | - |
| `fast_router` | Claude Haiku 4 | GPT-3.5 Turbo | Ollama |
| `independent_verifier` | Cross-family | Cross-family | - |
| `cheap_local` | - | - | Ollama, CodeLlama |

### Dynamic Model Switching

If OpenCode supports runtime model selection, you can switch models per task:

```bash
# Use primary model for critical work
opencode --model primary "review security implications"

# Use fast model for exploration
opencode --model fast "list all API endpoints"

# Use verifier model for cross-check
opencode --model verifier "verify the security analysis"
```

Check OpenCode's documentation for the exact CLI syntax.

