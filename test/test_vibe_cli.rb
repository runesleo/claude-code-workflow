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

  def test_sanitize_directory_name_with_special_chars
    assert_equal "my-project", @cli.send(:sanitize_directory_name, "my project")
    assert_equal "my-project", @cli.send(:sanitize_directory_name, "my@project")
    assert_equal "project-name", @cli.send(:sanitize_directory_name, "project/name")
    assert_equal "root", @cli.send(:sanitize_directory_name, "///")
    assert_equal "test", @cli.send(:sanitize_directory_name, "-test-")
    assert_equal "my-project", @cli.send(:sanitize_directory_name, "my---project")
  end

  def test_sanitize_directory_name_with_unicode
    assert_equal "my-project", @cli.send(:sanitize_directory_name, "my项目project")
    assert_equal "test-123", @cli.send(:sanitize_directory_name, "test-123")
  end

  def test_resolve_output_root_with_special_char_destination
    # Create a destination that will overlap with default output root
    # Default output root is "generated/warp" relative to repo root
    # Make destination a parent of the output root to trigger overlap
    dest_with_spaces = File.join(@repo_root, "generated")
    FileUtils.mkdir_p(dest_with_spaces)

    output = @cli.send(
      :resolve_output_root_for_use,
      target: "warp",
      destination_root: dest_with_spaces,
      explicit_output: nil
    )

    # Should use external staging due to overlap
    assert_includes output, ".vibe-generated"
    # Should contain sanitized name
    assert_match %r{generated-[a-f0-9]{12}/warp$}, output
  ensure
    # Don't remove generated dir as it's part of the repo
  end

  def test_checked_in_warp_runtime_matches_renderer
    build_root = Dir.mktmpdir("vibe-warp-build")
    overlay_path = File.join(@repo_root, "examples", "project-overlay.yaml")
    expected_support_files = %w[
      behavior-policies.md
      routing.md
      safety.md
      skills.md
      task-routing.md
      test-standards.md
      workflow-notes.md
    ].sort

    capture_io do
      @cli.run(["build", "warp", "--output", build_root, "--overlay", overlay_path])
    end

    assert_equal expected_support_files, warp_support_files(@repo_root)
    assert_equal expected_support_files, warp_support_files(build_root)
    assert_equal File.read(File.join(@repo_root, "WARP.md")), File.read(File.join(build_root, "WARP.md"))

    expected_support_files.each do |filename|
      tracked_path = File.join(@repo_root, ".vibe", "warp", filename)
      generated_path = File.join(build_root, ".vibe", "warp", filename)
      assert_equal File.read(tracked_path), File.read(generated_path), "Mismatch for #{filename}"
    end

    assert_equal normalized_manifest(File.join(@repo_root, ".vibe", "manifest.json")),
                 normalized_manifest(File.join(build_root, ".vibe", "manifest.json"))
    assert_equal normalized_target_summary(File.join(@repo_root, ".vibe", "target-summary.md")),
                 normalized_target_summary(File.join(build_root, ".vibe", "target-summary.md"))
  ensure
    FileUtils.rm_rf(build_root) if build_root && File.exist?(build_root)
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

  def warp_support_files(root)
    Dir.glob(File.join(root, ".vibe", "warp", "*.md")).map { |path| File.basename(path) }.sort
  end

  def normalized_manifest(path)
    manifest = JSON.parse(File.read(path))
    manifest.delete("generated_at")
    manifest.delete("output_root")
    manifest
  end

  def normalized_target_summary(path)
    File.read(path).lines.reject { |line| line.start_with?("- Generated at: ") }.join
  end
end
