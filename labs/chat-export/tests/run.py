#!/usr/bin/env python3
"""Synthetic-fixture tests for the chat exporters. Python 3 stdlib only; never reads your real chats."""
import base64
import contextlib
import io
import json
import sqlite3
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import common  # noqa: E402
import export_claude  # noqa: E402
import export_codex  # noqa: E402
import export_cursor  # noqa: E402
import export_grok  # noqa: E402

KEY = "sk-" + "a" * 30


def expect(condition, message):
    if not condition:
        raise AssertionError(message)


def run(module, argv):
    with contextlib.redirect_stdout(io.StringIO()):
        expect(module.main(argv) == 0, f"{module.__name__} exited non-zero")


def only_md(dest):
    files = list(dest.rglob("*.md"))
    expect(len(files) == 1, f"expected one markdown file in {dest}, got {len(files)}")
    return files[0].read_text()


def jsonl(path, records):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in records) + "\n")



def fake_pem(kind, newline="\n"):
    """Not a real key: tiny base64-encoded plain text, assembled at runtime."""
    return newline.join((
        "-----" + "BEGIN " + kind + "-----",
        "QUJDREVGRw==",
        "SElKS0w=",
        "-----" + "END " + kind + "-----",
    ))


def test_redaction(tmp):
    # All private-key labels use complete BEGIN/END delimiters and short PEM lines.
    for kind in ("PRIVATE KEY", "RSA PRIVATE KEY", "EC PRIVATE KEY",
                 "DSA PRIVATE KEY", "OPENSSH PRIVATE KEY", "ENCRYPTED PRIVATE KEY"):
        text = "Intro\n" + fake_pem(kind) + "\nOutro"
        expect(common.redact(text) == "Intro\n<REDACTED_PRIVKEY>\nOutro",
               f"PEM {kind}: redact only the key block, retain surrounding text")

    crlf = "Before\r\n" + fake_pem("ENCRYPTED PRIVATE KEY", "\r\n") + "\r\nAfter"
    expect(common.redact(crlf) == "Before\r\n<REDACTED_PRIVKEY>\r\nAfter",
           "PEM: CRLF-encoded key must be redacted")

    separate = fake_pem("RSA PRIVATE KEY") + "\nkeep between\n" + fake_pem("RSA PRIVATE KEY")
    expect(common.redact(separate) == "<REDACTED_PRIVKEY>\nkeep between\n<REDACTED_PRIVKEY>",
           "PEM: separately redact adjacent keys without consuming other messages")

    orphan = "-----" + "BEGIN RSA PRIVATE KEY-----\nexample only\n"
    expect(common.redact(orphan + "keep\n" + fake_pem("RSA PRIVATE KEY")) ==
           orphan + "keep\n<REDACTED_PRIVKEY>",
           "PEM: unpaired example must not swallow a later complete key")

    ordinary = ("普通聊天不应消失。\n多行说明继续保留。\n"
                "-----BEGIN PUBLIC KEY-----\nQUJDREVGRw==\n-----END PUBLIC KEY-----")
    expect(common.redact(ordinary) == ordinary,
           "normal multiline text and public keys must be preserved")

    api = KEY + "\n" + "ghp_" + "b" * 30 + "\nAPI_KEY=fictional-value"
    expect(common.redact(api) ==
           "<REDACTED_APIKEY>\n<REDACTED_GHTOKEN>\nAPI_KEY=<REDACTED>",
           "existing API-key, GitHub-token and assignment redaction must remain")


def test_claude(tmp):
    jsonl(tmp / "src/proj/s1.jsonl", [
        {"type": "user", "sessionId": "s1", "timestamp": "2026-10-01T00:00:00Z", "cwd": "/w",
         "message": {"content": "<system-reminder>injected</system-reminder>How do I ship?"}},
        {"type": "assistant", "message": {"content": [{"type": "thinking", "thinking": "hidden"},
                                                      {"type": "text", "text": f"Use the key {KEY}"}]}},
        {"type": "user", "message": {"content": [{"type": "tool_result", "content": "tool noise"}]}},
        {"type": "assistant", "isSidechain": True, "message": {"content": [{"type": "text", "text": "subagent"}]}},
        {"type": "assistant", "message": {"content": [{"type": "text", "text":
                                                               "Then run tests.\n" + fake_pem("RSA PRIVATE KEY") + "\nDone."}]}},
    ])
    run(export_claude, ["--src", str(tmp / "src"), "--dest", str(tmp / "out")])
    text = only_md(tmp / "out")
    expect("How do I ship?" in text and "Then run tests." in text and "Done." in text,
           "claude: user prompt and both replies kept")
    expect("<REDACTED_PRIVKEY>" in text and "QUJDREVGRw==" not in text,
           "claude: PEM blocks must be removed before writing Markdown")
    for dropped in ("injected", "hidden", "tool noise", "subagent", KEY):
        expect(dropped not in text, f"claude: {dropped!r} should not be exported")
    # Watermark: an unchanged rerun writes nothing.
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        export_claude.main(["--src", str(tmp / "src"), "--dest", str(tmp / "out")])
    expect("0 written" in out.getvalue(), "claude: unchanged session must not be rewritten")
    md = next((tmp / "out").glob("*.md"))
    expect(md.stat().st_mode & 0o077 == 0, "claude: exported file must be owner-only")
    expect((tmp / "out").stat().st_mode & 0o077 == 0, "claude: export dir must be owner-only")


