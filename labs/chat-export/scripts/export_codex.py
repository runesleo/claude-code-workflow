#!/usr/bin/env python3
"""Export Codex sessions to one markdown file per conversation.

Two sources, read-only:
  1. Codex's thread-history SQLite (newer Codex). It stores each turn's prompt and FINAL answer,
     even after rollout files are pruned. Preferred when present.
  2. rollout-*.jsonl under ~/.codex/sessions, for sessions the history db does not cover.

The trap this handles: newer Codex writes several assistant messages per turn (progress notes,
then the answer). An exporter that keeps only the first reply saves "let me look" and loses
every conclusion.
"""
import argparse
import datetime as dt
import hashlib
import json
import re
import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import DEST_ROOT, Watermark, file_sig, group_turns, render  # noqa: E402

CODEX_HOME = Path.home() / ".codex"
DEST = DEST_ROOT / "codex"

# Codex folds plugin lists, the whole AGENTS.md and environment context into the first user
# message. Left in, every session carries a copy of AGENTS.md and floods keyword search.
BOILERPLATE = [re.compile(rf"<{tag}>.*?</{tag}>", re.S) for tag in (
    "recommended_plugins", "INSTRUCTIONS", "environment_context", "user_instructions")]
BOILERPLATE.append(re.compile(r"^#\s*AGENTS\.md instructions for .*$", re.M))


def strip_boilerplate(text):
    for pattern in BOILERPLATE:
        text = pattern.sub("", text)
    return text.strip()


def content_text(content):
    if isinstance(content, str):
        return content
    if not isinstance(content, list):
        return ""
    return "\n".join(p["text"] for p in content if isinstance(p, dict) and isinstance(p.get("text"), str))


def parse_rollout(path):
    meta, messages = {}, []
    for line in path.open(encoding="utf-8", errors="replace"):
        try:
            rec = json.loads(line)
        except json.JSONDecodeError:
            continue
        payload = rec.get("payload")
        if not isinstance(payload, dict):
            continue
        if rec.get("type") == "session_meta" and not meta:
            meta = {"session_id": payload.get("session_id") or payload.get("id"), "cwd": payload.get("cwd"),
                    "timestamp": payload.get("timestamp") or rec.get("timestamp")}
        elif rec.get("type") == "response_item" and payload.get("type") == "message":
            role = payload.get("role")        # "developer" is the injected system prompt, not conversation
            if role in ("user", "assistant"):
                text = content_text(payload.get("content"))
                messages.append((role, strip_boilerplate(text) if role == "user" else text))
    return meta, group_turns(messages)


def newest(pattern):
    """Codex bumps the db file number on schema changes (state_5.sqlite ...): take the highest."""
    def version(p):
        m = re.search(r"_(\d+)\.sqlite$", p.name)
        return int(m.group(1)) if m else -1
    found = sorted(CODEX_HOME.glob(pattern), key=version)
    return found[-1] if found else None


def ro(path):
    return sqlite3.connect(f"file:{path}?mode=ro", uri=True)


def item_text(item_json):
    try:
        item = json.loads(item_json)
    except (TypeError, json.JSONDecodeError):
        return ""
    return item["text"] if isinstance(item.get("text"), str) else content_text(item.get("content"))


