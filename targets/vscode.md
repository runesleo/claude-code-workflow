# VS Code Target

VS Code should render the portable workflow through `AGENTS.md`, workspace-level instructions for GitHub Copilot Chat, and repo-local support docs under `.vibe/vscode/`.

## Minimum Common Primitives

- `AGENTS.md` as the shared instruction surface
- `.vscode/settings.json` with Copilot Chat workspace instructions referencing the generated docs
- repo-local SSOT files for durable project state
- `.vibe/vscode/` for generated behavior, routing, safety, and skill reference docs
- manual or rule-triggered review flows for skill-like behavior

## Portable Mapping

- `core/models/*.yaml` -> routing guidance inside `AGENTS.md` and `.vibe/vscode/routing.md`
- `core/skills/registry.yaml` -> rule references or manual invocation patterns; no native skill layer
- `core/security/policy.yaml` -> blocking rules surfaced in Copilot Chat warnings or workspace settings
- `core/policies/behaviors.yaml` -> `AGENTS.md` and `.vibe/vscode/behavior-policies.md`

## Phase 6 Build Output

- `bin/vibe build --target vscode` generates `AGENTS.md`, `.vscode/settings.json`, and `.vibe/vscode/*` support docs.
- `bin/vibe switch vscode` applies VS Code-oriented files into the current repo root by default.
- **Path Safety**: If the default output directory would overlap with the destination (e.g., when switching into the repo root), the tool automatically uses an external staging directory at `~/.vibe-generated/<repo-name>-<hash>/vscode/` to prevent conflicts.
- Project overlays can inject stack-specific preferences into the rendered VS Code config without changing shared defaults.

## Notes

- Treat VS Code Copilot Chat as an assistant with limited persistent context. The generated workspace instructions help anchor behavior.
- VS Code does not support automatic model switching per task — the routing guidance is informational.
- Keep generated `.vscode/settings.json` minimal and non-destructive; merge with existing workspace settings when present.

## Model Configuration

VS Code's AI capabilities come primarily through GitHub Copilot and Copilot Chat. Model selection depends on the user's Copilot subscription tier.

### Capability Tier Mapping

The default `vscode-default` profile maps capability tiers to Copilot model references:

```yaml
critical_reasoner: copilot.primary-model          # Best available Copilot model
workhorse_coder: copilot.default-agent-model      # Default Copilot agent model
fast_router: copilot.fast-model                   # Fast Copilot model for exploration
independent_verifier: second-model.or.manual-review  # Manual review or external tool
cheap_local: local.external-runner                # External local model or script
```

### Configuration Steps

**Step 1: Configure Copilot in VS Code**

1. Install GitHub Copilot and Copilot Chat extensions
2. Sign in with your GitHub account
3. Copilot model selection depends on your subscription tier (Individual, Business, Enterprise)

**Step 2: Generated workspace instructions**

The generated `.vscode/settings.json` will include:

```json
{
  "github.copilot.chat.codeGeneration.instructions": [
    { "file": "AGENTS.md" },
    { "file": ".vibe/vscode/behavior-policies.md" },
    { "file": ".vibe/vscode/routing.md" },
    { "file": ".vibe/vscode/safety.md" }
  ]
}
```

These instruct Copilot Chat to reference the generated workflow docs as context.

**Step 3: AI interprets routing guidance**

When using Copilot Chat, the AI will see these routing rules and understand:
- Critical logic and security work requires careful reasoning and verification
- Standard implementation uses default Copilot capabilities
- Quick exploration and lookups can proceed with default settings

### Project-Specific Overrides

Use a project overlay to document project-specific preferences:

```yaml
# .vibe/overlay.yaml
profile:
  mapping:
    critical_reasoner: copilot.gpt-4o
    workhorse_coder: copilot.claude-sonnet
  note_append:
    - "This project uses GPT-4o for critical reasoning in Copilot"
```

Then build with the overlay:
```bash
bin/vibe build vscode --overlay .vibe/overlay.yaml
bin/vibe switch vscode
```

### Important Notes

- **Copilot model switching is limited** — the routing guidance is primarily informational
- Copilot Chat typically uses a single model determined by your subscription
- The workspace instructions help Copilot Chat understand project conventions and safety expectations
- For truly critical decisions, consider using a dedicated Claude Code or Cursor session

### Cost Optimization

- Copilot Individual/Business tiers include bundled usage
- Use Copilot for `workhorse_coder` and `fast_router` tasks
- Reserve external tools (Claude Code, Cursor) for `critical_reasoner` tasks requiring explicit model selection
- Consider local Ollama models for `cheap_local` tasks (commit messages, formatting)

### Workflow Integration

VS Code works well with project-level vibe workflows:

```bash
# Inspect current vibe configuration
bin/vibe inspect

# Build VS Code target
bin/vibe build vscode --overlay .vibe/overlay.yaml

# Switch to VS Code target
bin/vibe switch vscode
```

The generated workspace instructions help Copilot Chat stay aligned with project conventions and safety requirements.
