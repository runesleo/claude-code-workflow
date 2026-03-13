# Migration Plan: Configuration-Driven Renderer Architecture

## Overview

This document outlines the incremental migration from the current imperative renderer implementation to the proposed configuration-driven architecture.

**Estimated Duration**: 6 days
**Risk Level**: Low (backward compatible, parallel implementation)
**Rollback Strategy**: Keep old renderers until new system is fully validated

## Phase 1: Infrastructure (Day 1)

### 1.1 Create Directory Structure

```bash
mkdir -p core/targets/schemas
touch core/targets/.gitkeep

mkdir -p templates/targets
touch templates/targets/.gitkeep

mkdir -p templates/docs
touch templates/docs/.gitkeep

mkdir -p templates/shared
touch templates/shared/.gitkeep

mkdir -p lib/vibe/renderers
touch lib/vibe/renderers/.gitkeep
```

### 1.2 Implement TargetConfig Loader

**File**: `lib/vibe/target_config.rb`

```ruby
module Vibe
  class TargetConfig
    attr_reader :target_id, :display_name, :output_paths, :doc_types,
                :entrypoint, :native_config, :file_operations, :integrations

    def self.load(target_id, repo_root)
      path = File.join(repo_root, "core", "targets", "#{target_id}.yaml")
      raise ConfigurationError, "Target config not found: #{target_id}" unless File.exist?(path)

      yaml = YAML.safe_load(File.read(path), aliases: true)
      new(yaml)
    end

    def initialize(config)
      @raw = config
      @target_id = config["target_id"]
      @display_name = config["display_name"]
      @output_paths = OutputPaths.new(config["output_paths"])
      @doc_types = config["doc_types"] || {}
      @entrypoint = EntrypointConfig.new(config["entrypoint"])
      @native_config = NativeConfig.new(config["native_config"]) if config["native_config"]
      @file_operations = config["file_operations"] || {}
      @integrations = config["integrations"] || {}
    end

    def output_paths_for(mode)
      mode == :project ? output_paths.project : output_paths.global
    end

    def doc_types_for(mode)
      mode == :project ? doc_types["project"] : doc_types["global"]
    end

    def file_operations_for(mode)
      mode == :project ? file_operations["project"] : file_operations["global"]
    end

    class OutputPaths
      attr_reader :global, :project

      def initialize(config)
        @global = OpenStruct.new(config["global"])
        @project = config["project"] ? OpenStruct.new(config["project"]) : @global
      end
    end

    class EntrypointConfig
      attr_reader :global, :project

      def initialize(config)
        @global = OpenStruct.new(config["global"]) if config["global"]
        @project = OpenStruct.new(config["project"]) if config["project"]
      end
    end

    class NativeConfig
      attr_reader :type, :template, :schema, :project_template

      def initialize(config)
        @type = config["type"]
        @template = config["template"]
        @schema = config["schema"]
        @project_template = config["project_template"]
        @project_only = config["project_only"] || false
        @global_only = config["global_only"] || false
      end

      def applies_to?(mode)
        return false if @project_only && mode != :project
        return false if @global_only && mode != :global
        true
      end
    end
  end
end
```

### 1.3 Implement TemplateEngine

**File**: `lib/vibe/template_engine.rb`

```ruby
require "erb"

module Vibe
  class TemplateEngine
    def initialize(base_path)
      @base_path = base_path
      @cache = {}
    end

    def render(template_path, context)
      full_path = File.join(@base_path, template_path)
      raise TemplateError, "Template not found: #{template_path}" unless File.exist?(full_path)

      template = load_template(full_path)
      erb = ERB.new(template, trim_mode: "-")
      erb.result(context.get_binding)
    rescue SyntaxError => e
      raise TemplateError, "Syntax error in template #{template_path}: #{e.message}"
    end

    def render_string(content, context)
      erb = ERB.new(content, trim_mode: "-")
      erb.result(context.get_binding)
    end

    private

    def load_template(path)
      @cache[path] ||= File.read(path)
    end
  end

  class TemplateContext
    include TemplateHelpers

    attr_reader :manifest, :target, :mode

    def initialize(manifest:, target_config:, mode:, repo_root:)
      @manifest = manifest
      @target = target_config
      @mode = mode
      @repo_root = repo_root
    end

    def get_binding
      binding
    end

    def profile
      manifest["profile"]
    end

    def policies
      manifest["policies"]
    end

    def skills
      manifest["skills"]
    end

    def overlay_sentence
      overlay = manifest["overlay"]
      return "`none`" if overlay.nil?
      "`#{overlay["name"]}` from `#{overlay["display_path"]}`"
    end

    def superpowers_installed?
      skills.any? { |s| s["namespace"] == "superpowers" }
    end

    def rtk_installed?
      manifest.dig("integrations", "rtk", "installed") == true
    end
  end
