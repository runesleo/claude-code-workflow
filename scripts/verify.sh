#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cd "$repo_root"

required_files="
README.md
README.zh.md
CHANGELOG.md
LICENSE
MIGRATION-v3.md
RELEASE_NOTES.md
REVIEW-codex-pass.md
AGENTS.md
CLAUDE.md
templates/shared/AGENTS.md
templates/claude/CLAUDE.md
templates/cursor/quiet-harness.mdc
docs/DAILY-REPORTS.md
media/launch-v3/README.md
media/launch-v3/X-DRAFT.zh.md
media/launch-v3/01-positioning.zh.svg
media/launch-v3/01-positioning.zh.png
media/launch-v3/02-three-layers.zh.svg
media/launch-v3/02-three-layers.zh.png
media/launch-v3/03-before-after.zh.svg
media/launch-v3/03-before-after.zh.png
media/launch-v3/04-rule-placement.zh.svg
media/launch-v3/04-rule-placement.zh.png
scripts/inventory.sh
scripts/install.sh
scripts/verify.sh
tests/inventory-smoke.sh
tests/install-smoke.sh
"

for required in $required_files; do
  if [ ! -f "$required" ]; then
    echo "VERIFY_FAIL missing $required" >&2
    exit 1
  fi
done

if [ -e README.en.md ]; then
  echo "VERIFY_FAIL README.en.md duplicates the English default" >&2
  exit 1
fi

if ! grep -Fq '# QuietHarness' README.md || ! grep -Fq '# QuietHarness' README.zh.md; then
  echo "VERIFY_FAIL product name is not consistent across both README files" >&2
  exit 1
fi

if [ -e templates/cursor/lean-baseline.mdc ]; then
  echo "VERIFY_FAIL stale pre-brand Cursor template remains active" >&2
  exit 1
fi

for legacy_dir in rules skills agents commands memory hooks; do
  if [ -e "$legacy_dir" ]; then
    echo "VERIFY_FAIL legacy v2 directory remains active: $legacy_dir" >&2
    exit 1
  fi
done

if ! grep -Fq './scripts/inventory.sh' MIGRATION-v3.md; then
  echo "VERIFY_FAIL migration guide omits the read-only inventory command" >&2
  exit 1
fi

bash -n scripts/inventory.sh
bash -n scripts/install.sh
bash -n scripts/verify.sh
bash -n tests/inventory-smoke.sh
bash -n tests/install-smoke.sh
./tests/inventory-smoke.sh
./tests/install-smoke.sh

private_hits="$(grep -REn '(/(Users|home)/[^/]+|leo[-]vault|_[i]nventory|active[-]tasks|T[0-9]{3,})' \
  AGENTS.md CLAUDE.md templates 2>/dev/null || true)"
if [ -n "$private_hits" ]; then
  echo "VERIFY_FAIL private or maintainer-only pattern in shipped instructions" >&2
  echo "$private_hits" >&2
  exit 1
fi

stale_hits="$(grep -REni '(mandatory subagent|PreToolUse Hook|memory-flush|today\.md|session-end)' \
  AGENTS.md CLAUDE.md templates 2>/dev/null || true)"
if [ -n "$stale_hits" ]; then
  echo "VERIFY_FAIL stale v2 trigger language in active instructions" >&2
  echo "$stale_hits" >&2
  exit 1
fi

template_bytes=$((
  $(wc -c < templates/shared/AGENTS.md) +
  $(wc -c < templates/claude/CLAUDE.md) +
  $(wc -c < templates/cursor/quiet-harness.mdc)
))

if [ "$template_bytes" -gt 8000 ]; then
  echo "VERIFY_FAIL template hot path is ${template_bytes} bytes (limit 8000)" >&2
  exit 1
fi

git diff --check

echo "VERIFY_OK template_bytes=$template_bytes"
