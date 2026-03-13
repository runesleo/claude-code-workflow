# frozen_string_literal: true

require_relative 'errors'

module Vibe
  # Overlay parsing, discovery, merging, and policy resolution.
  #
  # Host requirements:
  #   @repo_root    [String] — absolute path to the workflow repository root
  #   @policies_doc [Hash]   — parsed core/policies/behaviors.yaml
  #   tiers_doc     [Hash]   — parsed core/models/tiers.yaml
  #   SUPPORTED_TARGETS [Array<String>] — supported CLI targets exposed by the host
  #
  # Depends on methods from:
  #   Vibe::Utils — deep_merge, deep_copy, blankish?, display_path, read_yaml_abs
  module OverlaySupport
    MAX_OVERLAY_SCHEMA_VERSION = 10

    OVERLAY_CANDIDATES = [
      File.join(".vibe", "overlay.yaml"),
      File.join(".vibe", "overlay.yml")
    ].freeze
    def resolve_overlay(explicit_path:, search_roots:)
      path = explicit_path ? File.expand_path(explicit_path) : discover_overlay(search_roots)
      return nil if path.nil?

      raise ConfigurationError, "Overlay file not found: #{path}" unless File.file?(path)

      doc = read_yaml_abs(path) || {}
      raise ValidationError, "Overlay file must contain a YAML mapping: #{path}" unless doc.is_a?(Hash)

      # Validate schema version
      schema_version = doc["schema_version"]
      if schema_version && !schema_version.is_a?(Integer)
        raise ValidationError, "Overlay schema_version must be an integer: #{path}"
      end
      if schema_version && (schema_version < 1 || schema_version > MAX_OVERLAY_SCHEMA_VERSION)
        raise ValidationError, "Overlay schema_version out of range (1-#{MAX_OVERLAY_SCHEMA_VERSION}): #{path}"
      end

      # Validate structure types
      if doc["profile"] && !doc["profile"].is_a?(Hash)
        raise ValidationError, "Overlay 'profile' must be a mapping: #{path}"
      end
      if doc["policies"] && !doc["policies"].is_a?(Hash)
        raise ValidationError, "Overlay 'policies' must be a mapping: #{path}"
      end
      if doc["targets"] && !doc["targets"].is_a?(Hash)
        raise ValidationError, "Overlay 'targets' must be a mapping: #{path}"
      end

      known_keys = %w[schema_version name description profile policies targets]
      unknown_keys = doc.keys - known_keys
      unless unknown_keys.empty?
        warn "Warning: overlay #{path} contains unknown top-level keys: #{unknown_keys.join(', ')}. These will be ignored."
      end

      # Check for common format mistakes
      if doc["profile"] && doc["profile"]["mapping"] && !doc["profile"]["mapping_overrides"]
        warn "⚠️  Warning: overlay #{path} uses 'profile.mapping' which is ignored."
        warn "   Did you mean 'profile.mapping_overrides'?"
        warn "   See examples/project-overlay.yaml for correct format."
      end

      validate_overlay_semantics!(doc, path)

      {
        "schema_version" => doc["schema_version"] || 1,
        "path" => path,
        "name" => doc["name"] || File.basename(path),
        "description" => doc["description"],
        "profile" => doc["profile"] || {},
        "policies" => doc["policies"] || {},
        "targets" => doc["targets"] || {}
      }
    end

    def discover_overlay(search_roots)
      Array(search_roots).compact.map { |root| File.expand_path(root) }.uniq.each do |root|
        OVERLAY_CANDIDATES.each do |relative_path|
          candidate = File.join(root, relative_path)
          return candidate if File.file?(candidate)
        end
      end

      nil
    end

    def overlay_overview(overlay)
      return nil if overlay.nil?

      {
        "name" => overlay["name"],
        "path" => overlay["path"],
        "display_path" => display_path(overlay["path"]),
        "description" => overlay["description"],
        "schema_version" => overlay["schema_version"],
        "profile_mapping_overrides" => overlay_profile_mapping_overrides(overlay),
        "profile_note_append_count" => overlay_profile_note_append(overlay).length,
        "policy_patch_count" => overlay_policy_appends(overlay).length,
        "target_patch_targets" => overlay.fetch("targets", {}).keys.sort
      }
    end

    def overlay_summary(overlay, target:)
      return nil if overlay.nil?

      target_patch = overlay_target_patch(overlay, target)
      {
        "name" => overlay["name"],
        "path" => overlay["path"],
        "display_path" => display_path(overlay["path"]),
        "description" => overlay["description"],
        "schema_version" => overlay["schema_version"],
        "profile_mapping_overrides" => overlay_profile_mapping_overrides(overlay),
        "profile_note_append_count" => overlay_profile_note_append(overlay).length,
        "policy_patch_count" => overlay_policy_appends(overlay).length,
        "target_patch_keys" => target_patch.keys.sort
      }
    end

    def overlay_label(manifest)
      overlay = manifest["overlay"]
      return "" if overlay.nil?

      " + overlay #{overlay["name"]}"
    end

    def overlay_sentence(manifest)
      overlay = manifest["overlay"]
      return "`none`" if overlay.nil?

      "`#{overlay["name"]}` from `#{overlay["display_path"]}`"
    end

    def core_policies
      policies_doc.fetch("policies").map do |policy|
        {
          "id" => policy["id"],
          "category" => policy["category"],
          "enforcement" => policy["enforcement"],
          "target_render_group" => policy["target_render_group"],
          "summary" => policy["summary"],
          "source_refs" => policy["source_refs"] || []
        }
      end
    end

    def effective_policies(overlay)
      policies = deep_copy(core_policies)

      overlay_policy_appends(overlay).each do |policy|
        index = policies.index { |item| item["id"] == policy["id"] }
        if index
          policies[index] = deep_merge(policies[index], policy)
        else
          policies << policy
        end
      end

      policies
    end

    def overlay_profile_mapping_overrides(overlay)
      return {} if overlay.nil?
      normalize_overlay_profile_mapping_overrides(overlay.dig("profile", "mapping_overrides"))
    end

    def overlay_profile_note_append(overlay)
      return [] if overlay.nil?
      normalize_overlay_profile_note_append(overlay.dig("profile", "note_append"))
    end

    def overlay_policy_appends(overlay)
      return [] if overlay.nil?

      overlay_ref = display_path(overlay["path"])
      normalize_overlay_policy_appends(overlay.dig("policies", "append"), overlay_ref: overlay_ref)
    end

    def overlay_target_patch(overlay, target)
      return {} if overlay.nil?

      patch = overlay.dig("targets", target) || {}
      raise ValidationError, "Overlay targets.#{target} must be a mapping" unless patch.is_a?(Hash)

      deep_copy(patch)
    end

    def validate_overlay_semantics!(doc, path)
      normalize_overlay_profile_mapping_overrides(doc.dig("profile", "mapping_overrides"))
      normalize_overlay_profile_note_append(doc.dig("profile", "note_append"))
      normalize_overlay_policy_appends(doc.dig("policies", "append"), overlay_ref: display_path(path))
      validate_overlay_targets(doc["targets"], path)
    end

    def normalize_overlay_profile_mapping_overrides(overrides)
      overrides ||= {}
      raise ValidationError, "Overlay profile.mapping_overrides must be a mapping" unless overrides.is_a?(Hash)

      unknown_tiers = overrides.keys - overlay_capability_tiers
      return overrides if unknown_tiers.empty?

      raise ValidationError,
            "Overlay profile.mapping_overrides contains unknown capability tiers: #{unknown_tiers.join(', ')}. Known tiers: #{overlay_capability_tiers.join(', ')}"
    end

    def normalize_overlay_profile_note_append(notes)
      notes ||= []
      raise ValidationError, "Overlay profile.note_append must be a list" unless notes.is_a?(Array)

      notes
    end

    def normalize_overlay_policy_appends(policies, overlay_ref:)
      policies ||= []
      raise ValidationError, "Overlay policies.append must be a list" unless policies.is_a?(Array)

      policies.map do |policy|
        raise ValidationError, "Each overlay policy must be a mapping" unless policy.is_a?(Hash)

        required = %w[id category enforcement target_render_group summary]
        missing = required.select { |key| blankish?(policy[key]) }
        raise ValidationError, "Overlay policy is missing required keys: #{missing.join(', ')}" unless missing.empty?

        unless overlay_policy_enforcements.include?(policy["enforcement"])
          raise ValidationError,
                "Overlay policy #{policy['id']} uses unknown enforcement '#{policy['enforcement']}'. Expected one of: #{overlay_policy_enforcements.join(', ')}"
        end

        unless overlay_policy_render_groups.include?(policy["target_render_group"])
          raise ValidationError,
                "Overlay policy #{policy['id']} uses unknown target_render_group '#{policy['target_render_group']}'. Expected one of: #{overlay_policy_render_groups.join(', ')}"
        end

        {
          "id" => policy["id"],
          "category" => policy["category"],
          "enforcement" => policy["enforcement"],
          "target_render_group" => policy["target_render_group"],
          "summary" => policy["summary"],
          "source_refs" => (Array(policy["source_refs"]) + [overlay_ref]).uniq
        }
      end
    end

    def validate_overlay_targets(targets, path)
      targets ||= {}
      raise ValidationError, "Overlay 'targets' must be a mapping: #{path}" unless targets.is_a?(Hash)

      unknown_targets = targets.keys - overlay_supported_targets
      unless unknown_targets.empty?
        raise ValidationError,
              "Overlay targets contains unsupported targets: #{unknown_targets.join(', ')}. Supported targets: #{overlay_supported_targets.join(', ')}"
      end

      targets.each do |target_name, patch|
        raise ValidationError, "Overlay targets.#{target_name} must be a mapping: #{path}" unless patch.is_a?(Hash)
      end
    end

    def overlay_capability_tiers
      tiers_doc.fetch("tiers").keys
    end

    def overlay_policy_enforcements
      core_policies.map { |policy| policy["enforcement"] }.uniq
    end

    def overlay_policy_render_groups
      core_policies.map { |policy| policy["target_render_group"] }.uniq
    end

    def overlay_supported_targets
      return self.class::SUPPORTED_TARGETS if self.class.const_defined?(:SUPPORTED_TARGETS)

      []
    end

  end
end
