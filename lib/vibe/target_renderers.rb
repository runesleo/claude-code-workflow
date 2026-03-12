# frozen_string_literal: true

require_relative "config_driven_renderers"

module Vibe
  # Per-target file renderers that write generated output to disk.
  #
  # This module now uses configuration-driven rendering via ConfigDrivenRenderers
  # for supported platforms, while maintaining backward compatibility.
  #
  # Host requirements:
  #   @repo_root [String] — absolute path to the workflow repository root
  #
  # Depends on methods from:
  #   Vibe::Utils          — write_json, format_backtick_list
  #   Vibe::DocRendering   — render_*_doc, bullet_*, filtered_policies, mandatory/optional_skills
  #   Vibe::NativeConfigs  — claude_settings_config, cursor_cli_permissions_config, opencode_config
  #   Vibe::OverlaySupport — overlay_sentence
  #   Vibe::PathSafety     — copy_tree_contents
  #   Vibe::ConfigDrivenRenderers — modern config-driven platform rendering
  module TargetRenderers
    include Vibe::ConfigDrivenRenderers

    COPY_RUNTIME_ENTRIES = %w[rules docs skills agents commands memory].freeze

    def write_target_docs(output_dir, manifest, doc_types)
      doc_types.each do |type|
        filename = "#{type.to_s.gsub('_', '-')}.md"
        # Special cases for filenames
        filename = "behavior-policies.md" if type == :behavior
        filename = "execution-policy.md" if type == :execution_policy
        filename = "execution.md" if type == :execution

        content = case type
                  when :behavior then render_behavior_doc(manifest)
                  when :routing then render_routing_doc(manifest)
                  when :safety then render_safety_doc(manifest)
                  when :skills then render_skills_doc(manifest)
                  when :task_routing then render_task_routing_doc(manifest)
                  when :test_standards then render_test_standards_doc(manifest)
                  when :execution_policy then render_execution_policy_doc(manifest)
                  when :execution then render_execution_policy_doc(manifest)
                  when :general then render_general_doc(manifest)
                  when :workflow_notes then render_warp_workflow_notes_doc(manifest)
                  else
                    raise Vibe::Error, "Unknown doc type: #{type}"
                  end

        File.write(File.join(output_dir, filename), content)
      end
    end

    # Render Claude Code configuration
    # Now uses configuration-driven rendering for better maintainability
    def render_claude(output_root, manifest, project_level: false)
      render_platform(output_root, manifest, "claude-code", project_level: project_level)
    end

    # Legacy method - delegates to unified render_claude
    # Kept for backward compatibility
    def render_claude_global(output_root, manifest)
      COPY_RUNTIME_ENTRIES.each do |entry|
        source = File.join(@repo_root, entry)
        unless File.exist?(source)
          $stderr.puts "Warning: skipping missing runtime entry: #{entry}"
          next
        end

        destination = File.join(output_root, entry)

        if File.directory?(source)
          FileUtils.mkdir_p(destination)
          copy_tree_contents(source, destination)
        else
          FileUtils.mkdir_p(File.dirname(destination))
          FileUtils.cp(source, destination)
        end
      end

      # Conditionally include skill-triggers.md with Superpowers integration info
      superpowers_status = detect_superpowers
      if superpowers_status != :not_installed
        skill_triggers_source = File.join(@repo_root, "rules", "skill-triggers.md")
        skill_triggers_dest = File.join(output_root, "rules", "skill-triggers.md")

        if File.exist?(skill_triggers_source)
          content = File.read(skill_triggers_source)

          # Append Superpowers integration section
          superpowers_section = generate_superpowers_section(manifest)
          enhanced_content = superpowers_section.empty? ? content : content + "\n" + superpowers_section

          File.write(skill_triggers_dest, enhanced_content)
        end
      end

      write_json(File.join(output_root, "settings.json"), claude_settings_config(manifest))

      claude_dir = File.join(output_root, ".vibe", "claude-code")
      FileUtils.mkdir_p(claude_dir)
      File.write(File.join(claude_dir, "README.md"), <<~MD)
        # Claude Code target

        This output is intended to be copied into a Claude Code config directory such as `~/.claude`.

        Included runtime assets:
        - `CLAUDE.md`
        - `rules/`
        - `docs/`
        - `skills/`
        - `agents/`
        - `commands/`
        - `memory/`
        - `patterns.md`
        - `settings.json`

        Active profile: `#{manifest["profile"]}`
        Applied overlay: #{overlay_sentence(manifest)}
        Generated summary: `.vibe/target-summary.md`
      MD
      write_target_docs(claude_dir, manifest, %i[behavior safety task_routing test_standards])

      File.write(File.join(output_root, "CLAUDE.md"), render_target_entrypoint_md("Claude Code", manifest))
    end

    def render_claude_project(output_root, manifest)
      claude_dir = File.join(output_root, ".vibe", "claude-code")
      FileUtils.mkdir_p(claude_dir)
      write_target_docs(claude_dir, manifest, %i[behavior safety task_routing test_standards])

      File.write(File.join(output_root, "CLAUDE.md"), render_claude_project_md(manifest))
    end

    def render_codex(output_root, manifest, project_level: false)
      if project_level
        render_codex_project(output_root, manifest)
      else
        render_codex_global(output_root, manifest)
      end
    end

    def render_codex_global(output_root, manifest)
      codex_dir = File.join(output_root, ".vibe", "codex-cli")
      FileUtils.mkdir_p(codex_dir)
      write_target_docs(codex_dir, manifest, %i[behavior routing skills safety execution_policy task_routing test_standards])

      extra = <<~MD
        ## Execution model

        - Use `.vibe/codex-cli/execution-policy.md` for the default flow and review protocol.
        - Use `.vibe/codex-cli/routing.md` when task routing is ambiguous.
        - Use `.vibe/codex-cli/safety.md` when a task touches risky behavior or permissions.
        - Use `.vibe/codex-cli/behavior-policies.md` for the portable behavior baseline.
      MD

      File.write(File.join(output_root, "AGENTS.md"), render_target_entrypoint_md("Codex CLI", manifest, extra_sections: extra))
    end

    def render_codex_project(output_root, manifest)
      codex_dir = File.join(output_root, ".vibe", "codex-cli")
      FileUtils.mkdir_p(codex_dir)
      write_target_docs(codex_dir, manifest, %i[behavior routing skills safety execution_policy task_routing test_standards])

      File.write(File.join(output_root, "AGENTS.md"), render_codex_project_md(manifest))
    end

    def render_codex_project_md(manifest)
      <<~MD
        # Project Codex CLI Configuration

        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.  
        Applied overlay: #{overlay_sentence(manifest)}

        Global workflow rules are loaded from `~/.codex/`. This file adds project-specific context only.

        ## Project Context

        <!-- Describe your project: tech stack, architecture, key constraints -->

        ## Project-specific rules

        <!-- Add rules that apply only to this project -->

        ## Reference docs

        Supporting notes are under `.vibe/codex-cli/`:
        - `behavior-policies.md` — portable behavior baseline
        - `safety.md` — safety policy
        - `execution-policy.md` — execution and review protocol
        - `routing.md` — capability tier routing
        - `task-routing.md` — task complexity routing
        - `test-standards.md` — testing requirements
      MD
    end

    def render_cursor(output_root, manifest, project_level: false)
      if project_level
        render_cursor_project(output_root, manifest)
      else
        render_cursor_global(output_root, manifest)
      end
    end

    def render_cursor_global(output_root, manifest)
      cursor_rules_dir = File.join(output_root, ".cursor", "rules")
      cursor_support_dir = File.join(output_root, ".vibe", "cursor")
      FileUtils.mkdir_p(cursor_rules_dir)
      FileUtils.mkdir_p(cursor_support_dir)

      File.write(File.join(output_root, "AGENTS.md"), render_target_entrypoint_md("Cursor", manifest))

      write_json(File.join(output_root, ".cursor", "cli.json"), cursor_cli_permissions_config(manifest))
      write_target_docs(cursor_support_dir, manifest, %i[behavior routing safety skills task_routing test_standards])

      File.write(File.join(cursor_rules_dir, "00-vibe-core.mdc"), <<~MDC)
        ---
        description: Generated portable workflow core
        alwaysApply: true
        ---

        # Portable workflow core

        #{bullet_policy_summary(filtered_policies(manifest, ["always_on"]))}

        ## Mandatory skills

        #{bullet_skill_summary(mandatory_skills(manifest))}
      MDC

      File.write(File.join(cursor_rules_dir, "05-vibe-routing.mdc"), <<~MDC)
        ---
        description: Generated portable routing policy
        alwaysApply: true
        ---

        # Capability routing

        #{bullet_policy_summary(filtered_policies(manifest, ["routing"]))}

        ## Active mapping

        #{bullet_mapping(manifest["profile_mapping"])}
      MDC

      File.write(File.join(cursor_rules_dir, "08-vibe-safety.mdc"), <<~MDC)
        ---
        description: Generated portable safety policy
        alwaysApply: true
        ---

        # Safety policy

        #{bullet_policy_summary(filtered_policies(manifest, ["safety"]))}

        ## Target actions

        #{bullet_target_actions(manifest)}

        See `.cursor/cli.json` and `.vibe/cursor/safety.md` for the generated safety baseline.
      MDC

      File.write(File.join(cursor_rules_dir, "20-vibe-optional-skills.mdc"), <<~MDC)
        ---
        description: Portable optional skill and workflow reference
        alwaysApply: false
        ---

        # Optional workflow guidance

        #{bullet_policy_summary(filtered_policies(manifest, ["optional"]))}

        ## Optional skills

        #{bullet_skill_summary(optional_skills(manifest))}
      MDC
    end

    def render_cursor_project(output_root, manifest)
      cursor_rules_dir = File.join(output_root, ".cursor", "rules")
      cursor_support_dir = File.join(output_root, ".vibe", "cursor")
      FileUtils.mkdir_p(cursor_rules_dir)
      FileUtils.mkdir_p(cursor_support_dir)

      write_target_docs(cursor_support_dir, manifest, %i[behavior routing safety skills task_routing test_standards])

      # Project-level simplified rules
      File.write(File.join(cursor_rules_dir, "00-vibe-project.mdc"), <<~MDC)
        ---
        description: Project-specific workflow context
        alwaysApply: true
        ---

        # Project Cursor Configuration

        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.  
        Applied overlay: #{overlay_sentence(manifest)}

        Global rules are loaded from `~/.cursor/`. This file adds project-specific context only.

        ## Project Context

        <!-- Describe your project: tech stack, architecture, key constraints -->

        ## Project-specific rules

        <!-- Add rules that apply only to this project -->

        ## Reference

        See `.vibe/cursor/` for supporting documentation:
        - `behavior-policies.md` — portable behavior baseline
        - `safety.md` — safety policy
        - `routing.md` — capability tier routing
        - `task-routing.md` — task complexity routing
      MDC

      File.write(File.join(output_root, "AGENTS.md"), render_cursor_project_md(manifest))
    end

    def render_cursor_project_md(manifest)
      <<~MD
        # Project Cursor Configuration

        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.  
        Applied overlay: #{overlay_sentence(manifest)}

        Global workflow rules are loaded from `~/.cursor/`. This file adds project-specific context only.

        ## Project Context

        <!-- Describe your project: tech stack, architecture, key constraints -->

        ## Project-specific rules

        <!-- Add rules that apply only to this project -->

        ## Reference docs

        Supporting notes are under `.vibe/cursor/`:
        - `behavior-policies.md` — portable behavior baseline
        - `safety.md` — safety policy
        - `routing.md` — capability tier routing
        - `task-routing.md` — task complexity routing
        - `test-standards.md` — testing requirements
      MD
    end

    # Render OpenCode configuration
    # Now uses configuration-driven rendering for better maintainability
    def render_opencode(output_root, manifest, project_level: false)
      render_platform(output_root, manifest, "opencode", project_level: project_level)
    end

    def render_opencode_global(output_root, manifest)
      opencode_dir = File.join(output_root, ".vibe", "opencode")
      FileUtils.mkdir_p(opencode_dir)
      write_target_docs(opencode_dir, manifest, %i[behavior general routing skills safety execution])

      File.write(File.join(output_root, "AGENTS.md"), render_target_entrypoint_md("OpenCode", manifest))

      write_json(File.join(output_root, "opencode.json"), opencode_config(manifest))
    end

    def render_opencode_project(output_root, manifest)
      opencode_dir = File.join(output_root, ".vibe", "opencode")
      FileUtils.mkdir_p(opencode_dir)
      write_target_docs(opencode_dir, manifest, %i[behavior general routing skills safety execution])

      File.write(File.join(output_root, "AGENTS.md"), render_opencode_project_md(manifest))

      # Generate a minimal opencode.json for project-level config
      write_json(File.join(output_root, "opencode.json"), opencode_project_config(manifest))
    end

    def render_opencode_project_md(manifest)
      <<~MD
        # Project OpenCode Configuration

        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.  
        Applied overlay: #{overlay_sentence(manifest)}

        Global workflow rules are loaded from `~/.opencode/`. This file adds project-specific context only.

        ## Project Context

        <!-- Describe your project: tech stack, architecture, key constraints -->

        ## Project-specific rules

        <!-- Add rules that apply only to this project -->

        ## Reference docs

        Supporting notes are under `.vibe/opencode/`:
        - `behavior-policies.md` — portable behavior baseline
        - `safety.md` — safety policy
        - `routing.md` — capability tier routing
        - `skills.md` — portable skill registry
        - `execution.md` — execution and review protocol
      MD
    end

    def render_warp(output_root, manifest, project_level: false)
      if project_level
        render_warp_project(output_root, manifest)
      else
        render_warp_global(output_root, manifest)
      end
    end

    def render_warp_global(output_root, manifest)
      warp_dir = File.join(output_root, ".vibe", "warp")
      FileUtils.mkdir_p(warp_dir)

      extra = <<~MD
        ## Supporting files

        - Use `.vibe/warp/behavior-policies.md` for the full portable behavior baseline.
        - Use `.vibe/warp/routing.md` for tier routing and profile mapping.
        - Use `.vibe/warp/safety.md` for security-sensitive work and escalation policy.
        - Use `.vibe/warp/skills.md` for portable skill references.
        - Use `.vibe/warp/task-routing.md` for task complexity classification and process requirements.
        - Use `.vibe/warp/test-standards.md` for test coverage standards by complexity.
        - Use `.vibe/warp/workflow-notes.md` for conservative workflow guidance in Warp.
      MD

      File.write(File.join(output_root, "WARP.md"), render_target_entrypoint_md("Warp", manifest, extra_sections: extra))

      write_target_docs(warp_dir, manifest, %i[behavior routing skills safety task_routing test_standards workflow_notes])
    end

    def render_warp_project(output_root, manifest)
      warp_dir = File.join(output_root, ".vibe", "warp")
      FileUtils.mkdir_p(warp_dir)

      write_target_docs(warp_dir, manifest, %i[behavior routing skills safety task_routing test_standards workflow_notes])

      File.write(File.join(output_root, "WARP.md"), render_warp_project_md(manifest))
    end

    def render_warp_project_md(manifest)
      <<~MD
        # Project Warp Configuration

        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.  
        Applied overlay: #{overlay_sentence(manifest)}

        Global workflow rules are loaded from `~/.warp/` (or your Warp global config). This file adds project-specific context only.

        ## Project Context

        <!-- Describe your project: tech stack, architecture, key constraints -->

        ## Project-specific rules

        <!-- Add rules that apply only to this project -->

        ## Reference docs

        Supporting notes are under `.vibe/warp/`:
        - `behavior-policies.md` — portable behavior baseline
        - `safety.md` — safety policy
        - `routing.md` — capability tier routing
        - `workflow-notes.md` — conservative workflow guidance
        - `task-routing.md` — task complexity routing
        - `test-standards.md` — testing requirements
      MD
    end

    def render_antigravity(output_root, manifest, project_level: false)
      if project_level
        render_antigravity_project(output_root, manifest)
      else
        render_antigravity_global(output_root, manifest)
      end
    end

    def render_antigravity_global(output_root, manifest)
      ag_dir = File.join(output_root, ".vibe", "antigravity")
      FileUtils.mkdir_p(ag_dir)

      extra = <<~MD
        ## Target requirements

        - Understand task tracking files and project documentation before execution.
        - Treat `.vibe/antigravity/` documents as authoritative framework conventions.
        - Escalations and security policy constraints are detailed in `.vibe/antigravity/safety.md`.
      MD

      File.write(File.join(output_root, "AGENTS.md"), render_target_entrypoint_md("Antigravity", manifest, extra_sections: extra))

      write_target_docs(ag_dir, manifest, %i[behavior routing safety skills task_routing test_standards])
    end

    def render_antigravity_project(output_root, manifest)
      ag_dir = File.join(output_root, ".vibe", "antigravity")
      FileUtils.mkdir_p(ag_dir)

      write_target_docs(ag_dir, manifest, %i[behavior routing safety skills task_routing test_standards])

      File.write(File.join(output_root, "AGENTS.md"), render_antigravity_project_md(manifest))
    end

    def render_antigravity_project_md(manifest)
      <<~MD
        # Project Antigravity Configuration

        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.  
        Applied overlay: #{overlay_sentence(manifest)}

        Global workflow rules are loaded from `~/.antigravity/`. This file adds project-specific context only.

        ## Project Context

        <!-- Describe your project: tech stack, architecture, key constraints -->

        ## Project-specific rules

        <!-- Add rules that apply only to this project -->

        ## Reference docs

        Supporting notes are under `.vibe/antigravity/`:
        - `behavior-policies.md` — portable behavior baseline
        - `safety.md` — safety policy
        - `routing.md` — capability tier routing
        - `task-routing.md` — task complexity routing
        - `test-standards.md` — testing requirements
      MD
    end

    def render_vscode(output_root, manifest, project_level: false)
      if project_level
        render_vscode_project(output_root, manifest)
      else
        render_vscode_global(output_root, manifest)
      end
    end

    def render_vscode_global(output_root, manifest)
      vscode_dir = File.join(output_root, ".vscode")
      vibe_dir = File.join(output_root, ".vibe", "vscode")
      FileUtils.mkdir_p(vscode_dir)
      FileUtils.mkdir_p(vibe_dir)

      File.write(File.join(output_root, "AGENTS.md"), render_target_entrypoint_md("VS Code", manifest))

      write_target_docs(vibe_dir, manifest, %i[behavior routing safety skills task_routing test_standards])

      write_json(File.join(vscode_dir, "settings.json"), vscode_settings_config(manifest))
    end

    def render_vscode_project(output_root, manifest)
      vscode_dir = File.join(output_root, ".vscode")
      vibe_dir = File.join(output_root, ".vibe", "vscode")
      FileUtils.mkdir_p(vscode_dir)
      FileUtils.mkdir_p(vibe_dir)

      write_target_docs(vibe_dir, manifest, %i[behavior routing safety skills task_routing test_standards])

      File.write(File.join(output_root, "AGENTS.md"), render_vscode_project_md(manifest))

      # Minimal settings.json for project-level config
      write_json(File.join(vscode_dir, "settings.json"), vscode_project_settings_config(manifest))
    end

    def render_vscode_project_md(manifest)
      <<~MD
        # Project VS Code Configuration

        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.  
        Applied overlay: #{overlay_sentence(manifest)}

        Global workflow rules are loaded from your VS Code global settings. This file adds project-specific context only.

        ## Project Context

        <!-- Describe your project: tech stack, architecture, key constraints -->

        ## Project-specific rules

        <!-- Add rules that apply only to this project -->

        ## Reference docs

        Supporting notes are under `.vibe/vscode/`:
        - `behavior-policies.md` — portable behavior baseline
        - `safety.md` — safety policy
        - `routing.md` — capability tier routing
        - `task-routing.md` — task complexity routing
        - `test-standards.md` — testing requirements
      MD
    end

    def render_kimi_code(output_root, manifest, project_level: false)
      if project_level
        render_kimi_code_project(output_root, manifest)
      else
        render_kimi_code_global(output_root, manifest)
      end
    end

    def render_kimi_code_global(output_root, manifest)
      kimi_skills_dir = File.join(output_root, ".agents", "skills")
      kimi_support_dir = File.join(output_root, ".vibe", "kimi-code")
      FileUtils.mkdir_p(kimi_skills_dir)
      FileUtils.mkdir_p(kimi_support_dir)

      extra = <<~MD
        ## Skills

        Skills are defined in `.agents/skills/*/SKILL.md` files.

        ## Supporting documentation

        - `.vibe/kimi-code/behavior-policies.md` — Full behavior policy baseline
        - `.vibe/kimi-code/routing.md` — Capability tier routing reference
        - `.vibe/kimi-code/safety.md` — Security policy and escalation guidance
        - `.vibe/kimi-code/skills.md` — Portable skill registry reference
        - `.vibe/kimi-code/task-routing.md` — Task complexity classification
        - `.vibe/kimi-code/test-standards.md` — Test coverage requirements
      MD

      File.write(File.join(output_root, "KIMI.md"), render_target_entrypoint_md("Kimi Code", manifest, extra_sections: extra))

      # Generate supporting documentation
      write_target_docs(kimi_support_dir, manifest, %i[behavior routing safety skills task_routing test_standards])

      # Generate SKILL.md files for mandatory skills
      manifest.fetch("skills", []).each do |skill|
        next unless skill["trigger_mode"] == "mandatory"

        skill_dir = File.join(kimi_skills_dir, skill["id"])
        FileUtils.mkdir_p(skill_dir)

        allowed_tools = skill.fetch("allowed_tools", ["Read", "Grep", "Glob"])
        tool_list = allowed_tools.join(", ")

        File.write(File.join(skill_dir, "SKILL.md"), <<~SKILL)
          ---
          name: #{skill["id"]}
          description: #{skill["intent"]} (#{skill["severity"] || "P1"})
          version: 1.0.0
          allowed-tools:
          #{allowed_tools.map { |t| "  - #{t}" }.join("\n")}
          ---

          # #{skill["name"] || skill["id"].split("-").map(&:capitalize).join(" ")}

          #{skill["description"] || skill["intent"]}

          ## When to use

          #{skill["intent"]}

          ## Instructions

          #{skill["how_to_invoke"] || "Follow the workflow defined in this skill."}

          ---
          *Generated from portable skill registry*
        SKILL
      end

      # Generate a README for the kimi skills directory
      File.write(File.join(kimi_skills_dir, "README.md"), <<~MD)
        # Kimi Code Skills

        This directory contains Vibe workflow skills for Kimi Code.

        ## Usage

        ```bash
        # List available skills
        kimi skill list

        # Run a specific skill
        kimi skill run session-end
        ```

        ## Available Skills

        #{manifest.fetch("skills", []).select { |s| s["trigger_mode"] == "mandatory" }.map { |s| "- `#{s['id']}` — #{s['intent']}" }.join("\n")}
      MD
    end

    def render_kimi_code_project(output_root, manifest)
      kimi_support_dir = File.join(output_root, ".vibe", "kimi-code")
      FileUtils.mkdir_p(kimi_support_dir)

      # Generate supporting documentation only
      write_target_docs(kimi_support_dir, manifest, %i[behavior routing safety skills task_routing test_standards])

      File.write(File.join(output_root, "KIMI.md"), render_kimi_code_project_md(manifest))
    end

    def render_kimi_code_project_md(manifest)
      <<~MD
        # Project Kimi Code Configuration

        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.
        Applied overlay: #{overlay_sentence(manifest)}

        Global workflow rules are loaded from `~/.config/agents/`. This file adds project-specific context only.

        ## Project Context

        <!-- Describe your project: tech stack, architecture, key constraints -->

        ## Project-specific rules

        <!-- Add rules that apply only to this project -->

        ## Reference docs

        Supporting notes are under `.vibe/kimi-code/`:
        - `behavior-policies.md` — portable behavior baseline
        - `safety.md` — safety policy
        - `task-routing.md` — task complexity routing
        - `test-standards.md` — testing requirements
      MD
    end



    def render_target_entrypoint_md(target_name, manifest, extra_sections: nil)
      sp_info = verify_superpowers
      rtk_info = verify_rtk
      integrations = render_integrations_section(target_name, sp_info, rtk_info)

      <<~MD
        # Vibe workflow for #{target_name}

        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.#{integrations}
        Applied overlay: #{overlay_sentence(manifest)}

        #{target_entrypoint_intent(target_name)}

        ## Non-negotiable rules

        #{bullet_policy_summary(filtered_policies(manifest, %w[always_on routing safety]))}

        ## Capability routing

        #{bullet_mapping(manifest["profile_mapping"])}

        ## Mandatory portable skills

        #{bullet_skill_summary(mandatory_skills(manifest))}

        #{extra_sections}

        ## Safety floor

        #{bullet_target_actions(manifest)}
      MD
    end

    private

    def render_claude_project_md(manifest)
      <<~MD
        # Project Claude Code Configuration

        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.
        Applied overlay: #{overlay_sentence(manifest)}

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
      MD
    end

    def target_entrypoint_intent(target_name)
      case target_name
      when "Warp" then "This file is intended as the Warp project rule entrypoint for the repository."
      when "Kimi Code" then "This file serves as the project entrypoint for Kimi Code."
      when "Cursor", "Antigravity" then "Primary behavior is defined here, with supporting notes under `.vibe/#{target_name.downcase}/`.\n\nKeep repository files as the SSOT, verify before claiming completion, and follow the generated routing + safety rules."
      when "VS Code" then "VS Code (Copilot Chat) instructions use these generated guidelines as the baseline."
      when "OpenCode" then "Project rules are split into modular instruction files loaded from `opencode.json`.\n\nKeep repository files as the single source of truth, verify before claiming completion, and follow the generated safety policy."
      else "Keep repository files as the SSOT, verify before claiming completion, and follow the generated routing + safety rules."
      end
    end

    def superpowers_skill_list
      yaml_path = File.join(@repo_root, "core", "integrations", "superpowers.yaml")
      return [] unless File.exist?(yaml_path)

      doc = YAML.safe_load(File.read(yaml_path), aliases: true)
      Array(doc["skills"]).map { |s| { "id" => s["id"], "intent" => s["intent"] } }
    end

    def format_superpowers_skill_bullets
      skills = superpowers_skill_list
      return "" if skills.empty?

      skills.map { |s| "- `superpowers/#{s['id']}` — #{s['intent']}" }.join("\n")
    end

    # Data-driven templates for integration section rendering
    # Reduces conditional complexity and makes target-specific customization declarative
    INTEGRATION_TEMPLATES = {
      "kimi-code" => {
        superpowers: {
          header_style: :standalone,
          install_note_template: :kimi_specific,
          show_benefits: false,
          show_full_details: true
        },
        rtk: {
          header_style: :standalone,
          install_template: :kimi_specific,
          show_benefits: true,
          show_version: true
        }
      },
      "warp" => {
        superpowers: {
          header_style: :nested,
          install_note_template: :warp_specific,
          show_benefits: false,
          show_full_details: false
        },
        rtk: {
          header_style: :nested,
          install_template: :warp_specific,
          show_benefits: false,
          show_warp_note: true,
          show_version: true
        }
      },
      :default => {
        superpowers: {
          header_style: :nested,
          install_note_template: :generic,
          show_benefits: false,
          show_full_details: false
        },
        rtk: {
          header_style: :nested,
          install_template: :generic,
          show_benefits: false,
          show_warp_note: false,
          show_version: true
        }
      }
    }.freeze

    # Installation note templates for Superpowers
    SUPERPOWERS_INSTALL_TEMPLATES = {
      kimi_specific: <<~NOTE.chomp,
        # Clone the repository
        git clone https://github.com/obra/superpowers ~/.config/skills/superpowers

        # Then create symlinks to your skills directory
        ln -s ~/.config/skills/superpowers/skills/* ~/.config/agents/skills/  # Adjust path as needed
      NOTE
      warp_specific: <<~NOTE.chomp,
        # Clone the repository
        git clone https://github.com/obra/superpowers ~/.config/skills/superpowers

        # In Warp, manually add the skill paths or use as reference
      NOTE
      generic: ->(target_name) { <<~NOTE.chomp }
        # Clone the repository
        git clone https://github.com/obra/superpowers ~/.config/skills/superpowers

        # For #{target_name}, manually register the skills in your tool's skill system
        # or use the skill files from ~/.config/skills/superpowers/skills/
      NOTE
    }.freeze

    # RTK installation templates
    RTK_INSTALL_TEMPLATES = {
      kimi_specific: <<~CMD.chomp,
        brew install rtk

        # Then configure
        rtk init --global
      CMD
      warp_specific: "brew install rtk",
      generic: <<~CMD.chomp
        brew install rtk

        # Or build from source
        cargo install --git https://github.com/rtk-ai/rtk
      CMD
    }.freeze

    def render_integrations_section(target_name, sp_info, rtk_info)
      sections = []
      skill_bullets = format_superpowers_skill_bullets
      
      # Get target-specific template configuration
      target_key = target_name.downcase.gsub(' ', '-')
      template_config = INTEGRATION_TEMPLATES[target_key] || INTEGRATION_TEMPLATES[:default]
      
      # Render Superpowers section
      sections << render_superpowers_integration(target_name, sp_info, skill_bullets, template_config[:superpowers])
      
      # Render RTK section
      sections << render_rtk_integration(target_name, rtk_info, template_config[:rtk])
      
      sections.compact.join("\n\n")
    end

    private

    def render_superpowers_integration(target_name, sp_info, skill_bullets, config)
      return nil if skill_bullets.empty?
      
      is_standalone = config[:header_style] == :standalone
      
      if sp_info[:installed]
        render_installed_superpowers(target_name, sp_info, skill_bullets, is_standalone)
      else
        render_not_installed_superpowers(target_name, skill_bullets, config, is_standalone)
      end
    end

    def render_installed_superpowers(target_name, sp_info, skill_bullets, is_standalone)
      location = sp_info[:location] || "Unknown"
      
      if is_standalone
        header = "## Superpowers Skill Pack Integration"
      else
        header = "## Optional Integrations\n\n### Superpowers Skill Pack"
      end
      
      <<~SP
        #{header}

        **Status**: ✅ Installed (#{location})

        The following Superpowers skills are available:
        #{skill_bullets}
      SP
    end

    def render_not_installed_superpowers(target_name, skill_bullets, config, is_standalone)
      target_display = target_name == "Kimi Code" ? "" : " for #{target_name}"
      
      if is_standalone
        header = "## Optional: Superpowers Skill Pack"
      else
        header = "## Optional Integrations\n\n### Superpowers Skill Pack"
      end
      
      install_note = get_superpowers_install_note(config[:install_note_template], target_name)
      full_details_note = config[:show_full_details] ? "\nSee `core/integrations/superpowers.yaml` for full details." : ""
      
      <<~SP
        #{header}

        **Status**: ❌ Not installed

        Superpowers provides advanced skills for design refinement, TDD, debugging, and more.

        **Installation#{target_display}**:
        ```bash
        #{install_note}
        ```

        **Available skills#{config[:show_full_details] ? " after installation" : ""}**:
        #{skill_bullets}#{full_details_note}
      SP
    end

    def get_superpowers_install_note(template_key, target_name)
      template = SUPERPOWERS_INSTALL_TEMPLATES[template_key]
      return template.call(target_name) if template.is_a?(Proc)
      template
    end

    def render_rtk_integration(target_name, rtk_info, config)
      if rtk_info[:installed]
        render_installed_rtk(target_name, rtk_info, config)
      else
        render_not_installed_rtk(target_name, config)
      end
    end

    def render_installed_rtk(target_name, rtk_info, config)
      is_standalone = config[:header_style] == :standalone
      is_warp = target_name == "Warp"
      
      hook_status = rtk_info[:hook_configured] ? "✅ Configured" : "⚠️ Not configured"
      
      if is_standalone
        header = "## RTK Token Optimizer"
      else
        header = "### RTK Token Optimizer"
      end
      
      warp_note = config[:show_warp_note] ? "\n**For Warp**: Manually prefix commands with `rtk`, e.g., `rtk git status`" : ""
      config_note = (!is_warp && !rtk_info[:hook_configured]) ? "\n\n**To configure**: Run `rtk init --global`" : ""
      hook_line = is_warp ? "" : "**Hook**: #{hook_status}\n"
      
      <<~RTK
        #{header}

        **Status**: ✅ Installed
        #{hook_line}**Version**: #{rtk_info[:version] || "Unknown"}

        RTK reduces token consumption by 60-90% on common commands.#{warp_note}#{config_note}
      RTK
    end

    def render_not_installed_rtk(target_name, config)
      is_standalone = config[:header_style] == :standalone
      is_kimi = target_name == "Kimi Code"
      is_warp = target_name == "Warp"
      
      if is_standalone
        header = "## Optional: RTK Token Optimizer"
      else
        header = "### RTK Token Optimizer"
      end
      
      install_cmd = RTK_INSTALL_TEMPLATES[config[:install_template]]
      config_step = is_warp ? "" : "\n\n# Then configure\nrtk init --global"
      warp_note = config[:show_warp_note] ? "\n\n**For Warp**: Manually prefix commands with `rtk`, e.g., `rtk git status`" : ""
      generic_note = (!is_kimi && !is_warp) ? "\n\n\n**Note**: RTK works best with Claude Code. For #{target_name}, you may need to manually prefix commands with `rtk`." : ""
      
      benefits_section = if config[:show_benefits]
        <<~BENEFITS


          **Benefits**:
          - 60-90% token reduction on command outputs
          - Less than 10ms overhead per command
          - Works transparently via hooks

          See `core/integrations/rtk.yaml` for full details.
        BENEFITS
      else
        "#{warp_note}#{generic_note}"
      end
      
      <<~RTK
        #{header}

        **Status**: ❌ Not installed

        RTK is a CLI proxy that reduces LLM token consumption by 60-90% on common development commands#{is_kimi ? " (git, npm, pytest, etc.)" : ""}.

        **Installation**:
        ```bash
        # macOS/Linux with Homebrew
        #{install_cmd}#{config_step}
        ```#{benefits_section}
      RTK
    end

    private

    def generate_superpowers_section(manifest)
      manifest_skills = Array(manifest["skills"]).select { |skill| skill["namespace"] == "superpowers" }
      return "" if manifest_skills.empty?

      location = superpowers_location || "Unknown"
      trigger_contexts = load_superpowers_trigger_contexts

      header = build_superpowers_header(location)
      rows = build_superpowers_skill_rows(manifest_skills)
      trigger_section = build_superpowers_trigger_section(manifest_skills, trigger_contexts)
      footer = build_superpowers_footer

      header + rows + trigger_section + footer
    end

    def load_superpowers_trigger_contexts
      initialize_yaml_cache
      superpowers_yaml_path = File.join(@repo_root, "core", "integrations", "superpowers.yaml")
      trigger_contexts = {}

      if File.exist?(superpowers_yaml_path)
        superpowers_config = load_yaml_cached(superpowers_yaml_path)
        Array(superpowers_config["skills"]).each do |skill|
          key = skill["registry_id"] || skill["id"]
          trigger_contexts[key] = skill["trigger_context"]
        end
      end

      trigger_contexts
    end

    def build_superpowers_header(location)
      <<~MD

        ## Superpowers Skill Pack Integration

        **Status**: ✅ Installed (#{location})

        The following portable Superpowers skills are available for on-demand invocation:

        | Portable skill | Trigger mode | Description |
        |----------------|--------------|-------------|
      MD
    end

    def build_superpowers_skill_rows(manifest_skills)
      manifest_skills.map do |skill|
        "| `#{skill['id']}` | `#{skill['trigger_mode']}` | #{skill['intent']} |"
      end.join("\n")
    end

    def build_superpowers_trigger_section(manifest_skills, trigger_contexts)
      suggest_skills = manifest_skills.select { |s| s["trigger_mode"] == "suggest" }
      return "" if suggest_skills.empty?

      trigger_section = <<~MD


        ### When to Use Superpowers Skills

        | Scenario | Skill | Notes |
        |----------|-------|-------|
      MD

      trigger_rows = suggest_skills.map do |skill|
        context = trigger_contexts[skill["id"]] || "See documentation"
        "| #{context} | `#{skill['id']}` | Auto-suggested when applicable |"
      end

      trigger_section + trigger_rows.join("\n")
    end

    def build_superpowers_footer
      <<~MD


        **Usage**: `core/skills/registry.yaml` is the SSOT for portable skill IDs. The installed Superpowers pack may expose different native skill names.

        **Security**: All Superpowers skills have been reviewed and are considered safe for use.
        See `core/integrations/superpowers.yaml` for full skill definitions.
      MD
    end
  end
end
