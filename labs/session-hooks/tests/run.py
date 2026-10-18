#!/usr/bin/env python3
"""Feed synthetic hook stdin JSON to each hook and assert its output.

Python 3 stdlib only. Every run uses a throwaway HOME and state dirs, so it
never reads or writes your real Claude Code state.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

LAB = Path(__file__).resolve().parents[1]
HOOKS = LAB / "hooks"
EXAMPLE = LAB / "examples" / "needs-me.example.md"
CASES = []
TMP = ""


def expect(cond, msg):
    if not cond:
        raise AssertionError(msg)


def run(hook, payload, env=None, raw=None):
    base = {k: v for k, v in os.environ.items()
            if not k.startswith(("TITLE_NUDGE_", "NEEDS_ME_", "ARCHIVE_CHECK_", "SESSION_HOOKS_", "CLAUDE_CODE_"))}
    base["HOME"] = TMP
    base.update(env or {})
    stdin = raw if raw is not None else json.dumps(payload)
    proc = subprocess.run([sys.executable, str(HOOKS / hook)], input=stdin, text=True,
                          capture_output=True, env=base, timeout=20)
    expect(proc.returncode == 0, f"{hook} exit {proc.returncode}: {proc.stderr}")
    out = proc.stdout.strip()
    return json.loads(out) if out else None


def case(fn):
    CASES.append(fn)
    return fn


# ---------- session_title_nudge ----------

def title_env(**extra):
    env = {"CLAUDE_CODE_ENTRYPOINT": "claude-desktop", "TITLE_NUDGE_STATE_DIR": str(Path(TMP) / "title")}
    env.update(extra)
    return env


@case
def title_silent_in_plain_terminal():
    expect(run("session_title_nudge.py", {"session_id": "t0"}, {}) is None, "terminal session should be silent")


@case
def title_nudges_on_second_prompt_then_waits():
    env = title_env()
    expect(run("session_title_nudge.py", {"session_id": "t1"}, env) is None, "1st prompt should be silent")
    out = run("session_title_nudge.py", {"session_id": "t1"}, env)
    ctx = out["hookSpecificOutput"]["additionalContext"]
    expect(out["hookSpecificOutput"]["hookEventName"] == "UserPromptSubmit", "wrong event name")
    expect('set_session_title(session_id="self")' in ctx and "2-4 keywords" in ctx, ctx)
    expect(run("session_title_nudge.py", {"session_id": "t1"}, env) is None, "3rd prompt inside interval should be silent")


@case
def title_interval_zero_nudges_every_prompt_and_zh():
    env = title_env(TITLE_NUDGE_MINUTES="0", TITLE_NUDGE_FIRST="1", SESSION_HOOKS_LANG="zh")
    for _ in range(2):
        ctx = run("session_title_nudge.py", {"session_id": "t2"}, env)["hookSpecificOutput"]["additionalContext"]
        expect("对话标题检查" in ctx, ctx)


@case
def title_bridge_hint_and_override_and_disable():
    env = {"CLAUDE_CODE_ENVIRONMENT_KIND": "bridge", "TITLE_NUDGE_STATE_DIR": str(Path(TMP) / "title"),
           "TITLE_NUDGE_FIRST": "1"}
    ctx = run("session_title_nudge.py", {"session_id": "t3"}, env)["hookSpecificOutput"]["additionalContext"]
    expect("get_session()" in ctx, ctx)
    env2 = {"TITLE_NUDGE_TOOL_HINT": "/rename", "TITLE_NUDGE_STATE_DIR": str(Path(TMP) / "title"),
            "TITLE_NUDGE_FIRST": "1"}
    ctx = run("session_title_nudge.py", {"session_id": "t4"}, env2)["hookSpecificOutput"]["additionalContext"]
    expect("/rename" in ctx, ctx)
    expect(run("session_title_nudge.py", {"session_id": "t5"}, title_env(TITLE_NUDGE_DISABLED="1",
           TITLE_NUDGE_FIRST="1")) is None, "disabled hook should be silent")


@case
def title_rejects_bad_session_id():
    env = title_env(TITLE_NUDGE_FIRST="1")
    expect(run("session_title_nudge.py", {"session_id": "../x"}, env) is None, "path-like id must be ignored")
    expect(run("session_title_nudge.py", None, env, raw="not json") is None, "bad stdin must fail silently")


# ---------- archive_readiness_nudge ----------

def stop(message, **extra):
    payload = {"hook_event_name": "Stop", "last_assistant_message": message}
    payload.update(extra)
    return run("archive_readiness_nudge.py", payload)


@case
def archive_blocks_without_footer():
    out = stop("Done. Tests pass.")
    expect(out["decision"] == "block" and "Archive check" in out["reason"], out)


@case
def archive_accepts_en_and_zh_footers():
    for footer in ("Archive check: ready (delivered and verified)",
                   "archive check: not yet (waiting on review)",
                   "Archive check: hand off (owner: docs task)",
                   "归档检查：可以归档（已验收）",
                   "归档检查：暂不归档（等待决定）",
                   "归档检查:待交接"):
        expect(stop(f"Summary.\n\n{footer}") is None, f"footer rejected: {footer}")


@case
def archive_footer_must_be_last_line():
    out = stop("Archive check: ready (x)\nOne more thing.")
    expect(out and out["decision"] == "block", "footer not on last line should block")


@case
def archive_ready_with_running_task_blocks():
    out = stop("Archive check: ready (done)", background_tasks=[{"status": "running"}])
    expect(out and "running" in out["reason"], out)
    expect(stop("Archive check: not yet (running tasks)", background_tasks=[{"status": "running"}]) is None,
           "not-yet with running task should pass")


@case
def archive_never_loops_and_fails_open():
    expect(stop("no footer", stop_hook_active=True) is None, "stop_hook_active must not block again")
    expect(run("archive_readiness_nudge.py", {"hook_event_name": "Stop"}) is None, "missing message fails open")
    expect(run("archive_readiness_nudge.py", None, raw="{bad") is None, "bad stdin fails open")
    expect(run("archive_readiness_nudge.py", {"last_assistant_message": "x"},
               {"ARCHIVE_CHECK_DISABLED": "1"}) is None, "disabled hook should be silent")


@case
def archive_zh_reason():
    out = run("archive_readiness_nudge.py", {"last_assistant_message": "完成"}, {"SESSION_HOOKS_LANG": "zh"})
    expect("归档检查" in out["reason"], out)


# ---------- needs_me_surface ----------

def needs_env(path, seen="seen"):
    return {"NEEDS_ME_PATH": str(path), "NEEDS_ME_SEEN_DIR": str(Path(TMP) / seen)}


def ctx_of(out):
    return out["hookSpecificOutput"]["additionalContext"]


@case
def needs_silent_when_checklist_missing():
    expect(run("needs_me_surface.py", {"hook_event_name": "SessionStart", "session_id": "n0"},
               needs_env(Path(TMP) / "nope.md")) is None, "missing checklist should be silent")


@case
def needs_surfaces_open_items_and_dedupes_per_session():
    env = needs_env(EXAMPLE, "seen1")
    out = run("needs_me_surface.py", {"hook_event_name": "SessionStart", "session_id": "n1"}, env)
    ctx = ctx_of(out)
    expect(out["hookSpecificOutput"]["hookEventName"] == "SessionStart", out)
    expect("open_count=3" in ctx and "returned_count=3" in ctx and "remaining_new_count=0" in ctx, ctx)
    expect("keep the old landing page" not in ctx, "checked item must not surface")
    for bucket in ("AI_SELF_HANDLE", "HUMAN_DECISION", "WAIT_TRIGGER", "STALE_OR_DUPLICATE"):
        expect(bucket in ctx, f"missing bucket {bucket}")
    expect(run("needs_me_surface.py", {"hook_event_name": "UserPromptSubmit", "session_id": "n1"}, env) is None,
           "already-injected items should not repeat in the same session")
    again = run("needs_me_surface.py", {"hook_event_name": "SessionStart", "session_id": "n1"}, env)
    expect("returned_count=3" in ctx_of(again), "SessionStart must re-surface everything still open")


@case
def needs_new_item_only_and_source_marker_ignored():
    path = Path(TMP) / "needs.md"
    path.write_text("- [ ] Approve budget. Source: a\n", encoding="utf-8")
    env = needs_env(path, "seen2")
    run("needs_me_surface.py", {"hook_event_name": "UserPromptSubmit", "session_id": "n2"}, env)
    path.write_text("- [ ] Approve budget. Source: b\n- [ ] Choose a name.\n", encoding="utf-8")
    ctx = ctx_of(run("needs_me_surface.py", {"hook_event_name": "UserPromptSubmit", "session_id": "n2"}, env))
    expect("returned_count=1" in ctx and "Choose a name" in ctx and "Approve budget" not in ctx, ctx)


@case
def needs_pagination_reports_remaining():
    path = Path(TMP) / "many.md"
    path.write_text("".join(f"- [ ] item {i}\n" for i in range(5)), encoding="utf-8")
    env = needs_env(path, "seen3")
    env["NEEDS_ME_MAX_EMIT"] = "2"
    ctx = ctx_of(run("needs_me_surface.py", {"hook_event_name": "UserPromptSubmit", "session_id": "n3"}, env))
    expect("returned_count=2" in ctx and "remaining_new_count=3" in ctx, ctx)
    ctx = ctx_of(run("needs_me_surface.py", {"hook_event_name": "UserPromptSubmit", "session_id": "n3"}, env))
    expect("returned_count=2" in ctx and "remaining_new_count=1" in ctx and "item 2" in ctx, ctx)


@case
def needs_unreadable_source_is_unknown_not_empty():
    big = Path(TMP) / "big.md"
    big.write_text("- [ ] x\n" + "y" * 300000, encoding="utf-8")
    ctx = ctx_of(run("needs_me_surface.py", {"hook_event_name": "UserPromptSubmit", "session_id": "n4"},
                     needs_env(big, "seen4")))
    expect("SOURCE_UNAVAILABLE" in ctx and "UNKNOWN" in ctx, ctx)
    link = Path(TMP) / "link.md"
    link.symlink_to(EXAMPLE)
    ctx = ctx_of(run("needs_me_surface.py", {"hook_event_name": "UserPromptSubmit", "session_id": "n5"},
                     needs_env(link, "seen5")))
    expect("SOURCE_UNAVAILABLE" in ctx, "symlinked checklist must not be followed")


@case
def needs_zh_text():
    env = needs_env(EXAMPLE, "seen6")
    env["SESSION_HOOKS_LANG"] = "zh"
    ctx = ctx_of(run("needs_me_surface.py", {"hook_event_name": "SessionStart", "session_id": "n6"}, env))
    expect("不等于用户已经获知" in ctx, ctx)


def main():
    global TMP
    with tempfile.TemporaryDirectory() as tmp:
        TMP = tmp
        for fn in CASES:
            fn()
            print(f"ok  {fn.__name__}")
    print(f"SESSION_HOOKS_TESTS_OK {len(CASES)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
