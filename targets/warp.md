# Warp Target

Warp should render the portable workflow through project rules rooted in `WARP.md`, with supporting repo-local docs for routing, safety, and reusable behavior.

## Minimum Common Primitives

- `WARP.md` as the project rule entrypoint
- repo-local SSOT files for durable project state
- supporting docs or templates for routing, safety, and skill-like flows
- optional workflows as wrappers around project commands, not as canonical state

## Portable Mapping

- `core/models/*.yaml` -> `WARP.md` plus `.vibe/warp/routing.md`
- `core/skills/registry.yaml` -> rule references, reusable checklists, or workflow guidance
- `core/security/policy.yaml` -> rule-backed escalation guidance and any future native enforcement bridge
- `core/policies/behaviors.yaml` -> `WARP.md` and `.vibe/warp/behavior-policies.md`

## Phase 6 Build Output

- `bin/vibe build --target warp` generates `WARP.md` and `.vibe/warp/*` support docs.
- `bin/vibe switch warp` applies Warp-oriented files into the current repo root by default.
- **Path Safety**: If the default output directory would overlap with the destination (e.g., when switching into the repo root), the tool automatically uses an external staging directory at `~/.vibe-generated/<repo-name>-<hash>/warp/` to prevent conflicts.
- Project overlays can inject stack-specific preferences such as `uv` or `nvm` into the rendered Warp rule set without changing shared defaults.

## Notes

- Keep Warp support conservative and file-backed; do not assume direct management of Warp Drive state.
- Treat Warp workflows as optional wrappers over stable project commands such as `bin/vibe inspect`, `uv run ...`, `nvm use`, or repo-local scripts.

## Model Configuration

Warp's model configuration depends on its AI provider integration. The capability-tier routing system provides semantic guidance that Warp's AI can interpret.

### Capability Tier Mapping

The default `warp-default` profile maps capability tiers to Warp's model references:

```yaml
critical_reasoner: warp.primary-frontier-model       # Your configured primary AI model
workhorse_coder: warp.default-agent-model            # Your configured default AI model
fast_router: warp.fast-model                         # Your configured fast model (if available)
independent_verifier: second-model.or.manual-review  # Manual review or external verification
cheap_local: local.external-runner                   # External local model or script
```

### Configuration Steps

**Step 1: Configure AI provider in Warp**

1. Open Warp Settings
2. Navigate to AI or Assistant settings
3. Configure your AI provider (e.g., Anthropic Claude, OpenAI)
4. Select your preferred model

**Step 2: Generated rules reference the configured model**

The generated `WARP.md` will contain:

```markdown
## Capability routing

- `critical_reasoner` → `warp.primary-frontier-model`
- `workhorse_coder` → `warp.default-agent-model`
- `fast_router` → `warp.fast-model`
```

These are semantic references to your configured AI model in Warp settings.

**Step 3: AI interprets routing guidance**

When Warp's AI assistant processes your requests, it will see these routing rules and understand:
- Critical logic and security work requires highest reasoning capability
- Standard implementation uses the default configured model
- Quick exploration can use faster/cheaper alternatives if available

### Project-Specific Overrides

Use a project overlay to document project-specific AI preferences:

```yaml
# .vibe/overlay.yaml
profile:
  mapping:
    critical_reasoner: warp.claude-opus
    workhorse_coder: warp.claude-sonnet
  note_append:
    - "This project uses Claude Opus for critical reasoning"
    - "Python environment managed via uv"
```

Then build with the overlay:
```bash
bin/vibe build warp --overlay .vibe/overlay.yaml
bin/vibe switch warp
```

### Important Notes

- **Warp's model switching capabilities are limited** - the routing guidance is primarily informational
- Warp typically uses a single configured AI model for all interactions
- The routing rules help the AI understand task criticality and adjust its approach accordingly
- For truly critical decisions, consider using a dedicated Claude Code or Cursor session with explicit model selection

### Workflow Integration

Warp excels at wrapping project commands. Use it to:

```bash
# Inspect current vibe configuration
warp run "bin/vibe inspect"

# Build with project overlay
warp run "bin/vibe build warp --overlay .vibe/overlay.yaml"

# Run project-specific commands with proper environment
warp run "uv run pytest"  # For Python projects
warp run "nvm use && npm test"  # For Node projects
```

The AI routing guidance helps Warp's assistant understand when to be more careful vs. when to move quickly.

