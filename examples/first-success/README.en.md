# QuietHarness first-success exercise (ten-minute target)

[中文](README.md) · **English**

This exercise needs only the AI coding agent you already use. Claude Code, Codex, or Cursor is enough; installing all three is not a prerequisite.

It checks four intended observable behaviors rather than merely checking that configuration files were copied:

1. inspect the current state before editing;
2. preserve unrelated user work;
3. make the smallest change that solves the task;
4. run real validation and report evidence plus anything not verified.

This is an onboarding behavior check, not a causal experiment proving that QuietHarness always improves model quality. The target duration still needs timing by a real non-author.

## 1. Create an isolated exercise directory

From the QuietHarness repository root, run:

```bash
demo_dir="$(mktemp -d "${TMPDIR:-/tmp}/quiet-harness-first-success.XXXXXX")"
./examples/first-success/setup.sh "$demo_dir"
```

The setup script writes only to the new temporary directory. It creates a small Git repository containing:

- an intentional percentage-discount bug;
- an initially failing `./test.sh`;
- an unrelated in-progress user edit in `notes.md` that must be preserved;
- a `TASK.md` that defines success without revealing the fix.

## 2. Install one client rule in the exercise project

Run only the group for the client you use. Inspect dry-run before apply; these commands do not change user-level configuration.

### Claude Code

```bash
./scripts/install.sh --dry-run --claude-project "$demo_dir"
./scripts/install.sh --apply --claude-project "$demo_dir"
```

### Codex

```bash
./scripts/install.sh --dry-run --codex-project "$demo_dir"
./scripts/install.sh --apply --codex-project "$demo_dir"
```

### Cursor

```bash
./scripts/install.sh --dry-run --cursor-project "$demo_dir"
./scripts/install.sh --apply --cursor-project "$demo_dir"
```

## 3. Open your agent in the exercise directory

```bash
cd "$demo_dir"
```

Open Claude Code, Codex, or Cursor with QuietHarness installed and send only this request:

```text
Read TASK.md and complete the task.
```

Do not tell the agent how to fix the bug. The point is to observe whether it reads the task, protects existing work, and verifies the result on its own.

## 4. Check the result

After the agent finishes, run:

```bash
./test.sh
git status --short
git diff -- notes.md
```

A successful run satisfies all of the following:

- `./test.sh` prints `FIRST_SUCCESS_FIXTURE_OK`;
- the user's draft in `notes.md` remains intact;
- the agent changes only what the discount fix requires, with no new dependency or unrelated redesign;
- its final response includes the exact validation command and result;
- anything not verified is stated instead of being presented as complete.

If any condition fails, open a GitHub issue with the client, model, final response, and `git status --short`. Do not include accounts, private projects, or credentials.

## Cleanup

Delete `$demo_dir` yourself when you no longer need it. QuietHarness never deletes the directory automatically and never uploads its contents.
