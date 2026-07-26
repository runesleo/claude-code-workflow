#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/inventory.sh [CONFIG_ROOT ...]

Lists instruction files and every symlink under AI client config roots.
With no arguments, scans ~/.claude, ${CODEX_HOME:-~/.codex}, and ~/.cursor.
This command is read-only.
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

workflow_home="${HOME:-}"
if [ -z "$workflow_home" ] || [ "$workflow_home" = "/" ]; then
  echo "ERROR: HOME must resolve to a user directory, not /" >&2
  exit 2
fi

if [ "$#" -gt 0 ]; then
  roots=("$@")
else
  codex_home="${CODEX_HOME:-$workflow_home/.codex}"
  roots=("$workflow_home/.claude" "$codex_home" "$workflow_home/.cursor")
fi

file_pattern='(^|/)(CLAUDE(\.local)?\.md|AGENTS(\.override)?\.md|(SKILL|skill)\.md|hooks\.json|settings\.json|config\.toml|[^/]+\.mdc|rules(/[^/]+)+\.md|commands(/[^/]+)+\.md)$'

{
  for root in "${roots[@]}"; do
    if [ ! -e "$root" ] && [ ! -L "$root" ]; then
      continue
    fi

    # List every link, including whole-directory links such as rules/ or skills/.
    find "$root" -maxdepth 4 -type l -print 2>/dev/null || true
    find "$root" -maxdepth 4 -type f -print 2>/dev/null \
      | grep -E "$file_pattern" || true
  done
} | LC_ALL=C sort -u
