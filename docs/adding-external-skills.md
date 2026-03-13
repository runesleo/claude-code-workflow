# Adding External Skills

This guide explains how to add new external skills to the workflow system so that LLMs can automatically discover and use them based on context.

## Overview

External skills are third-party skill packs (like Superpowers) that extend the built-in workflow capabilities. The system automatically generates trigger rules that tell LLMs when to use each skill.

## Architecture

```
core/integrations/
  └── <skill-pack>.yaml     # Skill pack definition with trigger contexts

core/skills/
  └── registry.yaml         # Portable skill IDs and metadata

Generated output:
  rules/skill-triggers.md   # Auto-generated trigger rules for LLMs
```

## Step 1: Define the Skill Pack

Create or update `core/integrations/<skill-pack>.yaml`:

```yaml
schema_version: 1
name: my-skill-pack
type: skill_pack
namespace: mypack
source: https://github.com/example/my-skill-pack
description: Brief description of what this pack provides

skills:
  - id: original-skill-name          # Original ID in the skill pack
    registry_id: mypack/short-name   # Portable ID used in registry.yaml
    intent: Brief description of what this skill does
    trigger_context: When to use this skill (scenario description)

  - id: another-skill
    registry_id: mypack/another
    intent: Another skill description
    trigger_context: When implementing feature X or debugging Y
```

### Key Fields

- **id**: Original skill ID from the external pack
- **registry_id**: Portable ID that will be used in `registry.yaml` (format: `namespace/skill-name`)
- **intent**: One-line description of the skill's purpose
- **trigger_context**: Natural language description of when LLMs should suggest this skill

## Step 2: Register Skills in Registry

Add entries to `core/skills/registry.yaml`:

```yaml
skills:
  - id: mypack/short-name
    namespace: mypack
    entrypoint: external
    intent: Brief description of what this skill does
    trigger_mode: suggest    # or 'manual' for user-invoked only
    priority: P2
    supported_targets:
      claude-code: native-skill
      cursor: rule-or-manual-invocation
      # ... other targets
```

### Trigger Modes

- **suggest**: LLM will auto-suggest this skill when the scenario matches
- **manual**: User must explicitly invoke the skill (not auto-suggested)
- **mandatory**: Always triggered (reserved for critical built-in skills)

## Step 3: Test the Integration

1. **Build a target**:
   ```bash
   bin/vibe build claude-code --output generated/test
   ```

2. **Check generated rules**:
   ```bash
   cat generated/test/rules/skill-triggers.md
   ```

   You should see a section like:
   ```markdown
   ### When to Use My Skill Pack Skills

   | Scenario | Skill | Notes |
   |----------|-------|-------|
   | When implementing feature X | `mypack/short-name` | Auto-suggested when applicable |
   ```

3. **Run tests**:
   ```bash
   make test
   ```

4. **Update snapshots** (if tests fail due to new skills):
   ```bash
   for target in claude-code codex-cli cursor kimi-code opencode vscode warp antigravity; do
     bin/vibe build $target --output generated/$target --skip-integrations
     cp generated/$target/AGENTS.md .vibe/$target/ 2>/dev/null || true
   done
   ```

## Example: Adding a New Skill to Superpowers

Let's say Superpowers adds a new skill called `performance-profiling`:

### 1. Update `core/integrations/superpowers.yaml`

```yaml
skills:
  # ... existing skills ...

  - id: performance-profiling           # Original ID in superpowers
    registry_id: superpowers/profile    # Portable ID
    intent: Profile application performance and identify bottlenecks
    trigger_context: When investigating performance issues or slow operations
```

### 2. Update `core/skills/registry.yaml`

```yaml
skills:
  # ... existing skills ...

  - id: superpowers/profile
    namespace: superpowers
    entrypoint: external
    intent: Profile application performance and identify bottlenecks
    trigger_mode: suggest
    priority: P2
    supported_targets:
      claude-code: native-skill
      cursor: rule-or-manual-invocation
      opencode: native-skill
      # ... other targets
```

### 3. Rebuild and Test

```bash
bin/vibe build claude-code --output generated/test
cat generated/test/rules/skill-triggers.md | grep -A 10 "When to Use"
```

The generated output will now include:

```markdown
| When investigating performance issues or slow operations | `superpowers/profile` | Auto-suggested when applicable |
```

## Best Practices

### Writing Good Trigger Contexts

✅ **Good**:
- "When implementing new functionality"
- "Before creating pull requests"
- "When encountering bugs or test failures"
- "When refactoring code for better structure"

❌ **Bad**:
- "Use this skill" (not specific enough)
- "TDD workflow" (too technical, not scenario-based)
- "Always use this" (defeats the purpose of contextual triggering)

### Choosing Trigger Modes

- Use **suggest** for skills that should be proactively recommended
- Use **manual** for specialized skills that require explicit user intent
- Reserve **mandatory** for critical safety/quality checks only

### Namespace Conventions

- Use short, memorable namespace prefixes (e.g., `superpowers`, `mypack`)
- Keep skill names concise (e.g., `tdd`, `review`, `profile`)
- Full ID format: `namespace/skill-name`

## Troubleshooting

### Skill not appearing in generated rules

1. Check that `registry_id` in integration YAML matches `id` in registry.yaml
2. Verify `trigger_mode` is set to `suggest` (not `manual`)
3. Ensure `trigger_context` is defined in integration YAML

### Tests failing after adding skills

Run snapshot update:
```bash
for target in claude-code codex-cli cursor kimi-code opencode vscode warp antigravity; do
  bin/vibe build $target --output generated/$target --skip-integrations
  cp generated/$target/*.md .vibe/$target/ 2>/dev/null || true
done
make test
```

## See Also

- [Extending Recommendations](extending-recommendations.md) - Adding tools to installation suggestions
- [Skill Security Audit](../rules/skill-triggers.md) - Security review process for external skills
- [Registry Schema](../core/skills/registry.yaml) - Full registry structure