def export_threads(dest, mark, dry_run, thread_db, state_db):
    """Return the set of thread ids the history db covers, and how many files were written."""
    if not thread_db or not thread_db.exists():
        return set(), 0
    db = ro(thread_db)
    # Cheap per-thread signature first; item bodies are read only for threads that changed.
    sigs = {tid: f"{n}:{last}:{fin}" for tid, n, last, fin in db.execute(
        "SELECT thread_id, count(*), max(rollout_ordinal), max(final_agent_item_id) FROM thread_turns "
        "WHERE first_user_item_id IS NOT NULL AND final_agent_item_id IS NOT NULL GROUP BY thread_id")}
    changed = [tid for tid, sig in sigs.items() if not mark.unchanged(f"thread:{tid}", sig)]
    rows = []
    for i in range(0, len(changed), 500):
        chunk = changed[i:i + 500]
        rows += db.execute(
            "SELECT t.thread_id, t.started_at, u.item_json, a.item_json FROM thread_turns t "
            "JOIN thread_items u ON u.thread_id = t.thread_id AND u.item_id = t.first_user_item_id "
            "JOIN thread_items a ON a.thread_id = t.thread_id AND a.item_id = t.final_agent_item_id "
            f"WHERE t.thread_id IN ({','.join('?' * len(chunk))}) ORDER BY t.thread_id, t.rollout_ordinal",
            chunk).fetchall()
    info, children = {}, set()
    if state_db and state_db.exists():
        sdb = ro(state_db)
        info = {r[0]: {"title": r[1], "cwd": r[2], "created_at": r[3]}
                for r in sdb.execute("SELECT id, title, cwd, created_at FROM threads")}
        children = {r[0] for r in sdb.execute("SELECT child_thread_id FROM thread_spawn_edges")}
    by_thread = {}
    for tid, started, user_json, final_json in rows:
        if tid in children:
            continue      # subagent threads: the parent's final answer already carries their result
        user, final = strip_boilerplate(item_text(user_json)), item_text(final_json).strip()
        if user and final:
            by_thread.setdefault(tid, []).append({"user": user, "assistant": [final], "started": started or 0})
    written = 0
    for tid, turns in by_thread.items():
        meta = info.get(tid, {})
        created = meta.get("created_at") or turns[0]["started"]
        if created and created > 1e11:
            created /= 1000          # milliseconds
        date = dt.datetime.fromtimestamp(created).strftime("%Y-%m-%d") if created else "undated"
        if not dry_run:
            (dest / "threads").mkdir(parents=True, exist_ok=True)
            (dest / "threads" / f"{date}-{tid}.md").write_text(render(
                "codex-thread", tid, turns, title=(meta.get("title") or "").replace("\n", " "),
                timestamp=date, cwd=meta.get("cwd") or "", source_file=f"{thread_db}#{tid}"), encoding="utf-8")
        written += 1
    for tid in changed:
        mark.mark(f"thread:{tid}", sigs[tid])
    return set(sigs) - children, written


def rendered_source(path):
    try:
        m = re.search(r"^source_file: (.+)$", path.read_text(encoding="utf-8", errors="replace")[:2000], re.M)
    except OSError:
        return None
    return m.group(1).strip() if m else None


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--src", type=Path, default=CODEX_HOME / "sessions", help="rollout directory")
    ap.add_argument("--thread-db", type=Path, default=None, help="default: newest ~/.codex/thread_history_*.sqlite")
    ap.add_argument("--state-db", type=Path, default=None, help="default: newest ~/.codex/state_*.sqlite")
    ap.add_argument("--no-threads", action="store_true", help="only export rollout files")
    ap.add_argument("--dest", type=Path, default=DEST)
    ap.add_argument("--full", action="store_true", help="ignore the watermark and reprocess everything")
    ap.add_argument("--dry-run", action="store_true", help="report only, write nothing")
    args = ap.parse_args(argv)

    mark = Watermark(args.dest, args.full)
    covered, thread_written = set(), 0
    if not args.no_threads:
        covered, thread_written = export_threads(
            args.dest, mark, args.dry_run,
            args.thread_db or newest("thread_history_*.sqlite"), args.state_db or newest("state_*.sqlite"))

    files = sorted(args.src.rglob("rollout-*.jsonl"))
    written = skipped = 0
    for f in files:
        sig = file_sig(f)
        if mark.unchanged(str(f), sig):
            continue
        meta, turns = parse_rollout(f)
        if turns and meta.get("session_id") not in covered:
            if not args.dry_run:
                args.dest.mkdir(parents=True, exist_ok=True)
                # One session id spans many rollout files (resume/continue): name by the rollout's own id,
                # or siblings silently overwrite each other.
                rollout_id = f.stem.split("-")[-1][:8]
                date = (meta.get("timestamp") or "")[:10] or "undated"
                out = args.dest / f"{date}-{(meta.get('session_id') or 'nosid')[:8]}-{rollout_id}.md"
                if out.exists() and rendered_source(out) != str(f):
                    out = out.with_name(out.stem + "-" + hashlib.sha1(str(f).encode()).hexdigest()[:6] + ".md")
                out.write_text(render("codex", meta.get("session_id") or f.stem, turns,
                                      timestamp=meta.get("timestamp") or "", cwd=meta.get("cwd") or "",
                                      source_file=str(f)), encoding="utf-8")
            written += 1
        else:
            skipped += 1
        mark.mark(str(f), sig)
    if not args.dry_run:
        mark.save()
    print(f"codex: {thread_written} threads from history db, {written} rollouts written, "
          f"{skipped} skipped (empty or covered), {len(files)} rollouts seen"
          + (" (dry run)" if args.dry_run else f" -> {args.dest}"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
