#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "test_helper"
require "yaml"
require "fileutils"
require "tmpdir"
require_relative "../lib/vibe/utils"
require_relative "../lib/vibe/external_tools"

# Test host for external tools
class ExternalToolsHost
  include Vibe::Utils
  include Vibe::ExternalTools

  def initialize(repo_root)
    @repo_root = repo_root
  end
end

class TestYAMLSafety < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @host = ExternalToolsHost.new(@tmpdir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  # --- YAML.safe_load edge cases ---

  def test_safe_load_rejects_ruby_object_injection
    malicious_yaml = <<~YAML
      ---
      - !ruby/object:Object
        foo: bar
    YAML

    assert_raises(Psych::DisallowedClass, ArgumentError) do
      YAML.safe_load(malicious_yaml, aliases: true)
    end
  end

  def test_safe_load_rejects_arbitrary_class
    malicious_yaml = <<~YAML
      ---
      payload: !ruby/object:File
        path: /etc/passwd
    YAML

    assert_raises(Psych::DisallowedClass, ArgumentError) do
      YAML.safe_load(malicious_yaml, aliases: true)
    end
  end

  def test_safe_load_allows_basic_types
    safe_yaml = <<~YAML
      ---
      string: "hello"
      number: 42
      boolean: true
      array:
        - item1
        - item2
      hash:
        key: value
    YAML

    result = YAML.safe_load(safe_yaml, aliases: true)
    assert_equal "hello", result["string"]
    assert_equal 42, result["number"]
    assert_equal true, result["boolean"]
    assert_equal ["item1", "item2"], result["array"]
    assert_equal({ "key" => "value" }, result["hash"])
  end

  def test_safe_load_handles_aliases
    yaml_with_aliases = <<~YAML
      ---
      default: &default
        key: value
      instance:
        <<: *default
        extra: data
    YAML

    result = YAML.safe_load(yaml_with_aliases, aliases: true)
    assert_equal "value", result["instance"]["key"]
    assert_equal "data", result["instance"]["extra"]
  end

  def test_safe_load_handles_empty_document
    result = YAML.safe_load("", aliases: true)
    assert_nil result
  end

  def test_safe_load_handles_nil_value
    result = YAML.safe_load("null", aliases: true)
    assert_nil result
  end

  # --- Integration config loading ---

  def test_load_integration_config_handles_missing_file
    result = @host.load_integration_config("nonexistent")
    assert_nil result
  end

  def test_load_integration_config_handles_valid_yaml
    integrations_dir = File.join(@tmpdir, "core", "integrations")
    FileUtils.mkdir_p(integrations_dir)
    
    config_path = File.join(integrations_dir, "test-tool.yaml")
    File.write(config_path, <<~YAML)
      ---
      name: Test Tool
      version: "1.0"
      features:
        - feature1
        - feature2
    YAML

    result = @host.load_integration_config("test-tool")
    assert_equal "Test Tool", result["name"]
    assert_equal "1.0", result["version"]
    assert_equal ["feature1", "feature2"], result["features"]
  end

  def test_load_integration_config_handles_malformed_yaml
    integrations_dir = File.join(@tmpdir, "core", "integrations")
    FileUtils.mkdir_p(integrations_dir)
    
    config_path = File.join(integrations_dir, "bad-tool.yaml")
    File.write(config_path, <<~YAML)
      ---
      name: [unclosed array
      invalid yaml structure
    YAML

    # Should catch error and return nil
    result = @host.load_integration_config("bad-tool")
    assert_nil result
  end

  def test_load_integration_config_handles_missing_keys
    integrations_dir = File.join(@tmpdir, "core", "integrations")
    FileUtils.mkdir_p(integrations_dir)
    
    config_path = File.join(integrations_dir, "incomplete.yaml")
    File.write(config_path, <<~YAML)
      ---
      name: Incomplete Config
      # Missing other required keys
    YAML

    result = @host.load_integration_config("incomplete")
    assert_equal "Incomplete Config", result["name"]
    # Missing keys should return nil
    assert_nil result["version"]
  end

  def test_load_integration_config_rejects_ruby_objects
    integrations_dir = File.join(@tmpdir, "core", "integrations")
    FileUtils.mkdir_p(integrations_dir)
    
    config_path = File.join(integrations_dir, "malicious.yaml")
    File.write(config_path, <<~YAML)
      ---
      exploit: !ruby/object:Object
        payload: malicious
    YAML

    # Should catch error and return nil
    result = @host.load_integration_config("malicious")
    assert_nil result
  end

  def test_load_integration_config_handles_unicode
    integrations_dir = File.join(@tmpdir, "core", "integrations")
    FileUtils.mkdir_p(integrations_dir)
    
    config_path = File.join(integrations_dir, "unicode.yaml")
    File.write(config_path, <<~YAML)
      ---
      name: 工具名称
      description: Описание инструмента
      emoji: 🛠️
    YAML

    result = @host.load_integration_config("unicode")
    assert_equal "工具名称", result["name"]
    assert_equal "Описание инструмента", result["description"]
    assert_equal "🛠️", result["emoji"]
  end

  def test_load_integration_config_handles_deep_nesting
    integrations_dir = File.join(@tmpdir, "core", "integrations")
    FileUtils.mkdir_p(integrations_dir)
    
    config_path = File.join(integrations_dir, "nested.yaml")
    File.write(config_path, <<~YAML)
      ---
      level1:
        level2:
          level3:
            level4:
              level5:
                value: deep
    YAML

    result = @host.load_integration_config("nested")
    assert_equal "deep", result.dig("level1", "level2", "level3", "level4", "level5", "value")
  end
end
