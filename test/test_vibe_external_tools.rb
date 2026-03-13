# frozen_string_literal: true

require_relative "test_helper"
require "fileutils"
require "tmpdir"
require "json"
require_relative "../lib/vibe/external_tools"

class TestVibeExternalTools < Minitest::Test
  include Vibe::ExternalTools

  def setup
    @repo_root = File.expand_path("..", __dir__)
    @test_dir = Dir.mktmpdir("vibe_test")
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if @test_dir && Dir.exist?(@test_dir)
  end

  # --- Integration Config Loading ---

  def test_load_integration_config_superpowers
    config = load_integration_config("superpowers")
    refute_nil config
    assert_equal "superpowers", config["name"]
    assert_equal "skill_pack", config["type"]
  end

  def test_load_integration_config_rtk
    config = load_integration_config("rtk")
    refute_nil config
    assert_equal "rtk", config["name"]
    assert_equal "cli_tool", config["type"]
  end

  def test_load_integration_config_nonexistent
    config = load_integration_config("nonexistent")
    assert_nil config
  end

  def test_list_integrations
    integrations = list_integrations
    assert_includes integrations, "superpowers"
    assert_includes integrations, "rtk"
    refute_includes integrations, "README"
  end

  # --- Detection Methods Exist ---

  def test_detect_superpowers_method_exists
    assert_respond_to self, :detect_superpowers
  end

  def test_detect_rtk_method_exists
    assert_respond_to self, :detect_rtk
  end

  def test_superpowers_location_method_exists
    assert_respond_to self, :superpowers_location
  end

  def test_rtk_version_method_exists
    assert_respond_to self, :rtk_version
  end

  def test_rtk_binary_path_method_exists
    assert_respond_to self, :rtk_binary_path
  end

  def test_rtk_hook_configured_method_exists
    assert_respond_to self, :rtk_hook_configured?
  end

  # --- Verification Methods ---

  def test_verify_superpowers_returns_hash
    result = verify_superpowers
    assert_kind_of Hash, result
    assert_includes result.keys, :installed
  end

  def test_verify_rtk_returns_hash
    result = verify_rtk
    assert_kind_of Hash, result
    assert_includes result.keys, :installed
  end

  def test_integration_status_returns_hash
    status = integration_status
    assert_kind_of Hash, status
    assert_includes status.keys, :superpowers
    assert_includes status.keys, :rtk
  end

  def test_missing_integrations_returns_array
    missing = missing_integrations
    assert_kind_of Array, missing
  end

  def test_all_integrations_installed_returns_boolean
    result = all_integrations_installed?
    assert [true, false].include?(result)
  end

  # --- RTK Hook Configuration Test ---

  def test_rtk_hook_configured_with_test_settings
    settings_path = File.join(@test_dir, "settings.json")
    File.write(settings_path, JSON.generate({
      "hooks" => {
        "bashCommandPrepare" => "rtk rewrite"
      }
    }))

    stub_expand_path = lambda do |path|
      return settings_path if path == "~/.claude/settings.json"
      File.expand_path(path)
    end

    File.stub :expand_path, stub_expand_path do
      assert rtk_hook_configured?
    end
  end

  def test_rtk_hook_not_configured_with_empty_hooks
    settings_path = File.join(@test_dir, "settings.json")
    File.write(settings_path, JSON.generate({ "hooks" => {} }))

    stub_expand_path = lambda do |path|
      return settings_path if path == "~/.claude/settings.json"
      File.expand_path(path)
    end

    File.stub :expand_path, stub_expand_path do
      refute rtk_hook_configured?
    end
  end

  def test_verify_rtk_hook_only_reports_not_installed
    settings_path = File.join(@test_dir, "settings.json")
    File.write(settings_path, JSON.generate({
      "hooks" => {
        "bashCommandPrepare" => "rtk rewrite"
      }
    }))

    stub_expand_path = lambda do |path|
      return settings_path if path == "~/.claude/settings.json"

      path
    end

    self.stub(:system, ->(*_args) { false }) do
      File.stub :expand_path, stub_expand_path do
        assert_equal :hook_configured, detect_rtk

        result = verify_rtk
        refute result[:installed]
        refute result[:ready]
        assert_equal :hook_configured, result[:status]
        assert result[:hook_configured]
        assert_nil result[:binary]
        assert_nil result[:version]
      end
    end
  end
end