end
```

### 1.4 Implement TemplateHelpers

**File**: `lib/vibe/template_helpers.rb`

```ruby
module Vibe
  module TemplateHelpers
    def bullet_policy_summary(policies)
      return "- none" if policies.nil? || policies.empty?

      policies.map do |policy|
        "- `#{policy["id"]}` (`#{policy["enforcement"]}`) — #{policy["summary"]}"
      end.join("\n")
    end

    def bullet_skill_summary(skills)
      return "- none" if skills.nil? || skills.empty?

      skills.map do |skill|
        "- `#{skill["id"]}` (`#{skill["priority"]}`) — #{skill["intent"]}"
      end.join("\n")
    end

    def bullet_mapping(mapping)
      return "- none" if mapping.nil? || mapping.empty?

      mapping.map do |tier, executor|
        "- `#{tier}` → `#{executor}`"
      end.join("\n")
    end

    def bullet_target_actions(manifest)
      actions = manifest.dig("security", "target_actions")
      return "- none" if actions.nil? || actions.empty?

      actions.map do |severity, action|
        "- `#{severity}` — #{action}"
      end.join("\n")
    end

    def render_partial(partial_name, locals = {})
      # To be implemented with template engine
    end
  end
end
```

### Deliverables

- [ ] `lib/vibe/target_config.rb` - Target configuration loader
- [ ] `lib/vibe/template_engine.rb` - ERB template rendering
- [ ] `lib/vibe/template_helpers.rb` - Helper methods for templates
- [ ] `lib/vibe/template_context.rb` - Context object for templates
- [ ] Unit tests for all new classes

## Phase 2: Parallel Implementation (Days 2-3)

### 2.1 Create Claude Code Target Configuration

**File**: `core/targets/claude-code.yaml`

```yaml
schema_version: 1
target_id: claude-code
display_name: Claude Code
description: Anthropic's official CLI for Claude

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
    template: "targets/claude-code/global.md.erb"
    intent_template: "Keep repository files as the SSOT, verify before claiming completion, and follow the generated routing + safety rules."
  project:
    filename: "CLAUDE.md"
    template: "targets/claude-code/project.md.erb"

native_config:
  type: json
  template: "targets/claude-code/settings.json.erb"

file_operations:
  global:
    - type: copy_tree
      source: [rules, docs, skills, agents, commands, memory]
      destination: "."
    - type: conditional_copy
      condition: superpowers_installed
      source: "rules/skill-triggers.md"
      destination: "rules/skill-triggers.md"
      transform: append_superpowers_section

integrations:
  superpowers:
    header_style: nested
    show_full_details: false
  rtk:
    header_style: nested
    show_version: true

template_variables:
  config_dir: "~/.claude"
  supports_hooks: true
  supports_skills: true
```

### 2.2 Create Claude Code Templates

**File**: `templates/targets/claude-code/global.md.erb`

```erb
# Vibe workflow for <%= target.display_name %>

Generated from the portable `core/` spec with profile `<%= profile %>`.<%= superpowers_installed? ? "\n\n" + render_partial("shared/_integration_superpowers.md.erb") : "" %>
Applied overlay: <%= overlay_sentence %>

<%= target.entrypoint.global.intent_template %>

## Non-negotiable rules

<%= bullet_policy_summary(policies.select { |p| %w[always_on routing safety].include?(p["target_render_group"]) }) %>

## Capability routing

<%= bullet_mapping(manifest["profile_mapping"]) %>

## Mandatory portable skills

<%= bullet_skill_summary(skills.select { |s| s["trigger_mode"] == "mandatory" }) %>

