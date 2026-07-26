#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/install.sh --dry-run --claude [--codex]
  ./scripts/install.sh --apply --claude [--codex]
  ./scripts/install.sh --dry-run --cursor-project /path/to/project
  ./scripts/install.sh --apply --cursor-project /path/to/project

Options:
  --dry-run              Print exact targets. This is the default mode.
  --apply                Write files after backing up existing targets.
  --claude               Install ~/AGENTS.md and ~/.claude/CLAUDE.md.
  --codex                Install $CODEX_HOME/AGENTS.md (default: ~/.codex/AGENTS.md).
  --cursor-project PATH  Install one project-scoped Cursor rule.
  --help                 Show this help.
EOF
}

mode="dry-run"
want_claude=0
want_codex=0
cursor_project=""
target_count=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      mode="dry-run"
      ;;
    --apply)
      mode="apply"
      ;;
    --claude)
      want_claude=1
      target_count=$((target_count + 1))
      ;;
    --codex)
      want_codex=1
      target_count=$((target_count + 1))
      ;;
    --cursor-project)
      shift
      if [ "$#" -eq 0 ]; then
        echo "ERROR: --cursor-project requires a path" >&2
        exit 2
      fi
      cursor_project="$1"
      target_count=$((target_count + 1))
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [ "$target_count" -eq 0 ]; then
  echo "ERROR: choose --claude, --codex, or --cursor-project PATH" >&2
  usage >&2
  exit 2
fi

workflow_home="${HOME:-}"
if [ -z "$workflow_home" ] || [ "$workflow_home" = "/" ]; then
  echo "ERROR: HOME must resolve to a user directory, not /" >&2
  exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
shared_source="$repo_root/templates/shared/AGENTS.md"
claude_source="$repo_root/templates/claude/CLAUDE.md"
cursor_source="$repo_root/templates/cursor/quiet-harness.mdc"
timestamp="$(date +%Y%m%d-%H%M%S)-$$"
codex_home="${CODEX_HOME:-$workflow_home/.codex}"

