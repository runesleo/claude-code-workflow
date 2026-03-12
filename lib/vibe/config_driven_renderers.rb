# frozen_string_literal: true

require "yaml"

module Vibe
  # Configuration-driven target renderers.
  # Replaces the verbose per-target methods with declarative configuration.
  module ConfigDrivenRenderers
    # Load platform configuration from YAML
    def platform_configs
      @platform_configs ||= begin
        # Try current repo root first, then fall back to original repo
        config_path = File.join(@repo_root, "config", "platforms.yaml")
        unless File.exist?(config_path)
          # Fall back to original workflow repo
          original_repo = File.expand_path("../../../..", __FILE__)
          config_path = File.join(original_repo, "config", "platforms.yaml")
        end
        YAML.safe_load(File.read(config_path), aliases: true)["platforms"]
      end
    end

    # Generic platform renderer
    def render_platform(output_root, manifest, platform_id, project_level: false)
      config = platform_configs[platform_id]
      raise ArgumentError, "Unknown platform: #{platform_id}" unless config

      mode = project_level ? "project" : "global"
      path_config = config.dig("output_paths", mode)
      doc_types = config.dig("doc_types", mode) || []

      # Write target docs
      vibe_dir = File.join(output_root, path_config["vibe_subdir"])
      FileUtils.mkdir_p(vibe_dir)
      write_target_docs(vibe_dir, manifest, doc_types.map(&:to_sym))

      # Generate README.md in vibe directory
      File.write(File.join(vibe_dir, "README.md"), generate_vibe_readme(manifest, platform_id))

      # Copy runtime directories if configured
      if config["runtime_dirs"] && !config["runtime_dirs"].empty?
        copy_runtime_dirs(output_root, config["runtime_dirs"], mode)
      end

      # Generate native config if configured
      native_config = config.dig("native_config", mode)
      if native_config
        generate_native_config(output_root, manifest, native_config)
      end

      # Generate entrypoint
      generate_entrypoint(output_root, manifest, path_config["entrypoint_name"])

      # Platform-specific hooks
      send("after_render_#{platform_id}", output_root, manifest, mode) if respond_to?("after_render_#{platform_id}", true)
    end

    # Render Claude Code (delegates to generic renderer)
    def render_claude_v2(output_root, manifest, project_level: false)
      render_platform(output_root, manifest, "claude-code", project_level: project_level)
    end

    # Render OpenCode (delegates to generic renderer)
    def render_opencode_v2(output_root, manifest, project_level: false)
      render_platform(output_root, manifest, "opencode", project_level: project_level)
    end

    private

    # Copy runtime directories based on configuration
    def copy_runtime_dirs(output_root, dirs, mode)
      dirs.each do |entry|
        source = File.join(@repo_root, entry)
        next unless File.exist?(source)

        destination = File.join(output_root, entry)

        if File.directory?(source)
          FileUtils.mkdir_p(destination)
          copy_tree_contents(source, destination)
        else
          FileUtils.mkdir_p(File.dirname(destination))
          FileUtils.cp(source, destination)
        end
      end
    end

    # Generate native configuration file
    def generate_native_config(output_root, manifest, config)
      config_path = File.join(output_root, config["filename"])

      case config["type"]
      when "json"
        # Use existing native config methods
        method_name = config["filename"].gsub(".", "_").gsub("-", "_")
        if respond_to?(method_name)
          content = send(method_name, manifest)
          write_json(config_path, content)
        end
      end
    end

    # Generate entrypoint file
    def generate_entrypoint(output_root, manifest, filename)
      entrypoint_path = File.join(output_root, filename)

      content = case File.extname(filename)
                when ".md"
                  render_target_entrypoint_md(platform_label(manifest["target"]), manifest)
                when ".json"
                  # JSON entrypoints are handled by native_config
                  return
                else
                  "# #{manifest["target"]} configuration\n"
                end

      File.write(entrypoint_path, content)
    end

    # Claude Code specific hook
    def after_render_claude_code(output_root, manifest, mode)
      # Add Superpowers integration if installed
      superpowers_status = detect_superpowers
      return if superpowers_status == :not_installed

      skill_triggers_source = File.join(@repo_root, "rules", "skill-triggers.md")
      skill_triggers_dest = File.join(output_root, "rules", "skill-triggers.md")

      return unless File.exist?(skill_triggers_source)

      content = File.read(skill_triggers_source)
      superpowers_section = generate_superpowers_section(manifest)
      enhanced_content = superpowers_section.empty? ? content : content + "\n" + superpowers_section

      File.write(skill_triggers_dest, enhanced_content)
    end

    # Generate README for .vibe/<target>/ directory
    def generate_vibe_readme(manifest, platform_id)
      target_label = platform_label(platform_id)
      config = platform_configs[platform_id]
      runtime_assets = config["runtime_dirs"]&.map { |d| "- `#{d}/`" }&.join("\n") || ""

      <<~MD
        # #{target_label} target

        This output is intended to be copied into a #{target_label} config directory such as `~/.#{platform_id}`.

        Included runtime assets:
        #{runtime_assets}
        - `#{config.dig("native_config", "global", "filename") || "settings.json"}`

        Active profile: `#{manifest["profile"]}``
        Applied overlay: #{overlay_sentence(manifest)}
        Generated summary: `.vibe/target-summary.md`
      MD
    end
  end
end