def test_codex_rollout_keeps_final_answer(tmp):
    msg = lambda role, text: {"type": "response_item", "payload": {"type": "message", "role": role,  # noqa: E731
                                                                   "content": [{"type": "text", "text": text}]}}
    jsonl(tmp / "sessions/rollout-2026-10-01-abcdef12.jsonl", [
        {"type": "session_meta", "payload": {"id": "sess-1", "cwd": "/w", "timestamp": "2026-10-01T00:00:00Z"}},
        msg("developer", "system prompt"),
        msg("user", "<environment_context>env</environment_context>Fix the bug"),
        msg("assistant", "Let me look first."),
        msg("assistant", "Final: the bug was an off-by-one."),
    ])
    run(export_codex, ["--src", str(tmp / "sessions"), "--no-threads", "--dest", str(tmp / "out")])
    text = only_md(tmp / "out")
    expect("Final: the bug was an off-by-one." in text, "codex: final answer after a progress note must survive")
    expect("system prompt" not in text and "env" not in text, "codex: scaffolding stripped")


def test_codex_thread_history(tmp):
    db = sqlite3.connect(tmp / "thread_history_1.sqlite")
    db.executescript(
        "CREATE TABLE thread_turns(thread_id, rollout_ordinal, started_at, first_user_item_id, final_agent_item_id);"
        "CREATE TABLE thread_items(thread_id, item_id, item_json);")
    db.execute("INSERT INTO thread_turns VALUES('t1', 1, 1790000000, 'u1', 'a1')")
    db.execute("INSERT INTO thread_items VALUES('t1', 'u1', ?)", (json.dumps({"text": "Plan the release"}),))
    db.execute("INSERT INTO thread_items VALUES('t1', 'a1', ?)", (json.dumps({"text": "Release plan: three steps"}),))
    db.commit()
    run(export_codex, ["--src", str(tmp / "none"), "--thread-db", str(tmp / "thread_history_1.sqlite"),
                       "--state-db", str(tmp / "missing.sqlite"), "--dest", str(tmp / "out")])
    text = only_md(tmp / "out")
    expect("Plan the release" in text and "Release plan: three steps" in text, "codex: thread history exported")


def test_cursor_app(tmp):
    db = sqlite3.connect(tmp / "state.vscdb")
    db.execute("CREATE TABLE cursorDiskKV(key, value)")
    db.execute("INSERT INTO cursorDiskKV VALUES('composerData:c1', ?)", (json.dumps({
        "name": "Refactor", "createdAt": 1790000000000, "lastUpdatedAt": 1,
        "fullConversationHeadersOnly": [{"bubbleId": "b1"}, {"bubbleId": "b2"}]}),))
    db.execute("INSERT INTO cursorDiskKV VALUES('bubbleId:c1:b1', ?)", (json.dumps(
        {"type": 1, "text": "<user_info>os</user_info><user_query>Rename the module</user_query>"}),))
    db.execute("INSERT INTO cursorDiskKV VALUES('bubbleId:c1:b2', ?)", (json.dumps({"type": 2, "text": "Renamed."}),))
    db.commit()
    run(export_cursor, ["--app-db", str(tmp / "state.vscdb"), "--cli-root", str(tmp / "none"),
                        "--dest", str(tmp / "out")])
    text = only_md(tmp / "out")
    expect("Rename the module" in text and "Renamed." in text and "user_info" not in text, "cursor: app chat exported")


def test_grok(tmp):
    name = "sand.client.slice.account.x.transcript.replicas.conv-1234abcd"
    blob = tmp / "blobs" / (base64.b32encode(name.encode()).decode().rstrip("=").lower() + ".blob")
    blob.parent.mkdir(parents=True)
    body = (json.dumps({"kind": "message", "role": "user", "content": "Question", "timestampMs": 1790000000000})
            + json.dumps({"kind": "send-message", "message": {"type": "text", "content": f"Answer {KEY}"},
                          "timestampMs": 1790000001000}))
    blob.write_bytes(b"\x00\x01header" + body.encode())
    run(export_grok, ["--blob-dir", str(tmp / "blobs"), "--dest", str(tmp / "out")])
    text = only_md(tmp / "out")
    expect("Question" in text and "Answer" in text and KEY not in text, "grok: both sides exported, key redacted")


def main():
    for test in (test_redaction, test_claude, test_codex_rollout_keeps_final_answer, test_codex_thread_history,
                 test_cursor_app, test_grok):
        with tempfile.TemporaryDirectory() as tmp:
            test(Path(tmp))
    print("CHAT_EXPORT_TEST_OK")


if __name__ == "__main__":
    main()
