#!/usr/bin/env python3
"""Export Grok Bot desktop-app conversations (macOS) to one markdown file per conversation.

Grok Bot has no export API, but the desktop app keeps a plaintext replica of each conversation in
~/Library/Application Support/Grok Bot/sand-client-persistence/<base32 name>.blob. The slice named
`...transcript.replicas.<conversation-id>` is the conversation. Read-only; never touches the app.

Scope: only what this machine's app replica holds (not grok.com web chats).

Each blob has a binary header followed by JSON objects. Both kinds are needed, or you only see
half the conversation:
  {"kind":"message", "role":"user", "content":"..."}                  your messages
  {"kind":"send-message", "message":{"type":"text","content":"..."}}  Grok's replies
"""
import argparse
import base64
import datetime as dt
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import DEST_ROOT, Watermark, file_sig, group_turns, render  # noqa: E402

BLOB_DIR = Path.home() / "Library/Application Support/Grok Bot/sand-client-persistence"
DEST = DEST_ROOT / "grok"
MARKER = ".transcript.replicas."
START = re.compile(r'\{"kind":\s*"(?:message|send-message)"')


def decode_name(path):
    name = path.name[:-5] if path.name.endswith(".blob") else path.name
    try:
        return base64.b32decode(name.upper() + "=" * (-len(name) % 8)).decode("utf-8", "replace")
    except ValueError:
        return ""


def balanced_end(raw, start):
    """Index of the brace closing the JSON object that opens at `start`, string-aware."""
    depth, in_str, esc = 0, False, False
    for i in range(start, len(raw)):
        c = raw[i]
        if in_str:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
        elif c == '"':
            in_str = True
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return i
    return len(raw) - 1


def extract_messages(path):
    raw = path.read_bytes().decode("utf-8", "replace")
    msgs = []
    for m in START.finditer(raw):
        try:
            obj = json.loads(raw[m.start():balanced_end(raw, m.start()) + 1])
        except json.JSONDecodeError:
            continue
        if obj.get("kind") == "send-message":
            role, body = "assistant", (obj.get("message") or {}).get("content")
        else:
            role, body = obj.get("role"), obj.get("content")
        if isinstance(body, str) and body.strip():
            msgs.append({"role": role, "content": body, "ts": obj.get("timestampMs")})
    msgs.sort(key=lambda x: x["ts"] or 0)
    return msgs


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--blob-dir", type=Path, default=BLOB_DIR)
    ap.add_argument("--dest", type=Path, default=DEST)
    ap.add_argument("--full", action="store_true", help="ignore the watermark and reprocess everything")
    ap.add_argument("--dry-run", action="store_true", help="report only, write nothing")
    args = ap.parse_args(argv)

    mark = Watermark(args.dest, args.full)
    blobs = [(b, decode_name(b)) for b in sorted(args.blob_dir.glob("*.blob"))]
    blobs = [(b, name) for b, name in blobs if MARKER in name]
    written = 0
    for blob, name in blobs:
        sig = file_sig(blob)
        if mark.unchanged(str(blob), sig):
            continue
        messages = extract_messages(blob)
        turns = group_turns([(m["role"], m["content"]) for m in messages])
        if turns:
            conv_id = name.rsplit(MARKER, 1)[1]
            first = next((m["ts"] for m in messages if m["ts"]), None)
            when = dt.datetime.fromtimestamp(first / 1000).isoformat(timespec="seconds") if first else ""
            if not args.dry_run:
                args.dest.mkdir(parents=True, exist_ok=True)
                (args.dest / f"{when[:10] or 'undated'}-{conv_id}.md").write_text(render(
                    "grok-bot", conv_id, turns, timestamp=when, source_file=str(blob)), encoding="utf-8")
            written += 1
        mark.mark(str(blob), sig)
    if not args.dry_run:
        mark.save()
    print(f"grok: {written} written, {len(blobs)} conversations seen"
          + (" (dry run)" if args.dry_run else f" -> {args.dest}"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
