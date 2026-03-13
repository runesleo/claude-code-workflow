# Extending Integration Recommendations

This guide explains how to add new recommended integrations to the `bin/vibe init` system.

## Overview

The recommendation system is driven by `core/integrations/recommended.yaml`, which defines:
- **Categories**: Groups of related integrations (skill_packs, system_tools, etc.)
- **Priorities**: P1 (essential), P2 (recommended), P3 (optional)
- **Display metadata**: Icons, labels, and descriptions for each category

## Available Commands

```bash
bin/vibe init --platform PLATFORM --suggest    # Show recommendations for uninstalled tools
bin/vibe init --platform PLATFORM --verify     # Verify what's already installed
bin/vibe init --platform PLATFORM --force      # Force reinstall configuration
bin/vibe doctor                                # Check environment and integration status
```

After running `bin/vibe init --platform PLATFORM`, the system will automatically:
1. Install global configuration
2. Detect installed integrations
3. Prompt to install missing tools (in interactive terminal)

## Adding a New Integration

### Step 1: Create the Integration Specification

Create a new YAML file in `core/integrations/` with the integration details:

```yaml
# core/integrations/my-tool.yaml
schema_version: 1
name: my-tool
type: system_tool  # or skill_pack, linter, formatter, etc.
source: https://github.com/example/my-tool
description: Brief description of what this tool does

installation_methods:
  claude-code:
    preferred: plugin
    commands:
      - /plugin install my-tool
    notes: Installation notes

  manual:
    steps:
      - Clone repository
      - Run installation script
    notes: Fallback method

detection:
  paths:
    - ~/.claude/plugins/my-tool
    - ~/my-tool

benefits:
  - Benefit 1
  - Benefit 2
  - Benefit 3
```

### Step 2: Add Detection Logic

Add a `verify_my_tool` method in `lib/vibe/external_tools.rb`:

```ruby
def verify_my_tool
  # Check if tool is installed
  binary = `which my-tool`.strip

  if binary.empty?
    return { installed: false, ready: false }
  end

  version = `my-tool --version`.strip

  {
    installed: true,
    ready: true,
    binary: binary,
    version: version
  }
end
```

### Step 3: Update Recommended List

Add the integration to `core/integrations/recommended.yaml`:

```yaml
categories:
  system_tools:
    - name: my-tool
      priority: P2
      reason: Brief explanation of why this is recommended
      benefits_summary: One-line summary of key benefits
      platforms: [claude-code, cursor]  # Optional: limit to specific platforms
```

### Step 4: Test the Integration

```bash
# Check if it appears in suggestions
bin/vibe init --platform claude-code --suggest

# Test verification
bin/vibe init --platform claude-code --verify

# Test with a specific platform
bin/vibe init --platform opencode --suggest

# Check overall environment
bin/vibe doctor
```

## Adding a New Category

To add a completely new category (e.g., "formatters"):

### 1. Update `recommended.yaml`

```yaml
categories:
  # ... existing categories ...

  formatters:
    - name: prettier
      priority: P3
      reason: Consistent code formatting
      benefits_summary: Automatic formatting for JS/TS/CSS/HTML

category_order:
  - skill_packs
  - system_tools
  - formatters  # Add to display order

category_metadata:
  formatters:
    label: "Code Formatters"
    description: "Automatic code formatting tools"
    icon: "🎨"
```

### 2. Create Integration Specs

Create `core/integrations/prettier.yaml` with full details.

### 3. Add Detection Logic

Add `verify_prettier` method in `lib/vibe/external_tools.rb`.

## Priority Guidelines

- **P1 (Essential)**: Core tools that significantly enhance the workflow
  - Example: superpowers (adds 7 essential skills)

- **P2 (Recommended)**: Tools that provide clear value but aren't critical
  - Example: rtk (token optimization)

- **P3 (Optional)**: Nice-to-have tools for specific use cases
  - Example: linters, formatters, specialized tools

## Platform Filtering

Limit recommendations to specific platforms:

```yaml
- name: my-tool
  priority: P2
  reason: Platform-specific feature
  platforms: [claude-code, cursor]  # Only suggest for these platforms
```

If `platforms` is omitted, the tool is suggested for all platforms.

## Best Practices

1. **Keep descriptions concise**: One line for `reason`, one line for `benefits_summary`
2. **Provide clear installation paths**: Prefer automated methods over manual steps
3. **Test detection logic**: Ensure `verify_*` methods handle edge cases
4. **Document benefits**: List 3-5 concrete benefits in the integration spec
5. **Set appropriate priorities**: Don't mark everything as P1

## Example: Adding Rubocop

```yaml
# core/integrations/rubocop.yaml
schema_version: 1
name: rubocop
type: linter
source: https://github.com/rubocop/rubocop
description: Ruby code style checker and formatter

installation_methods:
  manual:
    steps:
      - gem install rubocop
    notes: Requires Ruby 2.7+

detection:
  paths:
    - Check if `rubocop` is in PATH

benefits:
  - Enforces consistent Ruby style
  - Catches common mistakes
  - Auto-fixes many issues
```

```yaml
# core/integrations/recommended.yaml
categories:
  linters:
    - name: rubocop
      priority: P3
      reason: Ruby code style enforcement
      benefits_summary: Consistent style and automatic fixes
      min_version: "1.50.0"
```

```ruby
# lib/vibe/external_tools.rb
def verify_rubocop
  binary = `which rubocop`.strip
  return { installed: false, ready: false } if binary.empty?

  version = `rubocop --version`.strip.split.last

  {
    installed: true,
    ready: true,
    binary: binary,
    version: version
  }
end
```

## Maintenance

When an integration becomes outdated:

1. Update the `source` URL in its YAML spec
2. Update `installation_methods` if commands changed
3. Adjust `priority` if relevance changed
4. Or remove it entirely from `recommended.yaml`

No code changes needed—just update the configuration files!
