# frozen_string_literal: true

require_relative "user_interaction"

module Vibe
  # RTK (Token Optimizer) installation and configuration.
  #
  # Host requirements:
  #   @repo_root [String] — absolute path to the workflow repository root
  #
  # Dependencies:
  #   - Vibe::UserInteraction — for user prompts
  #   - Vibe::ExternalTools — for install_rtk_via_homebrew (from external_tools.rb)
  module RtkInstaller
    include UserInteraction

    # Interactive RTK installation with multiple method choices
    # @param config [Hash] Integration configuration (optional, for backward compatibility)
    def install_rtk_interactive(config = nil)
      config ||= load_integration_config("rtk")
      puts
      puts "   Installation method:"
      puts "   1) Homebrew (macOS/Linux)"
      puts "   2) Manual download (GitHub releases)"
      puts "   3) Cargo"
      puts

      choice = ask_choice("   Choose [1-3]", ["1", "2", "3"])

      case choice
      when "1"
        install_rtk_via_homebrew_interactive
      when "2"
        install_rtk_manual_guide(config)
      when "3"
        install_rtk_via_cargo_interactive
      end
    end

    # Interactive Homebrew installation with user feedback
    def install_rtk_via_homebrew_interactive
      puts
      if system("which", "brew", out: File::NULL, err: File::NULL)
        if install_rtk_via_homebrew
          reset_integration_status!
          puts "   ✓ RTK installed successfully"
          configure_rtk_after_install
        else
          puts "   ✗ Installation failed"
        end
      else
        puts "   ✗ Homebrew not found. Please install Homebrew first or choose another method."
      end
    end

    # Display manual installation instructions
    # @param config [Hash] Integration configuration
    def install_rtk_manual_guide(config)
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

    # Interactive Cargo installation with user feedback
    def install_rtk_via_cargo_interactive
      puts
      if system("which", "cargo", out: File::NULL, err: File::NULL)
        puts "   Installing RTK via Cargo..."
        rtk_config = read_yaml_abs(File.join(@repo_root, "core/integrations/rtk.yaml"))
        cargo_url = rtk_config.dig("installation_methods", "cargo", "command")&.split&.last || "https://github.com/rtk-ai/rtk"

        if system("cargo", "install", "--git", cargo_url)
          reset_integration_status!
          puts "   ✓ RTK installed successfully"
          configure_rtk_after_install
        else
          puts "   ✗ Installation failed"
        end
      else
        puts "   ✗ Cargo not found. Please install Rust toolchain first or choose another method."
      end
    end

    # Configure RTK after successful installation
    def configure_rtk_after_install
      puts
      if ask_yes_no("   Configure RTK hook in ~/.claude/settings.json?")
        if configure_rtk_hook
          reset_integration_status!
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
end
