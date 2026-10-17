"""Shared pieces for the chat exporters: turn grouping, redaction, markdown rendering, watermark."""
import json
import os
import re
from pathlib import Path

# Exports are private conversations: every directory and file this process creates is owner-only.
os.umask(0o077)

DEST_ROOT = Path.home() / ".local/share/chat-export"

# A turn this large is almost always a pasted log or file; skip it rather than cut it mid-thought.
MAX_TURN_CHARS = 60_000

# Credentials are redacted before anything touches disk. Most specific patterns first.
REDACTIONS = [
    (re.compile(r"0x[a-fA-F0-9]{64}\b"), "<REDACTED_PRIVKEY>"),
    (re.compile(r"\bsk-[A-Za-z0-9_\-]{20,}"), "<REDACTED_APIKEY>"),
    (re.compile(r"\bghp_[A-Za-z0-9]{20,}"), "<REDACTED_GHTOKEN>"),
    (re.compile(r"\bgithub_pat_[A-Za-z0-9_]{20,}"), "<REDACTED_GHTOKEN>"),
    (re.compile(r"\bAKIA[0-9A-Z]{16}\b"), "<REDACTED_AWSKEY>"),
    (re.compile(r"\bxox[baprs]-[A-Za-z0-9\-]{10,}"), "<REDACTED_SLACK>"),
    (re.compile(r"(?i)\b(bearer)\s+[A-Za-z0-9._\-]{20,}"), r"\1 <REDACTED>"),
    (re.compile(r"(?i)\b([A-Z0-9_]*(?:SECRET|PASSWORD|PRIVATE_KEY|API_KEY|TOKEN)[A-Z0-9_]*)\s*=\s*\S+"),
     r"\1=<REDACTED>"),
    (re.compile(r"[A-Za-z0-9+/]{300,}={0,2}"), "<REDACTED_BLOB>"),
]


def redact(text):
    for pattern, repl in REDACTIONS:
        text = pattern.sub(repl, text)
    return text


def group_turns(messages):
    """messages: [(role, text)] in order. A user text opens a turn; every reply until the next user text
    belongs to it. Keeping all replies matters: newer agents stream progress notes before the final answer."""
    turns, current = [], None
    for role, text in messages:
        text = (text or "").strip()
        if not text:
            continue
        if role == "user":
            if current and current["assistant"]:
                turns.append(current)
            current = {"user": text, "assistant": []}
        elif role == "assistant" and current is not None:
            current["assistant"].append(text)
    if current and current["assistant"]:
        turns.append(current)
    return turns


def render(source, session_id, turns, *, title="", timestamp="", cwd="", source_file=""):
    lines = [
        "---",
        f"session_id: {session_id}",
        f"source: {source}",
        f"title: {json.dumps(title or '', ensure_ascii=False)}",
        f"timestamp: {timestamp or ''}",
        f"cwd: {cwd or ''}",
        f"turns: {len(turns)}",
        f"source_file: {source_file}",
        "---",
        "",
        f"# {source} {title or str(session_id)[:8]}",
        "",
    ]
    for i, turn in enumerate(turns, 1):
        assistant = "\n\n".join(turn["assistant"])
        if len(turn["user"]) + len(assistant) > MAX_TURN_CHARS:
            lines.append(f"## Turn {i} (skipped: exceeds {MAX_TURN_CHARS} chars)\n")
            continue
        lines += [f"## Turn {i}", "", "**User:**", "", redact(turn["user"]), "",
                  "**Assistant:**", "", redact(assistant), ""]
    return "\n".join(lines)


def file_sig(*paths):
    """mtime+size of each existing path: cheap change detection for the watermark."""
    return ":".join(f"{p.stat().st_mtime_ns}/{p.stat().st_size}" for p in paths if p.exists())


class Watermark:
    """Per-source {key: signature} file so reruns only touch what changed."""

    def __init__(self, dest, full=False):
        self.path = dest / ".watermark.json"
        try:
            self.state = {} if full else json.loads(self.path.read_text())
        except (OSError, json.JSONDecodeError):
            self.state = {}

    def unchanged(self, key, sig):
        return self.state.get(key) == sig

    def mark(self, key, sig):
        self.state[key] = sig

    def save(self):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(json.dumps(self.state, indent=0))
        # Tighten directories left world-readable by an earlier run; new ones already get 0700 from the umask.
        # Only the export dir itself and the default root; never a parent the user pointed --dest into.
        self.path.parent.chmod(0o700)
        if self.path.parent.parent == DEST_ROOT:
            DEST_ROOT.chmod(0o700)
