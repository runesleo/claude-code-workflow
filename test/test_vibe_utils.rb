#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require "json"
require "yaml"
require "fileutils"
require "tmpdir"
require_relative "../lib/vibe/utils"
load File.expand_path("../bin/vibe", __dir__)

# Lightweight host that satisfies Vibe::Utils dependency on @repo_root.
class UtilsHost
  include Vibe::Utils

  def initialize(repo_root)
    @repo_root = repo_root
  end
end

class TestVibeUtils < Minitest::Test
  def setup
    @host = UtilsHost.new("/fake/repo")
  end

  # --- deep_merge ---

  def test_deep_merge_hashes
    base  = { "a" => 1, "b" => { "x" => 10 } }
    extra = { "b" => { "y" => 20 }, "c" => 3 }
    result = @host.deep_merge(base, extra)
    assert_equal({ "a" => 1, "b" => { "x" => 10, "y" => 20 }, "c" => 3 }, result)
  end

  def test_deep_merge_arrays_dedup
    base  = %w[a b c]
    extra = %w[b c d]
    result = @host.deep_merge(base, extra)
    assert_equal(%w[a b c d], result)
  end

  def test_deep_merge_scalar_override_raises_error
    error = assert_raises(Vibe::ValidationError) do
      @host.deep_merge("old", "new")
    end
    assert_includes error.message, "base must be a Hash, Array, or nil"
  end

  def test_deep_merge_nil_base
    assert_equal({ "a" => 1 }, @host.deep_merge(nil, { "a" => 1 }))
  end

  def test_deep_merge_nil_extra
    assert_equal({ "a" => 1 }, @host.deep_merge({ "a" => 1 }, nil))
  end

  def test_deep_merge_does_not_mutate_base
    base = { "a" => { "x" => 1 } }
    @host.deep_merge(base, { "a" => { "y" => 2 } })
    assert_equal({ "a" => { "x" => 1 } }, base)
  end

  # --- deep_copy ---

  def test_deep_copy_isolates_nested_hash
    original = { "a" => { "b" => [1, 2] } }
    copy = @host.deep_copy(original)
    copy["a"]["b"] << 3
    assert_equal([1, 2], original["a"]["b"])
  end

  # --- blankish? ---

  def test_blankish_nil
    assert @host.blankish?(nil)
  end

  def test_blankish_empty_string
    assert @host.blankish?("")
  end

  def test_blankish_whitespace
    assert @host.blankish?("   ")
  end

  def test_blankish_non_empty
    refute @host.blankish?("hello")
  end

  # --- display_path ---

  def test_display_path_inside_repo
    assert_equal("src/main.rb", @host.display_path("/fake/repo/src/main.rb"))
  end

  def test_display_path_repo_root_itself
    assert_equal(".", @host.display_path("/fake/repo"))
  end

  def test_display_path_outside_repo
    assert_equal("/other/path", @host.display_path("/other/path"))
  end

  # --- format_backtick_list ---

  def test_format_backtick_list_normal
    assert_equal("`a`, `b`", @host.format_backtick_list(%w[a b]))
  end

  def test_format_backtick_list_empty
    assert_equal("`none`", @host.format_backtick_list([]))
  end

  def test_format_backtick_list_filters_blanks
    assert_equal("`a`", @host.format_backtick_list(["a", "", "  "]))
  end

  # --- I/O helpers (write_json / read_json round-trip) ---

  def test_write_and_read_json
    dir = Dir.mktmpdir
    path = File.join(dir, "test.json")
    @host.write_json(path, { "key" => "value" })

    result = @host.read_json(path)
    assert_equal({ "key" => "value" }, result)
  ensure
    FileUtils.rm_rf(dir)
  end

  def test_read_json_if_exists_missing
    assert_nil @host.read_json_if_exists("/nonexistent/file.json")
  end

  # --- validate_path! ---

  def test_validate_path_rejects_nil
    error = assert_raises(Vibe::ValidationError) do
      @host.validate_path!(nil, context: "test path")
    end
    assert_match(/cannot be nil/, error.message)
  end

  def test_validate_path_rejects_empty
    error = assert_raises(Vibe::ValidationError) do
      @host.validate_path!("", context: "test path")
    end
    assert_match(/cannot be empty/, error.message)
  end

  def test_validate_path_rejects_null_byte
    error = assert_raises(Vibe::ValidationError) do
      @host.validate_path!("path\0with\0null", context: "test path")
    end
    assert_match(/null byte/, error.message)
  end

  def test_validate_path_rejects_control_characters
    error = assert_raises(Vibe::ValidationError) do
      @host.validate_path!("path\x01with\x1fcontrol", context: "test path")
    end
    assert_match(/control characters/, error.message)
  end

  def test_validate_path_rejects_unsafe_traversal_to_parent
    error = assert_raises(Vibe::ValidationError) do
      @host.validate_path!("../../../etc/passwd", context: "output")
    end
    assert_match(/unsafe path traversal/, error.message)
  end

  def test_validate_path_rejects_traversal_outside_repo
    error = assert_raises(Vibe::ValidationError) do
      @host.validate_path!("../outside-repo", context: "output")
    end
    assert_match(/unsafe path traversal/, error.message)
  end

  def test_validate_path_allows_safe_relative_paths
    # Paths without .. are always safe
    assert_equal "generated/claude-code", @host.validate_path!("generated/claude-code")
    assert_equal "tmp/output", @host.validate_path!("tmp/output")
    assert_equal "src/main.rb", @host.validate_path!("src/main.rb")
  end

  def test_validate_path_allows_safe_paths_within_repo
    # Create a real temp directory to test with
    Dir.mktmpdir do |tmpdir|
      host = UtilsHost.new(tmpdir)
      # Path with .. that stays within repo
      safe_path = File.join(tmpdir, "subdir", "..", "file.txt")
      assert_equal safe_path, host.validate_path!(safe_path)
    end
  end

  def test_validate_path_allows_absolute_paths_in_tmp
    # Absolute paths in system temp directory are allowed
    tmp_path = File.join(Dir.tmpdir, "vibe-output")
    assert_equal tmp_path, @host.validate_path!(tmp_path)
  end