## Safety floor

<%= bullet_target_actions(manifest) %>
```

**File**: `templates/targets/claude-code/project.md.erb`

```erb
# Project <%= target.display_name %> Configuration

Generated from the portable `core/` spec with profile `<%= profile %>`.
Applied overlay: <%= overlay_sentence %>

Global workflow rules are loaded from `~/.claude/`. This file adds project-specific context only.

## Project Context

<!-- Describe your project: tech stack, architecture, key constraints -->

## Project-specific rules

<!-- Add rules that apply only to this project -->

## Reference docs

Supporting notes are under `.vibe/claude-code/`:
- `behavior-policies.md` — portable behavior baseline
- `safety.md` — safety policy
- `task-routing.md` — task complexity routing
- `test-standards.md` — testing requirements
```

**File**: `templates/targets/claude-code/settings.json.erb`

```erb
{
  "permissions": {
    "defaultMode": "default",
    "disableBypassPermissionsMode": "disable",
    "ask": [
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(scp:*)",
      "Bash(rsync:*)",
      "Bash(git push:*)",
      "Bash(npm publish:*)",
      "Bash(base64:*)",
      "Bash(eval:*)",
      "Bash(exec:*)",
      "WebFetch",
      "Write(./production/**)"
    ],
    "deny": [
      "Bash(rm -rf:*)",
      "Bash(shred:*)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(./**/*.key)",
      "Write(./**/.env*)",
      "Write(./**/*.key)"
    ]
  }
}
```

### 2.3 Implement New TargetRenderer

**File**: `lib/vibe/renderers/target_renderer.rb`

```ruby
module Vibe
  module Renderers
    class TargetRenderer
      COPY_RUNTIME_ENTRIES = %w[rules docs skills agents commands memory].freeze

      def initialize(repo_root)
        @repo_root = repo_root
        @template_engine = TemplateEngine.new(File.join(repo_root, "templates"))
      end

      def render(target_id, output_root, manifest, mode: :global)
        config = TargetConfig.load(target_id, @repo_root)
        paths = config.output_paths_for(mode)

        # Create directories
        ensure_directories(output_root, paths, config)

        # Write documentation
        doc_types = config.doc_types_for(mode) || []
        doc_types.each do |doc_type|
          write_doc(output_root, paths.support_dir, doc_type, manifest)
        end

        # Generate native config
        if config.native_config && config.native_config.applies_to?(mode)
          write_native_config(output_root, config.native_config, paths.native_config, manifest)
        end

        # Execute file operations (global mode only)
        if mode == :global
          execute_file_operations(output_root, config.file_operations_for(mode), manifest)
        end

        # Write entrypoint
        entrypoint_config = mode == :project ? config.entrypoint.project : config.entrypoint.global
        write_entrypoint(output_root, paths.base, entrypoint_config, manifest, config, mode)

        manifest
      end

      private

      def ensure_directories(output_root, paths, config)
        FileUtils.mkdir_p(File.join(output_root, paths.support_dir)) if paths.support_dir
        FileUtils.mkdir_p(File.join(output_root, paths.rules_dir)) if paths.rules_dir
        FileUtils.mkdir_p(File.join(output_root, paths.skills_dir)) if paths.skills_dir
      end

      def write_doc(output_root, support_dir, doc_type, manifest)
        filename = doc_filename(doc_type)
        template = "docs/#{doc_type}.md.erb"

        context = TemplateContext.new(manifest: manifest, target_config: nil, mode: nil, repo_root: @repo_root)
        content = @template_engine.render(template, context)

        File.write(File.join(output_root, support_dir, filename), content)
      end

      def doc_filename(doc_type)
        case doc_type
        when :behavior then "behavior-policies.md"
        when :execution_policy then "execution-policy.md"
        when :execution then "execution.md"
        else "#{doc_type.to_s.gsub('_', '-')}.md"
        end
      end

      def write_native_config(output_root, native_config, output_path, manifest)
        context = TemplateContext.new(manifest: manifest, target_config: nil, mode: nil, repo_root: @repo_root)
        content = @template_engine.render(native_config.template, context)

        # Parse and re-format to ensure valid JSON
        if native_config.type == "json"
          data = JSON.parse(content)
          content = JSON.pretty_generate(data)
        end

        File.write(File.join(output_root, output_path), content)
      end

      def execute_file_operations(output_root, operations, manifest)
        return unless operations

        operations.each do |op|
          next unless evaluate_condition(op["condition"], manifest)

          case op["type"]
          when "copy_tree"
            execute_copy_tree(output_root, op, manifest)
          when "conditional_copy"
            execute_conditional_copy(output_root, op, manifest)
          when "mkdir"
            FileUtils.mkdir_p(File.join(output_root, op["destination"]))
          end
        end
      end

      def evaluate_condition(condition, manifest)
        return true if condition.nil? || condition == "always"

        case condition
        when "superpowers_installed"
          manifest["skills"].any? { |s| s["namespace"] == "superpowers" }
        when "rtk_installed"
          manifest.dig("integrations", "rtk", "installed") == true
        else
          true
        end
      end

      def execute_copy_tree(output_root, op, manifest)
        Array(op["source"]).each do |source|
          source_path = File.join(@repo_root, source)
          next unless File.exist?(source_path)

          dest_path = File.join(output_root, op["destination"], source)
          FileUtils.mkdir_p(File.dirname(dest_path))

          if File.directory?(source_path)
            FileUtils.mkdir_p(dest_path)
            # Copy directory contents
          else
            FileUtils.cp(source_path, dest_path)
          end
        end
      end

      def write_entrypoint(output_root, base_path, entrypoint_config, manifest, target_config, mode)
        context = TemplateContext.new(
          manifest: manifest,
          target_config: target_config,
          mode: mode,
          repo_root: @repo_root
        )

        content = @template_engine.render(entrypoint_config.template, context)
        File.write(File.join(output_root, base_path, entrypoint_config.filename), content)
      end
    end
  end
