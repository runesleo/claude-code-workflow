# frozen_string_literal: true

require "json"
require "yaml"
require "open3"
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

      YAML.load_file(config_path)
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

    def detect_superpowers
      # Method 1: Check Claude Code plugin directory
      claude_plugins = File.expand_path("~/.claude/plugins/superpowers")
      return :claude_plugin if Dir.exist?(claude_plugins)

      # Method 2: Check Claude Code skills directory for superpowers symlinks
      claude_skills = File.expand_path("~/.claude/skills")
      if Dir.exist?(claude_skills)
        superpowers_skills = Dir.glob(File.join(claude_skills, "superpowers-*"))
        return :skills_symlink if superpowers_skills.any?
      end

      # Method 3: Check for local clone
      local_clone = File.expand_path("~/superpowers")
      return :local_clone if Dir.exist?(local_clone)

      # Method 4: Check Cursor plugin directory
      cursor_plugins = File.expand_path("~/.cursor/plugins/superpowers")
      return :cursor_plugin if Dir.exist?(cursor_plugins)

      :not_installed
    end

    def superpowers_location
      case detect_superpowers
      when :claude_plugin
        File.expand_path("~/.claude/plugins/superpowers")
      when :skills_symlink
        skills = Dir.glob(File.expand_path("~/.claude/skills/superpowers-*"))
        skills.first
      when :local_clone
        File.expand_path("~/superpowers")
      when :cursor_plugin
        File.expand_path("~/.cursor/plugins/superpowers")
      else
        nil
      end
    end

    def superpowers_skills_count
      location = superpowers_location
      return 0 unless location

      skills_dir = File.join(location, "skills")
      return 0 unless Dir.exist?(skills_dir)

      Dir.glob(File.join(skills_dir, "*/SKILL.md")).count
    end

    # --- RTK Detection ---

    def detect_rtk
      # Method 1: Check if rtk binary is in PATH
      return :installed if system(["which", "which"], "rtk", out: File::NULL, err: File::NULL)

      # Method 2: Check Claude settings.json for hook
      return :hook_configured if rtk_hook_configured?

      :not_installed
    end

    def rtk_version
      return nil unless detect_rtk == :installed

      version_output, status = Open3.capture2(["rtk", "rtk"], "--version", err: File::NULL)
      status.success? && !version_output.strip.empty? ? version_output.strip : nil
    rescue StandardError
      nil
    end

    def rtk_binary_path
      return nil unless detect_rtk == :installed

      path_output, status = Open3.capture2(["which", "which"], "rtk", err: File::NULL)
      status.success? ? path_output.strip : nil
    rescue StandardError
      nil
    end

    def rtk_hook_configured?
      settings_path = File.expand_path("~/.claude/settings.json")
      return false unless File.exist?(settings_path)

      begin
        settings = JSON.parse(File.read(settings_path))
        hook = settings.dig("hooks", "bashCommandPrepare")
        !hook.nil? && hook.include?("rtk")
      rescue JSON::ParserError
        false
      end
    end

    # --- Installation Helpers ---

    def install_rtk_via_homebrew
      return false unless system(["which", "which"], "brew", out: File::NULL, err: File::NULL)

      puts "Installing RTK via Homebrew..."
      system(["brew", "brew"], "install", "rtk")
    end


    def configure_rtk_hook
      return false unless detect_rtk == :installed

      puts "Configuring RTK hook..."
      system(["rtk", "rtk"], "init", "--global")
    end

    # --- Verification ---

    def verify_superpowers
      status = detect_superpowers
      return { installed: false } if status == :not_installed

      {
        installed: true,
        ready: true,
        method: status,
        location: superpowers_location,
        skills_count: superpowers_skills_count
      }
    end

    def verify_rtk
      status = detect_rtk
      hook_configured = rtk_hook_configured?
      binary_installed = (status == :installed)

      {
        installed: binary_installed,
        ready: binary_installed && hook_configured,
        status: status,
        binary: binary_installed ? rtk_binary_path : nil,
        version: binary_installed ? rtk_version : nil,
        hook_configured: hook_configured
      }
    end

    # --- Integration Status Summary ---

    def integration_status
      {
        superpowers: verify_superpowers,
        rtk: verify_rtk
      }
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

