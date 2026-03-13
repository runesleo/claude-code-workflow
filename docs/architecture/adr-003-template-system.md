# ADR-003: Template System Design

## Status
Proposed

## Context

The current rendering system embeds all templates as Ruby heredocs within the source code. This creates several maintainability issues:

### Current Problems

1. **Template Scattering**: Markdown templates are embedded in:
   - `target_renderers.rb` (entrypoint templates, integration sections)
   - `doc_rendering.rb` (documentation templates)
   - `native_configs.rb` (JSON configuration templates)

2. **No Template Reuse**: Common sections (integration blocks, policy lists) are duplicated across targets with minor variations.

3. **Poor Editor Support**: Embedded heredocs don't benefit from:
   - Syntax highlighting for Markdown/JSON
   - Linting and validation
   - Template preview

4. **Hardcoded Logic**: Template variations (like target-specific integration formatting) require code changes rather than configuration.

## Decision

Implement a file-based ERB template system with the following structure:

### Directory Layout

```
templates/
├── targets/
│   ├── claude-code/
│   │   ├── global.md.erb          # Global entrypoint
│   │   ├── project.md.erb         # Project entrypoint
│   │   ├── settings.json.erb      # Native config
│   │   └── _sidebar.md.erb        # Target-specific partial
│   ├── cursor/
│   │   ├── global.md.erb
│   │   ├── project.md.erb
│   │   ├── 00-vibe-core.mdc.erb
│   │   ├── 05-vibe-routing.mdc.erb
│   │   └── ...
│   └── ...
├── docs/
│   ├── behavior.md.erb
│   ├── routing.md.erb
│   ├── safety.md.erb
│   ├── skills.md.erb
│   └── ...
├── shared/
│   ├── _header.md.erb             # Common header with generation metadata
│   ├── _policy_list.md.erb        # Policy bullet list
│   ├── _skill_list.md.erb         # Skill bullet list
│   ├── _integration_superpowers.md.erb
│   └── _integration_rtk.md.erb
└── native_configs/
    ├── _base_permissions.json.erb
    └── ...
```

### Template API

Templates receive a `context` object with:

```ruby
class TemplateContext
  attr_reader :manifest, :target, :mode, :helpers

  def initialize(manifest:, target:, mode:, helpers:)
    @manifest = manifest
    @target = target
    @mode = mode
    @helpers = helpers
  end

  # Convenience accessors
  def profile; manifest["profile"]; end
  def policies; manifest["policies"]; end
  def skills; manifest["skills"]; end
  def overlay_sentence; helpers.overlay_sentence(manifest); end

  # Integration checks
  def superpowers_installed?
    skills.any? { |s| s["namespace"] == "superpowers" }
  end

  def rtk_installed?
    manifest.dig("integrations", "rtk", "installed")
  end
end
```

### Template Helpers

```ruby
module TemplateHelpers
  def bullet_policy_summary(policies)
    return "- none" if policies.empty?
    policies.map { |p| "- `#{p['id']}` (#{p['enforcement']}) — #{p['summary']}" }.join("\n")
  end

  def bullet_skill_summary(skills)
    return "- none" if skills.empty?
    skills.map { |s| "- `#{s['id']}` — #{s['intent']}" }.join("\n")
  end

  def bullet_mapping(mapping)
    mapping.map { |tier, executor| "- `#{tier}` → `#{executor}`" }.join("\n")
  end

  def integration_section(integration_name, config)
    # Renders appropriate partial based on integration and target
  end
end
```

### Example Templates

**global.md.erb** (Claude Code):
```erb
# Vibe workflow for <%= target.display_name %>

Generated from the portable `core/` spec with profile `<%= profile %>`.<%= context.superpowers_installed? ? "\n\n" + render("shared/_integration_superpowers.md.erb") : "" %>
Applied overlay: <%= overlay_sentence %>

<%= target.entrypoint_intent %>

## Non-negotiable rules

<%= bullet_policy_summary(policies.select { |p| %w[always_on routing safety].include?(p["target_render_group"]) }) %>

## Capability routing

<%= bullet_mapping(manifest["profile_mapping"]) %>

## Mandatory portable skills

<%= bullet_skill_summary(skills.select { |s| s["trigger_mode"] == "mandatory" }) %>

## Safety floor

<%= bullet_target_actions(manifest) %>
```

**_integration_superpowers.md.erb** (Shared partial):
```erb
## Optional Integrations

### Superpowers Skill Pack

<% if context.superpowers_installed? %>
**Status**: ✅ Installed (<%= superpowers_location %>)

The following Superpowers skills are available:
<%= format_superpowers_skill_bullets %>
<% else %>
**Status**: ❌ Not installed

Superpowers provides advanced skills for design refinement, TDD, debugging, and more.

**Installation**:
```bash
<%= superpowers_install_note(target) %>
```
<% end %>
```

### Template Engine

```ruby
module Vibe
  class TemplateEngine
    def initialize(base_path)
      @base_path = base_path
      @cache = {}
    end

    def render(template_path, context)
      template = load_template(template_path)
      erb = ERB.new(template, trim_mode: "-")
      erb.result(context.binding)
    end

    def render_inline(content, context)
      erb = ERB.new(content, trim_mode: "-")
      erb.result(context.binding)
    end

    private

    def load_template(path)
      @cache[path] ||= File.read(File.join(@base_path, path))
    end
  end
end
```

### Template Validation

Add template validation to catch errors early:

```ruby
class TemplateValidator
  def validate(template_path)
    errors = []

    # Check ERB syntax
    begin
      ERB.new(File.read(template_path), trim_mode: "-")
    rescue SyntaxError => e
      errors << "ERB syntax error: #{e.message}"
    end

    # Check for undefined variables (basic static analysis)
    content = File.read(template_path)
    context_methods = TemplateContext.instance_methods

    content.scan(/<%=?\s*(\w+)/).each do |match|
      var = match[0]
      unless context_methods.include?(var.to_sym) || local_variable?(var)
        errors << "Potentially undefined variable: #{var}"
      end
    end

    errors
  end
end
```

## Consequences

### Positive

1. **Editor Support**: Templates are standalone files with proper syntax highlighting
2. **Reusability**: Shared partials reduce duplication
3. **Separation of Concerns**: Presentation logic separated from rendering logic
4. **Testability**: Templates can be unit tested in isolation
5. **Non-developer Friendly**: Technical writers can modify templates without Ruby knowledge

### Negative

1. **File Proliferation**: More files to manage (mitigated by clear organization)
2. **Performance**: File I/O for template loading (mitigated by caching)
3. **Debugging**: ERB errors can be cryptic (mitigated by validation)

### Migration Strategy

**Phase 1: Infrastructure**
- Create `templates/` directory structure
- Implement `TemplateEngine` and `TemplateContext`
- Add template validation

**Phase 2: Extract Templates**
- Convert one target's templates (Claude Code)
- Run both old and new renderers, compare outputs
- Fix discrepancies

**Phase 3: Migrate All Targets**
- Extract templates for remaining targets
- Remove heredocs from Ruby files

**Phase 4: Shared Partials**
- Identify common patterns
- Extract to shared partials
- Update templates to use partials

## Related Decisions

- ADR-001: Configuration-Driven Target Renderer Architecture
- ADR-002: Overlay System Improvements
