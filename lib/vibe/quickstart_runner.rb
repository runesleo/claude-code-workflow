# frozen_string_literal: true

require_relative "platform_utils"
require_relative "user_interaction"
require_relative "integration_manager"

module Vibe
  # Quickstart setup for Claude Code.
  #
  # Host requirements:
  #   @repo_root [String] — absolute path to the workflow repository root
  #
  # Dependencies:
  #   - Vibe::PlatformUtils — for platform-related utilities
  #   - Vibe::UserInteraction — for user prompts
  #   - Vibe::IntegrationManager — for integration suggestions
  module QuickstartRunner
    include PlatformUtils
    include UserInteraction
    include IntegrationManager

    # Run quickstart setup for Claude Code
    # @param options [Hash] Options hash with :force key
    def run_quickstart(options = {})
      puts "\n⚡ Quickstart: Claude Code Setup"
      puts "=" * 50
      puts

      claude_home = File.expand_path("~/.claude")
      is_update = Dir.exist?(claude_home)

      if is_update
        puts "Claude Code configuration already exists at #{claude_home}."
        unless options[:force] || ask_yes_no("Would you like to overwrite it with the latest Vibe template?")
          puts "\nQuickstart cancelled. No changes made."
          return
        end
      else
        puts "Setting up Claude Code workflow in #{claude_home}..."
      end

      begin
        build_and_deploy_target(
          target: "claude-code",
          destination_root: claude_home,
          mode: "quickstart"
        )

        puts "\n✅ Success! Claude Code workflow has been #{is_update ? 'updated' : 'installed'}."
        puts

        # Check and suggest optional integrations (skip if @skip_integrations is set)
        check_and_suggest_integrations("claude-code") unless @skip_integrations

        puts "Next steps:"
        puts "1. Open #{File.join(claude_home, 'CLAUDE.md')} and customize these sections:"
        puts "   - User Info (name, project routes)"
        puts "   - Sub-project Memory Routes (map your projects to memory files)"
        puts "2. (Optional) Run `bin/vibe init` to install Superpowers or RTK."
        puts "3. Start a new session: claude"
        puts
      rescue StandardError => e
        puts "\n❌ Quickstart failed: #{e.message}"
        raise e
      end
    end
  end
end
