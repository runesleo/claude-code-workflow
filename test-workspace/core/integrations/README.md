# Integration Configurations

This directory contains YAML configuration files for external tool integrations.

## Purpose

Integration configs define how external tools and skill packs are:
- Detected in the user's environment
- Installed and configured
- Integrated into the workflow
- Verified for correct operation

## Structure

Each integration is defined in a separate YAML file:

```
core/integrations/
├── README.md              # This file
├── superpowers.yaml       # Superpowers skill pack
└── rtk.yaml               # RTK token optimizer
```

## Schema Types

### Skill Pack Integration

For external skill collections (e.g., Superpowers):

```yaml
schema_version: 1
name: tool-name
type: skill_pack
namespace: namespace-name
source: github-url
description: Brief description

installation_methods: {...}
detection: {...}
skills: [...]
integration: {...}
```

### CLI Tool Integration

For command-line utilities (e.g., RTK):

```yaml
schema_version: 1
name: tool-name
type: cli_tool
source: github-url
description: Brief description

installation_methods: {...}
detection: {...}
initialization: {...}
integration: {...}
benefits: [...]
```

## Adding New Integrations

1. Create `your-tool.yaml` in this directory
2. Follow the appropriate schema (skill_pack or cli_tool)
3. Implement detection logic in `lib/vibe/external_tools.rb`
4. Add to initialization flow in `lib/vibe/init_support.rb`
5. Document in `docs/integrations.md`

## Usage

These configs are consumed by:
- `bin/vibe init` - Initialization wizard
- `bin/vibe init --verify` - Verification command
- `lib/vibe/external_tools.rb` - Detection and installation logic

## Validation

To validate your integration config:

```bash
ruby -ryaml -e "YAML.load_file('core/integrations/your-tool.yaml')"
```

## See Also

- [Integration Documentation](../../docs/integrations.md) - User-facing integration guide
- [External Tools Module](../../lib/vibe/external_tools.rb) - Detection implementation
- [Init Support Module](../../lib/vibe/init_support.rb) - Installation flow