end
```

### 2.4 Compare Outputs

Create a test script to compare old and new renderer outputs:

**File**: `test/renderer_comparison_test.rb`

```ruby
require_relative "test_helper"

class RendererComparisonTest < Minitest::Test
  def setup
    @repo_root = File.expand_path("../..", __FILE__)
    @old_output = File.join(@repo_root, "test/output/old/claude-code")
    @new_output = File.join(@repo_root, "test/output/new/claude-code")

    FileUtils.rm_rf([@old_output, @new_output])
    FileUtils.mkdir_p([@old_output, @new_output])
  end

  def test_claude_code_output_matches
    # Generate with old renderer
    generate_with_old_renderer(@old_output)

    # Generate with new renderer
    generate_with_new_renderer(@new_output)

    # Compare file lists
    old_files = list_files(@old_output).sort
    new_files = list_files(@new_output).sort

    assert_equal old_files, new_files, "File lists should match"

    # Compare file contents
    old_files.each do |file|
      old_content = File.read(File.join(@old_output, file))
      new_content = File.read(File.join(@new_output, file))

      # Normalize whitespace for comparison
      old_normalized = normalize_content(old_content)
      new_normalized = normalize_content(new_content)

      assert_equal old_normalized, new_normalized, "Content mismatch in #{file}"
    end
  end

  private

  def generate_with_old_renderer(output_root)
    # Use existing build_target method
  end

  def generate_with_new_renderer(output_root)
    renderer = Vibe::Renderers::TargetRenderer.new(@repo_root)
    # Load manifest and render
  end

  def list_files(dir)
    Dir.glob("**/*", base: dir).select { |f| File.file?(File.join(dir, f)) }
  end

  def normalize_content(content)
    content.gsub(/\r\n/, "\n")        # Normalize line endings
         .gsub(/\n+/, "\n")           # Collapse multiple newlines
         .gsub(/Generated at: .*/, "Generated at: TIMESTAMP")  # Normalize timestamps
         .strip
  end
