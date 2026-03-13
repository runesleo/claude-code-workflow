# frozen_string_literal: true

require_relative "platform_utils"
require_relative "user_interaction"

module Vibe
  # Platform installation logic.
  #
  # Host requirements:
  #   @repo_root [String] — absolute path to the workflow repository root
  #
  # Dependencies:
  #   - Vibe::PlatformUtils — for platform-related utilities
  #   - Vibe::UserInteraction — for user prompts
  module PlatformInstaller
    include PlatformUtils
    include UserInteraction

    # Build, copy, and write marker for a target to a destination.
    # Shared core used by install_global_config and quickstart.
    # @param target [String] Normalized target name
    # @param destination_root [String] Absolute path to destination
    # @param mode [String] Marker mode ("init", "quickstart", etc.)
    # @param project_level [Boolean] Whether this is project-level config
    # @return [Hash] The generated manifest
    def build_and_deploy_target(target:, destination_root:, mode:, project_level: false)
      profile_name, profile = resolve_profile(target, nil)
      output_root = resolve_output_root_for_use(
        target: target,
        destination_root: destination_root,
        explicit_output: nil
      )
      overlay = resolve_overlay(explicit_path: nil, search_roots: [destination_root, @repo_root])

      manifest = build_target(
        target: target,
        profile_name: profile_name,
        profile: profile,
        output_root: output_root,
        overlay: overlay,
        project_level: project_level
      )

      FileUtils.mkdir_p(destination_root)
      copy_tree_contents(output_root, destination_root)

      write_marker(
        File.join(destination_root, ".vibe-target.json"),
        destination_root: destination_root,
        manifest: manifest,
        output_root: output_root,
        mode: mode
      )

      manifest
    end

    # Install global configuration for a platform
    # @param platform [String] Platform name
    # @param force [Boolean] Force overwrite if config exists
    def install_global_config(platform:, force:)
      target = normalize_target(platform)
      destination_root = default_global_destination(target)

      is_update = Dir.exist?(destination_root)

      puts "Target platform: #{platform_label(platform)}"
      puts "Install location: #{destination_root}"
      puts

      if is_update && !force
        puts "⚠️  Configuration already exists at #{destination_root}"
        unless ask_yes_no("Overwrite?")
          puts "\nInstallation cancelled."
          return
        end
      end

      puts "Installing global configuration..."
      puts

      build_and_deploy_target(
        target: target,
        destination_root: destination_root,
        mode: "init",
        project_level: false
      )

      puts "✅ Success! #{platform_label(platform)} global configuration has been #{is_update ? 'updated' : 'installed'}."
      puts
      puts "Configuration location: #{destination_root}"
      puts

      # Check and suggest optional integrations
      check_and_suggest_integrations(platform) unless @skip_integrations

      puts "Next steps:"
      puts "1. Review and customize #{File.join(destination_root, config_entrypoint(target))}"
      puts "2. In your project directory, run: vibe switch --platform #{platform}"
      puts
    end
  end
end
