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
claude_project="$tmp_root/claude-project"
codex_project="$tmp_root/codex-project"
project_home="$tmp_root/project-home"
mkdir -p "$test_home" "$cursor_project" "$claude_project" "$codex_project" "$project_home"

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

# A first-time trial can stay inside one project and leave user-level config untouched.
project_dry_output="$(HOME="$project_home" "$repo_root/scripts/install.sh" \
  --dry-run --claude-project "$claude_project" --codex-project "$codex_project")"
echo "$project_dry_output" | grep -q 'DRY_RUN_COMPLETE'
test ! -e "$claude_project/AGENTS.md"
test ! -e "$claude_project/CLAUDE.md"
test ! -e "$codex_project/AGENTS.md"
test ! -e "$project_home/AGENTS.md"
test ! -e "$project_home/.claude/CLAUDE.md"
test ! -e "$project_home/.codex/AGENTS.md"

HOME="$project_home" "$repo_root/scripts/install.sh" \
  --apply --claude-project "$claude_project" --codex-project "$codex_project" >/dev/null
cmp "$repo_root/templates/shared/AGENTS.md" "$claude_project/AGENTS.md"
cmp "$repo_root/templates/claude/CLAUDE.project.md" "$claude_project/CLAUDE.md"
cmp "$repo_root/templates/shared/AGENTS.md" "$codex_project/AGENTS.md"
test ! -e "$project_home/AGENTS.md"
test ! -e "$project_home/.claude/CLAUDE.md"
test ! -e "$project_home/.codex/AGENTS.md"

# Two client modes must never race to replace the same project target.
duplicate_project="$tmp_root/duplicate-project"
mkdir -p "$duplicate_project"
if HOME="$project_home" "$repo_root/scripts/install.sh" --apply \
  --claude-project "$duplicate_project" --codex-project "$duplicate_project" >/dev/null 2>&1; then
  echo "EXPECTED_FAIL duplicate project target was accepted" >&2
  exit 1
fi
test ! -e "$duplicate_project/AGENTS.md"
test ! -e "$duplicate_project/CLAUDE.md"

# Project-scoped Cursor install must not follow an intermediate symlink outside
# the selected project.
contained_project="$tmp_root/contained-project"
outside_cursor_dir="$tmp_root/outside-cursor-dir"
mkdir -p "$contained_project" "$outside_cursor_dir"
ln -s "$outside_cursor_dir" "$contained_project/.cursor"
if HOME="$project_home" "$repo_root/scripts/install.sh" --apply \
  --cursor-project "$contained_project" >/dev/null 2>&1; then
  echo "EXPECTED_FAIL project target escaped through an intermediate symlink" >&2
  exit 1
fi
test -L "$contained_project/.cursor"
test -z "$(find "$outside_cursor_dir" -mindepth 1 -print -quit)"

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

# If automatic restore itself fails, the installer must preserve the only
# recovery backup instead of deleting it during cleanup.
rollback_home="$tmp_root/rollback-home"
fake_bin="$tmp_root/fake-bin"
rollback_log="$tmp_root/rollback.log"
mkdir -p "$rollback_home/.claude" "$fake_bin"
printf 'rollback shared original\n' > "$rollback_home/AGENTS.md"
printf 'rollback claude original\n' > "$rollback_home/.claude/CLAUDE.md"
cat > "$fake_bin/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
source_path="${1:-}"
case "$source_path" in
  *.CLAUDE.md.stage-ai-workflow-*) exit 73 ;;
  *AGENTS.md.bak-ai-workflow-*) exit 74 ;;
esac
exec /bin/mv "$@"
EOF
chmod +x "$fake_bin/mv"

if PATH="$fake_bin:$PATH" HOME="$rollback_home" "$repo_root/scripts/install.sh" \
  --apply --claude >"$rollback_log" 2>&1; then
  echo "EXPECTED_FAIL injected install failure unexpectedly succeeded" >&2
  exit 1
fi
recovery_backup="$(find "$rollback_home" -maxdepth 1 -name 'AGENTS.md.bak-ai-workflow-*' -type f | head -n 1)"
test -n "$recovery_backup"
grep -q '^rollback shared original$' "$recovery_backup"
grep -q '^RECOVERY_BACKUP preserved after incomplete rollback:' "$rollback_log"
test ! -e "$rollback_home/AGENTS.md"
grep -q '^rollback claude original$' "$rollback_home/.claude/CLAUDE.md"

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
