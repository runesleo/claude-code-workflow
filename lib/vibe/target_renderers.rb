# frozen_string_literal: true

module Vibe
  # Per-target file renderers that write generated output to disk.
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
  module TargetRenderers
    COPY_RUNTIME_ENTRIES = %w[CLAUDE.md rules docs skills agents commands memory patterns.md].freeze

    def render_claude(output_root, manifest)
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
          superpowers_section = generate_superpowers_section(superpowers_status, manifest)
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
      File.write(File.join(claude_dir, "behavior-policies.md"), render_behavior_doc(manifest))
      File.write(File.join(claude_dir, "safety.md"), render_safety_doc(manifest))
      File.write(File.join(claude_dir, "task-routing.md"), render_task_routing_doc(manifest))
      File.write(File.join(claude_dir, "test-standards.md"), render_test_standards_doc(manifest))
    end

    def render_codex(output_root, manifest)
      codex_dir = File.join(output_root, ".vibe", "codex-cli")
      FileUtils.mkdir_p(codex_dir)
      File.write(File.join(codex_dir, "behavior-policies.md"), render_behavior_doc(manifest))
      File.write(File.join(codex_dir, "routing.md"), render_routing_doc(manifest))
      File.write(File.join(codex_dir, "skills.md"), render_skills_doc(manifest))
      File.write(File.join(codex_dir, "safety.md"), render_safety_doc(manifest))
      File.write(File.join(codex_dir, "execution-policy.md"), render_execution_policy_doc(manifest))
      File.write(File.join(codex_dir, "task-routing.md"), render_task_routing_doc(manifest))
      File.write(File.join(codex_dir, "test-standards.md"), render_test_standards_doc(manifest))

      File.write(File.join(output_root, "AGENTS.md"), <<~MD)
        # Vibe workflow for Codex CLI

        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.
        Applied overlay: #{overlay_sentence(manifest)}

        ## Non-negotiable rules

        #{bullet_policy_summary(filtered_policies(manifest, %w[always_on routing safety]))}

        ## Capability routing

        #{bullet_mapping(manifest["profile_mapping"])}

        ## Mandatory portable skills

        #{bullet_skill_summary(mandatory_skills(manifest))}

        ## Execution model

        - Use `.vibe/codex-cli/execution-policy.md` for the default flow and review protocol.
        - Use `.vibe/codex-cli/routing.md` when task routing is ambiguous.
        - Use `.vibe/codex-cli/safety.md` when a task touches risky behavior or permissions.
        - Use `.vibe/codex-cli/behavior-policies.md` for the portable behavior baseline.

        ## Safety floor

        #{bullet_target_actions(manifest)}
      MD
    end

    def render_cursor(output_root, manifest)
      cursor_rules_dir = File.join(output_root, ".cursor", "rules")
      cursor_support_dir = File.join(output_root, ".vibe", "cursor")
      FileUtils.mkdir_p(cursor_rules_dir)
      FileUtils.mkdir_p(cursor_support_dir)

      File.write(File.join(output_root, "AGENTS.md"), <<~MD)
        # Vibe workflow for Cursor

        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.
        Applied overlay: #{overlay_sentence(manifest)}

        Primary behavior is defined in `.cursor/rules/*.mdc`, with supporting notes under `.vibe/cursor/`.

        Keep repository files as the SSOT, verify before claiming completion, and follow the generated routing + safety rules.
      MD

      write_json(File.join(output_root, ".cursor", "cli.json"), cursor_cli_permissions_config(manifest))
      File.write(File.join(cursor_support_dir, "behavior-policies.md"), render_behavior_doc(manifest))
      File.write(File.join(cursor_support_dir, "routing.md"), render_routing_doc(manifest))
      File.write(File.join(cursor_support_dir, "safety.md"), render_safety_doc(manifest))
      File.write(File.join(cursor_support_dir, "skills.md"), render_skills_doc(manifest))
      File.write(File.join(cursor_support_dir, "task-routing.md"), render_task_routing_doc(manifest))
      File.write(File.join(cursor_support_dir, "test-standards.md"), render_test_standards_doc(manifest))

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

    def render_opencode(output_root, manifest)
      opencode_dir = File.join(output_root, ".vibe", "opencode")
      FileUtils.mkdir_p(opencode_dir)

      File.write(File.join(opencode_dir, "behavior-policies.md"), render_behavior_doc(manifest))
      File.write(File.join(opencode_dir, "general.md"), render_general_doc(manifest))
      File.write(File.join(opencode_dir, "routing.md"), render_routing_doc(manifest))
      File.write(File.join(opencode_dir, "skills.md"), render_skills_doc(manifest))
      File.write(File.join(opencode_dir, "safety.md"), render_safety_doc(manifest))
      File.write(File.join(opencode_dir, "execution.md"), render_execution_policy_doc(manifest))

      File.write(File.join(output_root, "AGENTS.md"), <<~MD)
        # Vibe workflow for OpenCode

        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.
        Applied overlay: #{overlay_sentence(manifest)}

        Project rules are split into modular instruction files loaded from `opencode.json`.

        Keep repository files as the single source of truth, verify before claiming completion, and follow the generated safety policy.
      MD

      write_json(File.join(output_root, "opencode.json"), opencode_config(manifest))
    end

    def render_warp(output_root, manifest)
      warp_dir = File.join(output_root, ".vibe", "warp")
      FileUtils.mkdir_p(warp_dir)

      File.write(File.join(output_root, "WARP.md"), <<~MD)
        # Vibe workflow for Warp

        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.
        Applied overlay: #{overlay_sentence(manifest)}

        This file is intended as the Warp project rule entrypoint for the repository.

        ## Non-negotiable rules

        #{bullet_policy_summary(filtered_policies(manifest, %w[always_on routing safety]))}

        ## Capability routing

        #{bullet_mapping(manifest["profile_mapping"])}

        ## Mandatory portable skills

        #{bullet_skill_summary(mandatory_skills(manifest))}

        ## Supporting files

        - Use `.vibe/warp/behavior-policies.md` for the full portable behavior baseline.
        - Use `.vibe/warp/routing.md` for tier routing and profile mapping.
        - Use `.vibe/warp/safety.md` for security-sensitive work and escalation policy.
        - Use `.vibe/warp/skills.md` for portable skill references.
        - Use `.vibe/warp/task-routing.md` for task complexity classification and process requirements.
        - Use `.vibe/warp/test-standards.md` for test coverage standards by complexity.
        - Use `.vibe/warp/workflow-notes.md` for conservative workflow guidance in Warp.

        ## Safety floor

        #{bullet_target_actions(manifest)}
      MD

      File.write(File.join(warp_dir, "behavior-policies.md"), render_behavior_doc(manifest))
      File.write(File.join(warp_dir, "routing.md"), render_routing_doc(manifest))
      File.write(File.join(warp_dir, "skills.md"), render_skills_doc(manifest))
      File.write(File.join(warp_dir, "safety.md"), render_safety_doc(manifest))
      File.write(File.join(warp_dir, "task-routing.md"), render_task_routing_doc(manifest))
      File.write(File.join(warp_dir, "test-standards.md"), render_test_standards_doc(manifest))
      File.write(File.join(warp_dir, "workflow-notes.md"), render_warp_workflow_notes_doc(manifest))
    end

    def render_antigravity(output_root, manifest)
      ag_dir = File.join(output_root, ".vibe", "antigravity")
      FileUtils.mkdir_p(ag_dir)

      File.write(File.join(output_root, "AGENTS.md"), <<~MD)
        # Vibe workflow for Antigravity

        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.
        Applied overlay: #{overlay_sentence(manifest)}

        Primary behavior is defined here, with supporting notes under `.vibe/antigravity/`.

        Keep repository files as the SSOT, verify before claiming completion, and follow the generated routing + safety rules.

        ## Non-negotiable rules

        #{bullet_policy_summary(filtered_policies(manifest, %w[always_on routing safety]))}

        ## Capability routing

        #{bullet_mapping(manifest["profile_mapping"])}

        ## Mandatory portable skills

        #{bullet_skill_summary(mandatory_skills(manifest))}

        ## Target requirements

        - Understand task tracking files and project documentation before execution.
        - Treat `.vibe/antigravity/` documents as authoritative framework conventions.
        - Escalations and security policy constraints are detailed in `.vibe/antigravity/safety.md`.

        ## Safety floor

        #{bullet_target_actions(manifest)}
      MD

      File.write(File.join(ag_dir, "behavior-policies.md"), render_behavior_doc(manifest))
      File.write(File.join(ag_dir, "routing.md"), render_routing_doc(manifest))
      File.write(File.join(ag_dir, "safety.md"), render_safety_doc(manifest))
      File.write(File.join(ag_dir, "skills.md"), render_skills_doc(manifest))
      File.write(File.join(ag_dir, "task-routing.md"), render_task_routing_doc(manifest))
      File.write(File.join(ag_dir, "test-standards.md"), render_test_standards_doc(manifest))
    end

    def render_vscode(output_root, manifest)
      vscode_dir = File.join(output_root, ".vscode")
      vibe_dir = File.join(output_root, ".vibe", "vscode")
      FileUtils.mkdir_p(vscode_dir)
      FileUtils.mkdir_p(vibe_dir)

      File.write(File.join(output_root, "AGENTS.md"), <<~MD)
        # Vibe workflow for VS Code

        Generated from the portable `core/` spec with profile `#{manifest["profile"]}`.
        Applied overlay: #{overlay_sentence(manifest)}

        VS Code (Copilot Chat) instructions use these generated guidelines as the baseline.

        ## Non-negotiable rules

        #{bullet_policy_summary(filtered_policies(manifest, %w[always_on routing safety]))}

        ## Capability routing

        #{bullet_mapping(manifest["profile_mapping"])}

        ## Mandatory portable skills

        #{bullet_skill_summary(mandatory_skills(manifest))}

        ## Safety floor

        #{bullet_target_actions(manifest)}
      MD

      File.write(File.join(vibe_dir, "behavior-policies.md"), render_behavior_doc(manifest))
      File.write(File.join(vibe_dir, "routing.md"), render_routing_doc(manifest))
      File.write(File.join(vibe_dir, "safety.md"), render_safety_doc(manifest))
      File.write(File.join(vibe_dir, "skills.md"), render_skills_doc(manifest))
      File.write(File.join(vibe_dir, "task-routing.md"), render_task_routing_doc(manifest))
      File.write(File.join(vibe_dir, "test-standards.md"), render_test_standards_doc(manifest))

      write_json(File.join(vscode_dir, "settings.json"), vscode_settings_config(manifest))
    end

    private

    def generate_superpowers_section(status, manifest)
      manifest_skills = Array(manifest["skills"]).select { |skill| skill["namespace"] == "superpowers" }
      return "" if manifest_skills.empty?

      location = case status
                 when :claude_plugin then "~/.claude/plugins/superpowers"
                 when :skills_symlink then "~/.claude/skills/superpowers-*"
                 when :local_clone then "~/superpowers"
                 when :cursor_plugin then "Cursor plugins"
                 else "Unknown"
                 end

      header = <<~MD

        ## Superpowers Skill Pack Integration

        **Status**: ✅ Installed (#{location})

        The following portable Superpowers skills are available for on-demand invocation:

        | Portable skill | Trigger mode | Description |
        |----------------|--------------|-------------|
      MD
      rows = manifest_skills.map do |skill|
        "| `#{skill['id']}` | `#{skill['trigger_mode']}` | #{skill['intent']} |"
      end.join("\n")

      footer = <<~MD


        **Usage**: `core/skills/registry.yaml` is the SSOT for portable skill IDs. The installed Superpowers pack may expose different native skill names.

        **Security**: All Superpowers skills have been reviewed and are considered safe for use.
        See `core/integrations/superpowers.yaml` for full skill definitions.
      MD

      header + rows + footer
    end
  end
end
