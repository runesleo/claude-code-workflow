#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/quiet-harness.XXXXXX")"

cleanup() {
  case "$tmp_root" in
    "${TMPDIR:-/tmp}"/quiet-harness.*) rm -rf -- "$tmp_root" ;;
    *) echo "REFUSE_CLEANUP unexpected temp path: $tmp_root" >&2 ;;
  esac
}
trap cleanup EXIT INT TERM

test_home="$tmp_root/home"
codex_home="$tmp_root/custom-codex"
cursor_project="$tmp_root/project"
mkdir -p "$test_home" "$cursor_project"

dry_output="$(HOME="$test_home" CODEX_HOME="$codex_home" "$repo_root/scripts/install.sh" \
  --dry-run --claude --codex --cursor-project "$cursor_project")"
echo "$dry_output" | grep -q 'DRY_RUN_COMPLETE'
test ! -e "$test_home/AGENTS.md"
test ! -e "$test_home/.claude/CLAUDE.md"
test ! -e "$codex_home/AGENTS.md"
test ! -e "$test_home/.codex/AGENTS.md"
test ! -e "$cursor_project/.cursor/rules/quiet-harness.mdc"

HOME="$test_home" CODEX_HOME="$codex_home" "$repo_root/scripts/install.sh" \
  --apply --claude --codex --cursor-project "$cursor_project" >/dev/null

cmp "$repo_root/templates/shared/AGENTS.md" "$test_home/AGENTS.md"
cmp "$repo_root/templates/claude/CLAUDE.md" "$test_home/.claude/CLAUDE.md"
cmp "$repo_root/templates/shared/AGENTS.md" "$codex_home/AGENTS.md"
cmp "$repo_root/templates/cursor/quiet-harness.mdc" "$cursor_project/.cursor/rules/quiet-harness.mdc"

backup_plan="$(HOME="$test_home" CODEX_HOME="$codex_home" "$repo_root/scripts/install.sh" \
  --dry-run --claude --codex --cursor-project "$cursor_project")"
echo "$backup_plan" | grep -q 'BACKUP_PLAN'

printf 'old claude config\n' > "$test_home/.claude/CLAUDE.md"
printf 'old cursor rule\n' > "$cursor_project/.cursor/rules/quiet-harness.mdc"
HOME="$test_home" CODEX_HOME="$codex_home" "$repo_root/scripts/install.sh" \
  --apply --claude --cursor-project "$cursor_project" >/dev/null

claude_backup="$(find "$test_home/.claude" -maxdepth 1 -name 'CLAUDE.md.bak-ai-workflow-*' -type f | head -n 1)"
cursor_backup="$(find "$cursor_project/.cursor/rules" -maxdepth 1 -name 'quiet-harness.mdc.bak-ai-workflow-*' -type f | head -n 1)"
test -n "$claude_backup"
test -n "$cursor_backup"
grep -q '^old claude config$' "$claude_backup"
grep -q '^old cursor rule$' "$cursor_backup"
cmp "$repo_root/templates/claude/CLAUDE.md" "$test_home/.claude/CLAUDE.md"
cmp "$repo_root/templates/cursor/quiet-harness.mdc" "$cursor_project/.cursor/rules/quiet-harness.mdc"

# A target symlink must be backed up as a symlink and replaced, never followed.
symlink_home="$tmp_root/symlink-home"
victim_file="$symlink_home/victim.txt"
mkdir -p "$symlink_home/.claude"
printf 'do not overwrite me\n' > "$victim_file"
ln -s "$victim_file" "$symlink_home/.claude/CLAUDE.md"

HOME="$symlink_home" "$repo_root/scripts/install.sh" --apply --claude >/dev/null
test ! -L "$symlink_home/.claude/CLAUDE.md"
cmp "$repo_root/templates/claude/CLAUDE.md" "$symlink_home/.claude/CLAUDE.md"
grep -q '^do not overwrite me$' "$victim_file"

symlink_backup="$(find "$symlink_home/.claude" -maxdepth 1 -name 'CLAUDE.md.bak-ai-workflow-*' -type l | head -n 1)"
test -n "$symlink_backup"
test "$(readlink "$symlink_backup")" = "$victim_file"

# The documented rollback restores the original link exactly.
rm -f "$symlink_home/.claude/CLAUDE.md"
mv "$symlink_backup" "$symlink_home/.claude/CLAUDE.md"
test -L "$symlink_home/.claude/CLAUDE.md"
test "$(readlink "$symlink_home/.claude/CLAUDE.md")" = "$victim_file"

# A file target that points to a directory must fail before touching any target.
symlink_dir_home="$tmp_root/symlink-dir-home"
external_dir="$tmp_root/external-dir"
mkdir -p "$symlink_dir_home/.claude" "$external_dir"
printf 'original shared\n' > "$symlink_dir_home/AGENTS.md"
ln -s "$external_dir" "$symlink_dir_home/.claude/CLAUDE.md"

if HOME="$symlink_dir_home" "$repo_root/scripts/install.sh" --apply --claude >/dev/null 2>&1; then
  echo "EXPECTED_FAIL directory symlink target was accepted" >&2
  exit 1
fi
grep -q '^original shared$' "$symlink_dir_home/AGENTS.md"
test -L "$symlink_dir_home/.claude/CLAUDE.md"
test -z "$(find "$external_dir" -mindepth 1 -print -quit)"

# Invalid later targets must fail preflight before any earlier target changes.
half_home="$tmp_root/half-home"
missing_project="$tmp_root/does-not-exist"
mkdir -p "$half_home/.claude"
printf 'original shared\n' > "$half_home/AGENTS.md"
printf 'original claude\n' > "$half_home/.claude/CLAUDE.md"

if HOME="$half_home" "$repo_root/scripts/install.sh" \
  --apply --claude --cursor-project "$missing_project" >/dev/null 2>&1; then
  echo "EXPECTED_FAIL missing Cursor project was accepted" >&2
  exit 1
fi
grep -q '^original shared$' "$half_home/AGENTS.md"
grep -q '^original claude$' "$half_home/.claude/CLAUDE.md"
test -z "$(find "$half_home" -name '*.bak-ai-workflow-*' -print -quit)"

# A directory at any file target also blocks the whole transaction up front.
mkdir -p "$half_home/.codex/AGENTS.md"
if HOME="$half_home" CODEX_HOME="$half_home/.codex" "$repo_root/scripts/install.sh" \
  --apply --claude --codex >/dev/null 2>&1; then
  echo "EXPECTED_FAIL directory target was accepted" >&2
  exit 1
fi
grep -q '^original shared$' "$half_home/AGENTS.md"
grep -q '^original claude$' "$half_home/.claude/CLAUDE.md"

echo "INSTALL_SMOKE_OK"
