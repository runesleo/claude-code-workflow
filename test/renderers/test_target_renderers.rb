# frozen_string_literal: true

require_relative "../test_helper"
require "yaml"
require "vibe/utils"
require "vibe/overlay_support"
require "vibe/doc_rendering"
require "vibe/native_configs"
require "vibe/path_safety"
require "vibe/external_tools"
require "vibe/platform_utils"
require "vibe/target_renderers"

# Test class that includes all required modules
class TargetRenderersTester
  include Vibe::Utils
  include Vibe::OverlaySupport
  include Vibe::DocRendering
  include Vibe::NativeConfigs
  include Vibe::PathSafety
  include Vibe::ExternalTools
  include Vibe::PlatformUtils
  include Vibe::TargetRenderers

  attr_accessor :repo_root, :policies_doc, :tiers_doc, :providers, :skip_integrations

  def initialize(repo_root)
    @repo_root = repo_root
    @yaml_cache = {}
    @skip_integrations = true
    # Load required docs
    @policies_doc = YAML.safe_load(File.read(File.join(repo_root, "core/policies/behaviors.yaml")), aliases: true)
    @tiers_doc = YAML.safe_load(File.read(File.join(repo_root, "core/models/tiers.yaml")), aliases: true)
    providers_path = File.join(repo_root, "core/models/providers.yaml")
    @providers = File.exist?(providers_path) ? YAML.safe_load(File.read(providers_path), aliases: true) : {}
  end

  # Override doc loaders to load from files
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

