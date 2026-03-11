# Current Architecture Analysis

## Overview

The Vibe workflow project generates AI coding assistant configurations for 8 different platforms. The rendering system is responsible for transforming portable YAML specifications into target-specific configuration files.

## File Structure

```
lib/vibe/
├── target_renderers.rb    # 1149 lines - Main rendering logic
├── doc_rendering.rb       # 573 lines - Markdown document generators
├── native_configs.rb      # 188 lines - JSON config builders
├── overlay_support.rb     # 275 lines - Overlay parsing and merging
└── builder.rb             # 283 lines - Build orchestration

core/
├── models/
│   ├── providers.yaml     # Profile definitions for each target
│   └── tiers.yaml         # Capability tier definitions
├── policies/
│   ├── behaviors.yaml     # Behavior policies
│   ├── task-routing.yaml  # Task complexity routing
│   └── test-standards.yaml # Test coverage standards
├── skills/
│   └── registry.yaml      # Skill definitions
├── security/
│   └── policy.yaml        # Security policy
└── integrations/
    ├── superpowers.yaml   # Superpowers skill pack metadata
    └── rtk.yaml           # RTK token optimizer metadata
```

## Duplication Analysis

### 1. Global vs Project Mode Duplication

**Pattern**: Every target implements separate global and project rendering methods.

**Lines affected**: ~400 lines across all targets

**Duplication metrics**:

| Target | Global Lines | Project Lines | Shared Logic |
|--------|-------------|---------------|--------------|
| Claude Code | 65 | 10 | ~80% |
| Cursor | 65 | 70 | ~85% |
| Codex CLI | 25 | 40 | ~70% |
| Kimi Code | 60 | 40 | ~75% |
| OpenCode | 25 | 40 | ~70% |
| Warp | 25 | 40 | ~70% |
| Antigravity | 25 | 40 | ~70% |
| VS Code | 25 | 40 | ~70% |

**Root cause**: No abstraction for rendering modes; each target manually implements the branching.

### 2. Directory Structure Duplication

**Pattern**: Every global renderer creates the same directory structure.

```ruby
# Repeated 8 times with minor variations
target_dir = File.join(output_root, ".vibe", "target-name")
FileUtils.mkdir_p(target_dir)
write_target_docs(target_dir, manifest, %i[behavior routing ...])
```

**Lines affected**: ~120 lines

**Variations**:
- Cursor uses `.cursor/rules` instead of `.vibe/cursor`
- Kimi Code uses `.agents/skills` for skill files
- VS Code uses `.vscode` for settings

**Root cause**: Directory paths are hardcoded in each renderer rather than being data-driven.

### 3. Entrypoint Markdown Duplication

**Pattern**: Each target has nearly identical project-level markdown templates.

**Comparison of project templates** (lines 755-780, 435-462, 369-395, etc.):

```ruby
# All follow this exact pattern:
<<~MD
  # Project {Target} Configuration

  Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.
  Applied overlay: #{overlay_sentence(manifest)}

  Global workflow rules are loaded from `~/{config_dir}/`. This file adds project-specific context only.

  ## Project Context

  <!-- Describe your project: tech stack, architecture, key constraints -->

  ## Project-specific rules

  <!-- Add rules that apply only to this project -->

  ## Reference docs

  Supporting notes are under `.vibe/{target}/`:
  - `behavior-policies.md` — portable behavior baseline
  - `safety.md` — safety policy
  - ...
MD
```

**Lines affected**: ~240 lines (8 targets × ~30 lines each)

**Variations**:
- Target name
- Config directory path (`~/.claude/`, `~/.cursor/`, etc.)
- Reference doc list (some have 4 items, some have 6)

**Root cause**: Templates embedded in code rather than extracted and parameterized.

### 4. Integration Rendering Complexity

**Pattern**: 164 lines of nested conditionals for Superpowers and RTK integration sections.

**Lines 808-1146** contain:
- `INTEGRATION_TEMPLATES` hash with target-specific configurations
- `SUPERPOWERS_INSTALL_TEMPLATES` hash
- `RTK_INSTALL_TEMPLATES` hash
- Multiple render methods with complex conditional logic

