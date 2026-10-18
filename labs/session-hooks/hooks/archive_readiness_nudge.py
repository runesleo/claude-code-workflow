#!/usr/bin/env python3
"""Claude Code Stop hook: require one archive-readiness line at the end of
every final answer.

Problem: sessions pile up because nobody can tell at a glance which ones are
actually done. This hook asks the model to end each final answer with one line
that judges the *whole* session:

    Archive check: ready (reason)
    Archive check: not yet (blocker)
    Archive check: hand off (owner / receipt still to verify)

It only checks that the line is there. It never archives, never reads history,
and never infers completion from age, title or task counts.

Python 3 standard library only.
"""
from __future__ import annotations

import json
import os
import re
import sys

LANG = (os.environ.get("SESSION_HOOKS_LANG") or "en").strip().lower()

# Both languages are always accepted, whatever SESSION_HOOKS_LANG says.
_FOOTER = re.compile(
    r"^(?:归档检查[：:]\s*(?P<zh>可以归档|暂不归档|待交接)"
    r"|archive check:\s*(?P<en>ready|not yet|hand off))"
    r"(?:\s|[（(。，,：:.]|$)",
    re.IGNORECASE,
)
_READY = {"可以归档", "ready"}
_ACTIVE = {"running", "in_progress", "pending", "queued"}

REASON = {
    "zh": (
        "请在本次最终回复最后单独写一行归档检查。根据整个对话的真实交付、未解决的决策、"
        "运行中的任务和已有交接回执判断：仅在本对话没有未交接事项时写「归档检查：可以归档（理由）」；"
        "否则写「归档检查：暂不归档（阻塞点）」或「归档检查：待交接（负责人 / 待验证回执）」。"
        "不要因为单个子步骤完成、时间流逝或标题就推断整个对话已完成。不要自动归档。"
    ),
    "en": (
        "End this final answer with one separate archive-check line. Judge the whole session: real "
        "deliverables, open decisions, running work and existing hand-off receipts. Write "
        "\"Archive check: ready (reason)\" only when nothing in this session is left unhanded; otherwise "
        "write \"Archive check: not yet (blocker)\" or \"Archive check: hand off (owner / receipt to "
        "verify)\". Do not infer the whole session is done from one finished sub-step, elapsed time or "
        "the title. Do not archive anything automatically."
    ),
}
RUNNING = {
    "zh": "此会话还有运行中的任务。请把末行改为「归档检查：暂不归档（运行中任务）」。",
    "en": "This session still has running tasks. Change the last line to "
          "\"Archive check: not yet (running tasks)\".",
}


def _msg(table: dict) -> str:
    return table.get(LANG, table["en"])


def check(payload: dict) -> dict:
    """Return a Claude Code Stop decision, with no side effects."""
    if not isinstance(payload, dict) or payload.get("stop_hook_active") is True:
        return {}  # already continuing because of a Stop hook: never loop
    message = payload.get("last_assistant_message")
    if not isinstance(message, str) or not message.strip():
        return {}  # host did not supply the final text: fail open
    last_line = message.rstrip().splitlines()[-1].strip()
    match = _FOOTER.match(last_line)
    if not match:
        return {"decision": "block", "reason": _msg(REASON)}
    verdict = (match.group("zh") or match.group("en") or "").lower()
    if verdict in _READY:
        for task in payload.get("background_tasks") or []:
            if isinstance(task, dict) and task.get("status") in _ACTIVE:
                return {"decision": "block", "reason": _msg(RUNNING)}
    return {}


def main() -> int:
    if (os.environ.get("ARCHIVE_CHECK_DISABLED") or "").strip() == "1":
        return 0
    try:
        payload = json.loads(sys.stdin.read(262144) or "{}")
    except (ValueError, OSError):
        return 0
    decision = check(payload)
    if decision:
        print(json.dumps(decision, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
