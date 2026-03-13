# frozen_string_literal: true

require "thread"
require "digest"
require "time"

module Vibe
  # Core build logic: YAML loading, profile resolution, manifest construction,
  # target rendering dispatch, and inspect payloads.
  #
  # Host requirements:
  #   @repo_root   [String] — absolute path to the workflow repository root
  #   @yaml_mutex  [Mutex]  — mutex for thread-safe YAML loading
  #
  # Depends on methods from:
  #   Vibe::Utils          — read_yaml, write_json, display_path, deep_merge, deep_copy, validate_path!
  #   Vibe::DocRendering   — render_target_summary, core_policies
  #   Vibe::OverlaySupport — overlay_*, effective_policies
  #   Vibe::PathSafety     — ensure_safe_output_path!
  #   Vibe::TargetRenderers — render_claude, render_codex, etc.
  #   Vibe::ExternalTools  — detect_superpowers
  module Builder
    # --- Lazy-loaded YAML documents with caching (thread-safe) ---

    def tiers_doc
      @yaml_mutex.synchronize do
        @tiers_doc ||= read_yaml("core/models/tiers.yaml")
      end
    end

    def providers
      @yaml_mutex.synchronize do
        @providers ||= read_yaml("core/models/providers.yaml")
      end
    end

    def skills_doc
      @yaml_mutex.synchronize do
        @skills_doc ||= read_yaml("core/skills/registry.yaml")
      end
    end

    def security_doc
      @yaml_mutex.synchronize do
        @security_doc ||= read_yaml("core/security/policy.yaml")
      end
    end

    def policies_doc
      @yaml_mutex.synchronize do
        @policies_doc ||= read_yaml("core/policies/behaviors.yaml")
      end
    end

    def task_routing_doc
      @yaml_mutex.synchronize do
        @task_routing_doc ||= read_yaml("core/policies/task-routing.yaml")
      end
    end

    def test_standards_doc
      @yaml_mutex.synchronize do
        @test_standards_doc ||= read_yaml("core/policies/test-standards.yaml")
      end
    end

    # --- Output path helpers ---

    def default_output_root(target)
      File.join(@repo_root, "generated", target)
    end

    def default_destination_for_target(_target)
      @repo_root
    end

    def resolve_output_root_for_use(target:, destination_root:, explicit_output:)
      return File.expand_path(explicit_output) if explicit_output

      output_root = File.expand_path(default_output_root(target))
      return output_root unless paths_overlap?(output_root, destination_root)

      destination_name = File.basename(destination_root)
      destination_name = sanitize_directory_name(destination_name)
      destination_name = "root" if destination_name.empty?
      destination_digest = Digest::SHA256.hexdigest(destination_root)[0, 12]

      home_dir = Dir.home
      raise Vibe::ConfigurationError, "Cannot determine home directory for external staging" if home_dir.nil? || home_dir.empty?

      File.join(home_dir, ".vibe-generated", "#{destination_name}-#{destination_digest}", target)
    end

    def sanitize_directory_name(name)
      return "root" if name.nil? || name.empty? || name == File::SEPARATOR

      sanitized = name.gsub(/[^a-zA-Z0-9_-]/, "-")
      sanitized = sanitized.gsub(/-+/, "-")
      sanitized = sanitized.gsub(/^-+|-+$/, "")
      sanitized.empty? ? "root" : sanitized
    end

    # --- Profile resolution ---

    def resolve_profile(target, requested_profile)
      profiles = providers.fetch("profiles")

      if requested_profile
        profile = profiles[requested_profile]
        raise Vibe::ConfigurationError, "Unknown profile: #{requested_profile}" if profile.nil?
        raise Vibe::ValidationError, "Profile #{requested_profile} does not target #{target}" unless profile["target"] == target

        return [requested_profile, profile]
      end

      default_profile_for_target(target)
    end

    def default_profile_for_target(target)
      profiles = providers.fetch("profiles").select { |_name, profile| profile["target"] == target }
      raise Vibe::ConfigurationError, "No profile found for target #{target}" if profiles.empty?

      profiles.sort_by do |_name, profile|
        case profile["maturity"]
        when "active" then 0
        when "planned" then 1
        else 2
        end
      end.first
    end

    # --- Build and manifest ---

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

      case target
      when "claude-code"
        render_claude(output_root, manifest, project_level: project_level)
      when "codex-cli"
        render_codex(output_root, manifest, project_level: project_level)
      when "cursor"
        render_cursor(output_root, manifest, project_level: project_level)
      when "kimi-code"
        render_kimi_code(output_root, manifest, project_level: project_level)
      when "opencode"
        render_opencode(output_root, manifest, project_level: project_level)
      when "warp"
        render_warp(output_root, manifest, project_level: project_level)
      when "antigravity"
        render_antigravity(output_root, manifest, project_level: project_level)
      when "vscode"
        render_vscode(output_root, manifest, project_level: project_level)
      else
        raise Vibe::ConfigurationError, "Target renderer not implemented: #{target}"
      end

      vibe_dir = File.join(output_root, ".vibe")
      FileUtils.mkdir_p(vibe_dir)
      write_json(File.join(vibe_dir, "manifest.json"), manifest)
      File.write(File.join(vibe_dir, "target-summary.md"), render_target_summary(manifest))
      manifest
    end

    def build_manifest(target:, profile_name:, profile:, output_root:, overlay:)
      profile_mapping = deep_merge(profile.fetch("mapping"), overlay_profile_mapping_overrides(overlay))
      profile_notes = (Array(profile["notes"]) + overlay_profile_note_append(overlay)).uniq
      policies = effective_policies(overlay)
      native_config_overlay = overlay_target_patch(overlay, target)

      {
        "schema_version" => 5,
        "generated_at" => Time.now.utc.iso8601,
        "source_repo" => ".",
        "output_root" => display_path(File.expand_path(output_root)),
        "target" => target,
        "profile" => profile_name,
        "profile_maturity" => profile["maturity"],
        "profile_notes" => profile_notes,
        "profile_mapping" => profile_mapping,
        "overlay" => overlay_summary(overlay, target: target),
        "native_config_overlay" => native_config_overlay,
        "routing_defaults" => tiers_doc["routing_defaults"],
        "tiers" => tiers_doc.fetch("tiers").transform_values do |tier|
          {
            "description" => tier["description"],
            "default_role" => tier["default_role"],
            "route_when" => tier["route_when"] || [],
            "avoid_when" => tier["avoid_when"] || []
          }
        end,
        "skills" => manifest_skills(target),
        "policies" => policies,
        "security" => {
          "severity_levels" => security_doc.fetch("severity_levels"),
          "signal_categories" => security_doc.fetch("signal_categories"),
          "adjudication_factors" => security_doc.fetch("adjudication_factors"),
          "target_actions" => security_doc.fetch("actions_by_target")[target]
        }
      }
    end

    def manifest_skills(target)
      skills_doc.fetch("skills").select do |skill|
        include_skill_in_manifest?(skill)
      end.map do |skill|
        {
          "id" => skill["id"],
          "namespace" => skill["namespace"],
          "intent" => skill["intent"],
          "trigger_mode" => skill["trigger_mode"],
          "priority" => skill["priority"],
          "target_support" => skill.fetch("supported_targets", {})[target]
        }
      end
    end

    def include_skill_in_manifest?(skill)
      condition = skill["conditional"]
      return true if condition.nil? || condition.to_s.strip.empty?

      case condition
      when "superpowers_installed"
        detect_superpowers != :not_installed
      else
        false
      end
    end

    # --- Inspect ---

    def inspect_payload(target:, overlay:)
      targets = target ? [target] : self.class::SUPPORTED_TARGETS

      {
        "schema_version" => 5,
        "repo_root" => @repo_root,
        "overlay" => overlay_overview(overlay),
        "base_policy_count" => core_policies.length,
        "effective_policy_count" => effective_policies(overlay).length,
        "current_repo_target" => read_json_if_exists(File.join(@repo_root, self.class::MARKER_FILENAME)),
        "targets" => targets.map { |item| inspect_target_payload(item, overlay: overlay) }
      }
    end

    def inspect_target_payload(target, overlay:)
      default_profile_name, default_profile = default_profile_for_target(target)
      generated_manifest = read_json_if_exists(File.join(default_output_root(target), ".vibe", "manifest.json"))
      preview_manifest = build_manifest(
        target: target,
        profile_name: default_profile_name,
        profile: default_profile,
        output_root: default_output_root(target),
        overlay: overlay
      )

      {
        "target" => target,
        "default_profile" => default_profile_name,
        "profile_maturity" => default_profile["maturity"],
        "profile_notes" => preview_manifest["profile_notes"],
        "resolved_profile_mapping" => preview_manifest["profile_mapping"],
        "overlay" => preview_manifest["overlay"],
        "native_config_overlay" => preview_manifest["native_config_overlay"],
        "generated_output" => File.expand_path(default_output_root(target)),
        "generated_manifest_present" => !generated_manifest.nil?,
        "generated_manifest" => generated_manifest
      }
    end
  end
end
