# frozen_string_literal: true

# CLI commands for skill management
# These methods are included in VibeCLI class

require_relative '../skill_manager'
require_relative '../skill_installer'
require_relative '../skill_detector'
require_relative '../skill_adapter'

module Vibe
  module SkillsCommands
    # Main entry point for 'vibe skills' subcommand
    def run_skills_command(argv)
      subcommand = argv.shift

      case subcommand
      when 'check'
        run_skills_check(argv)
      when 'list'
        run_skills_list(argv)
      when 'adapt'
        run_skills_adapt(argv)
      when 'skip'
        run_skills_skip(argv)
      when 'docs'
        run_skills_docs(argv)
      when 'install'
        run_skills_install(argv)
      when nil, 'help', '--help', '-h'
        puts skills_usage
      else
        raise Vibe::ValidationError, "Unknown skills subcommand: #{subcommand}\n\n#{skills_usage}"
      end
    end

    # vibe skills check - Check for new skills
    def run_skills_check(argv)
      options = parse_skills_check_options(argv)

      manager = SkillManager.new(@repo_root, Dir.pwd)

      if options[:update_timestamp]
        manager.update_check_timestamp
        puts "✓ Updated last check timestamp"
        return
      end

      changes = manager.detector.check_skill_changes

      if changes[:new_skills].empty? && changes[:new_packs].empty?
        puts "\n✓ No new skills found."
        puts
        puts "Your project has #{manager.list_skills[:adapted].length} adapted skills."
        puts "Last checked: #{changes[:last_checked]}"
        puts
        puts "💡 Run 'vibe skills list' to see all adapted skills."
        return
      end

      # Show detection results
      if options[:auto_adapt]
        manager.check_and_prompt(auto_adapt: true)
      else
        manager.check_and_prompt(auto_adapt: false)
      end
    end

    # vibe skills list - List all skills
    def run_skills_list(argv)
      manager = SkillManager.new(@repo_root, Dir.pwd)
      skills = manager.list_skills

      puts "\n📋 Skill Status"
      puts "=" * 60
      puts

      # Mandatory skills
      mandatory = skills[:adapted].select { |s| s[:mode] == 'mandatory' }
      if mandatory.any?
        puts "🔒 Mandatory Skills (#{mandatory.length}):"
        mandatory.each do |skill|
          puts "  • #{skill[:id]}"
          puts "    Adapted: #{time_ago(skill[:adapted_at])}" if skill[:adapted_at]
        end
        puts
      end

      # Suggest skills
      suggest = skills[:adapted].select { |s| s[:mode] == 'suggest' }
      if suggest.any?
        puts "💡 Suggest Skills (#{suggest.length}):"
        suggest.each do |skill|
          puts "  • #{skill[:id]}"
        end
        puts
      end

      # Not adapted skills
      if skills[:not_adapted].any?
        puts "⏳ Available but Not Adapted (#{skills[:not_adapted].length}):"
        skills[:not_adapted].first(10).each do |skill|
          puts "  • #{skill[:id]}"
        end
        if skills[:not_adapted].length > 10
          puts "    ... and #{skills[:not_adapted].length - 10} more"
        end
        puts "   Run 'vibe skills check' to adapt these skills"
        puts
      end

      # Skipped skills
      if skills[:skipped].any?
        puts "⏸️  Skipped Skills (#{skills[:skipped].length}):"
        skills[:skipped].each do |skill|
          puts "  • #{skill[:id]}"
        end
        puts
      end

      # Summary
      total_active = mandatory.length + suggest.length
      puts "📊 Summary: #{total_active} active, #{skills[:skipped].length} skipped, #{skills[:not_adapted].length} available"
      puts
    end

    # vibe skills adapt <id> - Adapt a specific skill
    def run_skills_adapt(argv)
      skill_id = argv.shift

      unless skill_id
        raise Vibe::ValidationError, "Missing skill ID\n\nUsage: vibe skills adapt <skill-id> [mode]"
      end

      mode = argv.shift || 'suggest'
      mode = mode.to_sym

      unless %i[suggest mandatory skip].include?(mode)
        raise Vibe::ValidationError, "Invalid mode: #{mode}\n\nValid modes: suggest, mandatory, skip"
      end

      manager = SkillManager.new(@repo_root, Dir.pwd)

      if manager.adapt_skill(skill_id, mode)
        puts "✅ Skill '#{skill_id}' adapted as #{mode}"
      else
        puts "❌ Failed to adapt skill '#{skill_id}'"
        exit 1
      end
    end

    # vibe skills skip <id> - Skip a skill
    def run_skills_skip(argv)
      skill_id = argv.shift

      unless skill_id
        raise Vibe::ValidationError, "Missing skill ID\n\nUsage: vibe skills skip <skill-id>"
      end

      manager = SkillManager.new(@repo_root, Dir.pwd)

      if manager.skip_skill(skill_id)
        puts "⏸️  Skill '#{skill_id}' skipped"
        puts "   You can adapt it later with: vibe skills adapt #{skill_id}"
      else
        puts "❌ Failed to skip skill '#{skill_id}'"
        exit 1
      end
    end

    # vibe skills docs <id> - Show skill documentation
    def run_skills_docs(argv)
      skill_id = argv.shift

      unless skill_id
        raise Vibe::ValidationError, "Missing skill ID\n\nUsage: vibe skills docs <skill-id>"
      end

      manager = SkillManager.new(@repo_root, Dir.pwd)
      skill = manager.skill_info(skill_id)

      unless skill
        puts "❌ Skill not found: #{skill_id}"
        puts "   Run 'vibe skills list' to see available skills"
        exit 1
      end

      puts "\n📚 Skill Documentation: #{skill_id}"
      puts "=" * 60
      puts
      puts "ID: #{skill[:id]}"
      puts "Namespace: #{skill[:namespace]}"
      puts "Intent: #{skill[:intent]}"
      puts "Priority: #{skill[:priority]}"
      puts "Safety Level: #{skill[:safety_level]}"
      puts "Adaptation Status: #{skill[:adaptation_status]}"
      puts "Adaptation Mode: #{skill[:adaptation_mode]}" if skill[:adaptation_mode]
      puts

      if skill[:requires_tools]&.any?
        puts "Required Tools:"
        skill[:requires_tools].each { |tool| puts "  • #{tool}" }
        puts
      end

      if skill[:supported_targets]&.any?
        puts "Supported Targets:"
        skill[:supported_targets].each do |target, mode|
          puts "  • #{target}: #{mode}"
        end
        puts
      end

      if skill[:entrypoint]
        entry_path = File.join(@repo_root, skill[:entrypoint])
        if File.exist?(entry_path)
          puts "Documentation:"
          puts "-" * 60
          content = File.read(entry_path)
          content.lines.first(50).each { |line| puts line }
          if content.lines.count > 50
            puts "..."
            puts "(See full documentation at: #{skill[:entrypoint]})"
          end
        end
      end

      puts
    end

    # vibe skills install <pack> - Install a skill pack
    def run_skills_install(argv)
      pack_name = argv.shift

      unless pack_name
        raise Vibe::ValidationError, "Missing skill pack name\n\nUsage: vibe skills install <pack-name>"
      end

      options = parse_skills_install_options(argv)

      installer = SkillInstaller.new(@repo_root, Dir.pwd)

      if options[:dry_run]
        installer.preview_installation(pack_name, platform: options[:platform])
      else
        success = installer.install(pack_name, 
          platform: options[:platform], 
          auto_adapt: options[:auto_adapt]
        )
        exit 1 unless success
      end
    end

    private

    def skills_usage
      <<~HELP
        Usage: vibe skills <subcommand> [options]

        Manage skill adaptation for your project.

        Subcommands:
          check              Check for new skills and adapt them
          list               List all skills and their status
          adapt <id>         Adapt a specific skill
          skip <id>          Skip a skill (mark as not applicable)
          docs <id>          Show skill documentation
          install <pack>     Install a skill pack

        Options for check:
          --auto-adapt       Automatically adapt all as suggest
          --update-timestamp Just update last check time

        Options for install:
          --platform P       Target platform (claude-code, opencode, etc.)
          --auto-adapt       Auto-adapt skills after installation
          --dry-run          Preview installation without making changes

        Examples:
          vibe skills check                    # Check for new skills
          vibe skills check --auto-adapt       # Auto-adapt all new skills
          vibe skills list                     # List all skills
          vibe skills adapt superpowers/tdd    # Adapt TDD skill
          vibe skills adapt superpowers/tdd mandatory  # As mandatory
          vibe skills skip superpowers/optimize # Skip optimization skill
          vibe skills docs superpowers/tdd     # View TDD documentation
          vibe skills install superpowers      # Install superpowers pack

        See docs/design-skill-adaptation.md for detailed documentation.
      HELP
    end

    def parse_skills_check_options(argv)
      options = { auto_adapt: false, update_timestamp: false }

      argv.each do |arg|
        case arg
        when '--auto-adapt'
          options[:auto_adapt] = true
        when '--update-timestamp'
          options[:update_timestamp] = true
        end
      end

      options
    end

    def parse_skills_install_options(argv)
      options = { platform: nil, auto_adapt: false, dry_run: false }

      i = 0
      while i < argv.length
        arg = argv[i]
        case arg
        when '--platform'
          i += 1
          options[:platform] = argv[i]
        when '--auto-adapt'
          options[:auto_adapt] = true
        when '--dry-run'
          options[:dry_run] = true
        end
        i += 1
      end

      options
    end

    def time_ago(timestamp)
      return 'unknown' unless timestamp

      time = Time.parse(timestamp)
      diff = Time.now - time

      case diff
      when 0..60
        'just now'
      when 60..3600
        "#{diff / 60} minutes ago"
      when 3600..86400
        "#{diff / 3600} hours ago"
      when 86400..604800
        "#{diff / 86400} days ago"
      else
        time.strftime('%Y-%m-%d')
      end
    rescue
      'unknown'
    end
  end
end
