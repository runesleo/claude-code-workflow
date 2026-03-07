#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "json"
require "open3"
require_relative "../lib/vibe/external_tools"
require_relative "../lib/vibe/init_support"

class TestVibeInit < Minitest::Test
  include Vibe::ExternalTools
  include Vibe::InitSupport

  class FakeInput
    def initialize(lines, tty:)
      @lines = Array(lines).dup
      @tty = tty
    end

    def gets
      @lines.shift
    end

    def tty?
      @tty
    end
  end

  def setup
    @repo_root = File.expand_path("..", __dir__)
    @test_home = Dir.mktmpdir("vibe-init-test")
    @original_home = ENV["HOME"]
    ENV["HOME"] = @test_home
  end

  def teardown
    ENV["HOME"] = @original_home
    FileUtils.rm_rf(@test_home) if @test_home && File.exist?(@test_home)
  end

  def test_load_integration_config_superpowers
    config = load_integration_config("superpowers")
    refute_nil config, "Config should not be nil"
    assert_equal "superpowers", config["name"]
    assert config.key?("detection"), "Config should have detection key"
    assert config.key?("installation_methods"), "Config should have installation_methods key"
    assert config.key?("skills"), "Config should have skills key"
  end

  def test_load_integration_config_rtk
    config = load_integration_config("rtk")
    refute_nil config, "Config should not be nil"
    assert_equal "rtk", config["name"]
    assert config.key?("detection"), "Config should have detection key"
    assert config.key?("installation_methods"), "Config should have installation_methods key"
  end

  def test_load_integration_config_missing
    config = load_integration_config("nonexistent")
    assert_nil config
  end

  def test_list_integrations
    integrations = list_integrations
    assert_includes integrations, "superpowers"
    assert_includes integrations, "rtk"
  end

  def test_detect_superpowers_not_installed
    status = detect_superpowers
    assert_equal :not_installed, status
  end

  def test_detect_superpowers_claude_plugin
    plugin_dir = File.join(@test_home, ".claude", "plugins", "superpowers")
    FileUtils.mkdir_p(plugin_dir)
    File.write(File.join(plugin_dir, "README.md"), "test")

    status = detect_superpowers
    assert_equal :claude_plugin, status
  end

  def test_detect_superpowers_skills_symlink
    skills_dir = File.join(@test_home, ".claude", "skills")
    FileUtils.mkdir_p(skills_dir)
    FileUtils.ln_s("/fake/superpowers", File.join(skills_dir, "superpowers-test"))

    status = detect_superpowers
    assert_equal :skills_symlink, status
  end

  def test_detect_superpowers_local_clone
    superpowers_dir = File.join(@test_home, "superpowers")
    FileUtils.mkdir_p(superpowers_dir)
    File.write(File.join(superpowers_dir, "README.md"), "test")

    status = detect_superpowers
    assert_equal :local_clone, status
  end

  def test_detect_rtk_not_installed
    status = detect_rtk
    assert_equal :not_installed, status
  end

  def test_detect_rtk_hook_configured_without_binary
    claude_dir = File.join(@test_home, ".claude")
    FileUtils.mkdir_p(claude_dir)
    File.write(File.join(claude_dir, "settings.json"), JSON.generate({
      "hooks" => {
        "bashCommandPrepare" => "rtk rewrite"
      }
    }))

    self.stub(:system, ->(*_args) { false }) do
      assert_equal :hook_configured, detect_rtk
    end
  end

  def test_verify_superpowers_not_installed
    result = verify_superpowers
    refute result[:installed]
  end

  def test_verify_rtk_not_installed
    result = verify_rtk
    refute result[:installed]
  end

  def test_verify_rtk_hook_configured_without_binary_is_not_ready
    claude_dir = File.join(@test_home, ".claude")
    FileUtils.mkdir_p(claude_dir)
    File.write(File.join(claude_dir, "settings.json"), JSON.generate({
      "hooks" => {
        "bashCommandPrepare" => "rtk rewrite"
      }
    }))

    self.stub(:system, ->(*_args) { false }) do
      result = verify_rtk
      refute result[:installed]
      refute result[:ready]
      assert_equal :hook_configured, result[:status]
      assert result[:hook_configured]
    end
  end

  def test_integration_status
    status = integration_status
    assert status.is_a?(Hash)
    assert status.key?(:superpowers)
    assert status.key?(:rtk)
  end

  def test_missing_integrations
    missing = missing_integrations
    assert missing.is_a?(Array)
    assert_includes missing, :superpowers
    assert_includes missing, :rtk
  end

  def test_superpowers_location_not_installed
    location = superpowers_location
    assert_nil location
  end

  def test_superpowers_location_claude_plugin
    plugin_dir = File.join(@test_home, ".claude", "plugins", "superpowers")
    FileUtils.mkdir_p(plugin_dir)
    File.write(File.join(plugin_dir, "README.md"), "test")

    location = superpowers_location
    assert_equal plugin_dir, location
  end

  def test_rtk_version_not_installed
    version = rtk_version
    assert_nil version
  end

  def test_check_environment
    # Should not raise error
    check_environment
  end

  def test_ask_yes_no_raises_validation_error_on_interactive_eof
    error = nil

    with_stdin(FakeInput.new([], tty: true)) do
      capture_io do
        error = assert_raises(Vibe::ValidationError) { ask_yes_no("Continue?") }
      end
    end

    assert_match(/Input ended before a response was provided/, error.message)
  end

  def test_ask_choice_raises_validation_error_on_interactive_eof
    error = nil

    with_stdin(FakeInput.new([], tty: true)) do
      capture_io do
        error = assert_raises(Vibe::ValidationError) { ask_choice("Choose [1-2]", %w[1 2]) }
      end
    end

    assert_match(/Input ended before a response was provided/, error.message)
  end

  def test_bin_vibe_init_rejects_non_interactive_stdin_with_clear_message
    output, status = Open3.capture2e(
      { "HOME" => @test_home },
      File.join(@repo_root, "bin", "vibe"),
      "init",
      stdin_data: "",
      chdir: @repo_root
    )

    refute status.success?
    assert_includes output, "interactive terminal"
    assert_includes output, "bin/vibe init --verify"
    assert_includes output, "docs/integrations.md"
    refute_includes output, "NoMethodError"
  end

  def test_bin_vibe_init_verify_allows_non_interactive_stdin
    output, status = Open3.capture2e(
      { "HOME" => @test_home },
      File.join(@repo_root, "bin", "vibe"),
      "init",
      "--verify",
      stdin_data: "",
      chdir: @repo_root
    )

    assert status.success?
    assert_includes output, "Verifying integrations..."
    refute_includes output, "interactive terminal"
  end

  def test_install_rtk_offers_manual_download_instead_of_install_script
    config = load_integration_config("rtk")

    self.stub(:ask_choice, "2") do
      stdout, = capture_io { install_rtk(config) }

      assert_includes stdout, "Manual download (GitHub releases)"
      assert_includes stdout, "https://github.com/rtk-ai/rtk/releases"
      refute_includes stdout, "Install script"
    end
  end

  private

  def with_stdin(io)
    original_stdin = $stdin
    $stdin = io
    yield
  ensure
    $stdin = original_stdin
  end
end