end
```

### Deliverables

- [ ] Claude Code target configuration
- [ ] Claude Code templates (global, project, settings.json)
- [ ] New TargetRenderer implementation
- [ ] Comparison test script
- [ ] Parity verified between old and new renderers

## Phase 3: Migration (Days 4-5)

### 3.1 Convert Remaining Targets

For each target (Cursor, Codex CLI, Kimi Code, OpenCode, Warp, Antigravity, VS Code):

1. Create target configuration YAML
2. Create templates (global.md.erb, project.md.erb, native config)
3. Run comparison test
4. Fix discrepancies

**Priority order**:
1. Cursor (similar to Claude Code)
2. VS Code (simple structure)
3. OpenCode (JSON config)
4. Codex CLI (AGENTS.md based)
5. Warp (WARP.md based)
6. Antigravity (AGENTS.md based)
7. Kimi Code (complex skill generation)

### 3.2 Update Builder Integration

**File**: `lib/vibe/builder.rb` (modifications)

```ruby
def build_target(target:, profile_name:, profile:, output_root:, overlay:, project_level: false)
  ensure_safe_output_path!(output_root)

  manifest = build_manifest(
    target: target,
    profile_name: profile_name,
    profile: profile,
    output_root: output_root,
    overlay: overlay
  )

  FileUtils.rm_rf(output_root)
  FileUtils.mkdir_p(output_root)

  # Use new renderer if target config exists
  config_path = File.join(@repo_root, "core", "targets", "#{target}.yaml")
  if File.exist?(config_path)
    renderer = Vibe::Renderers::TargetRenderer.new(@repo_root)
    renderer.render(target, output_root, manifest, mode: project_level ? :project : :global)
  else
    # Fall back to old renderer
    case target
    when "claude-code" then render_claude(output_root, manifest, project_level: project_level)
    # ... other targets
    end
  end

  # Write manifest and summary
  vibe_dir = File.join(output_root, ".vibe")
  FileUtils.mkdir_p(vibe_dir)
  write_json(File.join(vibe_dir, "manifest.json"), manifest)
  File.write(File.join(vibe_dir, "target-summary.md"), render_target_summary(manifest))

  manifest
end
```

### 3.3 Update Tests

- Migrate existing tests to use new renderer
- Add unit tests for TargetConfig
- Add unit tests for TemplateEngine
- Add integration tests for each target

### Deliverables

- [ ] All 8 targets converted
- [ ] Builder integration updated
- [ ] All tests passing
- [ ] No regressions in output

## Phase 4: Cleanup (Day 6)

### 4.1 Remove Old Renderer Code

**Files to modify**:
- `lib/vibe/target_renderers.rb` - Remove all render_* methods
- `lib/vibe/native_configs.rb` - Remove if fully migrated to templates
- `lib/vibe/doc_rendering.rb` - Keep only shared helper methods

**Keep for backward compatibility**:
- Method signatures in modules that include TargetRenderers
- Delegate to new renderer

### 4.2 Update Documentation

- Update ARCHITECTURE.md with new design
- Update CONTRIBUTING.md with template guidelines
- Add template authoring guide

### 4.3 Final Verification

```bash
# Run full test suite
bundle exec rake test

# Generate all targets and verify
bin/vibe build-all
diff -r generated/claude-code test/fixtures/expected/claude-code

# Test with overlays
bin/vibe apply claude-code --overlay examples/security-hardening.yaml
```

### Deliverables

- [ ] Old renderer code removed
- [ ] Documentation updated
- [ ] Full test suite passing
- [ ] Manual verification complete

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Template syntax errors | Medium | Medium | Validate templates at load time, add comprehensive tests |
| Output differences | Medium | High | Comparison tests for each target, normalize whitespace |
| Performance regression | Low | Low | Template caching, benchmark before/after |
| Breaking changes for users | Low | High | Keep old renderer as fallback, deprecate gradually |
| Incomplete migration | Low | Medium | Checklist for each target, code review |

## Rollback Plan

If critical issues are discovered:

1. **Immediate**: Revert to old renderer by removing config files
   ```bash
   mv core/targets/claude-code.yaml core/targets/claude-code.yaml.bak
   ```

2. **Short-term**: Fix issues in new renderer while keeping fallback

3. **Long-term**: Complete migration once stable

## Success Criteria

- [ ] All 8 targets generate identical output (modulo timestamps)
- [ ] New target can be added with < 50 lines of configuration
- [ ] Test coverage for renderer code > 90%
- [ ] No performance regression (> 10% slower)
- [ ] Documentation complete and accurate
