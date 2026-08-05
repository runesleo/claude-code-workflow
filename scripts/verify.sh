#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cd "$repo_root"

required_files="
README.md
README.en.md
CHANGELOG.md
LICENSE
MIGRATION-v3.md
MIGRATION-v3.en.md
RELEASE_NOTES.md
REVIEW-codex-pass.md
AGENTS.md
CLAUDE.md
templates/shared/AGENTS.md
templates/claude/CLAUDE.md
templates/claude/CLAUDE.project.md
templates/cursor/quiet-harness.mdc
docs/DAILY-REPORTS.md
docs/DAILY-REPORTS.en.md
docs/ARCHITECTURE.md
docs/ARCHITECTURE.en.md
docs/PRIVATE-OVERLAY.md
docs/PRIVATE-OVERLAY.en.md
docs/TASK-CONTINUITY.md
docs/TASK-CONTINUITY.en.md
examples/leo-system/README.md
examples/leo-system/README.en.md
examples/leo-system/AGENTS.private.example.md
examples/leo-system/business-lines.example.json
examples/leo-system/task.example.json
examples/leo-system/writer-lock.example.json
examples/leo-system/readout.example.txt
examples/first-success/README.md
examples/first-success/README.en.md
examples/first-success/setup.sh
examples/first-success/fixture/checkout.sh
examples/first-success/fixture/test.sh
examples/first-success/fixture/TASK.md
examples/first-success/fixture/notes.md
media/launch-v3/README.md
media/launch-v3/X-DRAFT.zh.md
media/launch-v3/00-system-map.zh.svg
media/launch-v3/00-system-map.zh.png
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
tests/first-success-smoke.sh
"

for required in $required_files; do
  if [ ! -f "$required" ]; then
    echo "VERIFY_FAIL missing $required" >&2
    exit 1
  fi
done

if [ -e README.zh.md ]; then
  echo "VERIFY_FAIL README.zh.md remains beside the Chinese default README.md" >&2
  exit 1
fi

if ! grep -Fq '# QuietHarness' README.md || ! grep -Fq '# QuietHarness' README.en.md; then
  echo "VERIFY_FAIL product name is not consistent across both README files" >&2
  exit 1
fi

if ! grep -Fq '**中文**' README.md || ! grep -Fq '**English**' README.en.md; then
  echo "VERIFY_FAIL README language-source markers are missing" >&2
  exit 1
fi

if grep -Fq './scripts/install.sh --dry-run --claude --codex' \
  README.md README.en.md MIGRATION-v3.md MIGRATION-v3.en.md; then
  echo "VERIFY_FAIL public docs still present multi-client installation as the default" >&2
  exit 1
fi

for marker in \
  '## 先在一个隔离项目试用' \
  "--claude-project \"\$demo_dir\"" \
  "--codex-project \"\$demo_dir\"" \
  'examples/first-success/README.md'; do
  if ! grep -Fq -- "$marker" README.md; then
    echo "VERIFY_FAIL Chinese first-success entry omits: $marker" >&2
    exit 1
  fi
done

for marker in \
  '## Try it inside one isolated project' \
  "--claude-project \"\$demo_dir\"" \
  "--codex-project \"\$demo_dir\"" \
  'examples/first-success/README.en.md'; do
  if ! grep -Fq -- "$marker" README.en.md; then
    echo "VERIFY_FAIL English first-success entry omits: $marker" >&2
    exit 1
  fi
done

for marker in '--claude-project)' '--codex-project)' 'duplicate install target'; do
  if ! grep -Fq -- "$marker" scripts/install.sh; then
    echo "VERIFY_FAIL project-scoped installer omits: $marker" >&2
    exit 1
  fi
done

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

if ! grep -Fq './scripts/inventory.sh' MIGRATION-v3.md || ! grep -Fq './scripts/inventory.sh' MIGRATION-v3.en.md; then
  echo "VERIFY_FAIL migration guide omits the read-only inventory command" >&2
  exit 1
fi

if ! grep -Fq '**中文**' MIGRATION-v3.md || \
   ! grep -Fq '[English](MIGRATION-v3.en.md)' MIGRATION-v3.md || \
   ! grep -Fq '[中文](MIGRATION-v3.md)' MIGRATION-v3.en.md || \
   ! grep -Fq '**English**' MIGRATION-v3.en.md; then
  echo "VERIFY_FAIL migration language-source markers are missing" >&2
  exit 1
fi

bash -n scripts/inventory.sh
bash -n scripts/install.sh
bash -n scripts/verify.sh
bash -n tests/inventory-smoke.sh
bash -n tests/install-smoke.sh
bash -n tests/first-success-smoke.sh
bash -n examples/first-success/setup.sh
bash -n examples/first-success/fixture/checkout.sh
bash -n examples/first-success/fixture/test.sh
./tests/inventory-smoke.sh
./tests/install-smoke.sh
./tests/first-success-smoke.sh

private_hits="$(grep -REn '(/(Users|home)/[^/]+|leo[-]vault|_[i]nventory|active[-]tasks|T[0-9]{3,})' \
  AGENTS.md CLAUDE.md templates docs examples 2>/dev/null || true)"
if [ -n "$private_hits" ]; then
  echo "VERIFY_FAIL private or maintainer-only pattern in shipped instructions" >&2
  echo "$private_hits" >&2
  exit 1
fi

for marker in '"owner_thread"' '"primary_worker"' '"next_action"' '"updated_at"' '"execution_map"' '"evaluator"'; do
  if ! grep -Fq "$marker" examples/leo-system/task.example.json; then
    echo "VERIFY_FAIL continuity example omits contract marker: $marker" >&2
    exit 1
  fi
done

for marker in '"active_writer"' '"allowed_paths"' '"validation_required"' '"release_receipt"'; do
  if ! grep -Fq "$marker" examples/leo-system/writer-lock.example.json; then
    echo "VERIFY_FAIL writer-lock example omits contract marker: $marker" >&2
    exit 1
  fi
done

for slug in personal_ops pm_strategy pm_intel portfolio content_writing product_distribution health_ops daily_rhythm research_dd; do
  if ! grep -Fq "\"slug\": \"$slug\"" examples/leo-system/business-lines.example.json; then
    echo "VERIFY_FAIL business-line map omits $slug" >&2
    exit 1
  fi
done

python3 -m json.tool examples/leo-system/business-lines.example.json >/dev/null
python3 -m json.tool examples/leo-system/task.example.json >/dev/null
python3 -m json.tool examples/leo-system/writer-lock.example.json >/dev/null

if command -v xmllint >/dev/null 2>&1; then
  xmllint --noout media/launch-v3/*.svg
fi

legacy_copy_hits="$(grep -REn '(README\.zh\.md|examples/solo-builder)' \
  AGENTS.md README.md README.en.md MIGRATION-v3.md MIGRATION-v3.en.md docs examples media CHANGELOG.md RELEASE_NOTES.md 2>/dev/null || true)"
if [ -n "$legacy_copy_hits" ]; then
  echo "VERIFY_FAIL stale language or example path remains" >&2
  echo "$legacy_copy_hits" >&2
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
