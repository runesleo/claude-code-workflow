# frozen_string_literal: true

require_relative "platform_utils"
require_relative "user_interaction"

module Vibe
  # Integration recommendations and suggestions.
  #
  # Host requirements:
  #   @repo_root [String] — absolute path to the workflow repository root
  #
  # Dependencies:
  #   - Vibe::PlatformUtils — for platform-related utilities
  #   - Vibe::UserInteraction — for user prompts
  module IntegrationRecommendations
    include PlatformUtils
    include UserInteraction

    # Suggest integrations that are recommended but not installed
    def suggest_integrations
      puts "Checking recommended integrations..."
      puts

      recommended = load_recommended_integrations
      unless recommended
        puts "⚠ Could not load recommendations configuration"
        return
      end

      suggested_by_category = {}
      category_order = recommended["category_order"] || recommended["categories"].keys

      category_order.each do |category|
        integrations = recommended.dig("categories", category) || []
        next if integrations.empty?

        integrations.each do |integration|
          name = integration["name"]
          info = send("verify_#{name}")
          next if info[:ready]  # Skip already installed

          suggested_by_category[category] ||= []
          suggested_by_category[category] << integration.merge("status" => info)
        end
      end

      if suggested_by_category.empty?
        puts "✓ All recommended integrations are already installed."
        puts
        return
      end

      puts "The following integrations are recommended but not yet installed:"
      puts

      category_order.each do |category|
        suggestions = suggested_by_category[category]
        next unless suggestions

        metadata = recommended.dig("category_metadata", category) || {}
        icon = metadata["icon"] || "•"
        label = metadata["label"] || category.to_s.split("_").map(&:capitalize).join(" ")
        description = metadata["description"]

        puts "#{icon} #{label}"
        puts "   #{description}" if description
        puts

        suggestions.each do |integration|
          display_integration_suggestion(integration)
        end
      end

      puts
      puts "To install these integrations interactively, run: bin/vibe init --setup"
      puts
    end

    # Install recommended integrations
    # @param auto_yes [Boolean] Auto-answer yes to all prompts
    def install_recommended(auto_yes: false)
      puts "Installing recommended integrations..."
      puts

      recommended = load_recommended_integrations
      unless recommended
        puts "⚠ Could not load recommendations configuration"
        return
      end

      # Collect integrations to install
      to_install = []
      category_order = recommended["category_order"] || recommended["categories"].keys

      category_order.each do |category|
        integrations = recommended.dig("categories", category) || []
        next if integrations.empty?

        integrations.each do |integration|
          name = integration["name"]
          info = send("verify_#{name}")
          next if info[:ready]  # Skip already installed

          to_install << integration
        end
      end

      if to_install.empty?
        puts "✓ All recommended integrations are already installed."
        puts
        return
      end

      puts "Found #{to_install.size} integration(s) to install:"
      to_install.each do |integration|
        puts "  • #{integration['name']}"
      end
      puts

      unless auto_yes
        return unless ask_yes_no("Proceed with installation?")
      end

      puts

      # Install each integration
      to_install.each do |integration|
        name = integration["name"]
        config = load_integration_config(name)

        unless config
          puts "⚠ Configuration not found for #{name}, skipping..."
          next
        end

        puts "Installing #{integration_label(name)}..."
        install_integration(name, config)
        puts
      end

      puts "✓ Installation complete!"
      puts
      puts "Run 'bin/vibe doctor' to verify everything is working correctly."
      puts
    end

    # Load recommended integrations from YAML
    # @return [Hash, nil] Recommended integrations configuration
    def load_recommended_integrations
      yaml_path = File.join(@repo_root, "core", "integrations", "recommended.yaml")
      return nil unless File.exist?(yaml_path)

      YAML.safe_load(File.read(yaml_path), aliases: true)
    rescue StandardError => e
      warn "Warning: Failed to load recommended integrations: #{e.message}"
      nil
    end

    # Display integration suggestion
    # @param integration [Hash] Integration configuration
    def display_integration_suggestion(integration)
      name = integration["name"]
      priority = integration["priority"] || "P2"
      reason = integration["reason"] || "No description available"
      benefits = integration["benefits_summary"]

      config = load_integration_config(name)

      priority_label = case priority
                       when "P1" then "Essential"
                       when "P2" then "Recommended"
                       when "P3" then "Optional"
                       else priority
                       end

      puts "   • #{name} [#{priority_label}]"
      puts "     #{reason}"
      puts "     Benefits: #{benefits}" if benefits

      if config
        method = detect_best_installation_method(name, config)
        puts "     Install: #{method}" if method
      end

      puts
    end

    # Detect best installation method for an integration
    # @param name [String] Integration name
    # @param config [Hash] Integration configuration
    # @return [String, nil] Best installation method description
    def detect_best_installation_method(name, config)
      methods = config["installation_methods"] || {}

      case name
      when "superpowers"
        if methods["claude-code"]
          "Claude Code plugin (recommended)"
        elsif methods["manual"]
          "Manual installation"
        end
      when "rtk"
        if system("which", "brew", out: File::NULL, err: File::NULL)
          "Homebrew: brew install rtk"
        elsif methods["manual"]
          "Manual download from GitHub releases"
        end
      else
        methods.keys.first&.capitalize
      end
    end

    # Get list of recommended integrations
    # @return [Array<Hash>] List of integration configs
    def get_recommended_integration_list
      recommended = load_recommended_integrations
      return [] unless recommended

      integrations = []
      category_order = recommended["category_order"] || recommended["categories"].keys

      category_order.each do |category|
        category_integrations = recommended.dig("categories", category) || []
        integrations.concat(category_integrations)
      end

      integrations
    end

    # Get human-readable label for integration
    # @param name [String] Integration name
    # @return [String] Human-readable label
    def integration_label(name)
      case name
      when "superpowers" then "Superpowers Skill Pack"
      when "rtk" then "RTK (Token Optimizer)"
      else name.to_s.split("_").map(&:capitalize).join(" ")
      end
    end
  end
end
