#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/quiet-harness-inventory.XXXXXX")"

cleanup() {
  case "$tmp_root" in
    "${TMPDIR:-/tmp}"/quiet-harness-inventory.*) rm -rf -- "$tmp_root" ;;
    *) echo "REFUSE_CLEANUP unexpected temp path: $tmp_root" >&2 ;;
  esac
}
trap cleanup EXIT INT TERM

claude_root="$tmp_root/.claude"
codex_root="$tmp_root/.codex"
cursor_root="$tmp_root/.cursor"
nested_root="$tmp_root/.claude-nested"
external_root="$tmp_root/external"
mkdir -p "$claude_root" "$codex_root" "$cursor_root/rules" \
  "$nested_root/rules/team" "$nested_root/commands/team" \
  "$external_root/rules" "$external_root/commands" "$external_root/skills"

ln -s "$external_root/rules" "$claude_root/rules"
ln -s "$external_root/commands" "$claude_root/commands"
ln -s "$external_root/skills" "$claude_root/skills"
touch "$claude_root/settings.json"
touch "$codex_root/AGENTS.override.md"
touch "$cursor_root/rules/lean.mdc"
touch "$nested_root/rules/team/legacy.md"
touch "$nested_root/commands/team/legacy.md"
touch "$claude_root/unrelated.txt"

inventory="$("$repo_root/scripts/inventory.sh" "$claude_root" "$codex_root" "$cursor_root" "$nested_root")"

for expected in \
  "$claude_root/rules" \
  "$claude_root/commands" \
  "$claude_root/skills" \
  "$claude_root/settings.json" \
  "$codex_root/AGENTS.override.md" \
  "$cursor_root/rules/lean.mdc" \
  "$nested_root/rules/team/legacy.md" \
  "$nested_root/commands/team/legacy.md"; do
  echo "$inventory" | grep -Fqx "$expected"
done

if echo "$inventory" | grep -Fq "$claude_root/unrelated.txt"; then
  echo "INVENTORY_FAIL unrelated file was listed" >&2
  exit 1
fi

echo "INVENTORY_SMOKE_OK"
