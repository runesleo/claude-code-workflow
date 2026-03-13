# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/vibe/skill_detector"
require_relative "../lib/vibe/skill_adapter"
require_relative "../lib/vibe/skill_manager"

class TestSkillManager < Minitest::Test
  def setup
    @repo_root = Dir.pwd
    @test_dir = Dir.mktmpdir("skill-manager-test")
    @manager = Vibe::SkillManager.new(@repo_root, @test_dir)
  end

  def teardown
    FileUtils.rm_rf(@test_dir)
  end

  def test_list_skills_returns_structure
    skills = @manager.list_skills

    assert skills.key?(:available)
    assert skills.key?(:adapted)
    assert skills.key?(:skipped)
    assert skills.key?(:not_adapted)

    assert_kind_of Array, skills[:available]
    assert_kind_of Array, skills[:adapted]
    assert_kind_of Array, skills[:skipped]
    assert_kind_of Array, skills[:not_adapted]
  end

  def test_detect_new_skills_finds_unadapted
    # Initially all skills are new
    new_skills = @manager.detector.detect_new_skills

    # Should find skills from registry
    assert new_skills.length > 0

    # Should include builtin skills
    builtin_skills = new_skills.select { |s| s[:namespace] == 'builtin' }
    assert builtin_skills.length > 0
  end

  def test_adapt_skill_creates_config
    skill_id = 'systematic-debugging'

    # Adapt skill
    assert @manager.adapt_skill(skill_id, :suggest)

    # Check config file created
    config_path = File.join(@test_dir, ".vibe/skills.yaml")
    assert File.exist?(config_path)

    # Check config content
    config = YAML.safe_load(File.read(config_path))
    assert config['adapted_skills'].key?(skill_id)
    assert_equal 'suggest', config['adapted_skills'][skill_id]['mode']
  end

  def test_skip_skill_records_skip
    skill_id = 'superpowers/optimize'

    # Skip skill
    assert @manager.skip_skill(skill_id)

    # Check config
    config_path = File.join(@test_dir, ".vibe/skills.yaml")
    config = YAML.safe_load(File.read(config_path))

    skipped = config['skipped_skills'].find { |s| s['id'] == skill_id }
    assert skipped
    assert_equal 'user_choice', skipped['reason']
  end

  def test_skill_info_returns_metadata
    skill_id = 'systematic-debugging'
    info = @manager.skill_info(skill_id)

    assert_equal skill_id, info[:id]
    assert_equal 'builtin', info[:namespace]
    assert info[:intent]
    assert info[:adaptation_status]
  end

  def test_update_check_timestamp
    @manager.update_check_timestamp

    config_path = File.join(@test_dir, ".vibe/skills.yaml")
    config = YAML.safe_load(File.read(config_path))

    assert config['last_checked']
    assert_kind_of String, config['last_checked']
  end
end

class TestSkillDetector < Minitest::Test
  def setup
    @repo_root = Dir.pwd
    @test_dir = Dir.mktmpdir("skill-detector-test")
    @detector = Vibe::SkillDetector.new(@repo_root, @test_dir)
  end

  def teardown
    FileUtils.rm_rf(@test_dir)
  end

  def test_load_registry_skills
    skills = @detector.send(:load_registry_skills)

    assert skills.length > 0

    # Check skill structure
    skill = skills.first
    assert skill[:id]
    assert skill[:namespace]
    assert skill[:intent]
  end

  def test_detect_new_skills_empty_project
    new_skills = @detector.detect_new_skills

    # All registry skills should be new
    registry = @detector.send(:load_registry_skills)
    assert_equal registry.length, new_skills.length
  end

  def test_get_skill_info_found
    info = @detector.get_skill_info('systematic-debugging')

    assert info
    assert_equal 'systematic-debugging', info[:id]
    assert_equal 'builtin', info[:namespace]
  end

  def test_get_skill_info_not_found
    info = @detector.get_skill_info('nonexistent-skill')

    assert_nil info
  end
end

class TestSkillAdapter < Minitest::Test
  def setup
    @repo_root = Dir.pwd
    @test_dir = Dir.mktmpdir("skill-adapter-test")
    @adapter = Vibe::SkillAdapter.new(@repo_root, @test_dir)
  end

  def teardown
    FileUtils.rm_rf(@test_dir)
  end

  def test_adapt_skill_suggest_mode
    skill_id = 'systematic-debugging'

    assert @adapter.adapt_skill(skill_id, :suggest)

    config = @adapter.send(:load_project_config)
    assert config['adapted_skills'].key?(skill_id)
    assert_equal 'suggest', config['adapted_skills'][skill_id]['mode']
  end

  def test_adapt_skill_mandatory_mode
    skill_id = 'verification-before-completion'

    assert @adapter.adapt_skill(skill_id, :mandatory)

    config = @adapter.send(:load_project_config)
    assert_equal 'mandatory', config['adapted_skills'][skill_id]['mode']
  end

  def test_adapt_skill_skip_mode
    skill_id = 'superpowers/optimize'

    assert @adapter.adapt_skill(skill_id, :skip)

    config = @adapter.send(:load_project_config)
    skipped = config['skipped_skills'].find { |s| s['id'] == skill_id }
    assert skipped
  end

  def test_adapt_all_as_batch
    skills = [
      { id: 'skill-1' },
      { id: 'skill-2' },
      { id: 'skill-3' }
    ]

    results = @adapter.adapt_all_as(skills, :suggest)

    assert_equal 3, results[:adapted].length
    assert_equal 0, results[:skipped].length

    config = @adapter.send(:load_project_config)
    assert_equal 3, config['adapted_skills'].keys.length
  end

  def test_recommend_mode_based_on_priority
    p0_skill = { priority: 'P0' }
    p1_skill = { priority: 'P1' }

    assert_equal :mandatory, @adapter.recommend_mode(p0_skill)
    assert_equal :suggest, @adapter.recommend_mode(p1_skill)
  end

  def test_project_config_created_with_defaults
    config = @adapter.send(:load_project_config)

    assert_equal 1, config['schema_version']
    assert_kind_of Hash, config['adapted_skills']
    assert_kind_of Array, config['skipped_skills']
    assert_kind_of Hash, config['installed_packs']
  end
end
