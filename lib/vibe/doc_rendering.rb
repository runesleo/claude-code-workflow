# frozen_string_literal: true

module Vibe
  # Markdown document renderers for inspect output, target summaries, and
  # per-concern documentation files (behavior, routing, skills, safety, etc.).
  #
  # Depends on methods from:
  #   Vibe::Utils          — format_backtick_list
  #   Vibe::OverlaySupport — overlay_sentence
  module DocRendering
    def initialize_yaml_cache
      @yaml_cache ||= {}
    end

    def load_yaml_cached(path)
      initialize_yaml_cache
      @yaml_cache[path] ||= read_yaml_abs(path)
    end

    def render_inspect(payload)
      lines = []
      lines << "Vibe inspection"
      lines << ""
      lines << "Repository root: #{payload["repo_root"]}"
      lines << "Base portable behavior policies: #{payload["base_policy_count"]}"
      lines << "Effective behavior policies: #{payload["effective_policy_count"]}"
      lines << ""

      overlay = payload["overlay"]
      if overlay
        lines << "Requested overlay:"
        lines << "- name: #{overlay["name"]}"
        lines << "- path: #{overlay["display_path"]}"
        lines << "- target patches: #{format_backtick_list(Array(overlay["target_patch_targets"]))}"
      else
        lines << "Requested overlay: none"
      end

      lines << ""
      marker = payload["current_repo_target"]
      if marker
        lines << "Current repo target marker:"
        lines << "- target: #{marker["target"]}"
        lines << "- profile: #{marker["profile"]}"
        lines << "- destination: #{marker["destination_root"]}"
        lines << "- applied_at: #{marker["applied_at"]}"
        if marker["overlay"]
          lines << "- overlay: #{marker["overlay"]["name"]} (#{marker["overlay"]["display_path"]})"
        end
      else
        lines << "Current repo target marker: none"
      end

      lines << ""
      lines << "Targets:"

      payload["targets"].each do |target_info|
        lines << "- #{target_info["target"]}"
        lines << "  default_profile: #{target_info["default_profile"]} (#{target_info["profile_maturity"]})"
        lines << "  generated_output: #{target_info["generated_output"]}"
        lines << "  generated_manifest_present: #{target_info["generated_manifest_present"]}"
        resolved_overlay = target_info["overlay"]
        lines << "  resolved_overlay: #{resolved_overlay ? resolved_overlay["name"] : 'none'}"
        Array(target_info["profile_notes"]).each do |note|
          lines << "  note: #{note}"
        end
      end

      lines.join("\n")
    end

    def render_target_summary(manifest)
      <<~MD
        # Generated target summary

        - Target: `#{manifest["target"]}`
        - Profile: `#{manifest["profile"]}`
        - Profile maturity: `#{manifest["profile_maturity"]}`
        - Generated at: `#{manifest["generated_at"]}`
        - Applied overlay: #{overlay_sentence(manifest)}

        ## Capability mapping

        #{bullet_mapping(manifest["profile_mapping"])}

        ## Overlay

        #{render_overlay_block(manifest)}

        ## Behavior policies

        #{bullet_policy_summary(manifest["policies"])}

        ## Skills

        #{bullet_skill_summary(manifest["skills"])}
      MD
    end

    def render_behavior_doc(manifest)
      body = manifest["policies"].map do |policy|
        refs = Array(policy["source_refs"]).map { |ref| "`#{ref}`" }.join(", ")
        refs = refs.empty? ? "none" : refs
        [
          "- `#{policy["id"]}` (#{policy["category"]}, #{policy["enforcement"]}, group: #{policy["target_render_group"]})",
          "  - #{policy["summary"]}",
          "  - source refs: #{refs}"
        ].join("\n")
      end.join("\n")

      source_note = if manifest["target"] != "claude-code"
        "\n> **Note:** Source refs refer to files in the portable workflow repository, not this generated output directory.\n"
      else
        ""
      end

      <<~MD
        # Behavior policies

        Generated target: `#{manifest["target"]}`
        Applied overlay: #{overlay_sentence(manifest)}
        #{source_note}
        #{body}
      MD
    end

    def render_general_doc(manifest)
      <<~MD
        # General workflow

        Generated target: `#{manifest["target"]}`
        Generated profile: `#{manifest["profile"]}`
        Applied overlay: #{overlay_sentence(manifest)}

        ## Working rules

        #{bullet_policy_summary(filtered_policies(manifest, %w[always_on routing safety]))}
      MD
    end

    def render_routing_doc(manifest)
      tier_descriptions = manifest["tiers"].map do |tier_id, tier|
        [
          "- `#{tier_id}` — #{tier["description"]} (role: `#{tier["default_role"]}`)",
          indent_bullets("Route when", tier["route_when"]),
          indent_bullets("Avoid when", tier["avoid_when"])
        ].join("\n")
      end.join("\n\n")

      routing_defaults = manifest["routing_defaults"].map do |key, value|
        if value.is_a?(Array)
          items = value.map { |item| "  - `#{item}`" }.join("\n")
          "- `#{key}`:\n#{items}"
        else
          "- `#{key}` = `#{value}`"
        end
      end.join("\n")

      model_config_note = render_model_config_note(manifest["target"], manifest["profile_mapping"])

      <<~MD
        # Routing profile

        Generated target: `#{manifest["target"]}`
        Active profile: `#{manifest["profile"]}`
        Applied overlay: #{overlay_sentence(manifest)}

        ## Routing behavior policies

        #{bullet_policy_summary(filtered_policies(manifest, ["routing"]))}

        ## Capability tiers

        #{tier_descriptions}

        ## Active mapping

        #{bullet_mapping(manifest["profile_mapping"])}

        #{model_config_note}

        ## Routing defaults

        #{routing_defaults}
      MD
    end

    def render_skills_doc(manifest)
      skill_lines = manifest["skills"].map do |skill|
        support = skill["target_support"] || "not-modeled"
        "- `#{skill["id"]}` (`#{skill["namespace"]}`, `#{skill["priority"]}`, `#{skill["trigger_mode"]}`, support: `#{support}`) — #{skill["intent"]}"
      end.join("\n")

      # Generate trigger scenarios table for suggest-mode external skills
      trigger_section = generate_skill_trigger_table(manifest)

      result = <<~MD
        # Portable skills

        Generated target: `#{manifest["target"]}`
        Applied overlay: #{overlay_sentence(manifest)}

        #{skill_lines}
      MD

      # Only append trigger section if it's not empty
      result += trigger_section unless trigger_section.empty?
      result
    end

    def generate_skill_trigger_table(manifest)
      # Filter for suggest-mode external skills
      suggest_skills = manifest["skills"].select do |skill|
        skill["trigger_mode"] == "suggest" && skill["namespace"] != "builtin"
      end

      return "" if suggest_skills.empty?

      # Load trigger contexts from integration configs
      trigger_contexts = {}

      # Load superpowers config if available (cached)
      superpowers_path = File.join(@repo_root, "core", "integrations", "superpowers.yaml")
      if File.exist?(superpowers_path)
        superpowers_config = load_yaml_cached(superpowers_path)
        Array(superpowers_config["skills"]).each do |skill|
          key = skill["registry_id"] || skill["id"]
          trigger_contexts[key] = skill["trigger_context"] if skill["trigger_context"]
        end
      end

      # Build trigger table rows
      rows = suggest_skills.map do |skill|
        context = trigger_contexts[skill["id"]] || "See documentation"
        "| #{context} | `#{skill['id']}` | Auto-suggested when applicable |"
      end

      return "" if rows.empty?

      <<~TABLE


        ## When to Use External Skills

        The following external skills are automatically suggested in relevant scenarios:

        | Scenario | Skill | Notes |
        |----------|-------|-------|
        #{rows.join("\n")}
      TABLE
    end

    def render_safety_doc(manifest)
      target_actions = manifest.fetch("security").fetch("target_actions")
      severity_lines = manifest.fetch("security").fetch("severity_levels").map do |severity, rule|
        examples = Array(rule["examples"]).map { |example| "  - #{example}" }.join("\n")
        "- `#{severity}` — #{rule["meaning"]}\n#{examples}"
      end.join("\n")

      action_lines = target_actions.map do |severity, action|
        "- `#{severity}` — #{action}"
      end.join("\n")

      signal_lines = manifest.fetch("security").fetch("signal_categories").map do |category|
        indicators = Array(category["indicators"]).map { |indicator| "`#{indicator}`" }.join(", ")
        upgrades = Array(category["upgrade_to_p0_when"]).map { |item| "`#{item}`" }.join(", ")
        line = "- `#{category["id"]}` (base: `#{category["base_severity"]}`) — indicators: #{indicators}"
        line += " | upgrade when: #{upgrades}" unless upgrades.empty?
        line
      end.join("\n")

      adjudication = manifest.fetch("security").fetch("adjudication_factors").map do |item|
        "- `#{item}`"
      end.join("\n")

      <<~MD
        # Safety policy

        Applied overlay: #{overlay_sentence(manifest)}

        ## Safety behavior policy

        #{bullet_policy_summary(filtered_policies(manifest, ["safety"]))}

        ## Native config overlay

        #{render_native_overlay_block(manifest)}

        ## Severity semantics

        #{severity_lines}

        ## Target actions

        #{action_lines}

        ## Signal categories

        #{signal_lines}

        ## Adjudication factors

        #{adjudication}
      MD
    end

    def render_execution_policy_doc(manifest)
      <<~MD
        # Execution policy

        Generated target: `#{manifest["target"]}`
        Active profile: `#{manifest["profile"]}`
        Applied overlay: #{overlay_sentence(manifest)}

        ## Default execution flow

        1. Classify the task by capability tier.
        2. Pick the mapped executor from the active profile.
        3. Apply mandatory portable skills before claiming completion.
        4. If risk appears, follow the generated safety policy.
        5. For critical work, prefer maker-checker flow with `independent_verifier`.

        ## Always-on behavior policies

        #{bullet_policy_summary(filtered_policies(manifest, ["always_on"]))}

        ## Mandatory portable skills

        #{bullet_skill_summary(mandatory_skills(manifest))}

        ## Optional portable skills

        #{bullet_skill_summary(optional_skills(manifest))}

        ## Safety actions

        #{bullet_target_actions(manifest)}
      MD
    end

    def render_warp_workflow_notes_doc(manifest)
      <<~MD
        # Warp workflow notes

        Generated target: `#{manifest["target"]}`
        Applied overlay: #{overlay_sentence(manifest)}

        ## Conservative mapping

        - Use `WARP.md` as the project-level Warp rule entrypoint.
        - Keep repository files as the single source of truth; Warp rules should point back to those files instead of replacing them.
        - If you later add Warp workflows, prefer repo-local commands that wrap `bin/vibe` or existing project scripts.
        - Keep runtime preferences such as `uv` and `nvm` in project overlays so they stay scoped to the right repositories.
        - This generator intentionally stays file-backed and does not try to manage Warp Drive state directly.
      MD
    end

    def filtered_policies(manifest, groups)
      manifest["policies"].select { |policy| groups.include?(policy["target_render_group"]) }
    end

    def mandatory_skills(manifest)
      manifest["skills"].select { |skill| skill["trigger_mode"] == "mandatory" }
    end

    def optional_skills(manifest)
      manifest["skills"].reject { |skill| skill["trigger_mode"] == "mandatory" }
    end

    def bullet_mapping(mapping)
      mapping.map { |tier, executor| "- `#{tier}` → `#{executor}`" }.join("\n")
    end

    def bullet_skill_summary(skills)
      return "- none" if skills.empty?

      skills.map do |skill|
        "- `#{skill["id"]}` (`#{skill["priority"]}`, `#{skill["trigger_mode"]}`) — #{skill["intent"]}"
      end.join("\n")
    end

    def bullet_policy_summary(policies)
      return "- none" if policies.empty?

      policies.map do |policy|
        "- `#{policy["id"]}` (`#{policy["enforcement"]}`) — #{policy["summary"]}"
      end.join("\n")
    end

    def bullet_target_actions(manifest)
      manifest.fetch("security").fetch("target_actions").map do |severity, action|
        "- `#{severity}` — #{action}"
      end.join("\n")
    end

    def indent_bullets(title, items)
      values = Array(items)
      return "  #{title}: none" if values.empty?

      ["  #{title}:"].concat(values.map { |item| "    - #{item}" }).join("\n")
    end

    def render_overlay_block(manifest)
      overlay = manifest["overlay"]
      return "- none" if overlay.nil?

      patch_keys = Array(overlay["target_patch_keys"])

      [
        "- Name: `#{overlay["name"]}`",
        "- Path: `#{overlay["display_path"]}`",
        "- Profile mapping overrides: #{format_backtick_list((overlay["profile_mapping_overrides"] || {}).keys.sort)}",
        "- Extra profile notes: `#{overlay["profile_note_append_count"]}`",
        "- Policy patches: `#{overlay["policy_patch_count"]}`",
        "- Native patch keys: #{format_backtick_list(patch_keys)}"
      ].join("\n")
    end

    def render_native_overlay_block(manifest)
      patch = manifest["native_config_overlay"]
      return "- none" if patch.nil? || patch.empty?

      patch.map do |key, value|
        detail = if value.is_a?(Hash)
          value.keys.sort.map { |item| "`#{item}`" }.join(", ")
        elsif value.is_a?(Array)
          value.map { |item| "`#{item}`" }.join(", ")
        else
          "`#{value}`"
        end
        detail = "`none`" if detail.nil? || detail.empty?
        "- `#{key}` → #{detail}"
      end.join("\n")
    end

    def render_task_routing_doc(manifest)
      return "" unless task_routing_doc

      complexity_sections = task_routing_doc.fetch("complexity_levels", {}).map do |level, config|
        criteria = config.fetch("criteria", {}).map { |k, v| "  - #{k}: #{v}" }.join("\n")
        examples = config.fetch("examples", []).map { |ex| "  - #{ex}" }.join("\n")
        requirements = config.fetch("process_requirements", {}).map { |k, v| "  - #{k}: #{v}" }.join("\n")

        <<~SECTION.chomp
          ### #{level.capitalize}

          #{config["description"]}

          **Criteria:**
          #{criteria}

          **Examples:**
          #{examples}

          **Process Requirements:**
          #{requirements}

          **Time Estimate:** #{config["time_estimate"]}
        SECTION
      end.join("\n\n")

      auto_rules = task_routing_doc.fetch("auto_detection", {}).fetch("rules", []).map do |rule|
        "- #{rule["condition"]} → `#{rule["complexity"]}` (#{rule["reason"]})"
      end.join("\n")

      <<~MD
        # Task Complexity Routing

        Generated target: `#{manifest["target"]}`
        Applied overlay: #{overlay_sentence(manifest)}

        This document defines how to route tasks by complexity level to balance quality and efficiency.

        ## Complexity Levels

        #{complexity_sections}

        ## Auto-Detection Rules

        #{auto_rules}

        ## Override Policy

        Users can override complexity classification with justification:
        - "this is urgent, skip full process"
        - "treat this as trivial"
        - "this needs full review despite being small"
      MD
    end

    def render_test_standards_doc(manifest)
      return "" unless test_standards_doc

      coverage_sections = test_standards_doc.fetch("coverage_by_complexity", {}).map do |level, config|
        <<~SECTION.chomp
          ### #{level.capitalize}

          #{config["description"]}

          - Unit coverage: #{config["unit_coverage"]}%
          - Integration coverage: #{config["integration_coverage"]}%
          - Manual verification: #{config["manual_verification"]}
        SECTION
      end.join("\n\n")

      critical_paths = test_standards_doc.fetch("critical_paths", []).map do |path|
        "- `#{path["path_pattern"] || path["function_pattern"]}` → #{path["coverage"]}% (#{path["reason"]})"
      end.join("\n")

      test_types = test_standards_doc.fetch("test_types", {}).map do |type, config|
        required = config.fetch("required_for", []).map { |r| "`#{r}`" }.join(", ")
        examples = config.fetch("examples", []).map { |ex| "  - #{ex}" }.join("\n")

        section = <<~SECTION.chomp
          ### #{type.capitalize}

          #{config["description"]}

          **Required for:** #{required}
        SECTION

        if config["must_cover"]
          must_cover = config["must_cover"].map { |item| "  - #{item}" }.join("\n")
          section += "\n\n**Must Cover:**\n#{must_cover}"
        end

        section += "\n\n**Examples:**\n#{examples}" unless examples.empty?
        section
      end.join("\n\n")

      <<~MD
        # Test Coverage Standards

        Generated target: `#{manifest["target"]}`
        Applied overlay: #{overlay_sentence(manifest)}

        This document defines minimum test requirements by task complexity and code type.

        ## Coverage by Complexity

        #{coverage_sections}

        ## Critical Paths

        These paths require 100% coverage regardless of complexity:

        #{critical_paths}

        ## Test Types

        #{test_types}

        ## Exemptions

        - Documentation-only changes: 0% coverage
        - Test code itself: optional coverage
        - Generated code: optional coverage
      MD
    end

    def render_model_config_note(target, profile_mapping)
      # Look up config note from providers.yaml profile data
      providers.fetch("profiles", {}).each_value do |profile|
        next unless profile["target"] == target
        note = profile["model_config_note"]
        return note.strip if note && !note.strip.empty?
      end
      ""
    end

  end
end
