# frozen_string_literal: true

module Vibe
  # Target-specific native configuration builders for Claude Code settings.json,
  # Cursor cli.json, and OpenCode opencode.json.
  #
  # Depends on methods from:
  #   Vibe::Utils — deep_merge
  module NativeConfigs
    def base_claude_settings_config
      {
        "permissions" => {
          "defaultMode" => "default",
          "disableBypassPermissionsMode" => "disable",
          "ask" => [
            "Bash(curl:*)",
            "Bash(wget:*)",
            "Bash(scp:*)",
            "Bash(rsync:*)",
            "Bash(git push:*)",
            "Bash(npm publish:*)",
            "Bash(base64:*)",
            "Bash(eval:*)",
            "Bash(exec:*)",
            "WebFetch",
            "Write(./production/**)"
          ],
          "deny" => [
            "Bash(rm -rf:*)",
            "Bash(shred:*)",
            "Read(./.env)",
            "Read(./.env.*)",
            "Read(./secrets/**)",
            "Read(./**/*.key)",
            "Write(./**/.env*)",
            "Write(./**/*.key)"
          ]
        }
      }
    end

    def claude_settings_config(manifest)
      deep_merge(base_claude_settings_config, manifest["native_config_overlay"] || {})
    end

    def base_cursor_cli_permissions_config
      {
        "permissions" => {
          "allow" => [
            "Read(**)",
            "Write(**)",
            "Shell(ls)",
            "Shell(cat)",
            "Shell(grep)",
            "Shell(rg)",
            "Shell(find)",
            "Shell(pwd)"
          ],
          "deny" => [
            "Shell(rm)",
            "Shell(shred)",
            "Read(.env*)",
            "Read(secrets/**)",
            "Read(**/*.key)",
            "Write(**/.env*)",
            "Write(**/*.key)"
          ]
        }
      }
    end

    def cursor_cli_permissions_config(manifest)
      deep_merge(base_cursor_cli_permissions_config, manifest["native_config_overlay"] || {})
    end

    def base_opencode_config
      {
        "$schema" => "https://opencode.ai/config.json",
        "instructions" => [
          ".vibe/opencode/behavior-policies.md",
          ".vibe/opencode/general.md",
          ".vibe/opencode/routing.md",
          ".vibe/opencode/skills.md",
          ".vibe/opencode/safety.md",
          ".vibe/opencode/execution.md"
        ],
        "permission" => {
          "read" => {
            "*" => "allow",
            "**/.env" => "deny",
            "**/.env.*" => "deny",
            "**/secrets/**" => "deny",
            "**/*.key" => "deny"
          },
          "write" => {
            "*" => "ask",
            "**/.env*" => "deny",
            "**/secrets/**" => "deny",
            "**/*.key" => "deny"
          },
          "edit" => {
            "*" => "ask",
            "**/.env*" => "deny",
            "**/secrets/**" => "deny",
            "**/*.key" => "deny"
          },
          "list" => "allow",
          "glob" => "allow",
          "grep" => "allow",
          "todoread" => "allow",
          "todowrite" => "allow",
          "bash" => {
            "*" => "ask",
            "pwd" => "allow",
            "ls*" => "allow",
            "cat *" => "allow",
            "grep *" => "allow",
            "rg *" => "allow",
            "find *" => "allow",
            "git status*" => "allow",
            "git diff*" => "allow",
            "git log*" => "allow",
            "rm *" => "deny",
            "shred *" => "deny",
            "curl *" => "ask",
            "wget *" => "ask",
            "scp *" => "ask",
            "rsync *" => "ask",
            "git push *" => "ask",
            "npm publish *" => "ask"
          },
          "webfetch" => "ask",
          "websearch" => "ask",
          "task" => "ask",
          "skill" => "ask",
          "external_directory" => "deny"
        }
      }
    end

    def opencode_config(manifest)
      deep_merge(base_opencode_config, manifest["native_config_overlay"] || {})
    end

    def opencode_project_config(manifest)
      # Project-level minimal config - references global config
      base = {
        "$schema" => "https://opencode.ai/config.json",
        "instructions" => [
          "AGENTS.md",
          ".vibe/opencode/behavior-policies.md",
          ".vibe/opencode/routing.md",
          ".vibe/opencode/safety.md"
        ],
        "extends" => "~/.opencode/opencode.json"
      }
      deep_merge(base, manifest["native_config_overlay"] || {})
    end

    def base_vscode_settings_config
      {
        "github.copilot.chat.codeGeneration.instructions" => [
          { "file" => "AGENTS.md" },
          { "file" => ".vibe/vscode/behavior-policies.md" },
          { "file" => ".vibe/vscode/routing.md" },
          { "file" => ".vibe/vscode/safety.md" }
        ]
      }
    end

    def vscode_settings_config(manifest)
      deep_merge(base_vscode_settings_config, manifest["native_config_overlay"] || {})
    end

    def vscode_project_settings_config(manifest)
      # Project-level minimal settings - references global config
      base = {
        "github.copilot.chat.codeGeneration.instructions" => [
          { "file" => "AGENTS.md" },
          { "file" => ".vibe/vscode/behavior-policies.md" },
          { "file" => ".vibe/vscode/safety.md" }
        ]
      }
      deep_merge(base, manifest["native_config_overlay"] || {})
    end
  end
end