class TestTargetRenderers < Minitest::Test
  def setup
    @repo_root = File.expand_path("../../..", __FILE__)
    @renderer = TargetRenderersTester.new(@repo_root)
    @build_root = Dir.mktmpdir("vibe-test")

    # Minimal manifest for testing - includes all required fields
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
          "target_support" => "native-skill",
          "intent" => "Find root cause before fixes"
        }
      ],
      "tiers" => {
        "critical_reasoner" => {
          "description" => "Highest-assurance reasoning",
          "default_role" => "maker_or_final_decider",
          "route_when" => ["Critical business logic"],
          "avoid_when" => ["Docs-only edits"]
        }
      },
      "routing_defaults" => {
        "direct_handle_max_changed_lines" => 50
      },
      "security" => {
        "severity_levels" => {
          "P0" => {"label" => "block", "runtime_action" => "deny_and_stop"},
          "P1" => {"label" => "high_risk_review", "runtime_action" => "require_context_review"},
          "P2" => {"label" => "warning", "runtime_action" => "warn_log_continue"}
        },
        "signal_categories" => [
          {"id" => "network_egress", "base_severity" => "P1", "indicators" => ["http_url"]},
          {"id" => "destructive_operation", "base_severity" => "P0", "indicators" => ["rm -rf"]}
        ],
        "adjudication_factors" => ["asset_sensitivity", "execution_capability", "scope_of_change"],
        "target_actions" => {
          "P0" => "Prefer hooks or permissions deny",
          "P1" => "Prefer hook-mediated confirmation",
          "P2" => "Warn in output and continue"
        }
      },
      "overlay" => nil
    }
  end

  def teardown
    FileUtils.rm_rf(@build_root) if @build_root && File.exist?(@build_root)
  end

  # === render_claude_global tests ===

  def test_render_claude_global_creates_claude_md
    @renderer.render_claude_global(@build_root, @base_manifest)

    assert File.exist?(File.join(@build_root, "CLAUDE.md")), "CLAUDE.md should exist"
    content = File.read(File.join(@build_root, "CLAUDE.md"))
    assert_includes content, "Vibe workflow"
    assert_includes content, "Claude Code"
  end

  def test_render_claude_global_copies_runtime_directories
    @renderer.render_claude_global(@build_root, @base_manifest)

    # Check that runtime directories are copied
    assert File.directory?(File.join(@build_root, "rules")), "rules/ directory should exist"
    assert File.directory?(File.join(@build_root, "skills")), "skills/ directory should exist"
    assert File.directory?(File.join(@build_root, "agents")), "agents/ directory should exist"
    assert File.directory?(File.join(@build_root, "commands")), "commands/ directory should exist"
    assert File.directory?(File.join(@build_root, "memory")), "memory/ directory should exist"
  end

  def test_render_claude_global_creates_settings_json
    @renderer.render_claude_global(@build_root, @base_manifest)

    settings_path = File.join(@build_root, "settings.json")
    assert File.exist?(settings_path), "settings.json should exist"

    settings = JSON.parse(File.read(settings_path))
    # settings.json structure varies by target and profile
    assert settings.is_a?(Hash), "settings.json should be a valid JSON object"
  end

  def test_render_claude_global_creates_vibe_directory
    @renderer.render_claude_global(@build_root, @base_manifest)

    vibe_dir = File.join(@build_root, ".vibe", "claude-code")
    assert File.directory?(vibe_dir), ".vibe/claude-code/ directory should exist"

    # Check documentation files
    assert File.exist?(File.join(vibe_dir, "README.md")), "README.md should exist"
    assert File.exist?(File.join(vibe_dir, "behavior-policies.md")), "behavior-policies.md should exist"
    assert File.exist?(File.join(vibe_dir, "safety.md")), "safety.md should exist"
    assert File.exist?(File.join(vibe_dir, "task-routing.md")), "task-routing.md should exist"
    assert File.exist?(File.join(vibe_dir, "test-standards.md")), "test-standards.md should exist"
  end

  def test_render_claude_global_includes_non_negotiable_rules
    @renderer.render_claude_global(@build_root, @base_manifest)

    claude_md = File.read(File.join(@build_root, "CLAUDE.md"))
    assert_includes claude_md, "Non-negotiable rules"
    assert_includes claude_md, "Capability routing"
  end

  # === render_claude_project tests ===

  def test_render_claude_project_creates_project_config
    @renderer.render_claude_project(@build_root, @base_manifest)

    assert File.exist?(File.join(@build_root, "CLAUDE.md")), "CLAUDE.md should exist"

    # Project config should reference global setup
    content = File.read(File.join(@build_root, "CLAUDE.md"))
    assert_includes content, "Global workflow rules are loaded"
    assert_includes content, "project-specific context"
  end

  def test_render_claude_project_creates_vibe_directory
    @renderer.render_claude_project(@build_root, @base_manifest)

    vibe_dir = File.join(@build_root, ".vibe", "claude-code")
    assert File.directory?(vibe_dir), ".vibe/claude-code/ directory should exist"

    # Should have supporting docs
    assert File.exist?(File.join(vibe_dir, "behavior-policies.md"))
    assert File.exist?(File.join(vibe_dir, "task-routing.md"))
  end

  def test_render_claude_project_does_not_copy_runtime_dirs
    @renderer.render_claude_project(@build_root, @base_manifest)

    # Project mode should not copy runtime directories
    refute File.directory?(File.join(@build_root, "rules")), "rules/ should not exist in project mode"
    refute File.directory?(File.join(@build_root, "skills")), "skills/ should not exist in project mode"
  end

  # === render_opencode_global tests ===

  def test_render_opencode_global_creates_agents_md
    opencode_manifest = @base_manifest.dup
    opencode_manifest["target"] = "opencode"
    opencode_manifest["profile"] = "opencode-default"

    @renderer.render_opencode_global(@build_root, opencode_manifest)

    assert File.exist?(File.join(@build_root, "AGENTS.md")), "AGENTS.md should exist"
    content = File.read(File.join(@build_root, "AGENTS.md"))
    assert_includes content, "Vibe workflow"
    assert_includes content, "OpenCode"
  end

  def test_render_opencode_global_creates_opencode_json
    opencode_manifest = @base_manifest.dup
    opencode_manifest["target"] = "opencode"

    @renderer.render_opencode_global(@build_root, opencode_manifest)

    config_path = File.join(@build_root, "opencode.json")
    assert File.exist?(config_path), "opencode.json should exist"

    config = JSON.parse(File.read(config_path))
    assert config.key?("instructions"), "opencode.json should have instructions"
  end

  def test_render_opencode_global_creates_vibe_directory
    opencode_manifest = @base_manifest.dup
    opencode_manifest["target"] = "opencode"

    @renderer.render_opencode_global(@build_root, opencode_manifest)

    vibe_dir = File.join(@build_root, ".vibe", "opencode")
    assert File.directory?(vibe_dir), ".vibe/opencode/ directory should exist"

    # OpenCode has different doc set
    assert File.exist?(File.join(vibe_dir, "behavior-policies.md"))
    assert File.exist?(File.join(vibe_dir, "routing.md"))
    assert File.exist?(File.join(vibe_dir, "safety.md"))
    assert File.exist?(File.join(vibe_dir, "execution.md"))
    assert File.exist?(File.join(vibe_dir, "general.md"))
  end

  # === render_opencode_project tests ===

  def test_render_opencode_project_creates_project_config
    opencode_manifest = @base_manifest.dup
    opencode_manifest["target"] = "opencode"

    @renderer.render_opencode_project(@build_root, opencode_manifest)

    assert File.exist?(File.join(@build_root, "AGENTS.md"))

    # Should create minimal opencode.json
    assert File.exist?(File.join(@build_root, "opencode.json"))
  end

  # === write_target_docs tests ===

  def test_write_target_docs_creates_expected_files
    doc_types = %i[behavior routing safety]
    output_dir = File.join(@build_root, "docs")
    FileUtils.mkdir_p(output_dir)

    @renderer.write_target_docs(output_dir, @base_manifest, doc_types)

    assert File.exist?(File.join(output_dir, "behavior-policies.md"))
    assert File.exist?(File.join(output_dir, "routing.md"))
    assert File.exist?(File.join(output_dir, "safety.md"))
  end

  def test_write_target_docs_unknown_type_raises_error
    output_dir = File.join(@build_root, "docs")
    FileUtils.mkdir_p(output_dir)

    assert_raises(Vibe::Error) do
      @renderer.write_target_docs(output_dir, @base_manifest, [:unknown_type])
    end
  end

  # === Integration test: full render flow ===

  # NOTE: These tests use legacy render methods to verify backward compatibility
  # The new config-driven renderer (render_claude_v2/render_opencode_v2) is tested separately

  def test_claude_full_render_structure
    # Use the global method directly to test backward compatibility
    @renderer.render_claude_global(@build_root, @base_manifest)

    # Top-level files
    assert File.exist?(File.join(@build_root, "CLAUDE.md"))
    assert File.exist?(File.join(@build_root, "settings.json"))

    # Runtime directories
    assert File.directory?(File.join(@build_root, "rules"))
    assert File.directory?(File.join(@build_root, "docs"))
    assert File.directory?(File.join(@build_root, "skills"))

    # Supporting docs
    vibe_dir = File.join(@build_root, ".vibe", "claude-code")
    assert File.directory?(vibe_dir)
    assert File.exist?(File.join(vibe_dir, "behavior-policies.md"))
    assert File.exist?(File.join(vibe_dir, "safety.md"))
    assert File.exist?(File.join(vibe_dir, "task-routing.md"))
  end

  def test_opencode_full_render_structure
    opencode_manifest = @base_manifest.dup
    opencode_manifest["target"] = "opencode"

    # Use the global method directly to test backward compatibility
    @renderer.render_opencode_global(@build_root, opencode_manifest)

    # Top-level files
    assert File.exist?(File.join(@build_root, "AGENTS.md"))
    assert File.exist?(File.join(@build_root, "opencode.json"))

    # Supporting docs
    vibe_dir = File.join(@build_root, ".vibe", "opencode")
    assert File.directory?(vibe_dir)
    assert File.exist?(File.join(vibe_dir, "behavior-policies.md"))
    assert File.exist?(File.join(vibe_dir, "routing.md"))
    assert File.exist?(File.join(vibe_dir, "safety.md"))
  end
end
