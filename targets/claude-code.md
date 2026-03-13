# Claude Code Target

Claude Code is the current first-class runtime target for this repository.

## Native Primitives

- `CLAUDE.md` for top-level instruction and memory entry
- `rules/` for always-loaded behavior guidance
- `docs/` for on-demand reference
- `skills/` for reusable native skills
- `agents/` and `commands/` for host-facing specialization
- hooks or permissions for stronger runtime safety enforcement

## Portable Mapping

- `core/models/*.yaml` -> `rules/behaviors.md` and `docs/task-routing.md`
- `core/skills/registry.yaml` -> `rules/skill-triggers.md` plus `skills/*/SKILL.md`
- `core/security/policy.yaml` -> `docs/content-safety.md` and any hook or permission policy
- future portable policy files -> `rules/` and `docs/` renderings

## Phase 1 Notes

- The current repository layout is already the Claude Code target.
- During migration, update `core/` first, then sync the Claude-facing markdown.
- Keep current skill names stable unless the portable registry changes first.

## Phase 2 Build Output

- `bin/vibe build --target claude-code` materializes a Claude-ready config tree.
- `bin/vibe use --target claude-code --destination ~/.claude` applies it to a Claude config directory.

## Phase 4 Additions

- The generated Claude output now includes a `settings.json` permission baseline derived from the portable safety policy.
- `.vibe/claude-code/behavior-policies.md` and `.vibe/claude-code/safety.md` mirror the portable behavior and safety schema for traceability.

## Phase 5 Additions

- Claude builds can now merge a project overlay into `settings.json` and the rendered behavior summary.
- `bin/vibe use` and `bin/vibe switch` will auto-discover `.vibe/overlay.yaml` in the destination repo when present.

## Phase 6 Additions

- Task routing and test standards are now generated as `.vibe/claude-code/task-routing.md` and `.vibe/claude-code/test-standards.md`.
- These files define complexity-based task classification (trivial/standard/critical) and corresponding test coverage requirements.
- AI assistants can use these policies to automatically adjust workflow rigor based on task complexity.

## Model Configuration

Claude Code supports dynamic model selection, which is essential for the capability-tier routing system.

### Capability Tier Mapping

The default `claude-code-default` profile maps capability tiers to Claude model classes:

```yaml
critical_reasoner: claude.opus-class      # Highest reasoning capability
workhorse_coder: claude.sonnet-class      # Balanced performance/cost
fast_router: claude.haiku-class           # Fast exploration
independent_verifier: second-model.cross-family  # Cross-model verification
cheap_local: local.ollama-class           # Local/offline fallback
```

### Configuration Methods

**Method 1: Launch-time model selection**
```bash
# Start with Opus for critical work
claude --model opus

# Start with Sonnet for daily development
claude --model sonnet

# Start with Haiku for quick exploration
claude --model haiku
```

**Method 2: Task tool model parameter**

When using the Task tool to spawn subagents, Claude can specify the model tier:

```markdown
# In your instructions to Claude
For critical security review, use Task tool with model: "opus"
For standard implementation, use Task tool with model: "sonnet"
For quick exploration, use Task tool with model: "haiku"
```

**Method 3: Settings configuration (if supported)**

Check `~/.claude/settings.json` for model preferences:

```json
{
  "defaultModel": "sonnet",
  "models": {
    "critical": "opus",
    "standard": "sonnet",
    "fast": "haiku"
  }
}
```

Note: The exact settings schema depends on your Claude Code version.

### Project-Specific Overrides

Use a project overlay to customize model mapping:

```yaml
# .vibe/overlay.yaml
profile:
  mapping:
    critical_reasoner: claude.opus-4-20250514
    workhorse_coder: claude.sonnet-4-20250514
```

Then build with the overlay:
```bash
bin/vibe build claude-code --overlay .vibe/overlay.yaml
bin/vibe use claude-code --destination ~/.claude
```

### Cost Optimization

- Use `workhorse_coder` (Sonnet) as the default for most work
- Reserve `critical_reasoner` (Opus) for security-sensitive or complex architectural decisions
- Leverage `fast_router` (Haiku) for exploration and quick lookups
- Enable `cheap_local` (Ollama) for commit messages and formatting

See `docs/task-routing.md` for detailed routing guidelines.

