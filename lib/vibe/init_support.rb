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
    # Main initialization flow - installs global configuration
    def run_init(platform:, force: false, verify_only: false, suggest_only: false)
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

      # Install global configuration
      install_global_config(platform: platform, force: force)
    end

    # Note: install_global_config, verify_platform_installation, suggest_platform_setup,
    # and verify_all_platforms are now defined in PlatformInstaller and PlatformVerifier modules

    # Note: check_and_suggest_integrations and check_environment are now defined in IntegrationManager module
    # Note: run_quickstart is now defined in QuickstartRunner module
    # Note: setup_integrations and related methods are now defined in IntegrationSetup module
    # Note: suggest_integrations, install_recommended, and related methods are now defined in IntegrationRecommendations module

    private

    # Note: check_environment is now defined in IntegrationManager module
    # Note: setup_integrations and related methods are now defined in IntegrationSetup module
    # Note: suggest_integrations, install_recommended, and related methods are now defined in IntegrationRecommendations module

    # Note: Superpowers installation methods are now defined in SuperpowersInstaller module
    # Note: RTK installation methods are now defined in RtkInstaller module

    def suggest_integrations
      puts "Checking recommended integrations..."
      puts

      recommended = load_recommended_integrations
      unless recommended
        puts "⚠ Could not load recommendations configuration"
        return
      end

      suggested_by_category = {}
      category_order = recommended["category_order"] || recommended["categories"].keys

      category_order.each do |category|
        integrations = recommended.dig("categories", category) || []
        next if integrations.empty?

        integrations.each do |integration|
          name = integration["name"]
          info = send("verify_#{name}")
          next if info[:ready]  # Skip already installed

          suggested_by_category[category] ||= []
          suggested_by_category[category] << integration.merge("status" => info)
        end
      end

      if suggested_by_category.empty?
        puts "✓ All recommended integrations are already installed."
        puts
        return
      end

      puts "The following integrations are recommended but not yet installed:"
      puts

      category_order.each do |category|
        suggestions = suggested_by_category[category]
        next unless suggestions

        metadata = recommended.dig("category_metadata", category) || {}
        icon = metadata["icon"] || "•"
        label = metadata["label"] || category.to_s.split("_").map(&:capitalize).join(" ")
        description = metadata["description"]

        puts "#{icon} #{label}"
        puts "   #{description}" if description
        puts

        suggestions.each do |integration|
          display_integration_suggestion(integration)
        end
      end

      puts
      puts "To install these integrations interactively, run: bin/vibe init --setup"
      puts
    end

    def install_recommended(auto_yes: false)
      puts "Installing recommended integrations..."
      puts

      recommended = load_recommended_integrations
      unless recommended
        puts "⚠ Could not load recommendations configuration"
        return
      end

      # Collect integrations to install
      to_install = []
      category_order = recommended["category_order"] || recommended["categories"].keys

      category_order.each do |category|
        integrations = recommended.dig("categories", category) || []
        next if integrations.empty?

        integrations.each do |integration|
          name = integration["name"]
          info = send("verify_#{name}")
          next if info[:ready]  # Skip already installed

          to_install << {
            name: name,
            priority: integration["priority"],
            reason: integration["reason"],
            category: category,
            info: info
          }
        end
      end

      if to_install.empty?
        puts "✓ All recommended integrations are already installed."
        puts
        return
      end

      # Display what will be installed
      puts "The following integrations will be installed:"
      puts
      to_install.each do |item|
        label = item[:name].capitalize
        puts "  • #{label} (#{item[:priority]})"
        puts "    #{item[:reason]}"
        puts
      end

      # Confirm installation
      unless auto_yes
        puts "This will guide you through the installation process."
        unless $stdin.tty?
          puts
          puts "⚠ Non-interactive terminal detected."
          puts "Use 'bin/vibe init --install -y' to skip confirmation, or run in an interactive terminal."
          return
        end
        return unless ask_yes_no("Continue?")
        puts
      else
        puts "Auto-installing (--yes flag provided)..."
        puts
      end

      # Install each integration
      installed_count = 0
      to_install.each_with_index do |item, index|
        name = item[:name]
        label = name.capitalize

        puts "[#{index + 1}/#{to_install.size}] Installing #{label}..."
        puts

        config = load_integration_config(name)
        unless config
          puts "   ⚠ Configuration not found for #{name}"
          puts
          next
        end

        install_integration(name, config)
        installed_count += 1
        puts
      end

      # Summary
      puts "=" * 50
      puts "Installation Summary"
      puts "=" * 50
      puts
      puts "Attempted: #{to_install.size}"
      puts "Completed: #{installed_count}"
      puts
      puts "Next steps:"
      puts "1. Run: bin/vibe init --verify"
      puts "2. Start using: claude"
      puts
    end

    def verify_integrations
      puts "Verifying integrations..."
      puts

      status = integration_status
      rtk_needs_hook = false

      status.each do |name, info|
        verify_integration_display(name, info)
        rtk_needs_hook = true if name == :rtk && info[:installed] && !info[:hook_configured]
      end

      puts
      if all_integrations_ready?
        puts "All integrations verified successfully! 🎉"
        puts
        puts "Next steps:"
        puts "1. Run: bin/vibe use #{@target_platform} --destination <your-project>"
        puts "2. Or:  bin/vibe switch #{@target_platform} (to apply to current repo)"
        puts "3. Start using: #{platform_command(@target_platform)}"
      elsif rtk_needs_hook
        puts "RTK is installed but hook is not configured."
        puts "Run: rtk init --global"
        puts
        puts "After that, you can:"
        puts "  bin/vibe use #{@target_platform} --destination <your-project>"
      else
        puts "Some integrations still need installation or configuration."
        puts "Run: bin/vibe init --setup (without --verify) to finish setup."
      end
      puts
    end

    def verify_integration_display(name, info)
      label = case name
              when :superpowers then "Superpowers"
              when :rtk then "RTK"
              else name.to_s.capitalize
              end

      if info[:ready]
        puts "[✓] #{label}"
        case name
        when :superpowers
          puts "    Location: #{info[:location]}"
          puts "    Skills detected: #{info[:skills_count]}"
        when :rtk
          puts "    Binary: #{info[:binary]}"
          puts "    Version: #{info[:version]}"
          puts "    Hook: #{info[:hook_configured] ? 'Configured' : 'Not configured'}"
        end
        puts "    Status: Ready"
      elsif name == :rtk && info[:installed]
        puts "[!] #{label}"
        puts "    Binary: #{info[:binary]}"
        puts "    Version: #{info[:version]}"
        puts "    Hook: Not configured"
        puts "    Status: Installed, hook not configured"
      elsif name == :rtk && info[:hook_configured]
        puts "[!] #{label}"
        puts "    Binary: Not found"
        puts "    Hook: Configured"
        puts "    Status: Hook configured, but RTK binary was not found"
      else
        puts "[✗] #{label}"
        puts "    Status: Not installed"
      end
      puts
    end

    def display_summary
      status = integration_status

      status.each do |name, info|
        label = case name
                when :superpowers then "Superpowers"
                when :rtk then "RTK"
                else name.to_s.capitalize
                end

        if info[:ready]
          puts "✓ #{label}: Ready"
        elsif name == :rtk && info[:installed]
          puts "⚠ #{label}: Installed but hook not configured"
        elsif name == :rtk && info[:hook_configured]
          puts "⚠ #{label}: Hook configured but binary not found"
        else
          puts "⚠ #{label}: Installation instructions provided"
        end
      end
    end

    # --- Recommendation System ---

    def load_recommended_integrations
      yaml_path = File.join(@repo_root, "core", "integrations", "recommended.yaml")
      return nil unless File.exist?(yaml_path)

      YAML.safe_load(File.read(yaml_path), aliases: true)
    rescue StandardError => e
      warn "Warning: Failed to load recommended integrations: #{e.message}"
      nil
    end

    def display_integration_suggestion(integration)
      name = integration["name"]
      priority = integration["priority"] || "P2"
      reason = integration["reason"] || "No description available"
      benefits = integration["benefits_summary"]

      config = load_integration_config(name)

      priority_label = case priority
                       when "P1" then "Essential"
                       when "P2" then "Recommended"
                       when "P3" then "Optional"
                       else priority
                       end

      puts "   • #{name} [#{priority_label}]"
      puts "     #{reason}"
      puts "     Benefits: #{benefits}" if benefits

      if config
        # Show installation method
        installation_method = detect_best_installation_method(name, config)
        if installation_method
          puts "     Installation: #{installation_method}"
        end

        # Show source URL
        if config["source"]
          puts "     Source: #{config['source']}"
        end
      end

      puts
    end

    def detect_best_installation_method(name, config)
      methods = config["installation_methods"] || {}

      # Try to detect the best method based on current environment
      if methods["claude-code"] && Dir.exist?(File.expand_path("~/.claude"))
        commands = methods.dig("claude-code", "commands") || []
        return commands.first if commands.any?
      end

      if methods["manual"]
        steps = methods.dig("manual", "steps") || []
        return steps.first if steps.any?
      end

      nil
    end

    def get_recommended_integration_list
      recommended = load_recommended_integrations
      return [] unless recommended

      integrations = []
      categories = recommended["categories"] || {}

      categories.each_value do |category_integrations|
        category_integrations.each do |integration|
          integrations << {
            name: integration["name"],
            label: integration_label(integration["name"]),
            priority: integration["priority"] || "P2"
          }
        end
      end

      integrations
    end

    def integration_label(name)
      case name
      when "superpowers" then "Superpowers Skill Pack"
      when "rtk" then "RTK (Token Optimizer)"
      else name.to_s.split("_").map(&:capitalize).join(" ")
      end
    end

    private

    def normalize_platform(platform)
      return "claude-code" if platform.nil?

      normalized = platform.to_s.downcase.gsub("_", "-")
      valid_platforms = %w[antigravity claude-code codex-cli cursor kimi-code opencode vscode warp]

      unless valid_platforms.include?(normalized)
        raise ValidationError, "Unsupported platform: #{platform}. Valid options: #{valid_platforms.join(', ')}"
      end

      normalized
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