**Complexity metrics**:
- 6 template configuration keys per target
- 4 different install note templates
- 3 different render paths per integration (installed, not installed, disabled)

**Root cause**: Integration rendering logic is imperative rather than declarative; target-specific customizations require code changes.

### 5. Native Config Duplication

**Pattern**: Similar JSON structures for permissions across targets.

**Lines affected**: ~150 lines in `native_configs.rb`

**Comparison**:

| Target | Config Structure | Overlap with Claude Code |
|--------|-----------------|-------------------------|
| Claude Code | permissions: { ask: [...], deny: [...] } | 100% (baseline) |
| Cursor | permissions: { allow: [...], deny: [...] } | ~60% |
| OpenCode | permission: { read: {}, write: {}, bash: {} } | ~40% |
| VS Code | github.copilot.chat.codeGeneration.instructions | ~10% |

**Root cause**: No shared schema or template for permission concepts; each target redefines similar concepts.

## Extension Point Analysis

### Adding a New Target

**Current process** (estimated 240 lines):

1. **In `target_renderers.rb`** (~150 lines):
   - Add `render_target` method with global/project branch
   - Add `render_target_global` method
   - Add `render_target_project` method
   - Add `render_target_project_md` method
   - Add target-specific integration templates if needed

2. **In `builder.rb`** (1 line):
   - Add case to `build_target` switch statement

3. **In `native_configs.rb`** (~40 lines):
   - Add `base_target_config` method
   - Add `target_config` method
   - Add `target_project_config` method if different

4. **In `doc_rendering.rb`** (~30 lines):
   - May need target-specific rendering logic

5. **In `core/models/providers.yaml`** (~20 lines):
   - Add profile definition

**Problems**:
- Changes required in 5+ files
- No single place to understand what a target needs
- Easy to miss integration points

### Adding a New Doc Type

**Current process**:

1. **In `target_renderers.rb`**:
   - Add filename mapping in `write_target_docs` (lines 18-43)
   - Add case to content dispatch

2. **In `doc_rendering.rb`**:
   - Add `render_*_doc` method

3. **In each target renderer**:
   - Update doc type arrays in `write_target_docs` calls

**Problems**:
- Doc type logic scattered across multiple files
- Each target must explicitly opt-in to new doc types
- No default behavior or inheritance

### Adding a New Integration

**Current process**:

1. **In `target_renderers.rb`** (~100 lines):
   - Add integration template configuration to `INTEGRATION_TEMPLATES`
   - Add install templates if needed
   - Add render methods for the integration
   - Update `render_integrations_section` to call new integration

2. **In `builder.rb`**:
   - May need to add integration detection

3. **In `integration_manager.rb`**:
   - Add installation/setup logic

**Problems**:
- Integration logic deeply coupled to target rendering
- Cannot add integration without modifying core renderer code

## Maintainability Issues

### 1. Test Difficulty

- Renderers perform file I/O directly, making unit testing hard
- No separation between content generation and file writing
- Integration tests require comparing large generated files

### 2. Code Review Burden

- Large files (1149 lines) are hard to review thoroughly
- Similar-looking code blocks make it easy to miss differences
- No visual diff for template changes

### 3. Documentation Drift

- Generated output structure is implicit in code
- No single source of truth for what each target produces
- Documentation must be manually updated when code changes

### 4. Error Handling

- Errors in template rendering produce cryptic Ruby stack traces
- No context about which target/doc type failed
- Partial file writes on failure leave corrupted output

## Root Cause Summary

| Issue | Root Cause | Current Impact |
|-------|-----------|----------------|
| Code duplication | Imperative rendering, no declarative config | 60%+ of renderer code is duplicated |
| Extension difficulty | Scattered target definitions | 240 lines to add one target |
| Poor testability | Tight coupling of I/O and logic | Low unit test coverage |
| Opaque overlays | Runtime patch application | Hard to debug overlay issues |
| Template scattering | Embedded heredocs | Poor editor support, no reuse |

## Recommendations

See ADR-001, ADR-002, and ADR-003 for detailed architectural proposals addressing these issues.
