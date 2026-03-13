# frozen_string_literal: true

require_relative "platform_utils"
require_relative "user_interaction"

module Vibe
  # Integration setup and configuration.
  #
  # Host requirements:
  #   @repo_root [String] — absolute path to the workflow repository root
  #
  # Dependencies:
  #   - Vibe::PlatformUtils — for platform-related utilities
  #   - Vibe::UserInteraction — for user prompts
  module IntegrationSetup
    include PlatformUtils
    include UserInteraction

    # Setup all integrations interactively
    def setup_integrations
      puts "Checking external integrations..."
      puts
      ensure_interactive_setup_available!

      # Load integrations from recommended.yaml
      integrations = get_recommended_integration_list
      if integrations.empty?
        # Fallback to hardcoded list if config not available
        integrations = [
          { "name" => "superpowers", "label" => "Superpowers Skill Pack", "priority" => "P1" },
          { "name" => "rtk", "label" => "RTK (Token Optimizer)", "priority" => "P2" }
        ]
      end

      integrations.each_with_index do |integration, index|
        setup_integration(integration["name"], integration["label"], index + 1, integrations.size)
      end

      puts
      puts "Configuration Summary"
      puts "=" * 50
      puts

      display_summary

      puts
      puts "Next steps:"
      if pending_integrations.any?
        puts "1. Complete the installation steps above"
        puts "2. Run: bin/vibe init --verify"
      else
        puts "1. Run: bin/vibe init --verify"
      end
      puts "2. Start using: claude"
      puts
      puts "For more information: docs/integrations.md"
      puts
    end

    # Setup a single integration
    # @param name [String] Integration name
    # @param label [String] Human-readable label
    # @param order [Integer] Current order number
    # @param total [Integer] Total number of integrations
    def setup_integration(name, label, order, total)
      puts "[#{order}/#{total}] #{label}"

      config = load_integration_config(name)
      unless config
        puts "   ⚠ Configuration not found"
        puts
        return
      end

      info = send("verify_#{name}")
      puts "   Status: #{setup_status_message(name, info)}"

      if info[:ready]
        puts
        return
      end

      if info[:installed]
        puts
        complete_integration_setup(name, info)
        puts
        return
      end

      puts
      display_integration_description(config)
      puts

      if ask_yes_no("   Would you like to install #{label}?")
        install_integration(name, config)
      else
        puts "   Skipped."
      end

      puts
    end

    # Get status message for integration setup
    # @param name [String] Integration name
    # @param info [Hash] Integration status info
    # @return [String] Status message
    def setup_status_message(name, info)
      case name
      when "superpowers"
        return "Already installed (#{info[:method]})" if info[:ready]
      when "rtk"
        return "Already installed (binary + hook configured)" if info[:ready]
        return "Installed, hook not configured" if info[:installed]
        return "Hook configured, but RTK binary was not found" if info[:hook_configured]
      end

      "Not installed"
    end

    # Complete setup for a partially installed integration
    # @param name [String] Integration name
    # @param info [Hash] Integration status info
    def complete_integration_setup(name, info)
      case name
      when "rtk"
        puts "   Binary: #{info[:binary]}" if info[:binary]
        puts "   Hook: #{info[:hook_configured] ? 'Configured' : 'Not configured'}"
        unless info[:hook_configured]
          if ask_yes_no("   Configure RTK hook now?")
            configure_rtk_hook
          end
        end
      end
    end

    # Display integration description
    # @param config [Hash] Integration configuration
    def display_integration_description(config)
      puts "   #{config['description']}"
      puts
      puts "   Benefits:"
      (config['benefits'] || []).each do |benefit|
        puts "   • #{benefit}"
      end
    end

    # Install an integration
    # @param name [String] Integration name
    # @param config [Hash] Integration configuration
    def install_integration(name, config)
      case name
      when "superpowers"
        install_superpowers(config)
      when "rtk"
        install_rtk_interactive(config)
      else
        puts "   ⚠ Installation not implemented for #{name}"
      end
    end
  end
end
