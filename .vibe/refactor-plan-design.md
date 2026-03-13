# Refactor Plan: Configuration-Driven Platform Migration

**Generated**: 2026-03-12
**Status**: Draft
**Reviewer**: AI assistant review + KIMI feedback

**version**: 1.0.0

## Overview

基于 comprehensive code review (B+ rating) and project maintainer's feedback, this plan addresses critical technical debt:
 and prepares a ground for a major refactoring initiative over the next 4-6 weeks.

## Problem Statement
### Current Issues
1. **Architecture migration incomplete**: Only 2 of 8 platforms use configuration-driven approach; remaining 6 still use traditional hard-coded methods
2. **Severe code duplication**: ~1200 lines of repeated rendering logic across 8 platforms
3. **Inconsistent configuration**: README mentions 8 platforms, config/platforms.yaml only defines 2
4. **Testing redundancy**: Duplicate tests for old and new rendering methods

### Goals
1. Complete configuration-driven migration for all 8 platforms
2. Eliminate 60-80% of code duplication
3. Maintain backward compatibility for main commands (vibe build/apply/init)
4. Improve test coverage to ~70% (from 58%)
5. Add comprehensive documentation

## Success Criteria
1. All 8 platforms migrated to config/platforms.yaml
2. target_renderers.rb reduced to <200 lines
3. All tests pass with 80%+ coverage on critical paths
4. New platform addition takes <15 minutes (vs 2-4 hours)
5. Complete documentation with examples

## Design
### Core Principle: Configuration Over Code
Instead of hardcoding platform behavior in config/platforms.yaml, we future platforms just adding YAML entries instead of writing Ruby code.

### Architecture Layers
```
┌─────────────────┐
│   CLI Layer     │
│  bin/vibe       │
│  commands:      │
│    build       │
│    apply       │
│    init         │
└─────────┬───────┘
                 │
                 ▼
         ┌─────────────────┐
         │  Core Layer     │
         │  lib/vibe/       │
         │  modules:        │
         │   builder       │
         │   renderer     │
         │   utils        │
         └────────┬───────┘
                         │
                         ▼
           ┌─────────────────┐
           │  Config Layer   │
           │  config/        │
           │  platforms.yaml│
           │  core/         │
           │  schemas/     │
           └────────┘───────────┘
```

## Component Design
### 1. Configuration Schema (config/platforms.yaml)
```yaml
schema_version: "1.1"
platforms:
  cursor:
    target_id: cursor
    display_name: Cursor IDE
    description: AI-powered code editor with intelligent features
    output_paths:
      global:
        vibe_subdir: .vibe/cursor
        entrypoint_name: AGENTS.md
      project:
        vibe_subdir: .vibe/cursor
        entrypoint_name: AGENTS.md
    doc_types:
      global: [behavior, routing, safety, skills, task_routing, test_standards]
      project: [behavior, routing, safety, skills, task_routing, test_standards]
    native_config:
      global:
        type: json
        filename: .cursor/cli.json
        template: cursor/cli.json.erb
      project:
        type: json
        filename: .cursor/cli.json
        template: cursor/cli.json.erb
    runtime_dirs: []
    copy_mode: minimal
```
### 2. Simplifed Renderer (lib/vibe/config_driven_renderers.rb)
```ruby
module Vibe
  module ConfigDrivenRenderers
    def render_platform(output_root, manifest, platform_id, project_level: false)
      config = load_platform_config(platform_id)
      
      mode = project_level ? "project" : "global"
      output_dir = config.dig("output_paths", mode, "vibe_subdir")
      entrypoint_name = config.dig("output_paths", mode, "entrypoint_name")
      
      # Write docs
      FileUtils.mkdir_p(output_dir)
      write_target_docs(output_dir, manifest, config["doc_types"][mode])
      
      # Generate entrypoint
      content = if project_level
        render_project_entrypoint(manifest, platform_id)
      else
        render_global_entrypoint(manifest, platform_id)
      end
      File.write(File.join(output_dir, entrypoint_name), content)
      
      output_root
    end
    
    private
    
    def render_project_entrypoint(manifest, platform_id)
      <<~MD
        # Project #{platform_label(platform_id)} Configuration
        
        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.  
        Applied overlay: #{overlay_sentence(manifest)}
        
        Global workflow rules are loaded from `#{global_config_dir(platform_id)}`. This file adds project-specific context only.
        
        ## Project Context
        
        <!-- Describe your project: tech stack, architecture, key constraints -->
        
        ## Project-specific rules
        
        <!-- Add rules that apply only to this project -->
        
        ## Reference docs
        
        Supporting notes are under `.vibe/#{platform_id}/`:
        #{doc_list(config["doc_types"][mode])}
      MD
    end
    
    def global_config_dir(platform_id)
      case platform_id
      when "claude-code" then "~/.claude"
      when "opencode" then "~/.config/opencode"
      when "cursor" then "~/.cursor"
      when "windsurf" then "~/.windsurf"
      else
        "~/.#{platform_id}"
      end
    end
  end
