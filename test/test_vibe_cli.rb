# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
load File.expand_path("../bin/vibe", __dir__)

class TestVibeCLI < Minitest::Test
  def setup
    @repo_root = File.expand_path("..", __dir__)
    @test_home = Dir.mktmpdir("vibe-cli-home")
    @output_root = Dir.mktmpdir("vibe-cli-output")
    @original_home = ENV["HOME"]
    ENV["HOME"] = @test_home
    @cli = VibeCLI.new(@repo_root)
  end

  def teardown
    ENV["HOME"] = @original_home
    FileUtils.rm_rf(@test_home) if @test_home && File.exist?(@test_home)
    FileUtils.rm_rf(@output_root) if @output_root && File.exist?(@output_root)
  end

  def test_build_manifest_excludes_conditional_superpowers_without_installation
    manifest = build_manifest("warp")

    refute_includes manifest.fetch("skills").map { |skill| skill["id"] }, "superpowers/tdd"
    refute_includes manifest.fetch("skills").map { |skill| skill["id"] }, "superpowers/brainstorm"
  end

  def test_build_manifest_includes_conditional_superpowers_when_installed
    plugin_dir = File.join(@test_home, ".claude", "plugins", "superpowers")
    FileUtils.mkdir_p(plugin_dir)

    manifest = build_manifest("warp")

    assert_includes manifest.fetch("skills").map { |skill| skill["id"] }, "superpowers/tdd"
    assert_includes manifest.fetch("skills").map { |skill| skill["id"] }, "superpowers/brainstorm"
  end

  def test_generate_superpowers_section_uses_portable_skill_ids
    plugin_dir = File.join(@test_home, ".claude", "plugins", "superpowers")
    FileUtils.mkdir_p(plugin_dir)

    manifest = build_manifest("claude-code")
    section = @cli.send(:generate_superpowers_section, :claude_plugin, manifest)

    assert_includes section, "| `superpowers/tdd` | `suggest` |"
    assert_includes section, "| `superpowers/brainstorm` | `manual` |"
    assert_includes section, "Test-driven development workflow with red-green-refactor cycle."
    assert_includes section, "portable skill IDs"
    refute_includes section, "| `brainstorming` |"
  end

  def test_switch_warp_uses_external_staging_when_repo_root_is_destination
    switch_repo_root = Dir.mktmpdir("vibe-switch-repo")
    FileUtils.cp_r(File.join(@repo_root, "core"), switch_repo_root)
    cli = VibeCLI.new(switch_repo_root)

    stdout, = capture_io { cli.run(["switch", "warp"]) }

    assert_includes stdout, "Applied warp"
    assert File.exist?(File.join(switch_repo_root, "WARP.md"))
    assert File.exist?(File.join(switch_repo_root, ".vibe", "warp", "routing.md"))

    marker = JSON.parse(File.read(File.join(switch_repo_root, ".vibe-target.json")))
    assert_includes marker.fetch("generated_output"), ".vibe-generated"
    refute_equal "generated/warp", marker.fetch("generated_output")
  ensure
    FileUtils.rm_rf(switch_repo_root) if switch_repo_root && File.exist?(switch_repo_root)
  end

  private

  def build_manifest(target)
    profile_name, profile = @cli.send(:default_profile_for_target, target)
    @cli.send(
      :build_manifest,
      target: target,
      profile_name: profile_name,
      profile: profile,
      output_root: File.join(@output_root, target),
      overlay: nil
    )
  end
end
