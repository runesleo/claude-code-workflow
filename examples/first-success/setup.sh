#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./examples/first-success/setup.sh /absolute/path/to/empty-demo-directory

Creates an isolated Git fixture for the QuietHarness first-success exercise.
The target must be an absolute path and must be empty.
EOF
}

if [ "$#" -ne 1 ]; then
  usage >&2
  exit 2
fi

target="$1"
case "$target" in
  /)
    echo "ERROR: demo target must not be /" >&2
    exit 2
    ;;
  /*) ;;
  *)
    echo "ERROR: demo target must be an absolute path" >&2
    exit 2
    ;;
esac

if [ -e "$target" ] && [ ! -d "$target" ]; then
  echo "ERROR: demo target exists and is not a directory: $target" >&2
  exit 2
fi

mkdir -p "$target"
if [ -n "$(find "$target" -mindepth 1 -print -quit)" ]; then
  echo "ERROR: demo target must be empty: $target" >&2
  exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fixture_dir="$script_dir/fixture"

for required in checkout.sh test.sh TASK.md notes.md; do
  if [ ! -f "$fixture_dir/$required" ]; then
    echo "ERROR: missing fixture file: $fixture_dir/$required" >&2
    exit 2
  fi
done

cp -R "$fixture_dir/." "$target/"
chmod +x "$target/checkout.sh" "$target/test.sh"

git -C "$target" init -q
git -C "$target" config user.name "QuietHarness Demo"
git -C "$target" config user.email "demo@quiet-harness.invalid"
git -C "$target" config commit.gpgsign false
git -C "$target" add checkout.sh test.sh TASK.md notes.md
git -c core.hooksPath=/dev/null -c commit.gpgsign=false \
  -C "$target" commit -q -m "fixture: initial checkout calculator"

# Keep trial-only instruction files out of the exercise's working-tree signal.
cat >> "$target/.git/info/exclude" <<'EOF'
AGENTS.md
CLAUDE.md
.cursor/
EOF

cat >> "$target/notes.md" <<'EOF'

Draft: keep the checkout copy short for mobile users.
EOF

cat <<EOF
FIRST_SUCCESS_READY $target
EXPECTED_INITIAL_TEST failing
UNRELATED_CHANGE notes.md

Next:
  1. Open your installed AI coding agent in: $target
  2. Ask it: Read TASK.md and complete the task.
  3. A successful run preserves notes.md, makes ./test.sh pass, and reports real verification evidence.
EOF