end

class TestVibeCLIThreadSafety < Minitest::Test
  def setup
    repo_root = File.expand_path("..", __dir__)
    @cli = VibeCLI.new(repo_root)
  end

  def test_tiers_doc_is_thread_safe
    threads = 10.times.map do
      Thread.new { @cli.tiers_doc }
    end
    results = threads.map(&:value)

    assert_equal 1, results.map(&:object_id).uniq.length
  end

  def test_providers_is_thread_safe
    threads = 10.times.map do
      Thread.new { @cli.providers }
    end
    results = threads.map(&:value)

    assert_equal 1, results.map(&:object_id).uniq.length
  end

  def test_skills_doc_is_thread_safe
    threads = 10.times.map do
      Thread.new { @cli.skills_doc }
    end
    results = threads.map(&:value)

    assert_equal 1, results.map(&:object_id).uniq.length
  end

  def test_security_doc_is_thread_safe
    threads = 10.times.map do
      Thread.new { @cli.security_doc }
    end
    results = threads.map(&:value)

    assert_equal 1, results.map(&:object_id).uniq.length
  end

  def test_policies_doc_is_thread_safe
    threads = 10.times.map do
      Thread.new { @cli.policies_doc }
    end
    results = threads.map(&:value)

    assert_equal 1, results.map(&:object_id).uniq.length
  end

  def test_task_routing_doc_is_thread_safe
    threads = 10.times.map do
      Thread.new { @cli.task_routing_doc }
    end
    results = threads.map(&:value)

    assert_equal 1, results.map(&:object_id).uniq.length
  end

  def test_test_standards_doc_is_thread_safe
    threads = 10.times.map do
      Thread.new { @cli.test_standards_doc }
    end
    results = threads.map(&:value)

    assert_equal 1, results.map(&:object_id).uniq.length
  end
end
