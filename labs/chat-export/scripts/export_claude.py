#!/usr/bin/env python3
"""Export Claude Code sessions (~/.claude/projects/*/<session>.jsonl) to one markdown file per session.

Kept: what you typed and Claude's visible text replies.
Dropped: system reminders, thinking, tool calls/results, meta records and subagent sidechains.
"""
import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import DEST_ROOT, Watermark, file_sig, group_turns, render  # noqa: E402

SRC = Path.home() / ".claude/projects"
DEST = DEST_ROOT / "claude"

INJECTED = [re.compile(rf"<{tag}>.*?</{tag}>", re.S) for tag in (
    "system-reminder", "local-command-stdout", "local-command-caveat", "task-notification")]


def strip_injected(text):
    for pattern in INJECTED:
        text = pattern.sub("", text)
    return text.strip()


def text_blocks(content):
    if isinstance(content, str):
        return content
    if not isinstance(content, list):
        return ""
    return "\n".join(b["text"] for b in content
                     if isinstance(b, dict) and b.get("type") == "text" and isinstance(b.get("text"), str))


def parse_session(path):
    meta, messages = {}, []
    for line in path.open(encoding="utf-8", errors="replace"):
        try:
            rec = json.loads(line)
        except json.JSONDecodeError:
            continue
        rtype = rec.get("type")
        if rtype == "custom-title" and isinstance(rec.get("customTitle"), str):
            meta["title"] = rec["customTitle"]
            continue
        if rtype not in ("user", "assistant") or rec.get("isSidechain") or rec.get("isMeta"):
            continue
        if not meta.get("session_id"):
            meta.update(session_id=rec.get("sessionId"), cwd=rec.get("cwd"), timestamp=rec.get("timestamp"))
        text = text_blocks((rec.get("message") or {}).get("content"))
        if rtype == "user":
            text = strip_injected(text)      # empty afterwards = tool result or pure injection
        messages.append((rtype, text))
    return meta, group_turns(messages)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--src", type=Path, default=SRC)
    ap.add_argument("--dest", type=Path, default=DEST)
    ap.add_argument("--full", action="store_true", help="ignore the watermark and reprocess everything")
    ap.add_argument("--dry-run", action="store_true", help="report only, write nothing")
    args = ap.parse_args(argv)

    mark = Watermark(args.dest, args.full)
    files = sorted((p for p in args.src.glob("*/*.jsonl") if "subagents" not in p.parts),
                   key=lambda p: p.stat().st_mtime_ns)    # a session copied across project dirs: newest wins
    written = empty = 0
    for f in files:
        sig = file_sig(f)
        if mark.unchanged(str(f), sig):
            continue
        meta, turns = parse_session(f)
        if turns:
            if not args.dry_run:
                args.dest.mkdir(parents=True, exist_ok=True)
                date = (meta.get("timestamp") or "")[:10] or "undated"
                (args.dest / f"{date}-{f.stem}.md").write_text(render(
                    "claude", meta.get("session_id") or f.stem, turns, title=meta.get("title", ""),
                    timestamp=meta.get("timestamp") or "", cwd=meta.get("cwd") or "", source_file=str(f)), encoding="utf-8")
            written += 1
        else:
            empty += 1
        mark.mark(str(f), sig)
    if not args.dry_run:
        mark.save()
    print(f"claude: {written} written, {empty} empty, {len(files)} sessions seen"
          + (" (dry run)" if args.dry_run else f" -> {args.dest}"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
