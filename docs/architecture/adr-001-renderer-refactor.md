# ADR-001: Configuration-Driven Target Renderer Architecture

## Status
Proposed

## Context

The current target renderer system in `lib/vibe/target_renderers.rb` has grown to 1149 lines with 8 platform renderers (Claude Code, OpenCode, Cursor, Kimi Code, VS Code, Warp, Antigravity, Codex CLI). Each renderer contains 100-200 lines of similar code with significant duplication.

### Current Problems

#### 1. Code Duplication Patterns

**Global vs Project Mode Duplication (Lines 45-124)**
Each target implements separate `render_*_global` and `render_*_project` methods with nearly identical structure:

```ruby
# Pattern repeated for all 8 targets
def render_claude(output_root, manifest, project_level: false)
  if project_level
    render_claude_project(output_root, manifest)
  else
    render_claude_global(output_root, manifest)
  end
end
```

The project-level methods differ only in:
- Which doc types are written (subset of global)
- Whether native configs (settings.json) are generated
- The entrypoint markdown template used

**Directory Creation Duplication**
Every global renderer repeats the same pattern:
```ruby
target_dir = File.join(output_root, ".vibe", "target-name")
FileUtils.mkdir_p(target_dir)
write_target_docs(target_dir, manifest, %i[behavior routing ...])
```

**Entrypoint Markdown Duplication (Lines 755-780, 435-462, etc.)**
Each target has nearly identical project markdown templates with only:
- Target name changes
- File path changes (`.vibe/{target}/`)
- Slight variations in reference doc listings

#### 2. Integration Rendering Complexity (Lines 808-1146)

The Superpowers and RTK integration sections contain 164 lines of nested conditionals with target-specific templates:

```ruby
INTEGRATION_TEMPLATES = {
  "kimi-code" => { superpowers: { ... }, rtk: { ... } },
  "warp" => { superpowers: { ... }, rtk: { ... } },
  :default => { ... }
}
```

This approach:
- Scatters target-specific knowledge across multiple data structures
- Requires code changes to add new integration templates
- Makes it difficult to understand what each target renders

#### 3. Extension Point Problems

**Adding a new target requires:**
1. Adding two methods (`render_target_global`, `render_target_project`) - ~150 lines
2. Adding entrypoint markdown method - ~30 lines
3. Adding to the case statement in `builder.rb` - 1 line
4. Adding integration templates if needed - ~20 lines
5. Adding native config methods in `native_configs.rb` - ~40 lines

**Total: ~240 lines of code for one target**

**Adding a new doc type requires:**
1. Adding to `write_target_docs` case statement
2. Adding render method in `doc_rendering.rb`
3. Updating all target doc type arrays that should include it

#### 4. Overlay Application Opacity

Overlays are applied opaquely in `builder.rb`:
```ruby
native_config_overlay = overlay_target_patch(overlay, target)
```

There's no visibility into:
- What overlays modify for each target
- Whether overlay patches are valid for the target's schema
- How overlays affect different rendering modes (global vs project)

### Root Causes

1. **Lack of declarative target definition**: Targets are defined by imperative code rather than configuration
2. **No separation of concerns**: File generation, content formatting, and target-specific logic are intertwined
3. **Template scattering**: Markdown templates are embedded in Ruby strings across multiple files
4. **Implicit conventions**: Directory structures and file naming are hardcoded throughout

## Decision

Refactor to a **configuration-driven renderer architecture** with four layers:

### Layer 1: Target Configuration Schema (YAML)

Define each target declaratively:

