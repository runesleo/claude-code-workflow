# Kimi Code Target

Kimi Code is a command-line AI coding assistant by Moonshot AI. It supports project-specific skills through SKILL.md files and global configuration.

## Native Primitives

- `SKILL.md` files in `.agents/skills/` for reusable capabilities
- Global config in `~/.config/agents/` for user-level preferences
- `.agents/` directory in project root for project-specific skills
- Command-line interface with subcommands and flags

## Portable Mapping

- `core/models/*.yaml` -> skill instructions and routing guidance in `.agents/skills/`
- `core/skills/registry.yaml` -> individual SKILL.md files under `.agents/skills/`
- `core/security/policy.yaml` -> safety instructions embedded in relevant skills
- `core/policies/*.yaml` -> behavior guidance in generated skills

## Phase 1 Notes

- Kimi Code uses a skill-centric model where capabilities are defined in SKILL.md files.
- Each skill has frontmatter (YAML) and markdown instructions.
- Skills can declare allowed tools and provide detailed usage instructions.
- Project-level skills override or extend global skills.

## Phase 2 Build Output

- `bin/vibe build --target kimi-code` generates `.agents/skills/*.md` files.
- The generator creates SKILL.md files with proper frontmatter for Kimi CLI.
- A root `KIMI.md` file serves as the project entrypoint for context.

## Phase 4 Additions

- Generated Kimi skills now include tool restrictions based on portable security policy.
- `.vibe/kimi-code/behavior-policies.md` and `.vibe/kimi-code/safety.md` provide traceability to portable schema.
- Skill files include P0/P1/P2 severity annotations in their descriptions.

## Phase 5 Additions

- Kimi builds can merge a project overlay into skill generation and KIMI.md.
- `bin/vibe use` and `bin/vibe switch` auto-discover `.vibe/overlay.yaml` when present.

## Phase 6 Additions

- Task routing and test standards are generated as `.vibe/kimi-code/task-routing.md` and `.vibe/kimi-code/test-standards.md`.
- These policies help AI assistants adapt workflow rigor based on task complexity.

## Model Configuration

Kimi Code uses Moonshot AI's models. The capability-tier routing system maps to available model classes.

### Capability Tier Mapping

The default `kimi-code-default` profile maps capability tiers to Moonshot model classes:

```yaml
critical_reasoner: kimi.k2.5-class         # Highest reasoning capability (e.g., k2.5)
workhorse_coder: kimi.default-class        # Balanced daily coding (e.g., moonshot-v1-8k)
fast_router: kimi.fast-class               # Fast exploration (e.g., moonshot-v1-8k with fast mode)
independent_verifier: second-model.cross-family  # Cross-model verification
cheap_local: local.ollama-class            # Local/offline fallback
```

### Configuration Methods

**Method 1: Launch with model selection**

Kimi CLI supports model selection via environment variables or config:

```bash
# Set default model in config
kimi config set model moonshot-v1-8k

# Or use environment variable for single session
export KIMI_MODEL=moonshot-v1-8k
```

**Method 2: Skill-level model hints**

Skills can include model recommendations in their instructions:

```markdown
For critical security review, prefer the k2.5-class model.
For standard implementation, the default model is sufficient.
For quick exploration, use the fast model option.
```

**Method 3: Project overlay**

Use `.vibe/overlay.yaml` to specify project-specific model preferences:

```yaml
profile:
  mapping:
    critical_reasoner: kimi.k2.5-class
    workhorse_coder: kimi.default-class
    fast_router: kimi.fast-class
```

## Installation

```bash
# Install Kimi CLI (if not already installed)
pip install kimi-cli

# Or with uv
uv tool install kimi-cli

# Verify installation
kimi --version
```

## Usage

```bash
# Start Kimi Code in current project
kimi

# Use a specific skill
kimi skill run session-end

# List available skills
kimi skill list

# Build Vibe workflow for Kimi
bin/vibe build kimi-code --output ./.agents

# Or apply directly to a project
bin/vibe use kimi-code --destination ~/my-project
```

## File Layout

When built for Kimi Code, the target generates:

```
.agents/
├── skills/
│   ├── session-end/SKILL.md
│   ├── systematic-debugging/SKILL.md
│   ├── verification-before-completion/SKILL.md
│   ├── planning-with-files/SKILL.md
│   └── experience-evolution/SKILL.md
└── KIMI.md              # Project entrypoint (top-level instructions)
```

## Differences from Claude Code

| Feature | Claude Code | Kimi Code |
|---------|-------------|-----------|
| Config format | Markdown rules + docs | SKILL.md files |
| Entry point | CLAUDE.md | KIMI.md |
| Skill system | Native with triggers | SKILL.md based |
| Global config | `~/.claude/` | `~/.config/agents/` |
| Project config | `CLAUDE.md` + `rules/` | `.agents/skills/` |
| Permission model | Settings + hooks | Tool restrictions in skills |

## Migration from Other Targets

To migrate an existing project to Kimi Code:

```bash
# Generate Kimi-specific config
bin/vibe switch kimi-code

# This creates:
# - .agents/skills/ with SKILL.md files
# - KIMI.md at project root
# - .vibe/kimi-code/ with supporting docs

# Commit the generated files
git add .agents/ KIMI.md
git commit -m "Add Kimi Code workflow support"
```
