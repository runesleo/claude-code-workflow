#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "test_helper"
require "json"
require "yaml"
require "fileutils"
require_relative "../lib/vibe/errors"
require_relative "../lib/vibe/utils"
require_relative "../lib/vibe/path_safety"

# Lightweight host satisfying PathSafety + Utils dependencies.
class PathSafetyHost
  include Vibe::Utils
  include Vibe::PathSafety

  def initialize(repo_root)
    @repo_root = repo_root
  end
end

class TestCliPathSafetyGuards < Minitest::Test
  def setup
    @host = PathSafetyHost.new("/fake/repo")
  end

  # --- ensure_safe_output_path! ---

  def test_refuses_root
    assert_aborts { @host.ensure_safe_output_path!("/") }
  end

  def test_refuses_home
    assert_aborts { @host.ensure_safe_output_path!(Dir.home) }
  end

  def test_refuses_repo_root
    assert_aborts { @host.ensure_safe_output_path!("/fake/repo") }
  end

  def test_refuses_repo_subdir_outside_generated
    assert_aborts { @host.ensure_safe_output_path!("/fake/repo/src") }
  end

  def test_allows_generated_subdir
    # Should not abort for generated/ paths
    @host.ensure_safe_output_path!("/fake/repo/generated/warp")
  end

  def test_refuses_unsafe_path_children
    # After security fix, children of unsafe paths are also blocked
    assert_aborts { @host.ensure_safe_output_path!("/tmp/vibe-test/output") }
    assert_aborts { @host.ensure_safe_output_path!("/etc/foo") }
    assert_aborts { @host.ensure_safe_output_path!("/var/lib/x") }
  end

  def test_refuses_shallow_path
    assert_aborts { @host.ensure_safe_output_path!("/tmp") }
  end

  def test_refuses_repo_parent_containing_repo
    host = PathSafetyHost.new("/fake/repo/nested")
    assert_aborts { host.ensure_safe_output_path!("/fake/repo") }
  end

  # --- context support tests ---

  def test_path_safety_error_includes_context
    error = assert_raises(Vibe::PathSafetyError) do
      @host.ensure_safe_output_path!("/fake/repo")
    end

    assert error.context[:suggestion]
    assert_match(/Use a path under generated/, error.context[:suggestion])
    assert_equal "/fake/repo", error.context[:output_path]
    assert_equal "/fake/repo", error.context[:repo_path]
  end

  def test_path_safety_error_to_s_includes_context
    error = assert_raises(Vibe::PathSafetyError) do
      @host.ensure_safe_output_path!("/fake/repo")
    end

    assert_match(/\[Context:/, error.to_s)
    assert_match(/suggestion/, error.to_s)
  end

  def test_validation_error_includes_field_and_value
    error = Vibe::ValidationError.new(
      "Invalid value",
      field: "target",
      value: "invalid-target"
    )

    assert_equal "target", error.field
    assert_equal "invalid-target", error.value
    assert_equal "target", error.context[:field]
    assert_equal "invalid-target", error.context[:value]
  end

  def test_base_error_context_empty_by_default
    error = Vibe::Error.new("Test error")
    assert_equal({}, error.context)
    assert_equal "Test error", error.to_s
  end

  # --- ensure_no_path_overlap! ---

  def test_overlap_same_path
    assert_aborts { @host.ensure_no_path_overlap!("/a/b", "/a/b") }
  end

  def test_overlap_output_inside_dest
    assert_aborts { @host.ensure_no_path_overlap!("/a/b/c", "/a/b") }
  end

  def test_overlap_dest_inside_output
    assert_aborts { @host.ensure_no_path_overlap!("/a/b", "/a/b/c") }
  end

  def test_no_overlap_separate_paths
    @host.ensure_no_path_overlap!("/a/b", "/c/d")
  end

  private

  # Helper: asserts that the block triggers PathSafetyError.
  def assert_aborts(&block)
    assert_raises(Vibe::PathSafetyError, &block)
  end
end
