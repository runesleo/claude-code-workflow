# frozen_string_literal: true

require_relative "../test_helper"
require "yaml"
require "vibe/utils"
require "vibe/overlay_support"
require "vibe/doc_rendering"
require "vibe/native_configs"
require "vibe/path_safety"
require "vibe/external_tools"
require "vibe/target_renderers"
require "vibe/config_driven_renderers"
require "vibe/platform_utils"

# Test class that includes all required modules
class ConfigDrivenRenderersTester
  include Vibe::Utils
  include Vibe::OverlaySupport
  include Vibe::DocRendering
  include Vibe::NativeConfigs
  include Vibe::PathSafety
  include Vibe::ExternalTools
  include Vibe::TargetRenderers
  include Vibe::ConfigDrivenRenderers
  include Vibe::PlatformUtils

  attr_accessor :repo_root, :policies_doc, :tiers_doc, :providers, :skip_integrations

  def initialize(repo_root)
    @repo_root = repo_root
    @yaml_cache = {}
    @skip_integrations = true
    @policies_doc = YAML.safe_load(File.read(File.join(repo_root, "core/policies/behaviors.yaml")), aliases: true)
    @tiers_doc = YAML.safe_load(File.read(File.join(repo_root, "core/models/tiers.yaml")), aliases: true)
    providers_path = File.join(repo_root, "core/models/providers.yaml")
    @providers = File.exist?(providers_path) ? YAML.safe_load(File.read(providers_path), aliases: true) : {}
  end

  def task_routing_doc
    @task_routing_doc ||= load_doc("core/policies/task-routing.yaml")
  end

  def test_standards_doc
    @test_standards_doc ||= load_doc("core/policies/test-standards.yaml")
  end

  def security_doc
    @security_doc ||= load_doc("core/security/policy.yaml")
  end

  def skills_doc
    @skills_doc ||= load_doc("core/skills/registry.yaml")
  end

  private

  def load_doc(relative_path)
    path = File.join(@repo_root, relative_path)
    File.exist?(path) ? YAML.safe_load(File.read(path), aliases: true) : nil
  end
end

class TestConfigDrivenRenderers < Minitest::Test
  def setup
    @repo_root = File.expand_path("../../..", __FILE__)
    @renderer = ConfigDrivenRenderersTester.new(@repo_root)
    @build_root = Dir.mktmpdir("vibe-test")

    @base_manifest = {
      "target" => "claude-code",
      "profile" => "claude-code-default",
      "profile_maturity" => "active",
      "generated_at" => "2026-03-12T00:00:00Z",
      "profile_mapping" => {
        "critical_reasoner" => "claude.opus-class",
        "workhorse_coder" => "claude.sonnet-class"
      },
      "policies" => [
        {
          "id" => "ssot-first",
          "category" => "state_management",
          "enforcement" => "mandatory",
          "target_render_group" => "always_on",
          "summary" => "Keep repository files as SSOT",
          "source_refs" => ["rules/behaviors.md"]
        }
      ],
      "skills" => [
        {
          "id" => "systematic-debugging",
          "namespace" => "builtin",
          "priority" => "P0",
          "trigger_mode" => "mandatory",
          "intent" => "Find root cause"
        }
      ],
      "tiers" => {
        "critical_reasoner" => {
          "description" => "Highest-assurance reasoning",
          "default_role" => "maker",
          "route_when" => ["Critical logic"],
          "avoid_when" => ["Docs-only"]
        }
      },
      "routing_defaults" => { "direct_handle_max_changed_lines" => 50 },
      "security" => {
        "severity_levels" => {
          "P0" => { "label" => "block", "runtime_action" => "deny" },
          "P1" => { "label" => "warning", "runtime_action" => "warn" }
        },
        "signal_categories" => [],
        "adjudication_factors" => [],
        "target_actions" => { "P0" => "Block" }
      },
      "overlay" => nil
    }
  end

  def teardown
    FileUtils.rm_rf(@build_root) if @build_root && File.exist?(@build_root)
  end

  def test_platform_configs_loads_from_yaml
    configs = @renderer.platform_configs

    assert configs.is_a?(Hash), "Should return a Hash"
    assert configs.key?("claude-code"), "Should have claude-code config"
    assert configs.key?("opencode"), "Should have opencode config"
  end

  def test_render_claude_v2_creates_expected_structure
    @renderer.render_claude_v2(@build_root, @base_manifest, project_level: false)

    # Check entrypoint
    assert File.exist?(File.join(@build_root, "CLAUDE.md")), "CLAUDE.md should exist"

    # Check vibe directory
    vibe_dir = File.join(@build_root, ".vibe", "claude-code")
    assert File.directory?(vibe_dir), ".vibe/claude-code/ should exist"

    # Check docs
    assert File.exist?(File.join(vibe_dir, "behavior-policies.md"))
    assert File.exist?(File.join(vibe_dir, "safety.md"))
    assert File.exist?(File.join(vibe_dir, "task-routing.md"))
  end

  def test_render_opencode_v2_creates_expected_structure
    manifest = @base_manifest.dup
    manifest["target"] = "opencode"

    @renderer.render_opencode_v2(@build_root, manifest, project_level: false)

    # Check entrypoint
    assert File.exist?(File.join(@build_root, "AGENTS.md")), "AGENTS.md should exist"

    # Check vibe directory
    vibe_dir = File.join(@build_root, ".vibe", "opencode")
    assert File.directory?(vibe_dir), ".vibe/opencode/ should exist"

    # Check docs
    assert File.exist?(File.join(vibe_dir, "behavior-policies.md"))
    assert File.exist?(File.join(vibe_dir, "routing.md"))
  end

  def test_render_platform_raises_on_unknown_platform
    assert_raises(ArgumentError) do
      @renderer.render_platform(@build_root, @base_manifest, "unknown-platform")
    end
  end

  def test_claude_v2_matches_legacy_render_claude
    # Build with new renderer
    @renderer.render_claude_v2(@build_root, @base_manifest, project_level: false)

    legacy_root = Dir.mktmpdir("vibe-legacy")
    begin
      # Build with legacy renderer
      @renderer.render_claude(legacy_root, @base_manifest, project_level: false)

      # Compare key files
      new_claude_md = File.read(File.join(@build_root, "CLAUDE.md"))
      legacy_claude_md = File.read(File.join(legacy_root, "CLAUDE.md"))

      # Both should contain key sections
      assert_includes new_claude_md, "Vibe workflow"
      assert_includes legacy_claude_md, "Vibe workflow"

      # Both should have vibe directory
      assert File.directory?(File.join(@build_root, ".vibe", "claude-code"))
      assert File.directory?(File.join(legacy_root, ".vibe", "claude-code"))
    ensure
      FileUtils.rm_rf(legacy_root)
    end
  end

  def test_opencode_v2_matches_legacy_render_opencode
    manifest = @base_manifest.dup
    manifest["target"] = "opencode"

    @renderer.render_opencode_v2(@build_root, manifest, project_level: false)

    legacy_root = Dir.mktmpdir("vibe-legacy")
    begin
      @renderer.render_opencode(legacy_root, manifest, project_level: false)

      new_agents_md = File.read(File.join(@build_root, "AGENTS.md"))
      legacy_agents_md = File.read(File.join(legacy_root, "AGENTS.md"))

      assert_includes new_agents_md, "Vibe workflow"
      assert_includes legacy_agents_md, "Vibe workflow"
    ensure
      FileUtils.rm_rf(legacy_root)
    end
  end
end
