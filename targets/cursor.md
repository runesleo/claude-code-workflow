# Cursor Target

Cursor should render the portable workflow through rules and project-scoped context, not through a fake Claude-style skill layer.

## Minimum Common Primitives

- `.cursor/rules/` for always-on, auto-attached, or manually attached rules
- project memories or sidecar context as cache
- repo-local SSOT files for durable project state
- manual or rule-triggered review flows for skill-like behavior

## Portable Mapping

- `core/models/*.yaml` -> rule guidance for routing and model selection
- `core/skills/registry.yaml` -> rule bundles, manual prompts, or reusable review checklists
- `core/security/policy.yaml` -> blocking or warning rules plus external wrapper enforcement where needed

## Phase 1 Notes

- Treat Cursor memories as convenience, not as the canonical workflow memory.
- Encode portable mandatory behavior in always-on rules first.
- Degrade optional skills into attached rules or manual invocation patterns.

## Phase 2 Build Output

- `bin/vibe build --target cursor` generates root `AGENTS.md` and `.cursor/rules/*.mdc`.
- The phase-2 generator currently splits always-on behavior from optional skill reference rules.

## Phase 3 Additions

- `bin/vibe switch cursor` applies Cursor-oriented files into the current repo root by default.
- The generated Cursor output now separates core, routing, safety, and optional-skill rules, with supporting notes under `.vibe/cursor/`.
- Phase 4 also generates `.cursor/cli.json` with a conservative permission baseline derived from the portable safety policy.

## Phase 5 Additions

- Cursor builds can now merge a project overlay into `.cursor/cli.json`, profile mapping, and the generated support docs.
- Destination repos with `.vibe/overlay.yaml` get that overlay automatically when using `bin/vibe use` or `bin/vibe switch`.

## Phase 6 Additions

- Task routing and test standards are now generated under `.vibe/cursor/task-routing.md` and `.vibe/cursor/test-standards.md`.
- These policies enable complexity-aware workflow adaptation for AI assistants working in Cursor.

## Model Configuration

Cursor's model selection is configured through its UI settings. The capability-tier routing system provides semantic guidance, but actual model selection happens in Cursor's settings.

### Capability Tier Mapping

The default `cursor-default` profile maps capability tiers to Cursor's model slots:

```yaml
critical_reasoner: cursor.primary-frontier-model     # Your configured primary model
workhorse_coder: cursor.default-agent-model          # Your configured default model
fast_router: cursor.fast-model                       # Your configured fast model
independent_verifier: second-model.or.manual-review  # Manual review or second model
cheap_local: local.external-runner                   # External local model
```

### Configuration Steps

**Step 1: Configure models in Cursor settings**

1. Open Cursor Settings (Cmd/Ctrl + ,)
2. Navigate to "Models" or "AI" section
3. Configure your model preferences:
   - **Primary Model**: Use for `critical_reasoner` and `workhorse_coder` (e.g., Claude Opus, GPT-4)
   - **Fast Model**: Use for `fast_router` (e.g., Claude Haiku, GPT-3.5)
   - **Review Model**: Optional second model for `independent_verifier`

**Step 2: Generated rules reference these models**

The generated `.cursor/rules/05-vibe-routing.mdc` will contain:

```markdown
## Active mapping

- `critical_reasoner` → `cursor.primary-frontier-model`
- `workhorse_coder` → `cursor.default-agent-model`
- `fast_router` → `cursor.fast-model`
```

These are semantic references to your configured models, not executable configuration.

**Step 3: AI interprets routing guidance**

When working in Cursor, the AI will see these routing rules and understand:
- Use your primary model for critical logic and security-sensitive work
- Use your default model for standard implementation
- Use your fast model for exploration and quick lookups

### Project-Specific Overrides

Use a project overlay to document project-specific model preferences:

```yaml
# .vibe/overlay.yaml
profile:
  mapping:
    critical_reasoner: cursor.gpt-4-turbo
    workhorse_coder: cursor.claude-sonnet
  note_append:
    - "This project uses GPT-4 Turbo for critical reasoning"
```

Then build with the overlay:
```bash
bin/vibe build cursor --overlay .vibe/overlay.yaml
bin/vibe use cursor --destination /path/to/project
```

### Important Notes

- **Cursor does not support automatic model switching per task** - the routing guidance is informational
- The AI assistant will see the routing rules but cannot programmatically switch models
- You may need to manually switch models in Cursor for critical tasks
- Consider using Cursor's "Chat with AI" feature to explicitly request a specific model for critical decisions

### Cost Optimization

- Configure a balanced model (Claude Sonnet, GPT-4) as your default
- Use a fast model (Claude Haiku, GPT-3.5) for exploration when available
- Manually switch to your strongest model (Claude Opus, GPT-4 Turbo) for security reviews and architecture decisions

