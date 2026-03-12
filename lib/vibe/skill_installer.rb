# frozen_string_literal: true

require_relative 'skill_manager'
require_relative 'superpowers_installer'

module Vibe
  # Wrapper for skill pack installation with automatic adaptation
  #
  # Usage:
  #   installer = SkillInstaller.new(repo_root)
  #   installer.install('superpowers', platform: 'claude-code')
  #
  class SkillInstaller
    SUPPORTED_PACKS = %w[superpowers].freeze

    attr_reader :repo_root, :project_root

    def initialize(repo_root, project_root = Dir.pwd)
      @repo_root = repo_root
      @project_root = project_root
    end

    # Install a skill pack and adapt its skills
    #
    # @param pack_name [String] Name of skill pack to install
    # @param platform [String] Target platform
    # @param auto_adapt [Boolean] Auto-adapt skills after installation
    # @return [Boolean] Installation success
    def install(pack_name, platform: nil, auto_adapt: false)
      unless SUPPORTED_PACKS.include?(pack_name)
        puts "❌ Unknown skill pack: #{pack_name}"
        puts "   Supported packs: #{SUPPORTED_PACKS.join(', ')}"
        return false
      end

      puts "\n🚀 Installing #{pack_name} Skill Pack"
      puts "=" * 60
      puts

      # Execute installation
      success = case pack_name
      when 'superpowers'
        install_superpowers(platform)
      else
        false
      end

      return false unless success

      # Detect and adapt new skills
      puts "\n🎉 Installation Complete!"
      puts

      adapt_new_skills(pack_name, auto_adapt: auto_adapt)

      true
    end

    # Preview what would be installed (dry run)
    #
    # @param pack_name [String] Name of skill pack
    # @param platform [String] Target platform
    def preview_installation(pack_name, platform: nil)
      puts "\n🔍 DRY RUN - Preview of #{pack_name} installation"
      puts "=" * 60
      puts

      case pack_name
      when 'superpowers'
        preview_superpowers_installation(platform)
      else
        puts "❌ Unknown skill pack: #{pack_name}"
      end

      puts "\n✅ This was a dry run. No changes were made."
      puts "   To actually install, run:"
      puts "   vibe install #{pack_name}"
      puts
    end

    private

    # Install Superpowers skill pack
    def install_superpowers(platform)
      platform ||= detect_current_platform

      puts "📦 Skill Pack: superpowers"
      puts "📍 Install Location: ~/.config/skills/superpowers"
      puts "🔧 Platform: #{platform}"
      puts

      # Use existing SuperpowersInstaller
      result = SuperpowersInstaller.install_superpowers_for_platform(platform)

      if result
        puts "\n✓ Superpowers installed successfully"
        true
      else
        puts "\n❌ Superpowers installation failed"
        false
      end
    end

    # Preview Superpowers installation
    def preview_superpowers_installation(platform)
      platform ||= detect_current_platform

      puts "📦 Skill Pack: superpowers"
      puts "📍 Install Location: ~/.config/skills/superpowers"
      puts "🔧 Platform: #{platform}"
      puts

      puts "Installation steps:"
      puts "  1. Clone from https://github.com/obra/superpowers.git"
      puts "  2. Create symlinks in platform skills directory"
      puts "  3. Detect available skills"
      puts "  4. Prompt for skill adaptation"
      puts

      puts "Expected skills to be available:"
      puts "  • superpowers/tdd"
      puts "  • superpowers/brainstorm"
      puts "  • superpowers/refactor"
      puts "  • superpowers/debug"
      puts "  • superpowers/architect"
      puts "  • superpowers/review"
      puts "  • superpowers/optimize"
      puts

      if Dir.exist?(File.expand_path('~/.config/skills/superpowers'))
        puts "⚠️  Note: Superpowers is already installed"
        puts "   Skills will be detected and available for adaptation"
      end
    end

    # Adapt new skills from installed pack
    def adapt_new_skills(pack_name, auto_adapt: false)
      manager = SkillManager.new(repo_root, project_root)

      # Update timestamp to trigger detection
      manager.update_check_timestamp

      # Detect new skills from this pack
      new_skills = manager.detector.detect_new_skills(pack_name)

      if new_skills.empty?
        puts "✓ No new skills to adapt from #{pack_name}"
        return
      end

      puts "🔍 Detected #{new_skills.length} new skills from #{pack_name}"
      puts

      if auto_adapt
        # Auto-adapt all as suggest
        puts "⚡ Auto-adapting all skills as suggest..."
        results = manager.adapter.adapt_all_as(new_skills, :suggest)
        show_adaptation_summary(results)
      else
        # Interactive adaptation
        results = manager.adapter.adapt_interactively(new_skills)
        show_adaptation_summary(results)
      end
    end

    # Show adaptation summary
    def show_adaptation_summary(results)
      puts "\n📊 Adaptation Summary"
      puts "=" * 60
      puts

      if results[:adapted]&.any?
        puts "✅ Adapted (#{results[:adapted].length} skills):"
        results[:adapted].each { |id| puts "   • #{id}" }
        puts
      end

      if results[:skipped]&.any?
        puts "⏸️  Skipped (#{results[:skipped].length} skills):"
        results[:skipped].each { |id| puts "   • #{id}" }
        puts "   You can adapt them later with: vibe skills adapt <id>"
        puts
      end

      puts "📝 Project configuration updated!"
      puts "   Configuration saved to: .vibe/skills.yaml"
      puts

      puts "🚀 Next Steps:"
      puts "   1. Review adapted skills: vibe skills list"
      puts "   2. Apply to project: vibe apply claude-code"
      puts "   3. View skill docs: vibe skills docs <id>"
      puts
    end

    # Detect current platform from environment
    def detect_current_platform
      # Check for installed platforms
      return 'claude-code' if Dir.exist?(File.expand_path('~/.claude'))
      return 'opencode' if Dir.exist?(File.expand_path('~/.config/opencode'))
      return 'codex-cli' if Dir.exist?(File.expand_path('~/.codex'))

      # Default
      'claude-code'
    end
  end
end