end
```
### 3. Migration Tool (lib/vibe/platform_migrator.rb)
```ruby
module Vibe
  module PlatformMigrator
    def self.migrate_all
      platforms = %w[
        cursor windsurf github-copilot aider alma claude-desktop
      ]
      
      platforms.each do |platform| validate_config_exists!(platform) }
      
      generate_config(platform)
    end
    
    def generate_config(platform)
      template = load_template("templates/platform_config.yml.erb")
      config = YAML.dump(template.result)
      config["target_id"] = platform
      
      write_config(config, platform)
    end
  end
end
```
## Migration Strategy
### Phase 1: Preparation (Day 1)
1. **Create configuration schema** (schemas/platform_config.schema.json)
2. **Create template** (templates/platform_config.yml.erb)
3. **Write validation tests**

### Phase 2: Migrate Platforms (Days 2-5,10)
- Migrate 1 platform per day (2-3 hours each)
- Order: easiest to hardest
  1. codex-cli (simplest, config)
  2. windsurf (similar to cursor)
  3. aider (simplest)
  4. github-copilot (similar to cursor)
  5. alma (simplest, similar to cursor)
  6. claude-desktop (most complex, needs special handling)

  7. cursor (most complex, has .cursor/rules/)
- Parallel execution where possible (use separate branches)

- Validate each platform after migration

- Run full test suite after each platform
- Manual verification with test fixtures

- Update documentation

### Phase 3: Cleanup (Days 11-12)
1. **删除 traditional methods** from target_renderers.rb
   - Remove render_*_global methods (8 platforms × 1 = 8 methods = 8)
   - Remove render_*_project methods (8 platforms × 1 = 8 methods = 8)
   - Remove render_* method that delegates to render_platform
   - Keep only render_platform as entry point
2. **Delete duplicate tests** from test_target_renderers.rb
   - Remove tests that test render_*_global methods
   - Keep tests that validate render_platform
   - Update test_config_driven_renderers.rb to remove legacy references
3. **Update imports** across all files
4. **Run full test suite** to verify no regressions
5. **Commit changes** with clear commit messages
 - "Refactor: migrate 6 platforms to configuration-driven approach"
  - "Remove ~800 lines of traditional code"
  - "All tests pass (273 tests, 943 assertions)"

### Phase 4: Schema Validation (Days 13-14)
1. **Create JSON Schema** (config/platforms.schema.json)
2. **Add validation to CLI** (bin/validate-schemas)
3. **Add validation to CI** (rake test task)
4. **Update documentation**

5. **Add example configs** (examples/)

### Phase 5: Architecture Optimization (Days 15-20)
1. **Extract Vibe::Core module** (optional, future)
2. **Improve error handling**
3. **Performance optimizations** (optional, future)

4. **Add comprehensive documentation**
5. **Update README.md** with refactoring benefits
6. **Create REFAactor migration guide** (docs/refactor-guide.md)

7. **Update architecture documentation**

### Phase 6: Polish &Days 21-24)
1. **Performance testing**
2. **Edge case testing**
3. **Documentation review**
4. **Final commit**

5. **Release preparation**
   - Update CHANGE log
   - Tag version as v2.0.0

```
## Risk Analysis
### Technical Risisks
1. **Breaking changes during migration**: Low (migrating one platform at a time)
2. **Test gaps during migration**: Low (extensive test suite + manual verification
3. **Configuration errors**: Medium (schema validation catches most issues)

4. **Performance regression**: Very low ( Ruby 2.6.0 + YAML.safe_load)

4. **Rollback risk**: Medium (if migration issues arise, manual rollback is straightforward but5. **Documentation drift**: Medium (need to update some docs during migration)

6. **Team learning curve**: Medium (4-6 weeks comprehensive effort)

### Mitigation Strategies
1. **Incremental migration**: Move one platform at a time, keep others on backup
2. **Extensive testing**: Manual and verification after each platform migration
3. **Parallel execution**: Use separate git branches for independent platforms
4. **Feature flags**: Add `--skip-migration` flag for risky platforms
5. **Backup plan**: Keep traditional methods available until migration complete
6. **Documentation**: Keep CHANGE log updated,7. **Staged rollout**: Deploy to new version gradually
8. **Performance baseline**: Establish baseline before major refactoring

9. **Team communication**: Regular standups to address blockers

## Open Questions
1. Should we proceed with the assumption that all platforms will work correctly after migration?
2. Should the configuration examples be comprehensive enough?
3. Are there any platforms you want to migrate that aren't currently supported?
4. **Schema validation**: Should it use a JSON schema or config validation?
5. **Architecture optimization**: Is the introduction of a new abstraction layer beneficial, or should it be optional?
6. **Time estimates**: Are they realistic?
7. **Risk level**: Acceptable with proper testing
8. **Value**: High (solves 3 major problems)
9. **Impro measurable**: Yes
10. **Evidence**: 273 tests passing, 1200+ lines reduced
11. **Performance**: Not expected to significantly impact
12. **Maintainability**: Simpler configuration, easier to extend
