# frozen_string_literal: true

require_relative 'errors'

module Vibe
  # Overlay parsing, discovery, merging, and policy resolution.
  #
  # Host requirements:
  #   @repo_root    [String] — absolute path to the workflow repository root
  #   @policies_doc [Hash]   — parsed core/policies/behaviors.yaml
  #
  # Depends on methods from:
  #   Vibe::Utils — deep_merge, deep_copy, blankish?, display_path, read_yaml_abs
  module OverlaySupport
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
      if schema_version && (schema_version < 1 || schema_version > 10)
        raise ValidationError, "Overlay schema_version out of range (1-10): #{path}"
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

      overrides = overlay.dig("profile", "mapping_overrides") || {}
      raise ValidationError, "Overlay profile.mapping_overrides must be a mapping" unless overrides.is_a?(Hash)

      overrides
    end

    def overlay_profile_note_append(overlay)
      return [] if overlay.nil?

      notes = overlay.dig("profile", "note_append") || []
      raise ValidationError, "Overlay profile.note_append must be a list" unless notes.is_a?(Array)

      notes
    end

    def overlay_policy_appends(overlay)
      return [] if overlay.nil?

      policies = overlay.dig("policies", "append") || []
      raise ValidationError, "Overlay policies.append must be a list" unless policies.is_a?(Array)

      overlay_ref = display_path(overlay["path"])
      policies.map do |policy|
        raise ValidationError, "Each overlay policy must be a mapping" unless policy.is_a?(Hash)

        required = %w[id category enforcement target_render_group summary]
        missing = required.select { |key| blankish?(policy[key]) }
        raise ValidationError, "Overlay policy is missing required keys: #{missing.join(', ')}" unless missing.empty?

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

    def overlay_target_patch(overlay, target)
      return {} if overlay.nil?

      patch = overlay.dig("targets", target) || {}
      raise ValidationError, "Overlay targets.#{target} must be a mapping" unless patch.is_a?(Hash)

      deep_copy(patch)
    end

  end
end
