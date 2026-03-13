# frozen_string_literal: true

require "json"
require "yaml"
require_relative "errors"
require_relative "platform_utils"
require_relative "user_interaction"
require_relative "platform_verifier"
require_relative "platform_installer"
require_relative "rtk_installer"
require_relative "integration_manager"
require_relative "quickstart_runner"
require_relative "superpowers_installer"
require_relative "integration_setup"
require_relative "integration_recommendations"
require_relative "integration_verifier"

module Vibe
  # Initialization and setup support for global platform configuration.
  #
  # Host requirements:
  #   @repo_root [String] — absolute path to the workflow repository root
  #
  # Cross-module dependencies:
  #   - Vibe::ValidationError (from errors.rb) — raised on validation failures
  #   - Vibe::PlatformUtils — platform-related utilities
  #   - Vibe::UserInteraction — user interaction utilities
  #   - Vibe::PlatformVerifier — platform verification logic
  #   - Vibe::PlatformInstaller — platform installation logic
  #   - Vibe::RtkInstaller — RTK installation logic
  #   - Vibe::IntegrationManager — integration detection and management
  #   - Vibe::QuickstartRunner — quickstart setup logic
  #   - Vibe::SuperpowersInstaller — Superpowers installation logic
  #   - Vibe::IntegrationSetup — integration setup logic
  #   - Vibe::IntegrationRecommendations — integration recommendations
  #   - Vibe::IntegrationVerifier — integration verification
  #   - JSON, YAML (stdlib) — for parsing configuration files
  module InitSupport
    include PlatformUtils
    include UserInteraction
    include PlatformVerifier
    include PlatformInstaller
    include RtkInstaller
    include IntegrationManager
    include QuickstartRunner
    include SuperpowersInstaller
    include IntegrationSetup
    include IntegrationRecommendations
    include IntegrationVerifier

    # Main initialization flow - installs global configuration
    def run_init(platform:, force: false, verify_only: false, suggest_only: false, dry_run: false)
      @target_platform = platform
      platform_name = platform_label(platform)

      puts "\n🚀 #{platform_name} Global Configuration Setup"
      puts "=" * 50
      puts

      if verify_only
        verify_platform_installation(platform)
        return
      end

      if suggest_only
        suggest_platform_setup(platform)
        return
      end

      if dry_run
        preview_global_config(platform: platform)
        return
      end

      # Install global configuration
      install_global_config(platform: platform, force: force)
    end

    def preview_global_config(platform:)
      target = normalize_target(platform)
      destination_root = default_global_destination(target)

      puts "🔍 DRY RUN - Preview of what would be installed:"
      puts
      puts "Target platform: #{platform_label(platform)}"
      puts "Install location: #{destination_root}"
      puts

      if Dir.exist?(destination_root)
        puts "⚠️  Configuration already exists at this location"
        puts "   (Would be overwritten with --force)"
        puts
      end

      puts "Files that would be created:"
      puts "  📄 #{config_entrypoint(target)}"
      puts "  📁 .vibe/#{target}/"
      puts "  📁 rules/"
      puts "  📁 docs/"
      puts "  📁 skills/"
      puts "  📁 agents/"
      puts "  📁 commands/"
      puts "  📁 memory/"
      puts

      puts "✅ This was a dry run. No changes were made."
      puts "   To actually install, run:"
      puts "   vibe init --platform #{platform}"
      puts
    end

    private

    def normalize_platform(platform)
      return "claude-code" if platform.nil?

      normalize_target(platform, strict: true)
    end

    def detect_current_platform
      return "claude-code" if Dir.exist?(File.expand_path("~/.claude"))
      return "cursor" if Dir.exist?(File.expand_path("~/.cursor"))
      return "opencode" if Dir.exist?(File.expand_path("~/.opencode"))
      return "codex-cli" if Dir.exist?(File.expand_path("~/.codex"))
      "claude-code"
    end
  end
end
