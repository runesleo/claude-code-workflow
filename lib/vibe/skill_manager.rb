# frozen_string_literal: true

require_relative 'skill_detector'
require_relative 'skill_adapter'

module Vibe
  # Unified skill management interface
  # Coordinates detection, adaptation, and configuration
  #
  # Usage:
  #   manager = SkillManager.new(repo_root, project_root)
  #   manager.check_and_prompt    # Check and interactively adapt
  #   manager.adapt_skill(id, mode)  # Adapt specific skill
  #   manager.list_skills         # List all skills
  #
  class SkillManager
    attr_reader :repo_root, :project_root, :detector, :adapter

    def initialize(repo_root, project_root = Dir.pwd)
      @repo_root = repo_root
      @project_root = project_root
      @detector = SkillDetector.new(repo_root, project_root)
      @adapter = SkillAdapter.new(repo_root, project_root)
    end

    # Check for new skills and prompt user to adapt
    # This is the main entry point for automatic skill detection
    #
    # @param auto_adapt [Boolean] If true, adapt all as suggest without prompting
    # @return [Hash] Results of adaptation
    def check_and_prompt(auto_adapt: false)
      changes = detector.check_skill_changes

      if changes[:new_skills].empty? && changes[:new_packs].empty?
        puts "✓ No new skills found." if verbose?
        return { adapted: [], skipped: [] }
      end

      # Show detection results
      show_detection_results(changes)

      if auto_adapt
        # Auto-adapt all as suggest
        adapter.adapt_all_as(changes[:new_skills], :suggest)
      else
        # Interactive adaptation
        adapter.adapt_interactively(changes[:new_skills])
      end
    end

    # Adapt a specific skill
    #
    # @param skill_id [String] Skill identifier
    # @param mode [Symbol] Adaptation mode (:suggest, :mandatory, :skip)
    # @return [Boolean] Success status
    def adapt_skill(skill_id, mode)
      skill = detector.get_skill_info(skill_id)

      unless skill
        puts "❌ Skill not found: #{skill_id}"
        return false
      end

      if adapter.adapt_skill(skill_id, mode)
        puts "✅ Skill '#{skill_id}' adapted as #{mode}"
        true
      else
        puts "❌ Failed to adapt skill '#{skill_id}'"
        false
      end
    end

    # Skip a skill (mark as not applicable)
    #
    # @param skill_id [String] Skill identifier
    # @return [Boolean] Success status
    def skip_skill(skill_id)
      adapt_skill(skill_id, :skip)
    end

    # List all skills with their adaptation status
    #
    # @return [Hash] Skills grouped by status
    def list_skills
      available = detector.list_available_skills
      project = load_project_skills

      {
        available: available,
        adapted: project[:adapted],
        skipped: project[:skipped],
        not_adapted: available.reject do |skill|
          project[:adapted].any? { |s| s[:id] == skill[:id] } ||
          project[:skipped].any? { |s| s[:id] == skill[:id] }
        end
      }
    end

    # Get detailed info about a skill
    #
    # @param skill_id [String] Skill identifier
    # @return [Hash, nil] Skill info with adaptation status
    def skill_info(skill_id)
      skill = detector.get_skill_info(skill_id)
      return nil unless skill

      project = load_project_skills

      adapted = project[:adapted].find { |s| s[:id] == skill_id }
      skipped = project[:skipped].find { |s| s[:id] == skill_id }

      skill.merge(
        adaptation_status: adapted ? :adapted : (skipped ? :skipped : :not_adapted),
        adaptation_mode: adapted&[:mode],
        adapted_at: adapted&[:adapted_at]
      )
    end

    # Update last check timestamp
    def update_check_timestamp
      config_path = File.join(project_root, ".vibe/skills.yaml")
      
      config = if File.exist?(config_path)
        YAML.safe_load(File.read(config_path), aliases: true) || {}
      else
        { 'schema_version' => 1 }
      end

      config['last_checked'] = Time.now.iso8601

      FileUtils.mkdir_p(File.dirname(config_path))
      File.write(config_path, YAML.dump(config))
    end

    private

    def show_detection_results(changes)
      puts "\n🔍 Skill Detection Results"
      puts "=" * 60
      puts

      if changes[:new_packs].any?
        puts "📦 Newly Installed Skill Packs:"
        changes[:new_packs].each do |pack|
          puts "  • #{pack[:name]} (v#{pack[:version]})"
          puts "    Installed at: #{pack[:installed_at]}"
        end
        puts
      end

      if changes[:new_skills].any?
        puts "✨ New Skills Available (#{changes[:new_skills].length}):"
        changes[:new_skills].each do |skill|
          puts "  • #{skill[:id]}"
          puts "    #{skill[:intent]}" if skill[:intent]
        end
        puts
      end

      puts "Last checked: #{changes[:last_checked]}"
      puts
    end

    def load_project_skills
      config_path = File.join(project_root, ".vibe/skills.yaml")
      
      unless File.exist?(config_path)
        return { adapted: [], skipped: [] }
      end

      doc = YAML.safe_load(File.read(config_path), aliases: true) || {}

      {
        adapted: doc['adapted_skills']&.map { |id, info| { id: id, **info } } || [],
        skipped: doc['skipped_skills'] || []
      }
    end

    def verbose?
      ENV['VIBE_VERBOSE'] == '1'
    end
  end
end
