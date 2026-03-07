# Antigravity Target

Antigravity should render the portable workflow through `AGENTS.md` and repo-local support docs, leveraging its native multi-agent task tracking and markdown-driven planning capabilities.

## Minimum Common Primitives

- `AGENTS.md` as the shared instruction surface
- repo-local SSOT files for memory, handoff, and status
- `.vibe/antigravity/` for generated behavior, routing, safety, and skill docs
- native task tracking artifacts (`task.md`, `implementation_plan.md`, `walkthrough.md`) as working memory

## Portable Mapping

- `core/models/*.yaml` -> active provider profile and routing guidance inside `AGENTS.md`
- `core/skills/registry.yaml` -> native skills where possible, rule-based fallback otherwise
- `core/security/policy.yaml` -> blocking rules surfaced through `notify_user` or execution deny logic
- `core/policies/behaviors.yaml` -> `AGENTS.md` and `.vibe/antigravity/behavior-policies.md`

## Phase 6 Build Output

- `bin/vibe build --target antigravity` generates `AGENTS.md` and `.vibe/antigravity/*` support docs.
- `bin/vibe switch antigravity` applies Antigravity-oriented files into the current repo root by default.
- **Path Safety**: If the default output directory would overlap with the destination (e.g., when switching into the repo root), the tool automatically uses an external staging directory at `~/.vibe-generated/<repo-name>-<hash>/antigravity/` to prevent conflicts.
- Project overlays can inject stack-specific preferences into the rendered Antigravity rule set without changing shared defaults.

## Notes

- Antigravity natively supports `task_boundary`, `notify_user`, and structured planning artifacts. These map well to the portable `planning-with-files` and `session-end` skills.
- Generated docs under `.vibe/antigravity/` serve as authoritative framework conventions that Antigravity's agents will reference.
- Treat Antigravity-managed knowledge items and brain artifacts as working cache, not as the workflow SSOT.

## Model Configuration

Antigravity's model configuration depends on its internal model routing and the user's subscription. The capability-tier routing system provides semantic guidance.

### Capability Tier Mapping

The default `antigravity-default` profile maps capability tiers to Antigravity's model references:

```yaml
critical_reasoner: antigravity.primary-frontier-model     # Primary high-reasoning model
workhorse_coder: antigravity.default-agent-model          # Default agent model for coding
fast_router: antigravity.fast-model                       # Fast model for exploration
independent_verifier: second-model.or.manual-review       # Manual review or external verification
cheap_local: local.external-runner                        # External local model or script
```

### Configuration Steps

**Step 1: Model selection in Antigravity**

Antigravity selects models based on task complexity and the user's configured preferences. The routing guidance in `AGENTS.md` helps the agent understand when to apply different reasoning levels.

**Step 2: Generated rules reference the configured model**

The generated `AGENTS.md` will contain:

```markdown
## Capability routing

- `critical_reasoner` → `antigravity.primary-frontier-model`
- `workhorse_coder` → `antigravity.default-agent-model`
- `fast_router` → `antigravity.fast-model`
```

These are semantic references to the model tiers available in Antigravity.

**Step 3: Agent interprets routing guidance**

When Antigravity's agents process requests, they will see these routing rules and understand:
- Critical logic, security, and architecture work requires the highest reasoning capability
- Standard implementation and analysis uses the default agent model
- Quick exploration, triage, and lookups can use faster alternatives

### Project-Specific Overrides

Use a project overlay to document project-specific AI preferences:

```yaml
# .vibe/overlay.yaml
profile:
  mapping:
    critical_reasoner: antigravity.frontier-latest
    workhorse_coder: antigravity.balanced-latest
  note_append:
    - "This project uses the latest frontier model for critical reasoning"
    - "Python environment managed via uv"
```

Then build with the overlay:
```bash
bin/vibe build antigravity --overlay .vibe/overlay.yaml
bin/vibe switch antigravity
```

### Important Notes

- Antigravity uses task tracking and structured planning natively, making skills like `planning-with-files` and `session-end` natural fits
- The `notify_user` tool in Antigravity maps directly to the P1 security escalation pathway
- Consider using Antigravity's multi-agent browser subagent for verification tasks that require UI interaction

### Workflow Integration

Antigravity works well with project-level vibe workflows:

```bash
# Inspect current vibe configuration
bin/vibe inspect

# Build with project overlay
bin/vibe build antigravity --overlay .vibe/overlay.yaml

# Switch to Antigravity target
bin/vibe switch antigravity
```

The AI routing guidance helps Antigravity's agents adjust reasoning depth based on task criticality.
