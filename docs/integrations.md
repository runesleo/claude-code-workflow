# External Tool Integrations

This document explains how the claude-code-workflow integrates with external tools and skill packs to enhance your development experience.

## Overview

The workflow supports two types of external integrations:

1. **Skill Packs** - Collections of reusable skills (e.g., Superpowers)
2. **CLI Tools** - Command-line utilities that enhance workflow (e.g., RTK)

All integrations are defined in `core/integrations/` as YAML configuration files.

## Supported Integrations

### Superpowers Skill Pack

**Purpose**: Advanced skill pack providing design refinement, TDD enforcement, systematic debugging, and more.

**Installation**:
- Claude Code: `/plugin marketplace add obra/superpowers-marketplace` then `/plugin install superpowers@superpowers-marketplace`
- Cursor: `/plugin-add superpowers`
- Manual: Clone and symlink to your tool's skills directory
**Portable skill IDs exposed by this workflow**:
- `superpowers/brainstorm` - Structured brainstorming and ideation sessions
- `superpowers/tdd` - Test-driven development workflow with red-green-refactor
- `superpowers/refactor` - Systematic refactoring guidance
- `superpowers/debug` - Advanced debugging workflow
- `superpowers/architect` - Architecture design and documentation
- `superpowers/review` - Code review workflow
- `superpowers/optimize` - Performance optimization guidance

The installed Superpowers pack may use different native skill names such as `brainstorming` or `test-driven-development`. Generated target files use the portable IDs from `core/skills/registry.yaml` as the SSOT.

**Configuration**: `core/integrations/superpowers.yaml`

### RTK (Token Optimizer)

**Purpose**: CLI proxy tool that reduces LLM token consumption by 60-90% on common development commands.

