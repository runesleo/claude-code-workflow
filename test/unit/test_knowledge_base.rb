# frozen_string_literal: true

require_relative "../test_helper"
require "vibe/knowledge_base"

class TestKnowledgeBase < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir("vibe-kb-test")
    @memory_dir = File.join(@test_dir, "memory")
    FileUtils.mkdir_p(@memory_dir)

    # Create test knowledge.yaml
    @test_data = {
      "schema_version" => 1,
      "last_updated" => "2026-03-12",
      "pitfalls" => [
        {
          "id" => "test-pitfall",
          "keywords" => {
            "en" => ["test", "yaml", "error"],
            "zh" => ["测试", "错误"]
          },
          "issue" => {
            "en" => "Test issue description",
            "zh" => "测试问题描述"
          },
          "solution" => {
            "en" => "Test solution",
            "zh" => "测试解决方案"
          },
          "discovered" => "2026-03-12",
          "times_encountered" => 1
        }
      ],
      "patterns" => [
        {
          "id" => "test-pattern",
          "name" => {
            "en" => "Test Pattern",
            "zh" => "测试模式"
          },
          "when_to_use" => {
            "en" => "When testing",
            "zh" => "测试时使用"
          },
          "times_used" => 2
        }
      ],
      "adrs" => [
        {
          "id" => "ADR-001",
          "title" => "Test Decision",
          "date" => "2026-03-12",
          "status" => "accepted",
          "context" => "Test context",
          "decision" => "Test decision"
        }
      ]
    }

    File.write(
      File.join(@memory_dir, "knowledge.yaml"),
      YAML.dump(@test_data)
    )

    @kb = Vibe::KnowledgeBase.new(@test_dir)
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def test_load_data
    assert_equal 1, @kb.data["schema_version"]
    assert_equal 1, @kb.pitfalls.length
    assert_equal 1, @kb.patterns.length
    assert_equal 1, @kb.adrs.length
  end

  def test_search_by_keyword_en
    results = @kb.search("yaml", lang: :en)
    assert_equal 1, results.length
    assert_equal :pitfall, results.first[:type]
    assert_equal "test-pitfall", results.first[:data]["id"]
  end

  def test_search_by_keyword_zh
    results = @kb.search("测试", lang: :zh)
    assert results.length >= 1
    ids = results.map { |r| r[:data]["id"] }
    assert_includes ids, "test-pitfall"
  end

  def test_search_no_match
    results = @kb.search("nonexistent")
    assert_equal 0, results.length
  end

  def test_pitfalls
    pitfalls = @kb.pitfalls
    assert_equal 1, pitfalls.length
    assert_equal "test-pitfall", pitfalls.first["id"]
  end

  def test_patterns
    patterns = @kb.patterns
    assert_equal 1, patterns.length
    assert_equal "test-pattern", patterns.first["id"]
  end

  def test_adrs
    adrs = @kb.adrs
    assert_equal 1, adrs.length
    assert_equal "ADR-001", adrs.first["id"]
  end

  def test_record_encounter
    @kb.record_encounter("test-pitfall")

    # Reload to verify persistence
    kb2 = Vibe::KnowledgeBase.new(@test_dir)
    pitfall = kb2.pitfalls.find { |p| p["id"] == "test-pitfall" }
    assert_equal 2, pitfall["times_encountered"]
  end

  def test_export_to_markdown
    markdown = @kb.export_to_markdown(lang: :en)

    assert_includes markdown, "# Project Knowledge"
    assert_includes markdown, "## Technical Pitfalls"
    assert_includes markdown, "### test-pitfall"
    assert_includes markdown, "Test issue description"
    assert_includes markdown, "## Reusable Patterns"
    assert_includes markdown, "Test Pattern"
    assert_includes markdown, "## Architecture Decisions"
    assert_includes markdown, "ADR-001: Test Decision"
  end

  def test_empty_kb
    empty_dir = Dir.mktmpdir("vibe-empty-test")
    FileUtils.mkdir_p(File.join(empty_dir, "memory"))

    kb = Vibe::KnowledgeBase.new(empty_dir)
    assert_equal [], kb.pitfalls
    assert_equal [], kb.patterns
    assert_equal [], kb.adrs
  ensure
    FileUtils.rm_rf(empty_dir) if empty_dir
  end
end
