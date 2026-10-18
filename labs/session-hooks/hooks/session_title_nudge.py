#!/usr/bin/env python3
"""Claude Code UserPromptSubmit hook: remind the model to retitle the session
when its main thread has moved on.

Long sessions keep the first auto-generated title ("Review a link") even after
the work has shifted to something else, so the session list stops being useful.
A rule in CLAUDE.md alone is a soft rule with no executor; this hook puts the
check in front of the model on the 2nd prompt, then at most once per interval.

It never renames anything itself. A hook only fires when you send a message,
so an idle session is not re-checked until your next prompt.

Python 3 standard library only.
"""
from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path


def _env(name: str, default: str = "") -> str:
    return (os.environ.get(name) or default).strip()


STATE_DIR = Path(
    _env("TITLE_NUDGE_STATE_DIR")
    or Path.home() / ".local/state/claude-session-hooks/title-nudge"
).expanduser()
FIRST = int(_env("TITLE_NUDGE_FIRST", "2"))
INTERVAL_S = 60 * float(_env("TITLE_NUDGE_MINUTES", "60"))
LANG = _env("SESSION_HOOKS_LANG", "en").lower()

TEXT = {
    "zh": {
        "desktop": 'set_session_title(session_id="self")',
        "bridge": "先用 get_session()（不带 id）拿本会话的 session_… id，再 set_session_title(<该 id>, 标题)"
                  "（这类会话不认 self）",
        "nudge": "【对话标题检查】本对话主线若已换（新对象/新任务成了主线，不是一次性插问），用 {how} "
                 "把标题改成 2–4 个关键词（多条并行用 · 分隔，最新的放前面）；用户手动起的标题先问再改。"
                 "没换就忽略，回复里不用提这条。",
    },
    "en": {
        "desktop": 'set_session_title(session_id="self")',
        "bridge": "call get_session() with no id to get this session's session_… id, then "
                  "set_session_title(<that id>, title) (these sessions do not accept \"self\")",
        "nudge": "[Session title check] If this session's main thread has changed (a new object or task "
                 "became the focus, not a one-off side question), use {how} to retitle it with 2-4 keywords "
                 "(separate parallel threads with \" · \", newest first). If the user named the session "
                 "themselves, ask before renaming. If nothing changed, ignore this and do not mention it.",
    },
}


def _text(key: str) -> str:
    return TEXT.get(LANG, TEXT["en"])[key]


def how_to_rename() -> str | None:
    override = _env("TITLE_NUDGE_TOOL_HINT")
    if override:
        return override
    if os.environ.get("CLAUDE_CODE_ENTRYPOINT") == "claude-desktop":
        return _text("desktop")
    if os.environ.get("CLAUDE_CODE_ENVIRONMENT_KIND") == "bridge":
        return _text("bridge")
    return None  # plain terminal session: no known title tool, stay silent


def main() -> None:
    if _env("TITLE_NUDGE_DISABLED") == "1":
        return
    how = how_to_rename()
    if not how:
        return
    data = json.loads(sys.stdin.read() or "{}")
    if not isinstance(data, dict):
        return
    sid = str(data.get("session_id") or "").strip()
    if not sid or "/" in sid or sid.startswith("."):
        return
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    path = STATE_DIR / f"{sid}.json"
    try:
        state = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        state = {}
    prompts = int(state.get("prompts", 0)) + 1
    last = float(state.get("last_nudge", 0) or 0)
    now = time.time()
    due = prompts >= FIRST and (last == 0 or now - last >= INTERVAL_S)
    path.write_text(json.dumps({"prompts": prompts, "last_nudge": now if due else last}), encoding="utf-8")
    for old in STATE_DIR.glob("*.json"):  # forget sessions idle for a week
        if now - old.stat().st_mtime > 7 * 86400:
            old.unlink(missing_ok=True)
    if not due:
        return
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": _text("nudge").format(how=how),
    }}, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass  # never block the user's prompt
