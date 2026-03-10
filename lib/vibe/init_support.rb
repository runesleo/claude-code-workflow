# frozen_string_literal: true

require "json"
require "yaml"
require_relative "errors"

module Vibe
  # Initialization and setup support for global platform configuration.
  #
  # Host requirements:
  #   @repo_root [String] — absolute path to the workflow repository root
  #
  # Cross-module dependencies:
  #   - Vibe::ValidationError (from errors.rb) — raised on validation failures
  #   - JSON, YAML (stdlib) — for parsing configuration files
  module InitSupport
    # Main initialization flow - installs global configuration
    def run_init(platform:, force: false, verify_only: false, suggest_only: false)
      @target_platform = platform
      platform_name = platform_label(platform)

      puts "\n🚀 #{platform_name} Global Configuration Setup"
      puts "=" * 50
      puts

      if verify_only
        verify_platform_installation(platform)
        return
      end

      if suggest_only
        suggest_platform_setup(platform)
        return
      end

      # Install global configuration
      install_global_config(platform: platform, force: force)
    end

    def install_global_config(platform:, force:)
      target = normalize_target(platform)
      destination_root = default_global_destination(target)

      is_update = Dir.exist?(destination_root)

      puts "Target platform: #{platform_label(platform)}"
      puts "Install location: #{destination_root}"
      puts

      if is_update && !force
        puts "⚠️  Configuration already exists at #{destination_root}"
        print "Overwrite? [y/N] "
        response = $stdin.gets
        if response.nil? || !["y", "yes"].include?(response.chomp.downcase)
          puts "\nInstallation cancelled."
          return
        end
      end

      puts "Installing global configuration..."
      puts

      profile_name, profile = resolve_profile(target, nil)
      output_root = resolve_output_root_for_use(
        target: target,
        destination_root: destination_root,
        explicit_output: nil
      )
      overlay = resolve_overlay(explicit_path: nil, search_roots: [destination_root, @repo_root])

      manifest = build_target(
        target: target,
        profile_name: profile_name,
        profile: profile,
        output_root: output_root,
        overlay: overlay,
        project_level: false  # Global mode
      )

      FileUtils.mkdir_p(destination_root)
      copy_tree_contents(output_root, destination_root)

      write_marker(
        File.join(destination_root, ".vibe-target.json"),
        destination_root: destination_root,
        manifest: manifest,
        output_root: output_root,
        mode: "init"
      )

      puts "✅ Success! #{platform_label(platform)} global configuration has been #{is_update ? 'updated' : 'installed'}."
      puts
      puts "Configuration location: #{destination_root}"
      puts

      # Check and suggest optional integrations
      check_and_suggest_integrations(platform)

      puts "Next steps:"
      puts "1. Review and customize #{File.join(destination_root, config_entrypoint(target))}"
      puts "2. In your project directory, run: vibe switch --platform #{platform}"
      puts
    end

    def default_global_destination(target)
      case target
      when "claude-code"
        File.expand_path("~/.claude")
      when "opencode"
        File.expand_path("~/.opencode")
      when "kimi-code"
        File.expand_path("~/.kimi")
      when "cursor"
        File.expand_path("~/.cursor")
      when "codex-cli"
        File.expand_path("~/.codex")
      else
        File.expand_path("~/.#{target}")
      end
    end

    def config_entrypoint(target)
      case target
      when "claude-code"
        "CLAUDE.md"
      when "opencode"
        "opencode.json"
      when "kimi-code"
        "KIMI.md"
      else
        "config.md"
      end
    end

    def verify_platform_installation(platform)
      target = normalize_target(platform)
      destination = default_global_destination(target)

      if Dir.exist?(destination)
        puts "✅ #{platform_label(platform)} configuration found at #{destination}"

        marker = File.join(destination, ".vibe-target.json")
        if File.exist?(marker)
          data = JSON.parse(File.read(marker))
          puts "   Profile: #{data['profile']}"
          puts "   Mode: #{data['mode']}"
        end
      else
        puts "❌ #{platform_label(platform)} configuration not found"
        puts "   Expected location: #{destination}"
        puts "   Run: vibe init --platform #{platform}"
      end
    end

    def suggest_platform_setup(platform)
      target = normalize_target(platform)
      destination = default_global_destination(target)

      puts "Suggested setup for #{platform_label(platform)}:"
      puts
      puts "1. Install global configuration:"
      puts "   vibe init --platform #{platform}"
      puts
      puts "2. Configuration will be installed to:"
      puts "   #{destination}"
      puts
      puts "3. Then in your project directory:"
      puts "   vibe switch --platform #{platform}"
      puts
    end

    # Check and suggest optional integrations after installation
    def check_and_suggest_integrations(platform)
      @target_platform = platform
      status = integration_status

      missing = []
      pending = []

      status.each do |name, info|
        if !info[:installed]
          missing << name
        elsif !info[:ready]
          pending << name
        end
      end

      return if missing.empty? && pending.empty?

      puts
      puts "📦 Optional Integrations"
      puts "=" * 50

      if missing.include?(:superpowers)
        puts
        puts "⚠️  Superpowers Skill Pack not detected"
        puts "   Superpowers provides advanced workflows like TDD, debugging, and code review."
        puts
        puts "   To install:"
        puts "   1. Visit: https://github.com/anthropics/superpowers"
        puts "   2. Follow installation instructions for #{platform_label(platform)}"
        puts

        if ask_yes_no("Would you like to open the installation page now?")
          open_url("https://github.com/anthropics/superpowers")
        end
      end

      if missing.include?(:rtk)
        puts
        puts "⚠️  RTK Token Optimizer not detected"
        puts "   RTK reduces token consumption by 60-90% on common commands."
        puts
        puts "   To install:"
        puts "   brew install rtk  # or download from https://github.com/runesleo/rtk"
        puts

        if ask_yes_no("Would you like to install RTK now? (requires Homebrew)")
          if install_rtk
            # Refresh status after installation
            status = integration_status
            pending << :rtk if status[:rtk][:installed] && !status[:rtk][:ready]
          end
        end
      end

      if pending.include?(:rtk)
        rtk_status = status[:rtk] || integration_status[:rtk]
        if rtk_status[:installed] && !rtk_status[:hook_configured]
          puts
          puts "⚠️  RTK is installed but hook not configured"
          puts "   To enable RTK optimization, run: rtk init --global"
          puts

          if ask_yes_no("Would you like to configure RTK hook now?")
            configure_rtk_hook
          end
        end
      end

      puts
    end

    # Install RTK via Homebrew
    def install_rtk
      puts
      puts "Installing RTK..."
      if system("brew", "install", "rtk")
        puts "✅ RTK installed successfully"
        return true
      else
        puts "❌ Failed to install RTK. Please install manually:"
        puts "   brew install rtk"
        puts "   or visit: https://github.com/runesleo/rtk"
        return false
      end
    end

    # Open URL in default browser (cross-platform)
    def open_url(url)
      case RbConfig::CONFIG["host_os"]
      when /darwin/
        system("open", url)
      when /linux/
        system("xdg-open", url)
      when /mswin|mingw|cygwin/
        system("start", url)
      else
        puts "Please visit: #{url}"
      end
    end

    # Ask yes/no question with default to no
    def ask_yes_no(question)
      print "#{question} [y/N] "
      response = $stdin.gets
      return false if response.nil?
      ["y", "yes"].include?(response.chomp.downcase)
    end

    def normalize_target(platform)
      # Map platform names to internal target names
      case platform.to_s.downcase
      when "claude-code", "claude"
        "claude-code"
      when "opencode"
        "opencode"
      when "kimi-code", "kimi"
        "kimi-code"
      when "cursor"
        "cursor"
      when "codex-cli", "codex"
        "codex-cli"
      when "vscode", "vs-code"
        "vscode"
      when "warp"
        "warp"
      when "antigravity"
        "antigravity"
      else
        platform.to_s.downcase
      end
    end

    def run_quickstart(options = {})
      puts "\n⚡ Quickstart: Claude Code Setup"
      puts "=" * 50
      puts

      claude_home = File.expand_path("~/.claude")
      is_update = Dir.exist?(claude_home)

      if is_update
        puts "Claude Code configuration already exists at #{claude_home}."
        unless options[:force] || ask_yes_no("Would you like to overwrite it with the latest Vibe template?")
          puts "\nQuickstart cancelled. No changes made."
          return
        end
      else
        puts "Setting up Claude Code workflow in #{claude_home}..."
      end

      # Execute the use command logic
      # We need to call back into VibeCLI or duplicate the logic.
      # Since we're in a module included in VibeCLI, we can use run_use if we handle argv.

      # Alternatively, we can use the internal methods:
      begin
        target = "claude-code"
        profile_name, profile = resolve_profile(target, nil)
        destination_root = claude_home
        output_root = resolve_output_root_for_use(
          target: target,
          destination_root: destination_root,
          explicit_output: nil
        )
        overlay = resolve_overlay(explicit_path: nil, search_roots: [destination_root, @repo_root])

        manifest = build_target(
          target: target,
          profile_name: profile_name,
          profile: profile,
          output_root: output_root,
          overlay: overlay
        )

        FileUtils.mkdir_p(destination_root)
        copy_tree_contents(output_root, destination_root)

        write_marker(
          File.join(destination_root, ".vibe-target.json"),
          destination_root: destination_root,
          manifest: manifest,
          output_root: output_root,
          mode: "quickstart"
        )

        puts "\n✅ Success! Claude Code workflow has been #{is_update ? 'updated' : 'installed'}."
        puts

        # Check and suggest optional integrations
        check_and_suggest_integrations("claude-code")

        puts "Next steps:"
        puts "1. Open #{File.join(claude_home, 'CLAUDE.md')} and customize these sections:"
        puts "   - User Info (name, project routes)"
        puts "   - Sub-project Memory Routes (map your projects to memory files)"
        puts "2. (Optional) Run `bin/vibe init` to install Superpowers or RTK."
        puts "3. Start a new session: claude"
        puts
      rescue StandardError => e
        puts "\n❌ Quickstart failed: #{e.message}"
        raise e
      end
    end

    private

    def check_environment
      puts "Checking your environment..."
      puts

      # Show target platform
      puts "✓ Target platform: #{platform_label(@target_platform)}"

      # Check Claude Code
      claude_dir = File.expand_path("~/.claude")
      if Dir.exist?(claude_dir)
        puts "✓ Claude Code detected at ~/.claude"
      else
        puts "⚠ Claude Code directory not found at ~/.claude"
        puts "  This workflow is designed for Claude Code."
        puts
      end

      # Detect current target (if in a repo with .vibe-target.json)
      if File.exist?(".vibe-target.json")
        target_info = JSON.parse(File.read(".vibe-target.json"))
        puts "✓ Current target: #{target_info['target']}"
      end

      puts
    end

    def setup_integrations
      puts "Checking external integrations..."
      puts
      ensure_interactive_setup_available!

      # Load integrations from recommended.yaml
      integrations = get_recommended_integration_list
      if integrations.empty?
        # Fallback to hardcoded list if config not available
        integrations = [
          { name: "superpowers", label: "Superpowers Skill Pack", priority: "P1" },
          { name: "rtk", label: "RTK (Token Optimizer)", priority: "P2" }
        ]
      end

      integrations.each_with_index do |integration, index|
        setup_integration(integration[:name], integration[:label], index + 1, integrations.size)
      end

      puts
      puts "Configuration Summary"
      puts "=" * 50
      puts

      display_summary

      puts
      puts "Next steps:"
      if pending_integrations.any?
        puts "1. Complete the installation steps above"
        puts "2. Run: bin/vibe init --verify"
      else
        puts "1. Run: bin/vibe init --verify"
      end
      puts "2. Start using: claude"
      puts
      puts "For more information: docs/integrations.md"
      puts
    end

    def setup_integration(name, label, order, total)
      puts "[#{order}/#{total}] #{label}"

      config = load_integration_config(name)
      unless config
        puts "   ⚠ Configuration not found"
        puts
        return
      end

      info = send("verify_#{name}")
      puts "   Status: #{setup_status_message(name, info)}"

      if info[:ready]
        puts
        return
      end

      if info[:installed]
        puts
        complete_integration_setup(name, info)
        puts
        return
      end

      puts
      display_integration_description(config)
      puts

      if ask_yes_no("   Would you like to install #{label}?")
        install_integration(name, config)
      else
        puts "   Skipped."
      end

      puts
    end

    def setup_status_message(name, info)
      case name
      when "superpowers"
        return "Already installed (#{info[:method]})" if info[:ready]
      when "rtk"
        return "Already installed (binary + hook configured)" if info[:ready]
        return "Installed, hook not configured" if info[:installed]
        return "Hook configured, but RTK binary was not found" if info[:hook_configured]
      end

      "Not installed"
    end

    def complete_integration_setup(name, info)
      case name
      when "rtk"
        puts "   Binary: #{info[:binary]}" if info[:binary]
        puts "   Hook: #{info[:hook_configured] ? 'Configured' : 'Not configured'}"
        return if info[:hook_configured]

        if ask_yes_no("   Configure RTK hook in ~/.claude/settings.json?")
          if configure_rtk_hook
            puts "   ✓ Hook configured successfully"
          else
            puts "   ✗ Hook configuration failed"
            puts "   You can manually run: rtk init --global"
          end
        else
          puts "   Skipped hook configuration."
          puts "   You can manually run: rtk init --global"
        end
      end
    end

    def display_integration_description(config)
      puts "   #{config['description']}"
      puts

      if config["type"] == "skill_pack" && config["skills"]
        puts "   Skills provided:"
        config["skills"].first(3).each do |skill|
          puts "   - #{skill['id']}: #{skill['intent']}"
        end
        if config["skills"].size > 3
          puts "   - ... and #{config['skills'].size - 3} more"
        end
      elsif config["benefits"]
        puts "   Benefits:"
        config["benefits"].first(3).each do |benefit|
          puts "   - #{benefit}"
        end
      end
    end

    def install_integration(name, config)
      case name
      when "superpowers"
        install_superpowers(config)
      when "rtk"
        install_rtk(config)
      else
        puts "   ⚠ Installation not implemented for #{name}"
      end
    end

    def install_superpowers(config)
      puts
      puts "   Installation method:"
      puts "   1) Claude Code plugin (recommended)"
      puts "   2) Manual clone and symlink"
      puts

      choice = ask_choice("   Choose [1-2]", ["1", "2"])

      case choice
      when "1"
        install_superpowers_plugin(config)
      when "2"
        install_superpowers_manual(config)
      end
    end

    def install_superpowers_plugin(config)
      puts
      puts "   ℹ️  Run these commands in your Claude Code session:"
      puts

      commands = config.dig("installation_methods", "claude-code", "commands") || []
      commands.each do |cmd|
        puts "      #{cmd}"
      end

      puts
      puts "   After installation, run: bin/vibe init --verify"
    end

    def install_superpowers_manual(config)
      puts
      puts "   Manual installation steps:"
      puts

      steps = config.dig("installation_methods", "manual", "steps") || []
      steps.each_with_index do |step, i|
        puts "   #{i + 1}. #{step}"
      end

      puts
      puts "   After installation, run: bin/vibe init --verify"
    end

    def install_rtk(config)
      puts
      puts "   Installation method:"
      puts "   1) Homebrew (macOS/Linux)"
      puts "   2) Manual download (GitHub releases)"
      puts "   3) Cargo"
      puts

      choice = ask_choice("   Choose [1-3]", ["1", "2", "3"])

      case choice
      when "1"
        install_rtk_homebrew
      when "2"
        install_rtk_manual(config)
      when "3"
        install_rtk_cargo
      end
    end

    def install_rtk_homebrew
      puts
      if system(["which", "which"], "brew", out: File::NULL, err: File::NULL)
        if install_rtk_via_homebrew
          puts "   ✓ RTK installed successfully"
          configure_rtk_after_install
        else
          puts "   ✗ Installation failed"
        end
      else
        puts "   ✗ Homebrew not found. Please install Homebrew first or choose another method."
      end
    end

    def install_rtk_manual(config)
      puts
      puts "   Manual installation steps:"
      puts

      manual_install = config.dig("installation_methods", "manual") || {}
      manual_url = manual_install["url"] || "https://github.com/rtk-ai/rtk/releases"

      puts "   1. Download the appropriate RTK binary from:"
      puts "      #{manual_url}"
      puts "   2. Place the `rtk` binary somewhere on your PATH."
      puts "   3. Run: rtk init --global"
      puts
      puts "   After installation, run: bin/vibe init --verify"
    end

    def install_rtk_cargo
      puts
      if system(["which", "which"], "cargo", out: File::NULL, err: File::NULL)
        puts "   Installing RTK via Cargo..."
        if system(["cargo", "cargo"], "install", "--git", "https://github.com/rtk-ai/rtk")
          puts "   ✓ RTK installed successfully"
          configure_rtk_after_install
        else
          puts "   ✗ Installation failed"
        end
      else
        puts "   ✗ Cargo not found. Please install Rust toolchain first or choose another method."
      end
    end

    def configure_rtk_after_install
      puts
      if ask_yes_no("   Configure RTK hook in ~/.claude/settings.json?")
        if configure_rtk_hook
          puts "   ✓ Hook configured successfully"
        else
          puts "   ✗ Hook configuration failed"
          puts "   You can manually run: rtk init --global"
        end
      else
        puts "   Skipped hook configuration."
        puts "   You can manually run: rtk init --global"
      end
    end

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

          to_install << {
            name: name,
            priority: integration["priority"],
            reason: integration["reason"],
            category: category,
            info: info
          }
        end
      end

      if to_install.empty?
        puts "✓ All recommended integrations are already installed."
        puts
        return
      end

      # Display what will be installed
      puts "The following integrations will be installed:"
      puts
      to_install.each do |item|
        label = item[:name].capitalize
        puts "  • #{label} (#{item[:priority]})"
        puts "    #{item[:reason]}"
        puts
      end

      # Confirm installation
      unless auto_yes
        puts "This will guide you through the installation process."
        unless $stdin.tty?
          puts
          puts "⚠ Non-interactive terminal detected."
          puts "Use 'bin/vibe init --install -y' to skip confirmation, or run in an interactive terminal."
          return
        end
        return unless ask_yes_no("Continue?")
        puts
      else
        puts "Auto-installing (--yes flag provided)..."
        puts
      end

      # Install each integration
      installed_count = 0
      to_install.each_with_index do |item, index|
        name = item[:name]
        label = name.capitalize

        puts "[#{index + 1}/#{to_install.size}] Installing #{label}..."
        puts

        config = load_integration_config(name)
        unless config
          puts "   ⚠ Configuration not found for #{name}"
          puts
          next
        end

        install_integration(name, config)
        installed_count += 1
        puts
      end

      # Summary
      puts "=" * 50
      puts "Installation Summary"
      puts "=" * 50
      puts
      puts "Attempted: #{to_install.size}"
      puts "Completed: #{installed_count}"
      puts
      puts "Next steps:"
      puts "1. Run: bin/vibe init --verify"
      puts "2. Start using: claude"
      puts
    end

    def verify_integrations
      puts "Verifying integrations..."
      puts

      status = integration_status
      rtk_needs_hook = false

      status.each do |name, info|
        verify_integration_display(name, info)
        rtk_needs_hook = true if name == :rtk && info[:installed] && !info[:hook_configured]
      end

      puts
      if all_integrations_ready?
        puts "All integrations verified successfully! 🎉"
        puts
        puts "Next steps:"
        puts "1. Run: bin/vibe use #{@target_platform} --destination <your-project>"
        puts "2. Or:  bin/vibe switch #{@target_platform} (to apply to current repo)"
        puts "3. Start using: #{platform_command(@target_platform)}"
      elsif rtk_needs_hook
        puts "RTK is installed but hook is not configured."
        puts "Run: rtk init --global"
        puts
        puts "After that, you can:"
        puts "  bin/vibe use #{@target_platform} --destination <your-project>"
      else
        puts "Some integrations still need installation or configuration."
        puts "Run: bin/vibe init --setup (without --verify) to finish setup."
      end
      puts
    end

    def verify_integration_display(name, info)
      label = case name
              when :superpowers then "Superpowers"
              when :rtk then "RTK"
              else name.to_s.capitalize
              end

      if info[:ready]
        puts "[✓] #{label}"
        case name
        when :superpowers
          puts "    Location: #{info[:location]}"
          puts "    Skills detected: #{info[:skills_count]}"
        when :rtk
          puts "    Binary: #{info[:binary]}"
          puts "    Version: #{info[:version]}"
          puts "    Hook: #{info[:hook_configured] ? 'Configured' : 'Not configured'}"
        end
        puts "    Status: Ready"
      elsif name == :rtk && info[:installed]
        puts "[!] #{label}"
        puts "    Binary: #{info[:binary]}"
        puts "    Version: #{info[:version]}"
        puts "    Hook: Not configured"
        puts "    Status: Installed, hook not configured"
      elsif name == :rtk && info[:hook_configured]
        puts "[!] #{label}"
        puts "    Binary: Not found"
        puts "    Hook: Configured"
        puts "    Status: Hook configured, but RTK binary was not found"
      else
        puts "[✗] #{label}"
        puts "    Status: Not installed"
      end
      puts
    end

    def display_summary
      status = integration_status

      status.each do |name, info|
        label = case name
                when :superpowers then "Superpowers"
                when :rtk then "RTK"
                else name.to_s.capitalize
                end

        if info[:ready]
          puts "✓ #{label}: Ready"
        elsif name == :rtk && info[:installed]
          puts "⚠ #{label}: Installed but hook not configured"
        elsif name == :rtk && info[:hook_configured]
          puts "⚠ #{label}: Hook configured but binary not found"
        else
          puts "⚠ #{label}: Installation instructions provided"
        end
      end
    end

    # --- User Input Helpers ---

    def ask_yes_no(prompt, default: true)
      ensure_interactive_setup_available!(prompt)
      suffix = default ? "[Y/n]" : "[y/N]"
      print "#{prompt} #{suffix}: "
      response = read_prompt_response!(prompt).strip.downcase

      return default if response.empty?
      response.start_with?("y")
    end

    def ask_choice(prompt, valid_choices)
      ensure_interactive_setup_available!(prompt)
      loop do
        print "#{prompt}: "
        choice = read_prompt_response!(prompt).strip

        return choice if valid_choices.include?(choice)

        puts "   Invalid choice. Please choose from: #{valid_choices.join(', ')}"
      end
    end

    def ensure_interactive_setup_available!(prompt = nil)
      return if $stdin.respond_to?(:tty?) && $stdin.tty?

      detail = prompt ? " when prompting for '#{prompt}'" : ""
      raise ValidationError,
            "bin/vibe init requires an interactive terminal#{detail}. Re-run `bin/vibe init` in a terminal, use `bin/vibe init --verify` to inspect current state, or follow `docs/integrations.md` for manual installation steps."
    end

    def read_prompt_response!(prompt)
      response = $stdin.gets
      return response unless response.nil?

      raise ValidationError,
            "Input ended before a response was provided for '#{prompt}'. Re-run `bin/vibe init` in an interactive terminal, use `bin/vibe init --verify` to inspect current state, or follow `docs/integrations.md` for manual installation steps."
    end

    # --- Recommendation System ---

    def load_recommended_integrations
      yaml_path = File.join(@repo_root, "core", "integrations", "recommended.yaml")
      return nil unless File.exist?(yaml_path)

      YAML.safe_load(File.read(yaml_path), aliases: true)
    rescue StandardError => e
      warn "Warning: Failed to load recommended integrations: #{e.message}"
      nil
    end

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
        # Show installation method
        installation_method = detect_best_installation_method(name, config)
        if installation_method
          puts "     Installation: #{installation_method}"
        end

        # Show source URL
        if config["source"]
          puts "     Source: #{config['source']}"
        end
      end

      puts
    end

    def detect_best_installation_method(name, config)
      methods = config["installation_methods"] || {}

      # Try to detect the best method based on current environment
      if methods["claude-code"] && Dir.exist?(File.expand_path("~/.claude"))
        commands = methods.dig("claude-code", "commands") || []
        return commands.first if commands.any?
      end

      if methods["manual"]
        steps = methods.dig("manual", "steps") || []
        return steps.first if steps.any?
      end

      nil
    end

    def get_recommended_integration_list
      recommended = load_recommended_integrations
      return [] unless recommended

      integrations = []
      categories = recommended["categories"] || {}

      categories.each_value do |category_integrations|
        category_integrations.each do |integration|
          integrations << {
            name: integration["name"],
            label: integration_label(integration["name"]),
            priority: integration["priority"] || "P2"
          }
        end
      end

      integrations
    end

    def integration_label(name)
      case name
      when "superpowers" then "Superpowers Skill Pack"
      when "rtk" then "RTK (Token Optimizer)"
      else name.to_s.split("_").map(&:capitalize).join(" ")
      end
    end

    private

    def normalize_platform(platform)
      return "claude-code" if platform.nil?

      normalized = platform.to_s.downcase.gsub("_", "-")
      valid_platforms = %w[antigravity claude-code codex-cli cursor kimi-code opencode vscode warp]

      unless valid_platforms.include?(normalized)
        raise ValidationError, "Unsupported platform: #{platform}. Valid options: #{valid_platforms.join(', ')}"
      end

      normalized
    end

    def detect_current_platform
      return "claude-code" if Dir.exist?(File.expand_path("~/.claude"))
      return "cursor" if Dir.exist?(File.expand_path("~/.cursor"))
      return "opencode" if Dir.exist?(File.expand_path("~/.opencode"))
      return "codex-cli" if Dir.exist?(File.expand_path("~/.codex"))
      "claude-code"
    end

    def platform_label(platform)
      case platform
      when "antigravity" then "Antigravity"
      when "claude-code" then "Claude Code"
      when "codex-cli" then "Codex CLI"
      when "cursor" then "Cursor"
      when "kimi-code" then "Kimi Code"
      when "opencode" then "OpenCode"
      when "vscode" then "VS Code"
      when "warp" then "Warp"
      else platform.to_s.split("-").map(&:capitalize).join(" ")
      end
    end

    def platform_command(platform)
      case platform
      when "antigravity" then "antigravity"
      when "claude-code" then "claude"
      when "codex-cli" then "codex"
      when "cursor" then "cursor"
      when "kimi-code" then "kimi"
      when "opencode" then "opencode"
      when "vscode" then "code"
      when "warp" then "warp"
      else platform
      end
    end
  end
end
