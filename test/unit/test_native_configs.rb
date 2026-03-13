# frozen_string_literal: true

require_relative "../test_helper"
require "vibe/utils"
require "vibe/native_configs"

# Test class that includes required modules
class NativeConfigsTester
  include Vibe::Utils
  include Vibe::NativeConfigs
end

class TestNativeConfigs < Minitest::Test
  def setup
    @tester = NativeConfigsTester.new
    @base_manifest = {
      "target" => "claude-code",
      "profile" => "claude-code-default",
      "native_config_overlay" => {}
    }
  end

  # === Claude Code settings.json tests ===

  def test_base_claude_settings_config_structure
    config = @tester.base_claude_settings_config

    assert config.is_a?(Hash), "Config should be a Hash"
    assert config.key?("permissions"), "Config should have permissions key"
    assert config["permissions"].key?("defaultMode"), "Permissions should have defaultMode"
    assert config["permissions"].key?("ask"), "Permissions should have ask list"
    assert config["permissions"].key?("deny"), "Permissions should have deny list"
  end

  def test_base_claude_settings_ask_permissions
    config = @tester.base_claude_settings_config
    ask = config["permissions"]["ask"]

    # Check for dangerous operations that should ask
    assert_includes ask, "Bash(curl:*)"
    assert_includes ask, "Bash(wget:*)"
    assert_includes ask, "Bash(scp:*)"
    assert_includes ask, "Bash(rsync:*)"
    assert_includes ask, "Bash(git push:*)"
    assert_includes ask, "Bash(npm publish:*)"
    assert_includes ask, "Bash(base64:*)"
    assert_includes ask, "Bash(eval:*)"
    assert_includes ask, "Bash(exec:*)"
    assert_includes ask, "WebFetch"
  end

  def test_base_claude_settings_deny_permissions
    config = @tester.base_claude_settings_config
    deny = config["permissions"]["deny"]

    # Check for operations that should be denied
    assert_includes deny, "Bash(rm -rf:*)"
    assert_includes deny, "Bash(shred:*)"
    assert_includes deny, "Read(./.env)"
    assert_includes deny, "Read(./.env.*)"
    assert_includes deny, "Read(./secrets/**)"
    assert_includes deny, "Read(./**/*.key)"
    assert_includes deny, "Write(./**/.env*)"
    assert_includes deny, "Write(./**/*.key)"
  end

  def test_claude_settings_config_with_empty_overlay
    config = @tester.claude_settings_config(@base_manifest)
    base = @tester.base_claude_settings_config

    # Should return base config when overlay is empty
    assert_equal base["permissions"]["ask"], config["permissions"]["ask"]
    assert_equal base["permissions"]["deny"], config["permissions"]["deny"]
  end

  def test_claude_settings_config_with_overlay
    manifest = @base_manifest.dup
    manifest["native_config_overlay"] = {
      "permissions" => {
        "ask" => ["Bash(custom:*)"],
        "allow" => ["Read(./safe/**)"]
      }
    }

    config = @tester.claude_settings_config(manifest)

    # Overlay should be merged
    assert_includes config["permissions"]["ask"], "Bash(custom:*)"
    # Base permissions should still be present (deep_merge behavior)
    assert_includes config["permissions"]["ask"], "Bash(curl:*)"
  end

  def test_claude_settings_config_without_overlay_key
    manifest = @base_manifest.dup
    manifest.delete("native_config_overlay")

    config = @tester.claude_settings_config(manifest)
    base = @tester.base_claude_settings_config

    # Should handle missing overlay gracefully
    assert_equal base["permissions"]["deny"], config["permissions"]["deny"]
  end

  # === OpenCode opencode.json tests ===

  def test_base_opencode_config_structure
    config = @tester.base_opencode_config

    assert config.is_a?(Hash), "Config should be a Hash"
    assert_equal "https://opencode.ai/config.json", config["$schema"]
    assert config.key?("instructions"), "Config should have instructions"
    assert config.key?("permission"), "Config should have permission"
  end

  def test_base_opencode_instructions
    config = @tester.base_opencode_config
    instructions = config["instructions"]

    assert_includes instructions, ".vibe/opencode/behavior-policies.md"
    assert_includes instructions, ".vibe/opencode/general.md"
    assert_includes instructions, ".vibe/opencode/routing.md"
    assert_includes instructions, ".vibe/opencode/skills.md"
    assert_includes instructions, ".vibe/opencode/safety.md"
    assert_includes instructions, ".vibe/opencode/execution.md"
  end

  def test_base_opencode_permission_structure
    config = @tester.base_opencode_config
    perm = config["permission"]

    assert perm.key?("read"), "Should have read permissions"
    assert perm.key?("write"), "Should have write permissions"
    assert perm.key?("edit"), "Should have edit permissions"
    assert perm.key?("bash"), "Should have bash permissions"
    assert perm.key?("list"), "Should have list permission"
    assert perm.key?("glob"), "Should have glob permission"
    assert perm.key?("grep"), "Should have grep permission"
  end

  def test_opencode_read_permissions
    perm = @tester.base_opencode_config["permission"]["read"]

    assert_equal "allow", perm["*"]
    assert_equal "deny", perm["**/.env"]
    assert_equal "deny", perm["**/.env.*"]
    assert_equal "deny", perm["**/secrets/**"]
    assert_equal "deny", perm["**/*.key"]
  end

  def test_opencode_write_permissions
    perm = @tester.base_opencode_config["permission"]["write"]

    assert_equal "ask", perm["*"]
    assert_equal "deny", perm["**/.env*"]
    assert_equal "deny", perm["**/secrets/**"]
    assert_equal "deny", perm["**/*.key"]
  end

  def test_opencode_bash_permissions
    perm = @tester.base_opencode_config["permission"]["bash"]

    # Allow list
    assert_equal "allow", perm["pwd"]
    assert_equal "allow", perm["ls*"]
    assert_equal "allow", perm["cat *"]
    assert_equal "allow", perm["grep *"]
    assert_equal "allow", perm["rg *"]
    assert_equal "allow", perm["find *"]
    assert_equal "allow", perm["git status*"]
    assert_equal "allow", perm["git diff*"]
    assert_equal "allow", perm["git log*"]

    # Deny list
    assert_equal "deny", perm["rm *"]
    assert_equal "deny", perm["shred *"]

    # Ask list
    assert_equal "ask", perm["curl *"]
    assert_equal "ask", perm["wget *"]
    assert_equal "ask", perm["scp *"]
    assert_equal "ask", perm["rsync *"]
    assert_equal "ask", perm["git push *"]
    assert_equal "ask", perm["npm publish *"]

    # Default
    assert_equal "ask", perm["*"]
  end

  def test_opencode_config_with_empty_overlay
    config = @tester.opencode_config(@base_manifest)
    base = @tester.base_opencode_config

    assert_equal base["instructions"], config["instructions"]
    assert_equal base["permission"]["read"], config["permission"]["read"]
  end

  def test_opencode_config_with_overlay
    manifest = @base_manifest.dup
    manifest["native_config_overlay"] = {
      "permission" => {
        "bash" => {
          "custom *" => "allow"
        }
      }
    }

    config = @tester.opencode_config(manifest)

    # Overlay should be merged
    assert_equal "allow", config["permission"]["bash"]["custom *"]
    # Base permissions should still be present
    assert_equal "deny", config["permission"]["bash"]["rm *"]
  end

  def test_opencode_project_config_structure
    manifest = @base_manifest.dup
    manifest["target"] = "opencode"
    config = @tester.opencode_project_config(manifest)

    assert_equal "https://opencode.ai/config.json", config["$schema"]
    assert config["instructions"].include?("AGENTS.md")
    assert config["instructions"].include?(".vibe/opencode/behavior-policies.md")
    assert_equal "~/.opencode/opencode.json", config["extends"]
  end

  def test_opencode_project_has_fewer_instructions
    project_config = @tester.opencode_project_config(@base_manifest)
    full_config = @tester.base_opencode_config

    # Project config should have fewer instructions than full config
    assert project_config["instructions"].length < full_config["instructions"].length
  end

  # === Cursor config tests (for completeness) ===

  def test_base_cursor_cli_permissions_structure
    config = @tester.base_cursor_cli_permissions_config

    assert config.is_a?(Hash)
    assert config.key?("permissions")
    assert config["permissions"].key?("allow")
    assert config["permissions"].key?("deny")
  end

  def test_cursor_permissions_allow_list
    config = @tester.base_cursor_cli_permissions_config
    allow = config["permissions"]["allow"]

    assert_includes allow, "Read(**)"
    assert_includes allow, "Write(**)"
    assert_includes allow, "Shell(ls)"
    assert_includes allow, "Shell(cat)"
    assert_includes allow, "Shell(grep)"
  end

  def test_cursor_permissions_deny_list
    config = @tester.base_cursor_cli_permissions_config
    deny = config["permissions"]["deny"]

    assert_includes deny, "Shell(rm)"
    assert_includes deny, "Shell(shred)"
    assert_includes deny, "Read(.env*)"
    assert_includes deny, "Read(secrets/**)"
    assert_includes deny, "Read(**/*.key)"
  end

  # === VSCode config tests (for completeness) ===

  def test_base_vscode_settings_config_structure
    config = @tester.base_vscode_settings_config

    assert config.is_a?(Hash)
    assert config.key?("github.copilot.chat.codeGeneration.instructions")
  end

  def test_vscode_settings_has_instructions
    config = @tester.base_vscode_settings_config
    instructions = config["github.copilot.chat.codeGeneration.instructions"]

    assert instructions.is_a?(Array)
    assert instructions.any? { |i| i["file"] == "AGENTS.md" }
    assert instructions.any? { |i| i["file"] == ".vibe/vscode/behavior-policies.md" }
  end

  def test_vscode_project_settings_has_fewer_instructions
    project_config = @tester.vscode_project_settings_config(@base_manifest)
    full_config = @tester.base_vscode_settings_config

    project_instructions = project_config["github.copilot.chat.codeGeneration.instructions"]
    full_instructions = full_config["github.copilot.chat.codeGeneration.instructions"]

    assert project_instructions.length < full_instructions.length
  end

  # === deep_merge integration tests ===

  def test_deep_merge_preserves_base_structure
    manifest = @base_manifest.dup
    manifest["native_config_overlay"] = {
      "new_key" => "new_value"
    }

    claude_config = @tester.claude_settings_config(manifest)
    opencode_config = @tester.opencode_config(manifest)

    # Both should preserve their base structures
    assert claude_config["permissions"]["ask"].is_a?(Array)
    assert opencode_config["permission"]["read"].is_a?(Hash)

    # And include the overlay
    assert_equal "new_value", claude_config["new_key"]
    assert_equal "new_value", opencode_config["new_key"]
  end

  def test_deep_merge_with_nested_overlay
    manifest = @base_manifest.dup
    manifest["native_config_overlay"] = {
      "permissions" => {
        "ask" => ["CustomAsk"],
        "new_permission_category" => ["Item"]
      }
    }

    config = @tester.claude_settings_config(manifest)

    # Nested arrays should be merged
    assert_includes config["permissions"]["ask"], "CustomAsk"
    assert_includes config["permissions"]["ask"], "Bash(curl:*)" # From base
    assert_includes config["permissions"]["new_permission_category"], "Item"
  end
end
