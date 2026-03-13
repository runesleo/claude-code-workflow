require_relative "test_helper"
require "yaml"

class TestRecommendations < Minitest::Test
  def setup
    @repo_root = File.expand_path("..", __dir__)
    @recommended_yaml = File.join(@repo_root, "core", "integrations", "recommended.yaml")
  end

  def test_recommended_yaml_exists
    assert File.exist?(@recommended_yaml), "recommended.yaml should exist"
  end

  def test_recommended_yaml_is_valid
    config = YAML.safe_load(File.read(@recommended_yaml), aliases: true)

    assert config["schema_version"], "Should have schema_version"
    assert config["categories"], "Should have categories"
    assert config["category_order"], "Should have category_order"
    assert config["category_metadata"], "Should have category_metadata"
  end

  def test_all_recommended_integrations_have_specs
    config = YAML.safe_load(File.read(@recommended_yaml), aliases: true)
    categories = config["categories"] || {}

    categories.each do |category_name, integrations|
      integrations.each do |integration|
        name = integration["name"]
        spec_path = File.join(@repo_root, "core", "integrations", "#{name}.yaml")

        assert File.exist?(spec_path),
               "Integration '#{name}' in category '#{category_name}' should have a spec file at #{spec_path}"
      end
    end
  end

  def test_category_order_matches_categories
    config = YAML.safe_load(File.read(@recommended_yaml), aliases: true)
    categories = config["categories"] || {}
    category_order = config["category_order"] || []

    category_order.each do |category|
      assert categories.key?(category),
             "Category '#{category}' in category_order should exist in categories"
    end
  end

  def test_category_metadata_matches_categories
    config = YAML.safe_load(File.read(@recommended_yaml), aliases: true)
    categories = config["categories"] || {}
    category_metadata = config["category_metadata"] || {}

    categories.keys.each do |category|
      assert category_metadata.key?(category),
             "Category '#{category}' should have metadata"

      metadata = category_metadata[category]
      assert metadata["label"], "Category '#{category}' should have a label"
      assert metadata["description"], "Category '#{category}' should have a description"
      assert metadata["icon"], "Category '#{category}' should have an icon"
    end
  end

  def test_integration_priorities_are_valid
    config = YAML.safe_load(File.read(@recommended_yaml), aliases: true)
    categories = config["categories"] || {}
    valid_priorities = ["P1", "P2", "P3"]

    categories.each do |category_name, integrations|
      integrations.each do |integration|
        priority = integration["priority"]
        assert valid_priorities.include?(priority),
               "Integration '#{integration['name']}' has invalid priority '#{priority}'"
      end
    end
  end
end
