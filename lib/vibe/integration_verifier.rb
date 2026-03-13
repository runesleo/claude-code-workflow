# frozen_string_literal: true

require_relative "platform_utils"

module Vibe
  # Integration verification and summary display.
  #
  # Host requirements:
  #   @repo_root [String] — absolute path to the workflow repository root
  #
  # Dependencies:
  #   - Vibe::PlatformUtils — for platform-related utilities
  module IntegrationVerifier
    include PlatformUtils

    # Verify all integrations and display status
    # @param target_platform [String, nil] Optional target platform for explicit context
    def verify_integrations(target_platform = nil)
      platform = target_platform || @target_platform
      
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
        puts "1. Run: bin/vibe use #{platform} --destination <your-project>"
        puts "2. Or:  bin/vibe switch #{platform} (to apply to current repo)"
        puts "3. Start using: #{platform_command(platform)}"
      elsif rtk_needs_hook
        puts "RTK is installed but hook is not configured."
        puts "Run: rtk init --global"
        puts
        puts "After that, you can:"
        puts "  bin/vibe use #{platform} --destination <your-project>"
      else
        puts "Some integrations still need installation or configuration."
        puts "Run: bin/vibe init --setup (without --verify) to finish setup."
      end
      puts
    end

    # Display verification status for a single integration
    # @param name [Symbol] Integration name
    # @param info [Hash] Integration status info
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

    # Display summary of all integrations
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
  end
end
