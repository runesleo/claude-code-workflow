# frozen_string_literal: true

require_relative "../test_helper"
require "yaml"
require "vibe/utils"
require "vibe/overlay_support"
require "vibe/doc_rendering"

# Test class that includes all required modules
class DocRenderingTester
  include Vibe::Utils
  include Vibe::OverlaySupport
  include Vibe::DocRendering

  attr_accessor :repo_root, :policies_doc, :tiers_doc, :providers

  def initialize(repo_root)
    @repo_root = repo_root
    @yaml_cache = {}
    # Load required docs for OverlaySupport
    @policies_doc = YAML.safe_load(File.read(File.join(repo_root, "core/policies/behaviors.yaml")), aliases: true)
    @tiers_doc = YAML.safe_load(File.read(File.join(repo_root, "core/models/tiers.yaml")), aliases: true)
    # Load providers for render_model_config_note
    providers_path = File.join(repo_root, "core/models/providers.yaml")
    @providers = File.exist?(providers_path) ? YAML.safe_load(File.read(providers_path), aliases: true) : {}
  end
end

class TestDocRendering < Minitest::Test
  def setup
    @repo_root = File.expand_path("../../..", __FILE__)
    @renderer = DocRenderingTester.new(@repo_root)

    # Minimal manifest for testing
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
        },
        {
          "id" => "verify-before-claim",
          "category" => "quality",
          "enforcement" => "mandatory",
          "target_render_group" => "always_on",
          "summary" => "Verify before claiming completion",
          "source_refs" => []
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
        },
        {
          "id" => "superpowers/tdd",
          "namespace" => "superpowers",
          "priority" => "P2",
          "trigger_mode" => "suggest",
          "target_support" => "external-skill",
          "intent" => "Test-driven development workflow"
        }
      ],
      "tiers" => {
        "critical_reasoner" => {
          "description" => "Highest-assurance reasoning",
          "default_role" => "maker_or_final_decider",
          "route_when" => ["Critical business logic"],
          "avoid_when" => ["Docs-only edits"]
        },
        "workhorse_coder" => {
          "description" => "Default daily coding tier",
          "default_role" => "primary_executor",
          "route_when" => ["Standard feature work"],
          "avoid_when" => ["Highest-risk business logic"]
        }
      },
      "routing_defaults" => {
        "direct_handle_max_changed_lines" => 50,
        "cross_verify_default_for" => ["critical_business_analysis"]
      },
      "overlay" => nil
    }
  end

  # === render_inspect tests ===

  def test_render_inspect_includes_repo_root
    payload = {
      "repo_root" => @repo_root,
      "base_policy_count" => 8,
      "effective_policy_count" => 8,
      "overlay" => nil,
      "current_repo_target" => nil,
      "targets" => []
    }

    output = @renderer.render_inspect(payload)
    assert_includes output, "Vibe inspection"
    assert_includes output, "Repository root:"
    assert_includes output, @repo_root
  end

  def test_render_inspect_shows_overlay_when_present
    payload = {
      "repo_root" => @repo_root,
      "base_policy_count" => 8,
      "effective_policy_count" => 9,
      "overlay" => {
        "name" => "test-overlay",
        "display_path" => ".vibe/overlay.yaml",
        "target_patch_targets" => ["claude-code"]
      },
      "current_repo_target" => nil,
      "targets" => []
    }

    output = @renderer.render_inspect(payload)
    assert_includes output, "test-overlay"
    assert_includes output, ".vibe/overlay.yaml"
    assert_includes output, "claude-code"
  end

  def test_render_inspect_shows_targets
    payload = {
      "repo_root" => @repo_root,
      "base_policy_count" => 8,
      "effective_policy_count" => 8,
      "overlay" => nil,
      "current_repo_target" => nil,
      "targets" => [
        {
          "target" => "claude-code",
          "default_profile" => "claude-code-default",
          "profile_maturity" => "active",
          "generated_output" => "generated/claude-code",
          "generated_manifest_present" => true,
          "overlay" => nil,
          "profile_notes" => ["Fully supported"]
        }
      ]
    }

    output = @renderer.render_inspect(payload)
    assert_includes output, "Targets:"
    assert_includes output, "claude-code"
    assert_includes output, "claude-code-default"
    assert_includes output, "Fully supported"
  end

  # === render_target_summary tests ===

  def test_render_target_summary_includes_basic_info
    output = @renderer.render_target_summary(@base_manifest)

    assert_includes output, "# Generated target summary"
    assert_includes output, "Target: `claude-code`"
    assert_includes output, "Profile: `claude-code-default`"
    assert_includes output, "Profile maturity: `active`"
  end

  def test_render_target_summary_includes_capability_mapping
    output = @renderer.render_target_summary(@base_manifest)

    assert_includes output, "## Capability mapping"
    assert_includes output, "critical_reasoner"
    assert_includes output, "claude.opus-class"
    assert_includes output, "workhorse_coder"
    assert_includes output, "claude.sonnet-class"
  end

  def test_render_target_summary_includes_policies
    output = @renderer.render_target_summary(@base_manifest)

    assert_includes output, "## Behavior policies"
    assert_includes output, "ssot-first"
    assert_includes output, "verify-before-claim"
  end

  def test_render_target_summary_includes_skills
    output = @renderer.render_target_summary(@base_manifest)

    assert_includes output, "## Skills"
    assert_includes output, "systematic-debugging"
    assert_includes output, "superpowers/tdd"
  end

  # === render_behavior_doc tests ===

  def test_render_behavior_doc_includes_all_policies
    output = @renderer.render_behavior_doc(@base_manifest)

    assert_includes output, "# Behavior policies"
    assert_includes output, "ssot-first"
    assert_includes output, "state_management"
    assert_includes output, "mandatory"
    assert_includes output, "verify-before-claim"
    assert_includes output, "quality"
  end

  def test_render_behavior_doc_includes_source_refs
    output = @renderer.render_behavior_doc(@base_manifest)

    assert_includes output, "rules/behaviors.md"
    assert_includes output, "source refs: none" # For verify-before-claim
  end

  def test_render_behavior_doc_no_note_for_claude_code
    output = @renderer.render_behavior_doc(@base_manifest)

    # claude-code target should not have the source note
    refute_includes output, "Source refs refer to files in the portable workflow"
  end

  def test_render_behavior_doc_includes_note_for_non_claude
    manifest = @base_manifest.merge("target" => "opencode")
    output = @renderer.render_behavior_doc(manifest)

    assert_includes output, "Source refs refer to files in the portable workflow"
  end

  # === render_general_doc tests ===

  def test_render_general_doc_structure
    output = @renderer.render_general_doc(@base_manifest)

    assert_includes output, "# General workflow"
    assert_includes output, "Generated target: `claude-code`"
    assert_includes output, "## Working rules"
    assert_includes output, "ssot-first"
  end

  # === render_routing_doc tests ===

  def test_render_routing_doc_includes_tier_descriptions
    output = @renderer.render_routing_doc(@base_manifest)

    assert_includes output, "# Routing profile"
    assert_includes output, "## Capability tiers"
    assert_includes output, "critical_reasoner"
    assert_includes output, "Highest-assurance reasoning"
    assert_includes output, "workhorse_coder"
    assert_includes output, "Default daily coding tier"
  end

  def test_render_routing_doc_includes_routing_policies
    output = @renderer.render_routing_doc(@base_manifest)

    # Should include routing policies (if any in the manifest)
    assert_includes output, "## Routing behavior policies"
  end

  def test_render_routing_doc_includes_mapping
    output = @renderer.render_routing_doc(@base_manifest)

    assert_includes output, "## Active mapping"
    assert_includes output, "critical_reasoner"
    assert_includes output, "claude.opus-class"
  end

  def test_render_routing_doc_includes_defaults
    output = @renderer.render_routing_doc(@base_manifest)

    assert_includes output, "## Routing defaults"
    assert_includes output, "direct_handle_max_changed_lines"
    assert_includes output, "50"
    assert_includes output, "cross_verify_default_for"
    assert_includes output, "critical_business_analysis"
  end

  # === render_skills_doc tests ===

  def test_render_skills_doc_includes_all_skills
    output = @renderer.render_skills_doc(@base_manifest)

    assert_includes output, "# Portable skills"
    assert_includes output, "systematic-debugging"
    assert_includes output, "builtin"
    assert_includes output, "P0"
    assert_includes output, "mandatory"
    assert_includes output, "superpowers/tdd"
    assert_includes output, "superpowers"
    assert_includes output, "P2"
    assert_includes output, "suggest"
  end

  def test_render_skills_doc_includes_intents
    output = @renderer.render_skills_doc(@base_manifest)

    assert_includes output, "Find root cause before fixes"
    assert_includes output, "Test-driven development workflow"
  end

  # === generate_skill_trigger_table tests ===

  def test_generate_skill_trigger_table_for_suggest_skills
    output = @renderer.generate_skill_trigger_table(@base_manifest)

    # superpowers/tdd is a suggest-mode skill
    assert_includes output, "When to Use External Skills"
    assert_includes output, "superpowers/tdd"
  end

  def test_generate_skill_trigger_table_empty_for_no_suggest_skills
    manifest = @base_manifest.dup
    manifest["skills"] = [
      {
        "id" => "systematic-debugging",
        "namespace" => "builtin",
        "priority" => "P0",
        "trigger_mode" => "mandatory",
        "intent" => "Find root cause"
      }
    ]

    output = @renderer.generate_skill_trigger_table(manifest)
    assert_equal "", output
  end

  # === Helper method tests ===

  def test_yaml_caching
    # First load should cache
    path = File.join(@repo_root, "core", "integrations", "superpowers.yaml")
    skip "superpowers.yaml not found" unless File.exist?(path)

    result1 = @renderer.load_yaml_cached(path)
    result2 = @renderer.load_yaml_cached(path)

    assert_same result1, result2, "Should return cached result"
  end
end