```yaml
# core/targets/claude-code.yaml
target_id: claude-code
display_name: Claude Code
output_paths:
  global:
    base: "."
    support_dir: ".vibe/claude-code"
    native_config: "settings.json"
  project:
    base: "."
    support_dir: ".vibe/claude-code"

doc_types:
  global: [behavior, safety, task_routing, test_standards]
  project: [behavior, safety, task_routing, test_standards]

entrypoint:
  global:
    filename: "CLAUDE.md"
    template: "claude-code/global.md.erb"
  project:
    filename: "CLAUDE.md"
    template: "claude-code/project.md.erb"

native_config:
  type: "json"
  template: "claude-code/settings.json.erb"
  schema: "claude-code/settings.schema.json"

integrations:
  superpowers:
    header_style: nested
    show_full_details: false
  rtk:
    header_style: nested
    show_warp_note: false

file_operations:
  global:
    - type: copy_tree
      source: ["rules", "docs", "skills", "agents", "commands", "memory"]
      destination: "."
    - type: conditional_copy
      condition: superpowers_installed
      source: "rules/skill-triggers.md"
      destination: "rules/skill-triggers.md"
      transform: append_superpowers_section
```

### Layer 2: Renderer Engine (Ruby)

A generic renderer that interprets target configurations:

```ruby
module Vibe
  class TargetRenderer
    def initialize(target_config, manifest)
      @config = target_config
      @manifest = manifest
    end

    def render(output_root, mode: :global)
      paths = @config.output_paths[mode]

      # Create directories
      ensure_directories(output_root, paths)

      # Write documentation
      @config.doc_types[mode].each do |doc_type|
        write_doc(output_root, paths.support_dir, doc_type)
      end

      # Generate native config
      if @config.native_config && mode == :global
        write_native_config(output_root, paths.native_config)
      end

      # Execute file operations
      @config.file_operations[mode]&.each do |op|
        execute_file_operation(output_root, op)
      end

      # Write entrypoint
      write_entrypoint(output_root, paths.base, mode)
    end
  end
end
```

### Layer 3: Template System (ERB)

Extract all markdown and JSON templates to separate files:

```
templates/
├── claude-code/
│   ├── global.md.erb
│   ├── project.md.erb
│   └── settings.json.erb
├── cursor/
│   ├── global.md.erb
│   ├── project.md.erb
│   └── 00-vibe-core.mdc.erb
└── _shared/
    ├── _integration_superpowers.md.erb
    ├── _integration_rtk.md.erb
    └── _policy_list.md.erb
```

### Layer 4: Integration Plugins

Convert integration rendering to a plugin system:

```ruby
module Vibe
  module IntegrationPlugins
    class SuperpowersPlugin < BasePlugin
      def self.applicable?(manifest)
        manifest["skills"].any? { |s| s["namespace"] == "superpowers" }
      end

      def render_section(target_config, mode)
        # Plugin determines how to render for each target
      end
    end
  end
end
```

## Consequences

### Positive

1. **Reduced code for new targets**: From ~240 lines to ~40 lines (YAML config + templates)
2. **Single source of truth**: Target behavior defined in one configuration file
3. **Easier testing**: Configuration validation separate from rendering logic
4. **Template reuse**: Shared partials for common sections
5. **Clear extension points**: New targets, doc types, and integrations have defined schemas

### Negative

1. **Migration effort**: ~2-3 days to refactor existing renderers
2. **Template overhead**: More files to manage (though better organized)
3. **YAML complexity**: Need validation and schema for target configs
4. **Runtime overhead**: Configuration loading and ERB rendering (minimal)

### Migration Strategy

**Phase 1: Infrastructure (Day 1)**
- Create `TargetRenderer` class
- Create `TargetConfig` schema and loader
- Set up template directory structure

**Phase 2: Parallel Implementation (Days 2-3)**
- Implement one target (Claude Code) using new system
- Keep old renderers as fallback
- Compare outputs for parity

**Phase 3: Migration (Days 4-5)**
- Convert remaining targets one by one
- Add configuration validation
- Update tests

**Phase 4: Cleanup (Day 6)**
- Remove old renderer methods
- Remove embedded templates
- Update documentation

## Related Decisions

- ADR-002: Overlay System Improvements
- ADR-003: Template System Design
