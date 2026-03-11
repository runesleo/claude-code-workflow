# frozen_string_literal: true

require "json"
require "yaml"
require "open3"
require "pathname"
require_relative "errors"

module Vibe
  # External tool detection and integration support.
  #
  # Host requirements:
  #   @repo_root [String] — absolute path to the workflow repository root
  module ExternalTools
    # Load integration config for a specific tool
    def load_integration_config(tool_name)
      config_path = File.join(@repo_root, "core/integrations/#{tool_name}.yaml")
      return nil unless File.exist?(config_path)

      YAML.safe_load(File.read(config_path), aliases: true)
    rescue StandardError => e
      warn "Failed to load integration config for #{tool_name}: #{e.message}"
      nil
    end

    # Get all available integration configs
    def list_integrations
      integrations_dir = File.join(@repo_root, "core/integrations")
      return [] unless Dir.exist?(integrations_dir)

      Dir.glob(File.join(integrations_dir, "*.yaml")).map do |path|
        File.basename(path, ".yaml")
      end.reject { |name| name == "README" }
    end

    # --- Superpowers Detection ---

    # Platform-specific superpowers paths.
    # skills_dir: directory where individual skill symlinks are created.
    # skills_source: the superpowers skills source directory that symlinks point into.
    SUPERPOWERS_PLATFORM_PATHS = {
      "claude-code" => {
        plugin: "~/.claude/plugins/superpowers",
        skills_dir: "~/.claude/skills",
        skills_source: "~/.config/skills/superpowers/skills"
      },
      "cursor" => {
        plugin: "~/.cursor/plugins/superpowers"
      },
      "opencode" => {
        plugin: "~/.config/opencode/plugins/superpowers.js",
        skills_dir: "~/.config/opencode/skills",
        skills_source: "~/.config/skills/superpowers/skills"
      },
      "kimi-code" => {
        plugin: "~/.config/agents/plugins/superpowers",
        skills_dir: "~/.config/agents/skills",
        skills_source: "~/.config/skills/superpowers/skills"
      },
      "codex-cli" => {
        skills_dir: "~/.codex/skills",
        skills_source: "~/.config/skills/superpowers/skills"
      }
    }.freeze

    def detect_superpowers(target_platform = nil)
      skip_integrations = defined?(@skip_integrations) ? @skip_integrations : false
      return :not_installed if skip_integrations

      current_platform = defined?(@target_platform) ? @target_platform : nil
      platform = target_platform || current_platform

      # Platform-specific detection
      if platform && SUPERPOWERS_PLATFORM_PATHS[platform]
        paths = SUPERPOWERS_PLATFORM_PATHS[platform]

        if paths[:plugin]
          expanded = File.expand_path(paths[:plugin])
          return :platform_plugin if File.exist?(expanded) || Dir.exist?(expanded)
        end

        if paths[:skills_dir] && paths[:skills_source]
          skills_dir = File.expand_path(paths[:skills_dir])
          source_dir = File.expand_path(paths[:skills_source])
          if Dir.exist?(skills_dir) && superpowers_symlinks_in(skills_dir, source_dir).any?
            return :platform_skills
          end
        end
      end

      # Cross-platform fallback: check common locations
      claude_plugins = File.expand_path("~/.claude/plugins/superpowers")
      return :claude_plugin if Dir.exist?(claude_plugins)

      # Check XDG-compliant shared location
      shared_clone = File.expand_path("~/.config/skills/superpowers")
      return :shared_clone if Dir.exist?(shared_clone)

      local_clone = File.expand_path("~/superpowers")
      return :local_clone if Dir.exist?(local_clone)

      cursor_plugins = File.expand_path("~/.cursor/plugins/superpowers")
      return :cursor_plugin if Dir.exist?(cursor_plugins)

      :not_installed
    end

    def superpowers_location(target_platform = nil)
      current_platform = defined?(@target_platform) ? @target_platform : nil
      platform = target_platform || current_platform

      case detect_superpowers(platform)
      when :platform_plugin
        paths = SUPERPOWERS_PLATFORM_PATHS[platform]
        File.expand_path(paths[:plugin]) if paths
      when :platform_skills
        paths = SUPERPOWERS_PLATFORM_PATHS[platform]
        File.expand_path(paths[:skills_dir]) if paths
      when :claude_plugin
        File.expand_path("~/.claude/plugins/superpowers")
      when :shared_clone
        File.expand_path("~/.config/skills/superpowers")
      when :local_clone
        File.expand_path("~/superpowers")
      when :cursor_plugin
        File.expand_path("~/.cursor/plugins/superpowers")
      else
        nil
      end
    end

    def superpowers_skills_count(target_platform = nil)
      current_platform = defined?(@target_platform) ? @target_platform : nil
      platform = target_platform || current_platform

      if platform && SUPERPOWERS_PLATFORM_PATHS[platform]
        paths = SUPERPOWERS_PLATFORM_PATHS[platform]
        if paths[:skills_dir] && paths[:skills_source]
          skills_dir = File.expand_path(paths[:skills_dir])
          source_dir = File.expand_path(paths[:skills_source])
          links = superpowers_symlinks_in(skills_dir, source_dir)
          return links.size if links.any?
        end
      end

      # Fallback: count skills in the shared clone
      shared_skills = File.expand_path("~/.config/skills/superpowers/skills")
      return Dir.children(shared_skills).size if Dir.exist?(shared_skills)

      0
    end

    # Returns entries in skills_dir whose symlink targets are inside source_dir.
    # Handles both relative and absolute symlink paths, and skips broken symlinks.
    def superpowers_symlinks_in(skills_dir, source_dir)
      return [] unless Dir.exist?(skills_dir)

      normalized_source = File.expand_path(source_dir)

      Dir.children(skills_dir).select do |entry|
        link_path = File.join(skills_dir, entry)
        next false unless File.symlink?(link_path)

        begin
          # Resolve symlink target to absolute path
          target = File.readlink(link_path)
          # Handle relative symlinks by resolving from the link's directory
          absolute_target = Pathname.new(target).absolute? ? target : File.expand_path(target, skills_dir)

          # Check if target is inside source_dir
          absolute_target.start_with?(normalized_source)
        rescue Errno::ENOENT, Errno::ELOOP
          # Skip broken or circular symlinks
          warn "Warning: Broken symlink detected: #{link_path}" if ENV["VIBE_DEBUG"]
          false
        end
      end
    end

    # --- RTK Detection ---

    def detect_rtk
      skip_integrations = defined?(@skip_integrations) ? @skip_integrations : false
      return :not_installed if skip_integrations

      # Method 1: Check if rtk binary is in PATH
      return :installed if system("which", "rtk", out: File::NULL, err: File::NULL)

      # Method 2: Check Claude settings.json for hook
      return :hook_configured if rtk_hook_configured?

      :not_installed
    end

    def rtk_version
      return nil unless detect_rtk == :installed

      version_output, status = Open3.capture2("rtk", "--version", err: File::NULL)
      status.success? && !version_output.strip.empty? ? version_output.strip : nil
    rescue StandardError => e
      warn "Warning: Failed to get RTK version: #{e.message}" if ENV["VIBE_DEBUG"]
      nil
    end

    def rtk_binary_path
      return nil unless detect_rtk == :installed

      path_output, status = Open3.capture2("which", "rtk", err: File::NULL)
      status.success? ? path_output.strip : nil
    rescue StandardError => e
      warn "Warning: Failed to get RTK binary path: #{e.message}" if ENV["VIBE_DEBUG"]
      nil
    end

    def rtk_hook_configured?
      settings_path = File.expand_path("~/.claude/settings.json")
      return false unless File.exist?(settings_path)

      begin
        settings = JSON.parse(File.read(settings_path))
        
        # Check new PreToolUse hook format (RTK 0.27+)
        pre_tool_use = settings.dig("hooks", "PreToolUse")
        if pre_tool_use.is_a?(Array)
          pre_tool_use.each do |hook_config|
            next unless hook_config["matcher"] == "Bash"
            hooks = hook_config["hooks"]
            if hooks.is_a?(Array)
              hooks.each do |h|
                return true if h["command"]&.include?("rtk")
              end
            end
          end
        end
        
        # Fallback: check old bashCommandPrepare format
        hook = settings.dig("hooks", "bashCommandPrepare")
        hook.is_a?(String) && hook.include?("rtk")
      rescue JSON::ParserError
        false
      end
    end

    # --- Installation Helpers ---

    def install_rtk_via_homebrew
      return false unless system("which", "brew", out: File::NULL, err: File::NULL)

      puts "Installing RTK via Homebrew..."
      system("brew", "install", "rtk")
    end


    def configure_rtk_hook
      return false unless detect_rtk == :installed

      puts "Configuring RTK hook..."
      system("rtk", "init", "--global")
    end

    # --- Verification ---

    def verify_superpowers(target_platform = nil)
      current_platform = defined?(@target_platform) ? @target_platform : nil
      platform = target_platform || current_platform
      
      status = detect_superpowers(platform)
      return { installed: false } if status == :not_installed

      location = superpowers_location(platform)

      # For platform-specific detection, it's both installed and ready
      if status == :platform_plugin || status == :platform_skills
        return {
          installed: true,
          ready: true,
          method: status,
          location: location,
          skills_count: superpowers_skills_count(platform)
        }
      end

      # For fallback detection (shared_clone, local_clone, etc.):
      # platform is "ready" only if we can confirm platform-specific integration exists.
      # Unknown platforms (no entry in SUPERPOWERS_PLATFORM_PATHS) are assumed ready.
      platform_ready = platform.nil? || !SUPERPOWERS_PLATFORM_PATHS.key?(platform)

      # If platform has specific paths, check if they're actually configured
      if platform && SUPERPOWERS_PLATFORM_PATHS.key?(platform)
        paths = SUPERPOWERS_PLATFORM_PATHS[platform]
        if paths[:plugin]
          expanded = File.expand_path(paths[:plugin])
          platform_ready = true if File.exist?(expanded) || Dir.exist?(expanded)
        end
        if !platform_ready && paths[:skills_dir] && paths[:skills_source]
          skills_dir = File.expand_path(paths[:skills_dir])
          source_dir = File.expand_path(paths[:skills_source])
          platform_ready = true if superpowers_symlinks_in(skills_dir, source_dir).any?
        end
      end

      {
        installed: true,
        ready: platform_ready,
        method: status,
        location: location,
        skills_count: superpowers_skills_count(platform),
        platform_configured: platform_ready
      }
    end

    def verify_rtk(target_platform = nil)
      current_platform = defined?(@target_platform) ? @target_platform : nil
      platform = target_platform || current_platform
      
      status = detect_rtk
      hook_configured = rtk_hook_configured?
      binary_installed = (status == :installed)

      # For non-claude-code platforms, hook is not required
      rtk_needs_hook = platform.nil? || platform == "claude-code"
      ready = binary_installed && (rtk_needs_hook ? hook_configured : true)

      {
        installed: binary_installed,
        ready: ready,
        status: status,
        binary: binary_installed ? rtk_binary_path : nil,
        version: binary_installed ? rtk_version : nil,
        hook_configured: hook_configured
      }
    end

    # --- Integration Status Summary ---

    def integration_status
      @_integration_status_cache ||= {
        superpowers: verify_superpowers,
        rtk: verify_rtk
      }
    end

    # Clear cached integration status (call after install/configure actions)
    def reset_integration_status!
      @_integration_status_cache = nil
    end

    def all_integrations_installed?
      status = integration_status
      status.values.all? { |s| s[:installed] }
    end

    def missing_integrations
      status = integration_status
      status.select { |_name, s| !s[:installed] }.keys
    end

    def pending_integrations
      status = integration_status
      status.select { |_name, s| !s[:ready] }.keys
    end

    def all_integrations_ready?
      status = integration_status
      status.values.all? { |s| s[:ready] }
    end
  end
end

