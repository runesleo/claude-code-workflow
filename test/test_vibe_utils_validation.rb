#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/vibe/utils"

class UtilsHost
  include Vibe::Utils

  def initialize(repo_root)
    @repo_root = repo_root
  end
end

class TestVibeUtilsValidation < Minitest::Test
  def setup
    @host = UtilsHost.new("/fake/repo")
  end

  def test_deep_merge_string_base_returns_extra
    result = @host.deep_merge("invalid", {})
    assert_equal({}, result)
  end

  def test_deep_merge_string_extra_returns_extra
    result = @host.deep_merge({}, "invalid")
    assert_equal("invalid", result)
  end

  def test_deep_merge_accepts_nil_base
    result = @host.deep_merge(nil, { a: 1 })
    assert_equal({ a: 1 }, result)
  end

  def test_deep_merge_accepts_nil_extra
    result = @host.deep_merge({ a: 1 }, nil)
    assert_equal({ a: 1 }, result)
  end

  def test_deep_merge_numeric_base_returns_extra
    result = @host.deep_merge(123, {})
    assert_equal({}, result)
  end

  def test_deep_merge_numeric_extra_returns_extra
    result = @host.deep_merge({}, 456)
    assert_equal(456, result)
  end
end
