#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/quiet-harness-first-success.XXXXXX")"

cleanup() {
  case "$tmp_root" in
    "${TMPDIR:-/tmp}"/quiet-harness-first-success.*) rm -rf -- "$tmp_root" ;;
    *) echo "REFUSE_CLEANUP unexpected temp path: $tmp_root" >&2 ;;
  esac
}
trap cleanup EXIT INT TERM

demo_dir="$tmp_root/demo"
setup_output="$("$repo_root"/examples/first-success/setup.sh "$demo_dir")"

echo "$setup_output" | grep -Fq "FIRST_SUCCESS_READY $demo_dir"
echo "$setup_output" | grep -Fq 'EXPECTED_INITIAL_TEST failing'
test -x "$demo_dir/checkout.sh"
test -x "$demo_dir/test.sh"
test -f "$demo_dir/TASK.md"
test -d "$demo_dir/.git"

"$repo_root/scripts/install.sh" --apply --claude-project "$demo_dir" >/dev/null
cmp "$repo_root/templates/shared/AGENTS.md" "$demo_dir/AGENTS.md"
cmp "$repo_root/templates/claude/CLAUDE.project.md" "$demo_dir/CLAUDE.md"

status_before="$(git -C "$demo_dir" status --short)"
if [ "$status_before" != ' M notes.md' ]; then
  echo "FIRST_SUCCESS_SMOKE_FAIL unexpected initial status: $status_before" >&2
  exit 1
fi

if (cd "$demo_dir" && ./test.sh >"$tmp_root/test.out" 2>&1); then
  echo "FIRST_SUCCESS_SMOKE_FAIL fixture unexpectedly passed before the fix" >&2
  exit 1
fi
grep -Fq 'TEST_FAIL subtotal=2500 discount=10 expected=2250 got=2490' "$tmp_root/test.out"
grep -Fq 'Fix the defect in this repository and leave the project in a working state.' "$demo_dir/TASK.md"
if grep -Fq 'notes.md' "$demo_dir/TASK.md" || grep -Fq 'validation command' "$demo_dir/TASK.md"; then
  echo "FIRST_SUCCESS_SMOKE_FAIL task coaches the behavior under evaluation" >&2
  exit 1
fi

echo "FIRST_SUCCESS_SMOKE_OK"
