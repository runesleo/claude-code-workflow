# ADR-002: Overlay System Improvements

## Status
Proposed

## Context

The current overlay system in `lib/vibe/overlay_support.rb` provides basic patch capabilities but has several limitations that reduce transparency and safety.

### Current Limitations

#### 1. Opaque Application (Lines 174-181)

```ruby
def overlay_target_patch(overlay, target)
  return {} if overlay.nil?
  patch = overlay.dig("targets", target) || {}
  raise ValidationError, "Overlay targets.#{target} must be a mapping" unless patch.is_a?(Hash)
  deep_copy(patch)
end
```

Problems:
- No visibility into what fields are being patched
- No validation that patched fields are valid for the target
- No type checking beyond "must be a mapping"
- Deep merge behavior is implicit

#### 2. Late Validation

Overlay validation happens at load time but doesn't validate:
- Whether target-specific patches match the target's native config schema
- Whether policy appends reference valid policy IDs
- Type compatibility between overlay values and base values

#### 3. No Conditional Overlays

All overlays are static. Common use cases that require workarounds:
- "Apply this overlay only for Claude Code targets"
- "Apply this overlay only when Superpowers is installed"
- "Apply this overlay only in project mode"

#### 4. Limited Introspection

The `overlay_summary` method (lines 98-113) provides basic counts but doesn't show:
- What specific fields would be modified
- Whether the overlay would conflict with existing settings
- The effective result of applying the overlay

## Decision

Implement four improvements to the overlay system:

### 1. Target Schema Validation

Define schemas for each target's native config overlay:

```yaml
# core/targets/schemas/claude-code.schema.yaml
schema_version: 1
target: claude-code

fields:
  permissions:
    type: object
    description: "Permission rules for Claude Code"
    properties:
      defaultMode:
        type: string
        enum: ["default", "ask", "deny"]
      ask:
        type: array
        items: { type: string }
      deny:
        type: array
        items: { type: string }
    additionalProperties: false

  hooks:
    type: array
    items:
      type: object
      properties:
        command: { type: string }
        script: { type: string }
      required: [command, script]

validation_mode: strict  # reject unknown fields
```

Update `overlay_target_patch` to validate against schema:

```ruby
def overlay_target_patch(overlay, target)
  return {} if overlay.nil?

  patch = overlay.dig("targets", target) || {}
  schema = load_target_schema(target)

  validator = OverlaySchemaValidator.new(schema)
  errors = validator.validate(patch)

  unless errors.empty?
    raise ValidationError, "Overlay validation failed for #{target}: #{errors.join(', ')}"
  end

  deep_copy(patch)
end
```

### 2. Transparent Overlay Application

Add an `OverlayPreview` class that shows exactly what would change:

```ruby
class OverlayPreview
  def initialize(base_manifest, overlay, target)
    @base = base_manifest
    @overlay = overlay
    @target = target
  end

  def changes
    [
      *profile_changes,
      *policy_changes,
      *native_config_changes
    ]
  end

  def profile_changes
    overrides = overlay_profile_mapping_overrides(@overlay)
    overrides.map do |tier, executor|
      old = @base["profile_mapping"][tier]
      {
        type: :profile_mapping,
        tier: tier,
        old_value: old,
        new_value: executor,
        description: "#{tier}: #{old} -> #{executor}"
      }
    end
  end

  def native_config_changes
    patch = overlay_target_patch(@overlay, @target)
    base_config = base_native_config(@target)

    diff_native_configs(base_config, patch)
  end
end
```

Usage in CLI:
```bash
$ bin/vibe apply --overlay my-overlay.yaml --preview
Overlay: my-overlay.yaml
Target: claude-code

Changes:
  Profile Mapping:
    - critical_reasoner: claude.opus-class -> claude.o3-class
  Native Config:
    - permissions.defaultMode: "default" -> "ask"
    + permissions.ask[10]: "Bash(docker push:*)"
  Policies:
    + 2 policy patches (see --verbose)
```

### 3. Conditional Overlays

Extend overlay schema to support conditions:

```yaml
# .vibe/overlay.yaml
schema_version: 2
name: conditional-overlay

conditions:
  all_of:
    - target: [claude-code, cursor]
    - mode: global  # or project
    - integration_installed: superpowers

  # Alternative: any_of with not
  # any_of:
  #   - target: claude-code
  #   - and:
  #       - target: cursor
  #       - integration_installed: superpowers

profile:
  mapping_overrides:
    critical_reasoner: claude.o3-class

targets:
  claude-code:
    permissions:
      defaultMode: ask
```

Implementation:

```ruby
class OverlayConditionEvaluator
  def initialize(context)
    @context = context  # { target:, mode:, installed_integrations: [], ... }
  end

  def evaluate(conditions)
    return true if conditions.nil? || conditions.empty?

    conditions.all? do |operator, operands|
      case operator
      when "all_of" then operands.all? { |c| evaluate_condition(c) }
      when "any_of" then operands.any? { |c| evaluate_condition(c) }
      when "not" then !evaluate_condition(operands)
      else evaluate_condition(operator => operands)
      end
    end
  end

  def evaluate_condition(condition)
    condition.all? do |key, value|
      case key
      when "target" then Array(value).include?(@context[:target])
      when "mode" then @context[:mode] == value
      when "integration_installed"
        Array(value).all? { |i| @context[:installed_integrations].include?(i) }
      end
    end
  end
end
```

### 4. Overlay Composition

Support multiple overlays with explicit precedence:

```yaml
# .vibe/overlay.yaml
schema_version: 2
name: composed-overlay

extends:
  - path: ./base-security.yaml
    precedence: lower
  - path: ./claude-specific.yaml
    precedence: higher
    condition:
      target: claude-code

profile:
  mapping_overrides:
    # These override both base overlays
    workhorse_coder: claude.sonnet-4.5
```

## Consequences

### Positive

1. **Fail-fast validation**: Invalid overlays caught at load time, not render time
2. **Transparency**: Users can preview exactly what overlays change
3. **Flexibility**: Conditional overlays reduce need for multiple overlay files
4. **Composability**: Common patterns can be shared and extended

### Negative

1. **Schema maintenance**: New target features require schema updates
2. **Complexity**: Condition evaluation adds logic that must be tested
3. **Performance**: Schema validation and condition evaluation add overhead

### Migration Strategy

**Phase 1: Schema Validation (Backward Compatible)**
- Add schemas for all targets
- Validate overlays against schemas (warning only initially)
- After 1 release cycle, make validation errors fatal

**Phase 2: Preview Command**
- Add `bin/vibe apply --preview` flag
- Add `OverlayPreview` class
- Show preview in CLI output

**Phase 3: Conditional Overlays**
- Add schema_version 2 support
- Add condition evaluation
- Document with examples

**Phase 4: Composition**
- Add `extends` support
- Implement overlay merging with precedence

## Related Decisions

- ADR-001: Configuration-Driven Target Renderer Architecture
- ADR-003: Template System Design
