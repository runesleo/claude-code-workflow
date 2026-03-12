# frozen_string_literal: true

require_relative 'errors'
require_relative 'utils'
require_relative 'skill_detector'

module Vibe
  # Adapts skills to project configuration
  # Handles interactive adaptation and configuration updates
  #
  # Usage:
  #   adapter = SkillAdapter.new(repo_root, project_root)
  #   adapter.adapt_interactively([skill1, skill2])
  #   adapter.adapt_skill(skill_id, :suggest)
  #
  class SkillAdapter
    include Vibe::Utils

    PROJECT_SKILLS_CONFIG = ".vibe/skills.yaml".freeze

    attr_reader :repo_root, :project_root, :detector

    def initialize(repo_root, project_root = Dir.pwd)
      @repo_root = repo_root
      @project_root = project_root
      @detector = SkillDetector.new(repo_root, project_root)
    end

    # Interactively adapt multiple skills
    #
    # @param skills [Array<Hash>] Skills to adapt
    # @return [Hash] Adaptation results
    def adapt_interactively(skills)
      return { adapted: [], skipped: [] } if skills.empty?

      puts "\n🤔 How would you like to adapt these #{skills.length} skills?"
      puts
      puts "[1] ⚡ Quick Setup - Adapt all as suggest (recommended)"
      puts "[2] 🔒 Strict Mode - Adapt all as mandatory"
      puts "[3] 🔍 Review Each - Decide individually"
      puts "[4] ⏭️  Skip - Don't adapt now"
      puts "[5] ❓ Help - Learn more about skill adaptation"
      puts

      choice = ask_user("Your choice [1/2/3/4/5]: ", %w[1 2 3 4 5])

      case choice
      when '1'
        adapt_all_as(skills, :suggest)
      when '2'
        adapt_all_as(skills, :mandatory)
      when '3'
        adapt_individually(skills)
      when '4'
        skip_all(skills)
      when '5'
        show_adaptation_help
        adapt_interactively(skills) # Recurse after help
      end
    end

    # Adapt a single skill with specified mode
    #
    # @param skill_id [String] Skill identifier
    # @param mode [Symbol] Adaptation mode (:suggest, :mandatory, :skip)
    # @return [Boolean] Success status
    def adapt_skill(skill_id, mode)
      skill = detector.get_skill_info(skill_id)
      return false unless skill

      config = load_project_config

      case mode
      when :suggest, :mandatory
        config['adapted_skills'] ||= {}
        config['adapted_skills'][skill_id] = {
          'mode' => mode.to_s,
          'adapted_at' => Time.now.strftime('%Y-%m-%dT%H:%M:%S%z'),
          'adapted_by' => 'user_choice'
        }

        # Remove from skipped if present
        config['skipped_skills'] = config['skipped_skills'].reject { |s| s['id'] == skill_id }

      when :skip
        config['skipped_skills'] ||= []
        config['skipped_skills'] << {
          'id' => skill_id,
          'skipped_at' => Time.now.strftime('%Y-%m-%dT%H:%M:%S%z'),
          'reason' => 'user_choice'
        }

        # Remove from adapted if present
        config['adapted_skills']&.delete(skill_id)
      end

      save_project_config(config)
      true
    end

    # Adapt all skills with the same mode
    #
    # @param skills [Array<Hash>] Skills to adapt
    # @param mode [Symbol] Adaptation mode
    # @return [Hash] Results
    def adapt_all_as(skills, mode)
      puts "\n⚡ Adapting all #{skills.length} skills as #{mode}..."

      adapted = []
      skills.each do |skill|
        if adapt_skill(skill[:id], mode)
          adapted << skill[:id]
          puts "  ✅ #{skill[:id]}"
        end
      end

      puts "\n✅ Adapted #{adapted.length} skills as #{mode}"

      { adapted: adapted, skipped: [] }
    end

    # Skip all skills
    #
    # @param skills [Array<Hash>] Skills to skip
    # @return [Hash] Results
    def skip_all(skills)
      puts "\n⏭️  Skipping all #{skills.length} skills..."

      skipped = []
      skills.each do |skill|
        if adapt_skill(skill[:id], :skip)
          skipped << skill[:id]
        end
      end

      puts "\n⏸️  Skipped #{skipped.length} skills"
      puts "   You can adapt them later with: vibe skills adapt <id>"

      { adapted: [], skipped: skipped }
    end

    # Show adaptation help
    def show_adaptation_help
      puts "\n📖 Skill Adaptation Help"
      puts "=" * 60
      puts
      puts "What is skill adaptation?"
      puts "  Skill adaptation determines how a skill is triggered in your"
      puts "  project. You can choose from three modes:"
      puts
      puts "🔹 Suggest Mode (recommended)"
      puts "   The skill is suggested when relevant to your current task."
      puts "   Best for: Most skills, especially optional workflows"
      puts
      puts "🔹 Mandatory Mode"
      puts "   The skill is always active and enforced."
      puts "   Best for: Critical skills like safety checks, verification"
      puts
      puts "🔹 Skip"
      puts "   The skill is not adapted to this project."
      puts "   Best for: Skills not relevant to your project type"
      puts
      puts "Examples:"
      puts "  • TDD skill → Suggest (only when writing tests)"
      puts "  • Security audit → Mandatory (always check)"
      puts "  • Mobile optimization → Skip (for backend projects)"
      puts
      puts "Press Enter to continue..."
      $stdin.gets
    end

    # Get recommendation for skill adaptation mode
    #
    # @param skill [Hash] Skill metadata
    # @return [Symbol] Recommended mode (:suggest, :mandatory, :skip)
    def recommend_mode(skill)
      # Based on skill priority
      case skill[:priority]
      when 'P0'
        :mandatory
      when 'P1', 'P2'
        :suggest
      else
        :suggest
      end
    end

    private

    # Adapt skills individually with interactive prompts
    def adapt_individually(skills)
      adapted = []
      skipped = []

      skills.each_with_index do |skill, index|
        puts "\n" + "=" * 60
        puts "📦 Skill #{index + 1}/#{skills.length}: #{skill[:id]}"
        puts "=" * 60
        puts
        puts "Name: #{skill[:name]}"
        puts "Intent: #{skill[:intent]}"
        puts "Priority: #{skill[:priority]}"
        puts

        if skill[:description]
          puts "Description:"
          puts "  #{skill[:description]}"
          puts
        end

        recommendation = recommend_mode(skill)
        puts "💡 Recommendation: #{recommendation} mode"
        puts

        loop do
          puts "Adapt this skill as:"
          puts "  [s] Suggest    - Recommend when relevant"
          puts "  [m] Mandatory  - Always use this skill"
          puts "  [i] Ignore     - Skip this skill"
          puts "  [v] View Docs  - Read full documentation"
          puts "  [?] Help       - Explain adaptation modes"
          puts

          choice = ask_user("Your choice [s/m/i/v/?]: ", %w[s m i v ?])

          case choice
          when 's'
            if adapt_skill(skill[:id], :suggest)
              adapted << skill[:id]
              puts "\n✅ Adapted as: suggest"
            end
            break

          when 'm'
            if adapt_skill(skill[:id], :mandatory)
              adapted << skill[:id]
              puts "\n✅ Adapted as: mandatory"
            end
            break

          when 'i'
            if adapt_skill(skill[:id], :skip)
              skipped << skill[:id]
              puts "\n⏸️  Skipped"
            end
            break

          when 'v'
            show_skill_docs(skill)

          when '?'
            show_adaptation_help
          end
        end

        # Pause between skills (except last)
        if index < skills.length - 1
          puts "\nPress Enter to continue to next skill..."
          $stdin.gets
        end
      end

      { adapted: adapted, skipped: skipped }
    end

    # Show skill documentation
    def show_skill_docs(skill)
      puts "\n📚 Skill Documentation: #{skill[:id]}"
      puts "=" * 60
      puts
      puts "ID: #{skill[:id]}"
      puts "Namespace: #{skill[:namespace]}"
      puts "Intent: #{skill[:intent]}"
      puts "Priority: #{skill[:priority]}"
      puts "Safety Level: #{skill[:safety_level]}"
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
        entry_path = File.join(repo_root, skill[:entrypoint])
        if File.exist?(entry_path)
          puts "Documentation:"
          puts "-" * 60
          content = File.read(entry_path)
          # Show first 30 lines
          content.lines.first(30).each { |line| puts line }
          puts "-" * 60
          puts "  (... see full docs at #{skill[:entrypoint]})"
        end
      end

      puts "\nPress Enter to return to adaptation..."
      $stdin.gets
    end

    # Load project skill configuration
    def load_project_config
      config_path = File.join(project_root, PROJECT_SKILLS_CONFIG)
      
      if File.exist?(config_path)
        YAML.safe_load(File.read(config_path), aliases: true) || {}
      else
        {
          'schema_version' => 1,
          'adapted_skills' => {},
          'skipped_skills' => [],
          'installed_packs' => {}
        }
      end
    end

    # Save project skill configuration
    def save_project_config(config)
      config_path = File.join(project_root, PROJECT_SKILLS_CONFIG)
      
      # Ensure .vibe directory exists
      FileUtils.mkdir_p(File.dirname(config_path))
      
      # Update timestamp
      config['last_checked'] = Time.now.strftime('%Y-%m-%dT%H:%M:%S%z')
      
      File.write(config_path, YAML.dump(config))
    end

    # Ask user for input with validation
    def ask_user(prompt, valid_options = nil)
      loop do
        print prompt
        input = $stdin.gets&.strip

        if input.nil? || input.empty?
          puts "Please enter a value."
          next
        end

        if valid_options && !valid_options.include?(input.downcase)
          puts "Invalid option. Please choose from: #{valid_options.join(', ')}"
          next
        end

        return input.downcase
      end
    end
  end
end
