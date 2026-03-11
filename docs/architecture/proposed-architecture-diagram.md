# Proposed Architecture Diagram

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLI Interface                                   │
│                     (bin/vibe apply, inspect, validate)                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Build Orchestrator                                 │
│                         (Vibe::BuildOrchestrator)                            │
│                                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ Profile     │  │ Overlay     │  │ Manifest    │  │ Target Renderer     │ │
│  │ Resolver    │  │ Resolver    │  │ Builder     │  │ Dispatcher          │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    ▼                  ▼                  ▼
┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│   Target Renderer    │  │   Target Renderer    │  │   Target Renderer    │
│   (Claude Code)      │  │   (Cursor)           │  │   (Other Targets)    │
│                      │  │                      │  │                      │
│  ┌────────────────┐  │  │  ┌────────────────┐  │  │  ┌────────────────┐  │
│  │ Target Config  │  │  │  │ Target Config  │  │  │  │ Target Config  │  │
│  │ (.yaml)        │  │  │  │ (.yaml)        │  │  │  │ (.yaml)        │  │
│  └────────────────┘  │  │  └────────────────┘  │  │  └────────────────┘  │
│                      │  │                      │  │                      │
│  ┌────────────────┐  │  │  ┌────────────────┐  │  │  ┌────────────────┐  │
│  │ Template Set   │  │  │  │ Template Set   │  │  │  │ Template Set   │  │
│  │ (.erb files)   │  │  │  │ (.erb files)   │  │  │  │ (.erb files)   │  │
│  └────────────────┘  │  │  └────────────────┘  │  │  └────────────────┘  │
└──────────────────────┘  └──────────────────────┘  └──────────────────────┘
```

## Component Details

### 1. Configuration Layer

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Configuration Layer                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Target Configuration Files                        │   │
│  │                                                                      │   │
│  │   core/targets/claude-code.yaml    core/targets/cursor.yaml         │   │
│  │   ├─ target_id                     ├─ target_id                     │   │
│  │   ├─ output_paths                  ├─ output_paths                  │   │
│  │   ├─ doc_types                     ├─ doc_types                     │   │
│  │   ├─ entrypoint                    ├─ entrypoint                    │   │
│  │   ├─ native_config                 ├─ native_config                 │   │
│  │   ├─ file_operations               ├─ file_operations               │   │
│  │   └─ integrations                  └─ integrations                  │   │
│  │                                                                      │   │
│  │   core/targets/codex-cli.yaml      core/targets/kimi-code.yaml      │   │
│  │   ... (6 more targets)                                             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Schema Definitions                                │   │
│  │                                                                      │   │
│  │   core/targets/schemas/claude-code.schema.yaml                      │   │
│  │   core/targets/schemas/cursor.schema.yaml                           │   │
│  │   ... (validation schemas for overlay patches)                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2. Rendering Engine

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Rendering Engine                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Vibe::TargetRenderer                              │   │
│  │                                                                      │   │
│  │   initialize(target_config, manifest)                                │   │
│  │   render(output_root, mode: :global|:project)                        │   │
│  │                                                                      │   │
│  │   ┌─────────────────────────────────────────────────────────────┐   │   │
│  │   │ 1. Directory Setup                                          │   │   │
│  │   │    - Create output_paths based on mode                      │   │   │
│  │   └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                      │   │
│  │   ┌─────────────────────────────────────────────────────────────┐   │   │
│  │   │ 2. Documentation Generation                                 │   │   │
│  │   │    - For each doc_type in config:                           │   │   │
│  │   │      - Load doc template                                    │   │   │
│  │   │      - Render with TemplateContext                          │   │   │
│  │   │      - Write to support_dir                                 │   │   │
│  │   └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                      │   │
│  │   ┌─────────────────────────────────────────────────────────────┐   │   │
│  │   │ 3. Native Config Generation                                 │   │   │
│  │   │    - If native_config defined and mode matches:             │   │   │
│  │   │      - Load native config template                          │   │   │
│  │   │      - Merge with overlay patches                           │   │   │
│  │   │      - Validate against schema                              │   │   │
│  │   │      - Write to output path                                 │   │   │
│  │   └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                      │   │
│  │   ┌─────────────────────────────────────────────────────────────┐   │   │
│  │   │ 4. File Operations                                          │   │   │
│  │   │    - For each operation in config:                          │   │   │
│  │   │      - Evaluate condition                                   │   │   │
│  │   │      - Execute copy/write operation                         │   │   │
│  │   │      - Apply transforms if specified                        │   │   │
│  │   └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                      │   │
│  │   ┌─────────────────────────────────────────────────────────────┐   │   │
│  │   │ 5. Entrypoint Generation                                    │   │   │
│  │   │    - Load entrypoint template for mode                      │   │   │
│  │   │    - Render with TemplateContext                            │   │   │
│  │   │    - Write to base path                                     │   │   │
│  │   └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3. Template System

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Template System                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Vibe::TemplateEngine                              │   │
│  │                                                                      │   │
│  │   render(template_path, context) ──▶ Compiled ERB output           │   │
│  │                                                                      │   │
│  │   Features:                                                          │   │
│  │   - Template caching                                                 │   │
│  │   - Partial rendering                                                │   │
│  │   - Layout support                                                   │   │
│  │   - Syntax validation                                                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Vibe::TemplateContext                             │   │
│  │                                                                      │   │
│  │   Provides to templates:                                             │   │
│  │   - manifest        (full manifest hash)                             │   │
│  │   - target          (target configuration)                           │   │
│  │   - mode            (:global or :project)                            │   │
│  │   - helpers         (TemplateHelpers module)                         │   │
│  │   - integrations    (integration status)                             │   │
│  │                                                                      │   │
│  │   Helper methods:                                                    │   │
│  │   - bullet_policy_summary(policies)                                  │   │
│  │   - bullet_skill_summary(skills)                                     │   │
│  │   - bullet_mapping(mapping)                                          │   │
│  │   - overlay_sentence                                                 │   │
│  │   - superpowers_installed?                                           │   │
│  │   - rtk_installed?                                                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Template Directory Structure                      │   │
│  │                                                                      │   │
│  │   templates/                                                         │   │
│  │   ├── targets/                                                       │   │
│  │   │   ├── claude-code/                                               │   │
│  │   │   │   ├── global.md.erb                                          │   │
│  │   │   │   ├── project.md.erb                                         │   │
│  │   │   │   └── settings.json.erb                                      │   │
│  │   │   ├── cursor/                                                    │   │
│  │   │   │   ├── global.md.erb                                          │   │
│  │   │   │   ├── project.md.erb                                         │   │
│  │   │   │   ├── 00-vibe-core.mdc.erb                                   │   │
│  │   │   │   └── ...                                                    │   │
│  │   │   └── ... (6 more targets)                                       │   │
│  │   ├── docs/                                                          │   │
│  │   │   ├── behavior.md.erb                                            │   │
│  │   │   ├── routing.md.erb                                             │   │
│  │   │   ├── safety.md.erb                                              │   │
│  │   │   └── ...                                                        │   │
│  │   └── shared/                                                        │   │
│  │       ├── _header.md.erb                                             │   │
│  │       ├── _policy_list.md.erb                                        │   │
│  │       ├── _skill_list.md.erb                                         │   │
│  │       ├── _integration_superpowers.md.erb                            │   │
│  │       └── _integration_rtk.md.erb                                    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4. Overlay System

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Overlay System                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Vibe::OverlayManager                              │   │
│  │                                                                      │   │
│  │   resolve_overlay(path) ──▶ Validated Overlay                      │   │
│  │   apply_overlay(manifest, overlay) ──▶ Modified Manifest           │   │
│  │   preview_changes(manifest, overlay) ──▶ Change List               │   │
│  │                                                                      │   │
│  │   Components:                                                        │   │
│  │   ├─ OverlayResolver      (path resolution, discovery)               │   │
│  │   ├─ OverlayValidator     (schema validation)                        │   │
│  │   ├─ OverlayMerger        (deep merging)                             │   │
│  │   ├─ OverlayPreview       (change preview)                           │   │
│  │   └─ ConditionEvaluator   (conditional overlays)                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Overlay Schema (v2)                               │   │
│  │                                                                      │   │
│  │   schema_version: 2                                                  │   │
│  │   name: my-overlay                                                   │   │
│  │                                                                      │   │
│  │   conditions:          # NEW: Conditional application                │   │
│  │     all_of:                                                          │   │
│  │       - target: [claude-code, cursor]                                │   │
│  │       - mode: global                                                 │   │
│  │                                                                      │   │
│  │   extends:             # NEW: Composition                            │   │
│  │     - path: ./base.yaml                                              │   │
│  │       precedence: lower                                              │   │
│  │                                                                      │   │
│  │   profile:             # Profile mapping overrides                   │   │
│  │     mapping_overrides:                                               │   │
│  │       critical_reasoner: claude.o3-class                             │   │
│  │                                                                      │   │
│  │   policies:            # Policy patches                              │   │
│  │     append: []                                                       │   │
│  │                                                                      │   │
│  │   targets:             # Target-specific native config               │   │
│  │     claude-code:                                                     │   │
│  │       permissions:                                                   │   │
│  │         defaultMode: ask                                             │   │
│  │     cursor:                                                          │   │
│  │       ...                                                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5. Integration Plugin System

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Integration Plugin System                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Vibe::IntegrationPlugin (Base Class)              │   │
│  │                                                                      │   │
│  │   class IntegrationPlugin                                            │   │
│  │     def self.applicable?(manifest) ──▶ Boolean                       │   │
│  │     def self.priority ──▶ Integer                                    │   │
│  │     def render_section(target_config, mode) ──▶ String               │   │
│  │     def install_instructions(target) ──▶ Hash                        │   │
│  │   end                                                                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Plugin Registry                                   │   │
│  │                                                                      │   │
│  │   Vibe::IntegrationPlugins.register(SuperpowersPlugin)               │   │
│  │   Vibe::IntegrationPlugins.register(RtkPlugin)                       │   │
│  │   Vibe::IntegrationPlugins.register(CustomPlugin)                    │   │
│  │                                                                      │   │
│  │   Rendering:                                                         │   │
│  │   plugins = IntegrationPlugins.applicable_for(manifest)              │   │
│  │   plugins.each do |plugin|                                           │   │
│  │     content = plugin.render_section(target_config, mode)             │   │
│  │     entrypoint.insert_integration_section(content)                   │   │
│  │   end                                                                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Example: SuperpowersPlugin                        │   │
│  │                                                                      │   │
│  │   class SuperpowersPlugin < IntegrationPlugin                        │   │
│  │     def self.applicable?(manifest)                                   │   │
│  │       manifest["skills"].any? { |s| s["namespace"] == "superpowers" }│   │
│  │     end                                                              │   │
│  │                                                                      │   │
│  │     def render_section(target_config, mode)                          │   │
│  │       template = select_template(target_config.target_id)            │   │
│  │       engine.render(template, context)                               │   │
│  │     end                                                              │   │
│  │                                                                      │   │
│  │     private                                                          │   │
│  │                                                                      │   │
│  │     def select_template(target_id)                                   │   │
│  │       # Check for target-specific template                           │   │
│  │       # Fall back to default template                                │   │
│  │     end                                                              │   │
│  │   end                                                                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   User      │────▶│    CLI      │────▶│  Orchestrator│────▶│   Target    │
│  Command    │     │   Parser    │     │              │     │  Renderer   │
└─────────────┘     └─────────────┘     └─────────────┘     └──────┬──────┘
                                                                   │
                    ┌──────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Output    │◀────│   Writer    │◀────│  Template   │◀────│   Context   │
│   Files     │     │             │     │   Engine    │     │   Builder   │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘

Detailed Flow:
==============

1. User runs: bin/vibe apply claude-code --overlay my-overlay.yaml

2. CLI Parser validates arguments and options

3. Orchestrator coordinates:
   a. Load target config (core/targets/claude-code.yaml)
   b. Resolve profile from providers.yaml
   c. Load and validate overlay
   d. Build manifest (base + profile + overlay)
   e. Instantiate TargetRenderer with config and manifest

4. TargetRenderer.render(output_root, mode: :global):
   a. Load templates from templates/targets/claude-code/
   b. Build TemplateContext with manifest data
   c. For each doc_type: TemplateEngine.render(doc_template, context)
   d. For native_config: render, validate against schema, write
   e. Execute file_operations (copy_tree, conditional_copy, etc.)
   f. Render entrypoint template with integration sections

5. Writer creates files atomically (write to temp, then rename)

6. Output: Generated configuration in output_root/
```

## Migration Path

```
Phase 1: Infrastructure
=======================
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Create Target  │────▶│  Create Template│────▶│  Create Schema  │
│    Config       │     │    Engine       │     │   Validation    │
│   Loader        │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘

Phase 2: Parallel Implementation
================================
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ Implement One   │────▶│   Compare       │────▶│   Fix           │
│ Target (Claude) │     │   Outputs       │     │   Discrepancies │
└─────────────────┘     └─────────────────┘     └─────────────────┘

Phase 3: Migration
==================
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Convert        │────▶│  Update         │────▶│  Remove         │
│  Remaining      │     │  Tests          │     │  Old Code       │
│  Targets        │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘

Phase 4: Enhancements
=====================
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Add Overlay    │────▶│  Add Integration│────▶│  Add Template   │
│  Improvements   │     │    Plugins      │     │   Partials      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```
