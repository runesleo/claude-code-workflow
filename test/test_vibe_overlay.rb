#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require "json"
require "yaml"
require "fileutils"
require "stringio"
require "tmpdir"
require_relative "../lib/vibe/utils"
require_relative "../lib/vibe/overlay_support"

# Lightweight host satisfying OverlaySupport + Utils dependencies.
class OverlayHost
  SUPPORTED_TARGETS = %w[claude-code codex-cli cursor kimi-code opencode warp].freeze
  include Vibe::Utils
  include Vibe::OverlaySupport

  attr_reader :repo_root
  def initialize(repo_root, policies_doc, tiers_doc)
    @repo_root = repo_root
    @policies_doc = policies_doc
    @tiers_doc = tiers_doc
  end

  def policies_doc
    @policies_doc
  end

  def tiers_doc
    @tiers_doc
  end
end

class TestVibeOverlay < Minitest::Test
  MINIMAL_POLICIES = {
    "policies" => [
      {
        "id" => "pol-1",
        "category" => "core",
        "enforcement" => "mandatory",
        "target_render_group" => "always_on",
        "summary" => "Always verify before claiming.",
        "source_refs" => ["rules/behaviors.md"]
      },
      {
        "id" => "pol-2",
        "category" => "workflow",
        "enforcement" => "recommended",
        "target_render_group" => "optional",
        "summary" => "Optional workflow guidance.",
        "source_refs" => ["rules/behaviors.md"]
      }
    ]
  }.freeze
  MINIMAL_TIERS = {
    "tiers" => {
      "critical_reasoner" => {},
      "workhorse_coder" => {},
      "fast_router" => {},
      "independent_verifier" => {},
      "cheap_local" => {}
    }
  }.freeze

  def setup
    @tmp = Dir.mktmpdir
    @host = OverlayHost.new(@tmp, MINIMAL_POLICIES, MINIMAL_TIERS)
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  # --- resolve_overlay ---

  def test_resolve_overlay_explicit_path
    overlay_path = File.join(@tmp, "my-overlay.yaml")
    File.write(overlay_path, YAML.dump({
      "name" => "test-overlay",
      "profile" => { "mapping_overrides" => { "critical_reasoner" => "gpt-4o" } },
      "policies" => {},
      "targets" => {}
    }))

    overlay = @host.resolve_overlay(explicit_path: overlay_path, search_roots: [])
    assert_equal("test-overlay", overlay["name"])
  end

  def test_resolve_overlay_auto_discovery
    vibe_dir = File.join(@tmp, ".vibe")
    FileUtils.mkdir_p(vibe_dir)
    File.write(File.join(vibe_dir, "overlay.yaml"), YAML.dump({ "name" => "discovered" }))

    overlay = @host.resolve_overlay(explicit_path: nil, search_roots: [@tmp])
    assert_equal("discovered", overlay["name"])
  end

  def test_resolve_overlay_warns_on_unknown_keys
    overlay_path = File.join(@tmp, "weird.yaml")
    File.write(overlay_path, YAML.dump({ "name" => "x", "bogus_key" => true }))

    warnings = capture_warnings do
      @host.resolve_overlay(explicit_path: overlay_path, search_roots: [])
    end
    assert_match(/unknown top-level keys.*bogus_key/, warnings)
  end

  def test_resolve_overlay_nil_when_no_file
    result = @host.resolve_overlay(explicit_path: nil, search_roots: [@tmp])
    assert_nil result
  end

  # --- effective_policies ---

  def test_effective_policies_without_overlay
    policies = @host.effective_policies(nil)
    assert_equal(2, policies.length)
    assert_equal("pol-1", policies.first["id"])
  end

  def test_effective_policies_with_appended_policy
    overlay_path = File.join(@tmp, "overlay.yaml")
    File.write(overlay_path, YAML.dump({
      "name" => "extra",
      "policies" => {
        "append" => [
          {
            "id" => "pol-2",
            "category" => "project",
            "enforcement" => "recommended",
            "target_render_group" => "always_on",
            "summary" => "Extra rule from overlay."
          }
        ]
      }
    }))

    overlay = @host.resolve_overlay(explicit_path: overlay_path, search_roots: [])
    policies = @host.effective_policies(overlay)
    assert_equal(2, policies.length)
    assert_equal("pol-2", policies.last["id"])
    # Verify overlay ref is appended to source_refs
    assert(policies.last["source_refs"].any? { |ref| ref.include?("overlay.yaml") })
  end

  def test_effective_policies_merges_existing_policy
    overlay_path = File.join(@tmp, "overlay.yaml")
    File.write(overlay_path, YAML.dump({
      "name" => "patch",
      "policies" => {
        "append" => [
          {
            "id" => "pol-1",
            "category" => "core",
            "enforcement" => "mandatory",
            "target_render_group" => "always_on",
            "summary" => "Updated summary from overlay."
          }
        ]
      }
    }))

    overlay = @host.resolve_overlay(explicit_path: overlay_path, search_roots: [])
    policies = @host.effective_policies(overlay)
    assert_equal(2, policies.length)
    assert_equal("Updated summary from overlay.", policies.first["summary"])
  end

  # --- overlay_target_patch ---

  def test_overlay_target_patch_extracts_target
    overlay_path = File.join(@tmp, "overlay.yaml")
    File.write(overlay_path, YAML.dump({
      "name" => "t",
      "targets" => {
        "claude-code" => { "permissions" => { "ask" => ["Bash(docker:*)"] } },
        "warp" => {}
      }
    }))

    overlay = @host.resolve_overlay(explicit_path: overlay_path, search_roots: [])
    patch = @host.overlay_target_patch(overlay, "claude-code")
    assert_equal({ "permissions" => { "ask" => ["Bash(docker:*)"] } }, patch)
  end

  def test_overlay_target_patch_returns_empty_for_missing_target
    overlay_path = File.join(@tmp, "overlay.yaml")
    File.write(overlay_path, YAML.dump({ "name" => "t" }))

    overlay = @host.resolve_overlay(explicit_path: overlay_path, search_roots: [])
    assert_equal({}, @host.overlay_target_patch(overlay, "warp"))
  end

  def test_resolve_overlay_rejects_unknown_mapping_override_tier
    overlay_path = File.join(@tmp, "bad-tier.yaml")
    File.write(overlay_path, YAML.dump({
      "name" => "bad-tier",
      "profile" => { "mapping_overrides" => { "typo_tier" => "gpt-4o" } }
    }))

    error = assert_raises(Vibe::ValidationError) do
      @host.resolve_overlay(explicit_path: overlay_path, search_roots: [])
    end

    assert_match(/unknown capability tiers: typo_tier/, error.message)
  end

  def test_resolve_overlay_rejects_unknown_policy_enforcement
    overlay_path = File.join(@tmp, "bad-enforcement.yaml")
    File.write(overlay_path, YAML.dump({
      "name" => "bad-enforcement",
      "policies" => {
        "append" => [
          {
            "id" => "pol-x",
            "category" => "project",
            "enforcement" => "definitely",
            "target_render_group" => "always_on",
            "summary" => "Bad enforcement"
          }
        ]
      }
    }))

    error = assert_raises(Vibe::ValidationError) do
      @host.resolve_overlay(explicit_path: overlay_path, search_roots: [])
    end

    assert_match(/unknown enforcement 'definitely'/, error.message)
  end

  def test_resolve_overlay_rejects_unknown_target_render_group
    overlay_path = File.join(@tmp, "bad-render-group.yaml")
    File.write(overlay_path, YAML.dump({
      "name" => "bad-render-group",
      "policies" => {
        "append" => [
          {
            "id" => "pol-x",
            "category" => "project",
            "enforcement" => "mandatory",
            "target_render_group" => "not-a-real-group",
            "summary" => "Bad render group"
          }
        ]
      }
    }))

    error = assert_raises(Vibe::ValidationError) do
      @host.resolve_overlay(explicit_path: overlay_path, search_roots: [])
    end

    assert_match(/unknown target_render_group 'not-a-real-group'/, error.message)
  end

  def test_resolve_overlay_rejects_unknown_target_patch_target
    overlay_path = File.join(@tmp, "bad-target.yaml")
    File.write(overlay_path, YAML.dump({
      "name" => "bad-target",
      "targets" => {
        "not-a-target" => {}
      }
    }))

    error = assert_raises(Vibe::ValidationError) do
      @host.resolve_overlay(explicit_path: overlay_path, search_roots: [])
    end

    assert_match(/unsupported targets: not-a-target/, error.message)
  end

  private

  def capture_warnings
    old_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = old_stderr
  end
end