case "$workflow_home" in
  /*) ;;
  *)
    echo "ERROR: HOME must be an absolute path" >&2
    exit 2
    ;;
esac

if [ "$want_codex" -eq 1 ]; then
  case "$codex_home" in
    /)
      echo "ERROR: CODEX_HOME must not be /" >&2
      exit 2
      ;;
    /*) ;;
    *)
      echo "ERROR: CODEX_HOME must be an absolute path" >&2
      exit 2
      ;;
  esac
fi

for required in "$shared_source" "$claude_source" "$cursor_source"; do
  if [ ! -f "$required" ]; then
    echo "ERROR: missing template: $required" >&2
    exit 2
  fi
done

if [ -n "$cursor_project" ]; then
  if [ ! -d "$cursor_project" ]; then
    echo "ERROR: Cursor project does not exist: $cursor_project" >&2
    exit 2
  fi
  cursor_project="$(cd "$cursor_project" && pwd)"
  if [ "$cursor_project" = "/" ]; then
    echo "ERROR: Cursor project must not be /" >&2
    exit 2
  fi
fi

sources=()
targets=()

add_target() {
  target_index="${#targets[@]}"
  sources[target_index]="$1"
  targets[target_index]="$2"
}

if [ "$want_claude" -eq 1 ]; then
  add_target "$shared_source" "$workflow_home/AGENTS.md"
  add_target "$claude_source" "$workflow_home/.claude/CLAUDE.md"
fi

if [ "$want_codex" -eq 1 ]; then
  add_target "$shared_source" "$codex_home/AGENTS.md"
fi

if [ -n "$cursor_project" ]; then
  add_target "$cursor_source" "$cursor_project/.cursor/rules/quiet-harness.mdc"
fi

target_total="${#targets[@]}"
target_index=0
while [ "$target_index" -lt "$target_total" ]; do
  source_file="${sources[$target_index]}"
  target_file="${targets[$target_index]}"

  if [ ! -f "$source_file" ]; then
    echo "ERROR: missing template: $source_file" >&2
    exit 2
  fi
  if [ -d "$target_file" ]; then
    echo "ERROR: target is a directory: $target_file" >&2
    exit 2
  fi

  echo "PLAN $source_file -> $target_file"
  if [ -e "$target_file" ] || [ -L "$target_file" ]; then
    echo "BACKUP_PLAN $target_file -> ${target_file}.bak-ai-workflow-${timestamp}"
  fi
  target_index=$((target_index + 1))
done

if [ "$mode" = "dry-run" ]; then
  echo "DRY_RUN_COMPLETE no files written"
  exit 0
fi

staged_files=()
backup_files=()
had_original=()
applied_count=0
transaction_active=1

cleanup_transaction_files() {
  cleanup_index=0
  while [ "$cleanup_index" -lt "$target_total" ]; do
    staged_file="${staged_files[$cleanup_index]:-}"
    backup_file="${backup_files[$cleanup_index]:-}"
    if [ -n "$staged_file" ] && { [ -e "$staged_file" ] || [ -L "$staged_file" ]; }; then
      rm -f "$staged_file" || true
    fi
    if [ -n "$backup_file" ] && { [ -e "$backup_file" ] || [ -L "$backup_file" ]; }; then
      rm -f "$backup_file" || true
    fi
    cleanup_index=$((cleanup_index + 1))
  done
}

rollback_transaction() {
  rollback_ok=1
  rollback_index=$((applied_count - 1))
  while [ "$rollback_index" -ge 0 ]; do
    target_file="${targets[$rollback_index]}"
    backup_file="${backup_files[$rollback_index]:-}"

    if [ "${had_original[$rollback_index]}" -eq 1 ]; then
      if ! rm -f "$target_file"; then
        echo "ROLLBACK_ERROR could not remove $target_file" >&2
        rollback_ok=0
      elif ! mv "$backup_file" "$target_file"; then
        echo "ROLLBACK_ERROR could not restore $target_file" >&2
        rollback_ok=0
      else
        backup_files[rollback_index]=""
      fi
    elif ! rm -f "$target_file"; then
      echo "ROLLBACK_ERROR could not remove new target $target_file" >&2
      rollback_ok=0
    fi
    rollback_index=$((rollback_index - 1))
  done

  cleanup_transaction_files
  transaction_active=0
  if [ "$rollback_ok" -eq 1 ]; then
    echo "ROLLBACK_COMPLETE no targets left partially installed" >&2
  else
    echo "ROLLBACK_INCOMPLETE inspect the paths above" >&2
  fi
}

abort_transaction() {
  abort_reason="$1"
  echo "ERROR: $abort_reason" >&2
  if [ "$transaction_active" -eq 1 ]; then
    rollback_transaction
  fi
  exit 1
}

trap 'abort_transaction "installation interrupted"' INT TERM HUP
trap 'abort_transaction "unexpected command failure"' ERR

# Stage every source beside its destination before replacing any target. This
# catches missing permissions and invalid paths without leaving a half install.
target_index=0
while [ "$target_index" -lt "$target_total" ]; do
  source_file="${sources[$target_index]}"
  target_file="${targets[$target_index]}"
  target_dir="$(dirname "$target_file")"
  target_name="$(basename "$target_file")"
  stage_file="$target_dir/.${target_name}.stage-ai-workflow-${timestamp}"
  backup_file="${target_file}.bak-ai-workflow-${timestamp}"

  staged_files[target_index]="$stage_file"
  backup_files[target_index]=""
  had_original[target_index]=0

  if ! mkdir -p "$target_dir"; then
    abort_transaction "cannot create target directory: $target_dir"
  fi
  if [ -e "$stage_file" ] || [ -L "$stage_file" ]; then
    abort_transaction "staging path already exists: $stage_file"
  fi
  if ! cp -p "$source_file" "$stage_file"; then
    abort_transaction "cannot stage template for: $target_file"
  fi

  if [ -e "$target_file" ] || [ -L "$target_file" ]; then
    if [ -e "$backup_file" ] || [ -L "$backup_file" ]; then
      abort_transaction "backup path already exists: $backup_file"
    fi
    backup_files[target_index]="$backup_file"
    if ! cp -Pp "$target_file" "$backup_file"; then
      abort_transaction "cannot back up target: $target_file"
    fi
    had_original[target_index]=1
  fi
  target_index=$((target_index + 1))
done

target_index=0
while [ "$target_index" -lt "$target_total" ]; do
  target_file="${targets[$target_index]}"
  stage_file="${staged_files[$target_index]}"
  # Count the current target before rename so an interrupt at any point in the
  # replacement is conservatively rolled back, even if rename already landed.
  applied_count=$((target_index + 1))
  if { [ -e "$target_file" ] || [ -L "$target_file" ]; } && ! rm -f "$target_file"; then
    abort_transaction "cannot remove existing target: $target_file"
  fi
  if ! mv "$stage_file" "$target_file"; then
    abort_transaction "cannot install target: $target_file"
  fi
  staged_files[target_index]=""
  target_index=$((target_index + 1))
done

transaction_active=0
trap - ERR INT TERM HUP

target_index=0
while [ "$target_index" -lt "$target_total" ]; do
  backup_file="${backup_files[$target_index]}"
  if [ -n "$backup_file" ]; then
    echo "BACKUP $backup_file"
  fi
  echo "INSTALLED ${targets[$target_index]}"
  target_index=$((target_index + 1))
done

echo "APPLY_COMPLETE restart affected clients or open a new session"