**Installation**:
- macOS/Linux: `brew install rtk`
- Cargo: `cargo install --git https://github.com/rtk-ai/rtk`
- Manual download: [GitHub releases](https://github.com/rtk-ai/rtk/releases)

**Initialization**:
```bash
rtk init --global
```

This configures a hook in `~/.claude/settings.json` to transparently intercept commands.
`bin/vibe init` only automates the Homebrew and Cargo paths; for manual installs it prints release instructions instead of executing a remote install script.

**Verification states**:
- **Ready** - RTK binary is installed and the Claude hook is configured
- **Installed, hook not configured** - RTK is present, but `rtk init --global` still needs to run
- **Hook configured, binary not found** - a stale hook exists in `~/.claude/settings.json`, but the RTK binary is not currently available

**Benefits**:
- 60-90% token reduction on command outputs
- <10ms overhead per command
- Works with git, npm, cargo, pytest, jest, and more
- Zero dependencies, single binary

**Configuration**: `core/integrations/rtk.yaml`

## Integration Architecture

```
core/integrations/
├── superpowers.yaml    # Skill pack integration config
├── rtk.yaml            # CLI tool integration config
└── README.md           # This file

Detection & Installation Flow:
1. bin/vibe init [--platform PLATFORM]  # User runs initialization
2. Detect installed tools
3. Distinguish installed vs ready state (platform-aware)
4. Ask user to install or finish configuration
5. Configure hooks/symlinks (platform-specific)
6. Verify installation
```

## Adding a New Integration

### Step 1: Create Configuration File

Create `core/integrations/your-tool.yaml`:

```yaml
schema_version: 1
name: your-tool
type: cli_tool  # or skill_pack
source: https://github.com/author/your-tool
description: Brief description

installation_methods:
  homebrew:
    command: brew install your-tool
    platforms: [macos, linux]

detection:
  binary: your-tool
  version_command: your-tool --version

integration:
  auto_enable: ask_user
  priority: P1

benefits:
  - Benefit 1
  - Benefit 2
```

### Step 2: Implement Detection Logic

Add detection method in `lib/vibe/external_tools.rb`:

```ruby
def detect_your_tool
  return :installed if system("which your-tool > /dev/null 2>&1")
  :not_installed
end
```

### Step 3: Add to Initialization Flow

Update `lib/vibe/init_support.rb` to include your tool in the initialization wizard.

### Step 4: Document Usage

Add usage instructions to this file and update relevant README sections.

## Integration Schema

### Skill Pack Schema

```yaml
schema_version: 1
name: string
type: skill_pack
namespace: string
source: url
description: string

installation_methods:
  <target>:
    preferred: plugin|manual
    commands: [string]
    notes: string

detection:
  paths: [string]
  verification:
    method: string
    sample_skills: [string]

skills:
  - id: string
    intent: string
    trigger_context: string

integration:
  auto_enable: ask_user|always|never
  priority: P0|P1|P2
  fallback_strategy: string
```

### CLI Tool Schema

```yaml
schema_version: 1
name: string
type: cli_tool
source: url
description: string

installation_methods:
  <method>:
    command: string
    platforms: [string]
    notes: string

detection:
  binary: string
  version_command: string
  hook_check:
    file: path
    path: json.path
    contains: string

initialization:
  command: string
  effect: string

integration:
  auto_enable: ask_user|always|never
  priority: P0|P1|P2
  targets:
    <target>:
      method: string
      notes: string

benefits: [string]
```

## Detection Strategy

The workflow uses a multi-level detection strategy:

1. **Binary Check**: Is the tool in PATH?
2. **Config Check**: Is it configured in tool settings?
3. **Path Check**: Does the installation directory exist?
4. **Verification**: Can we invoke a sample command?

## Installation Flow

When `bin/vibe init` is run:

1. **Scan**: Check all integrations in `core/integrations/`
2. **Detect**: Run detection logic for each integration
3. **Report**: Show installation status
4. **Prompt**: Ask user if they want to install missing tools
5. **Install**: Execute installation commands (with user confirmation)
6. **Configure**: Set up hooks, symlinks, or config files
7. **Differentiate**: Report whether each integration is merely installed or fully ready
8. **Verify**: Confirm successful installation

## User Experience

### First-time Setup

```bash
$ bin/vibe init

🚀 Claude Code Workflow Initialization
======================================

Checking your environment...
✓ Claude Code detected at ~/.claude

Checking external integrations...

[1/2] Superpowers Skill Pack
   Status: Not installed
   Would you like to install? [Y/n]: y

   Run these commands in Claude Code:
   /plugin marketplace add obra/superpowers-marketplace
   /plugin install superpowers@superpowers-marketplace

[2/2] RTK (Token Optimizer)
   Status: Not installed
   Would you like to install? [Y/n]: y
   Installing via Homebrew...
   ✓ RTK installed (version 0.x.x)
   ✓ Hook configured

Configuration complete! 🎉
```

If RTK is present but not fully configured, the setup flow now reports that explicitly instead of marking it ready:

```bash
$ bin/vibe init

[2/2] RTK (Token Optimizer)
   Status: Installed, hook not configured
   Binary: /opt/homebrew/bin/rtk
   Hook: Not configured
   Configure RTK hook in ~/.claude/settings.json? [Y/n]:
```

### Verification

```bash
$ bin/vibe init --verify

Verifying integrations...

[✓] Superpowers
    Location: ~/.claude/plugins/superpowers
    Skills: 7 detected
    Status: Ready

[✓] RTK
    Binary: /opt/homebrew/bin/rtk
    Version: 0.x.x
    Hook: Configured
    Status: Ready

All integrations verified! 🎉
```

Partial RTK states are also surfaced during verification:

```bash
$ bin/vibe init --verify

[!] RTK
    Binary: Not found
    Hook: Configured
    Status: Hook configured, but RTK binary was not found
```

## Troubleshooting

### Superpowers Not Detected

1. Check installation: `ls ~/.claude/plugins/superpowers`
2. Check generated docs/manifest: Superpowers portable IDs only appear after detection succeeds
3. Verify in Claude Code: Try invoking the pack-native command for your installation
4. Reinstall: Follow installation commands again

### RTK Hook Not Working

1. Check settings: `cat ~/.claude/settings.json | grep bashCommandPrepare`
2. Reinitialize: `rtk init --global`
3. Restart Claude Code

### RTK Reports Hook Configured But Binary Missing

1. Check whether RTK is still installed: `which rtk`
2. If missing, reinstall RTK using Homebrew, Cargo, or the GitHub releases page
3. Re-run `bin/vibe init --verify` to confirm the state returns to Ready

### Integration Conflicts

If multiple tools provide similar functionality:
- The workflow will prefer the most specific tool
- You can disable integrations by removing their YAML files
- Check `core/integrations/<tool>.yaml` for conflict resolution strategy

## Best Practices

1. **Always verify after installation**: Run `bin/vibe init --verify`
2. **Keep integrations updated**: Check tool repositories for updates
3. **Document custom integrations**: Add your own YAML files for team tools
4. **Test in isolation**: Verify each integration works independently
5. **Review security**: External tools may require additional permissions

## Security Considerations

- **Skill Packs**: Review skills before enabling auto-triggers
- **CLI Tools**: Prefer package managers or reviewed release binaries over remote install scripts
- **Hooks**: Understand what hooks modify in your config
- **Permissions**: Some tools may require additional access

## Future Integrations

Planned integrations:
- Additional skill packs from the community
- Code quality tools (linters, formatters)
- Deployment automation tools
- Testing frameworks

To request a new integration, open an issue at:
https://github.com/nehcuh/claude-code-workflow/issues

---

For more information:
- Superpowers: https://github.com/obra/superpowers
- RTK: https://github.com/rtk-ai/rtk
