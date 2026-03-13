# frozen_string_literal: true

require_relative "platform_utils"

module Vibe
  # Platform verification and setup suggestions.
  #
  # Host requirements:
  #   @repo_root [String] — absolute path to the workflow repository root
  #
  # Dependencies:
  #   - Vibe::PlatformUtils — for platform-related utilities
  module PlatformVerifier
    include PlatformUtils

    # Verify if a specific platform is installed
    # @param platform [String] Platform name
    def verify_platform_installation(platform)
      target = normalize_target(platform)
      destination = default_global_destination(target)
      
      puts "Target platform: #{platform_label(platform)}"
      puts

      if Dir.exist?(destination)
        puts "✅ #{platform_label(platform)} configuration found at #{destination}"

        marker = File.join(destination, ".vibe-target.json")
        if File.exist?(marker)
          data = JSON.parse(File.read(marker))
          puts "   Profile: #{data['profile']}"
          puts "   Mode: #{data['mode']}"
        end
      else
        puts "❌ #{platform_label(platform)} configuration not found"
        puts "   Expected location: #{destination}"
        puts "   Run: vibe init --platform #{platform}"
      end
    end

    # Display setup suggestions for a platform
    # @param platform [String] Platform name
    def suggest_platform_setup(platform)
      target = normalize_target(platform)
      destination = default_global_destination(target)

      puts "Suggested setup for #{platform_label(platform)}:"
      puts
      puts "1. Install global configuration:"
      puts "   vibe init --platform #{platform}"
      puts
      puts "2. Configuration will be installed to:"
      puts "   #{destination}"
      puts
      puts "3. Then in your project directory:"
      puts "   vibe apply #{platform}"
      puts

      # Show integration suggestions
      if respond_to?(:suggest_integrations, true)
        puts
        suggest_integrations
      end
    end

    # Verify all supported platforms
    def verify_all_platforms
      puts
      installed = []
      not_installed = []

      supported_targets = Vibe::PlatformUtils::VALID_TARGETS
      supported_targets.each do |target|
        destination = default_global_destination(target)
        if Dir.exist?(destination)
          installed << target
        else
          not_installed << target
        end
      end

      if installed.any?
        puts "✅ Installed platforms:"
        installed.each do |target|
          puts "   - #{platform_label(target)}"
        end
      end

      if not_installed.any?
        puts "❌ Not installed platforms:"
        not_installed.each do |target|
          puts "   - #{platform_label(target)}"
        end
      end

      puts
      puts "Run 'vibe init --platform PLATFORM' to install a platform."
    end
  end
end
