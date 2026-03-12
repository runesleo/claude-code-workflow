# frozen_string_literal: true

require_relative 'errors'
require_relative 'utils'

module Vibe
  # Detects new skills from registry and installed skill packs
  #
  # Usage:
  #   detector = SkillDetector.new(repo_root)
  #   new_skills = detector.detect_new_skills
  #   newly_installed = detector.detect_newly_installed_packs
  #
  class SkillDetector
    include Vibe::Utils

    SKILL_REGISTRY_PATH = "core/skills/registry.yaml".freeze
    USER_SKILLS_DIR = File.expand_path("~/.config/skills").freeze
    PROJECT_SKILLS_CONFIG = ".vibe/skills.yaml".freeze

    attr_reader :repo_root, :project_root

    def initialize(repo_root, project_root = Dir.pwd)
      @repo_root = repo_root
      @project_root = project_root
    end

    # Detect skills that are available but not yet adapted to the project
    #
    # @return [Array<Hash>] Array of skill metadata hashes
    def detect_new_skills(skill_pack = nil)
      registry_skills = load_registry_skills(skill_pack)
      project_skills = load_project_skills

      # Find skills in registry but not in project
      new_skills = registry_skills.reject do |skill|
        project_skills[:adapted].any? { |s| s[:id] == skill[:id] } ||
        project_skills[:skipped].any? { |s| s[:id] == skill[:id] }
      end

      new_skills
    end

    # Detect newly installed skill packs since last check
    #
    # @return [Array<Hash>] Array of newly installed pack info
    def detect_newly_installed_packs
      return [] unless Dir.exist?(USER_SKILLS_DIR)

      current_packs = scan_installed_packs
      last_check_time = load_last_check_time

      new_packs = current_packs.select do |pack|
        pack[:installed_at] > last_check_time
      end

      new_packs
    end

    # Check if there are any skill changes that need attention
    #
    # @return [Hash] Summary of changes
    def check_skill_changes
      {
        new_skills: detect_new_skills,
        new_packs: detect_newly_installed_packs,
        last_checked: load_last_check_time
      }
    end

    # Get detailed info about a specific skill
    #
    # @param skill_id [String] Skill identifier (e.g., "superpowers/tdd")
    # @return [Hash, nil] Skill metadata or nil if not found
    def get_skill_info(skill_id)
      all_skills = load_registry_skills
      all_skills.find { |s| s[:id] == skill_id }
    end

    # List all available skills from registry
    #
    # @return [Array<Hash>] All available skills
    def list_available_skills
      load_registry_skills
    end

    private

    # Load skills from core registry
    def load_registry_skills(filter_pack = nil)
      registry_path = File.join(repo_root, SKILL_REGISTRY_PATH)
      return [] unless File.exist?(registry_path)

      doc = YAML.safe_load(File.read(registry_path), aliases: true)
      return [] unless doc && doc['skills']

      skills = doc['skills'].map do |skill|
        next if filter_pack && !skill['id'].start_with?(filter_pack)

        {
          id: skill['id'],
          namespace: skill['namespace'],
          name: skill['id'].split('/').last,
          intent: skill['intent'],
          description: skill['description'],
          trigger_mode: skill['trigger_mode'],
          priority: skill['priority'],
          requires_tools: skill['requires_tools'] || [],
          supported_targets: skill['supported_targets'] || {},
          entrypoint: skill['entrypoint'],
          safety_level: skill['safety_level']
        }
      end

      skills.compact
    end

    # Load project skill configuration
    def load_project_skills
      config_path = File.join(project_root, PROJECT_SKILLS_CONFIG)
      
      unless File.exist?(config_path)
        return { adapted: [], skipped: [], installed_packs: {} }
      end

      doc = YAML.safe_load(File.read(config_path), aliases: true) || {}

      {
        adapted: doc['adapted_skills']&.map { |id, info| { id: id, **info } } || [],
        skipped: doc['skipped_skills'] || [],
        installed_packs: doc['installed_packs'] || {}
      }
    end

    # Scan user skills directory for installed packs
    def scan_installed_packs
      return [] unless Dir.exist?(USER_SKILLS_DIR)

      Dir.glob(File.join(USER_SKILLS_DIR, "*")).select { |f| File.directory?(f) }.map do |pack_dir|
        pack_name = File.basename(pack_dir)
        {
          name: pack_name,
          path: pack_dir,
          installed_at: File.mtime(pack_dir),
          version: detect_pack_version(pack_dir)
        }
      end
    end

    # Try to detect pack version from common version files
    def detect_pack_version(pack_dir)
      version_files = ['version.txt', 'VERSION', '.version']
      version_files.each do |file|
        path = File.join(pack_dir, file)
        return File.read(path).strip if File.exist?(path)
      end

      # Try git tags
      git_dir = File.join(pack_dir, '.git')
      if Dir.exist?(git_dir)
        tags = Dir.glob(File.join(git_dir, 'refs', 'tags', '*'))
        return File.basename(tags.max) if tags.any?
      end

      'unknown'
    end

    # Load last check timestamp
    def load_last_check_time
      config_path = File.join(project_root, PROJECT_SKILLS_CONFIG)
      return Time.at(0) unless File.exist?(config_path)

      doc = YAML.safe_load(File.read(config_path), aliases: true) || {}
      last_checked = doc['last_checked']

      last_checked ? Time.parse(last_checked) : Time.at(0)
    rescue StandardError
      Time.at(0)
    end
  end
end
