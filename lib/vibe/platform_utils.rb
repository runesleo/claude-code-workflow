# frozen_string_literal: true

module Vibe
  # Platform-related utility methods.
  #
  # Host requirements:
  #   None (self-contained utilities)
  module PlatformUtils
    # Focused on Claude Code and OpenCode for stability
    # Other platforms temporarily disabled: antigravity, cursor, kimi-code, vscode, warp
    VALID_TARGETS = %w[claude-code opencode codex-cli].freeze

    TARGET_ALIAS_MAP = {
      "claude" => "claude-code",
      "claude-code" => "claude-code",
      "opencode" => "opencode",
      "codex" => "codex-cli",
      "codex-cli" => "codex-cli"
    }.freeze

    # Normalize platform name to internal target name.
    # Handles aliases, underscores, and validates against known targets.
    # @param platform [String, nil] Platform name (e.g., "claude", "claude_code")
    # @param strict [Boolean] If true, raises on unknown platform; if false, returns input downcased
    # @return [String] Normalized platform name
    # @raise [Vibe::ValidationError] if strict and platform is unknown
    def normalize_target(platform, strict: false)
      normalized = platform.to_s.downcase.gsub("_", "-")
      resolved = TARGET_ALIAS_MAP[normalized]

      if resolved
        resolved
      elsif strict
        raise Vibe::ValidationError, "Unsupported platform: #{platform}. Valid options: #{VALID_TARGETS.join(', ')}"
      else
        normalized
      end
    end

    # Get human-readable platform label
    # @param platform [String] Platform name
    # @return [String] Human-readable label
    def platform_label(platform)
      case normalize_target(platform)
      when "claude-code"
        "Claude Code"
      when "opencode"
        "OpenCode"
      when "kimi-code"
        "Kimi Code"
      when "cursor"
        "Cursor"
      when "codex-cli"
        "Codex CLI"
      when "vscode"
        "VS Code"
      when "warp"
        "Warp"
      when "antigravity"
        "Antigravity"
      else
        platform.to_s.capitalize
      end
    end

    # Get default global destination directory for a target
    # @param target [String] Target name
    # @return [String] Absolute path to global config directory
    def default_global_destination(target)
      case target
      when "claude-code"
        File.expand_path("~/.claude")
      when "opencode"
        # OpenCode uses XDG config directory per official docs
        # https://github.com/opencode-ai/opencode
        File.expand_path("~/.config/opencode")
      when "kimi-code"
        File.expand_path("~/.config/agents")
      when "cursor"
        File.expand_path("~/.cursor")
      when "codex-cli"
        File.expand_path("~/.codex")
      when "warp"
        # Warp terminal uses ~/.warp/ for workflows
        File.expand_path("~/.warp")
      when "vscode"
        File.expand_path("~/.vscode")
      else
        File.expand_path("~/.#{target}")
      end
    end

    # Get config entrypoint filename for a target
    # @param target [String] Target name
    # @return [String] Entrypoint filename
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

    # Get platform-specific command name
    # @param platform [String] Platform name
    # @return [String] Command name
    def platform_command(platform)
      case normalize_target(platform)
      when "claude-code" then "claude"
      when "codex-cli" then "codex"
      when "kimi-code" then "kimi"
      when "vscode" then "code"
      else normalize_target(platform)
      end
    end
  end
end
