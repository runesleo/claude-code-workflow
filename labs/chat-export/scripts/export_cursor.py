#!/usr/bin/env python3
"""Export Cursor conversations (app composer + cursor-agent CLI) to one markdown file per conversation.

Two local stores, both opened read-only:
  app: <Cursor user dir>/globalStorage/state.vscdb. composerData:<id> lists bubble ids in order;
       bubbleId:<id>:<bubble> holds type 1 (user) / type 2 (assistant) text.
  cli: ~/.cursor/chats/<workspace>/<agent>/store.db. Content-addressed blobs; the root blob named in
       meta lists message hashes in order.
"""
import argparse
import datetime as dt
import json
import platform
import re
import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import DEST_ROOT, Watermark, file_sig, group_turns, render  # noqa: E402

if platform.system() == "Darwin":
    APP_DB = Path.home() / "Library/Application Support/Cursor/User/globalStorage/state.vscdb"
else:
    APP_DB = Path.home() / ".config/Cursor/User/globalStorage/state.vscdb"
CLI_ROOT = Path.home() / ".cursor/chats"
DEST = DEST_ROOT / "cursor"

QUERY = re.compile(r"<user_query>\s*(.*?)\s*</user_query>", re.S)
INJECTED = re.compile(r"<(user_info|timestamp|system_reminder|system_notification|attached_files|rules)>.*?</\1>", re.S)


def ro(path):
    return sqlite3.connect(f"file:{path}?mode=ro", uri=True)


def clean_user(text):
    m = QUERY.search(text)
    return (m.group(1) if m else INJECTED.sub("", text)).strip()


def content_text(content):
    if isinstance(content, str):
        return content
    if not isinstance(content, list):
        return ""
    return "\n".join(p["text"] for p in content
                     if isinstance(p, dict) and p.get("type") == "text" and isinstance(p.get("text"), str))


def iso(ms):
    return dt.datetime.fromtimestamp(ms / 1000).isoformat(timespec="seconds") if ms else ""


def cli_conversation(store):
    db = ro(store)
    meta = json.loads(bytes.fromhex(db.execute("SELECT value FROM meta WHERE key='0'").fetchone()[0]))
    blobs = dict(db.execute("SELECT id, data FROM blobs"))
    root = bytes(blobs.get(meta.get("latestRootBlobId"), b""))
    ordered = sorted((pos, bid) for bid in blobs if (pos := root.find(bytes.fromhex(bid))) >= 0)
    messages = []
    for _, bid in ordered:
        data = bytes(blobs[bid])
        if not data.startswith(b"{"):
            continue
        try:
            msg = json.loads(data)
        except json.JSONDecodeError:
            continue
        role, text = msg.get("role"), content_text(msg.get("content"))
        if role in ("user", "assistant"):
            messages.append((role, clean_user(text) if role == "user" else text))
    return meta, group_turns(messages)


def export_cli(cli_root, dest, mark, dry_run):
    written = 0
    for store in sorted(cli_root.glob("*/*/store.db")):
        sig, key = file_sig(store, store.with_name("store.db-wal")), f"cli:{store}"
        if mark.unchanged(key, sig):
            continue
        try:
            meta, turns = cli_conversation(store)
        except (sqlite3.Error, ValueError, TypeError, KeyError) as exc:
            print(f"  cli read error {store.parent.name}: {type(exc).__name__}", file=sys.stderr)
            continue
        if turns:
            try:
                cwd = json.loads((store.parent / "meta.json").read_text()).get("cwd", "")
            except (OSError, json.JSONDecodeError):
                cwd = ""
            name = meta.get("name") if meta.get("name") not in (None, "New Agent") else ""
            when = iso(meta.get("createdAt"))
            if not dry_run:
                (dest / "cli").mkdir(parents=True, exist_ok=True)
                (dest / "cli" / f"{when[:10] or 'undated'}-{store.parent.name}.md").write_text(render(
                    "cursor-cli", store.parent.name, turns, title=name or "", timestamp=when, cwd=cwd,
                    source_file=str(store)), encoding="utf-8")
            written += 1
        mark.mark(key, sig)
    return written


def export_app(app_db, dest, mark, dry_run):
    if not app_db.exists():
        return 0
    db = ro(app_db)
    written = 0
    for key, value in db.execute("SELECT key, value FROM cursorDiskKV WHERE key LIKE 'composerData:%'"):
        try:
            data = json.loads(value)
        except (TypeError, json.JSONDecodeError):
            continue
        headers = data.get("fullConversationHeadersOnly") or []
        cid = key.split(":", 1)[1]
        sig = f"{len(headers)}:{data.get('lastUpdatedAt') or ''}"
        if not headers or mark.unchanged(f"app:{cid}", sig):
            continue
        messages = []
        for h in headers:
            row = db.execute("SELECT value FROM cursorDiskKV WHERE key=?",
                             (f"bubbleId:{cid}:{h.get('bubbleId')}",)).fetchone()
            if not row:
                continue
            bubble = json.loads(row[0])
            role = {1: "user", 2: "assistant"}.get(bubble.get("type"))
            if role:
                text = bubble.get("text") or ""
                messages.append((role, clean_user(text) if role == "user" else text))
        turns = group_turns(messages)
        if turns:
            when = iso(data.get("createdAt"))
            if not dry_run:
                (dest / "app").mkdir(parents=True, exist_ok=True)
                (dest / "app" / f"{when[:10] or 'undated'}-{cid}.md").write_text(render(
                    "cursor-app", cid, turns, title=data.get("name") or "", timestamp=when,
                    source_file=f"{app_db}#{cid}"), encoding="utf-8")
            written += 1
        mark.mark(f"app:{cid}", sig)
    return written


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--app-db", type=Path, default=APP_DB)
    ap.add_argument("--cli-root", type=Path, default=CLI_ROOT)
    ap.add_argument("--dest", type=Path, default=DEST)
    ap.add_argument("--full", action="store_true", help="ignore the watermark and reprocess everything")
    ap.add_argument("--dry-run", action="store_true", help="report only, write nothing")
    args = ap.parse_args(argv)
    mark = Watermark(args.dest, args.full)
    cli = export_cli(args.cli_root, args.dest, mark, args.dry_run)
    app = export_app(args.app_db, args.dest, mark, args.dry_run)
    if not args.dry_run:
        mark.save()
    print(f"cursor: {app} app + {cli} cli conversations written"
          + (" (dry run)" if args.dry_run else f" -> {args.dest}"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
