# Session Hooks Lab

[中文](README.md) · **English**

Three Claude Code hooks for the three ways long-running agent sessions drift: titles that no longer match the work, no idea which sessions can be closed, and decisions only you can make that nobody brings up.

> Experimental, not a prerequisite for QuietHarness. Python 3 standard library only, no network, no login. The hooks only add text to the model's context; they never rename sessions, archive anything or close your to-dos for you.

| Hook | Event | Problem |
|---|---|---|
| [`session_title_nudge.py`](hooks/session_title_nudge.py) | UserPromptSubmit | The work moved on, the title is still the auto-generated first line |
| [`archive_readiness_nudge.py`](hooks/archive_readiness_nudge.py) | Stop | Sessions pile up and you cannot tell which are done |
| [`needs_me_surface.py`](hooks/needs_me_surface.py) | SessionStart + UserPromptSubmit | Scripts and agents write down "needs your decision" items that nobody reads |

## Try it once

```bash
cd labs/session-hooks
python3 tests/run.py          # throwaway dirs only; never touches your real Claude Code state

# Feed a Stop event by hand and see how it blocks
echo '{"last_assistant_message":"Done, tests pass."}' | python3 hooks/archive_readiness_nudge.py
```

## Install

```bash
mkdir -p ~/.claude/hooks
cp hooks/*.py ~/.claude/hooks/
cp examples/needs-me.example.md ~/.claude/needs-me.md   # only for the third hook; then replace with your own items
```

Merge `env` and `hooks` from [`examples/settings.example.json`](examples/settings.example.json) into `~/.claude/settings.json` (append to existing events, do not overwrite them). The hooks are independent; install any subset.

One language switch for all three: `SESSION_HOOKS_LANG=en` or `zh` (default `en`).

---

## 1. Session title nudge — `session_title_nudge.py`

**Problem.** A session starts as "look at this link" and turns into fixing a deploy script, but the title stays on the first line. The longer the session list, the less you can find. A "retitle when the topic changes" line in CLAUDE.md is a soft rule nobody executes.

**What it does.** On the 2nd prompt, then at most once per interval (default 60 minutes), it adds one note to the model's context: if the main thread changed, retitle with 2-4 keywords, separate parallel threads with ` · ` and put the newest first; ask before renaming a title you set yourself; otherwise ignore it silently. The model decides; the hook changes nothing.

**Which tool it suggests.** In the desktop app (`CLAUDE_CODE_ENTRYPOINT=claude-desktop`) it suggests `set_session_title(session_id="self")`. Sessions started from phone or web (`CLAUDE_CODE_ENVIRONMENT_KIND=bridge`) do not accept `self`, so it suggests `get_session()` first to get the session id. Plain terminal sessions have no known title tool and stay silent unless you set `TITLE_NUDGE_TOOL_HINT`.

| Env var | Default | Effect |
|---|---|---|
| `TITLE_NUDGE_MINUTES` | `60` | Minimum minutes between nudges |
| `TITLE_NUDGE_FIRST` | `2` | First prompt number that can nudge |
| `TITLE_NUDGE_TOOL_HINT` | empty | Your own "how to retitle" text; when set, nudges in any session |
| `TITLE_NUDGE_STATE_DIR` | `~/.local/state/claude-session-hooks/title-nudge` | Per-session counters, removed after 7 idle days |
| `TITLE_NUDGE_DISABLED` | empty | `1` turns it off |

**Limits.** Hooks only fire when you send a message, so idle sessions are not checked. It nudges the model, which can still judge wrong.

---

## 2. Archive check — `archive_readiness_nudge.py`

**Problem.** After a dozen sessions a day you cannot tell which ones delivered, which wait on a decision and which were handed to someone else. Guessing from titles or last activity is often wrong: a finished sub-step is not a finished session.

**What it does.** When the model is about to end its turn, the hook checks the last line. It must be one of these, or the Stop hook returns `block` and asks for it:

```text
Archive check: ready (delivered and verified, nothing left)
Archive check: not yet (waiting for you to pick an option)
Archive check: hand off (moved to the docs task, receipt to verify)
```

The Chinese form `归档检查：可以归档 / 暂不归档 / 待交接` is accepted too, regardless of the language switch. The judgment covers the whole session: real deliverables, open decisions, running work and existing hand-off receipts. If the host includes `background_tasks` in the event and one is still running, "ready" is blocked as well.

It is only a one-line reminder: it does not archive, read history, look at time or titles, or schedule anything.

| Env var | Default | Effect |
|---|---|---|
| `SESSION_HOOKS_LANG` | `en` | Language of the instruction text |
| `ARCHIVE_CHECK_DISABLED` | empty | `1` turns it off |

**Limits.** Needs `last_assistant_message` in the Stop event; if the host does not send it, the hook lets the turn end. With `stop_hook_active=true` it never blocks again, to avoid loops, so a second miss goes through. `background_tasks` is not present in every version. It adds one line to every final answer; skip it if you do not want that.

---

## 3. "Needs me" checklist — `needs_me_surface.py`

**Problem.** Some things only you can decide: approve a cost, choose a direction, log in to a service again. Scripts and agents write them into some file and nobody looks, or each AI keeps its own copy and nags twice.

**What it does.** It reads exactly one Markdown checklist (default `~/.claude/needs-me.md`), one item per line, takes only unchecked `- [ ]` lines and injects them into the model's context:

```text
[needs-me / candidate coverage] open_count=3; returned_count=3; remaining_new_count=0; event=SessionStart. ...
- [3f1c…] Approve or reject the $20/month upgrade for the staging database. Source: weekly-cost-report
...
```

and tells the model to:
- put every returned item into exactly one bucket: `AI_SELF_HANDLE` (the AI can do it), `HUMAN_DECISION` (verified, really needs you), `WAIT_TRIGGER` (waiting on something external), `STALE_OR_DUPLICATE`. **The four counts must add up to returned_count**; mark what it cannot verify `UNKNOWN`, and never mention one item while dropping the rest;
- show you only what really needs your decision, briefly; do what the AI can do first, with a receipt;
- treat injection as not the same as you having seen it, and never close an item because of it. Only you (or the process that owns the item) tick the box in the file.

**Dedup.** Each item gets a 16-hex fingerprint of its text; anything after `Source:` / `来源：` is ignored, so re-attributing an item does not make it new. Within a session, already-injected items do not repeat; `SessionStart` re-surfaces everything still open. At most 40 per injection; the rest is reported as `remaining_new_count` and comes with the next prompt.

**Failure is never "nothing to do".** Checklist missing: treated as not configured, silent. Checklist present but unreadable (symlink, over 256 KB, not UTF-8): it injects `SOURCE_UNAVAILABLE; open_count=UNKNOWN` and tells the model not to claim there is nothing open.

| Env var | Default | Effect |
|---|---|---|
| `NEEDS_ME_PATH` | `~/.claude/needs-me.md` | The checklist |
| `NEEDS_ME_SEEN_DIR` | `~/.local/state/claude-session-hooks/needs-me-seen` | Per-session injection record, removed after 7 idle days |
| `NEEDS_ME_MAX_EMIT` | `40` | Max items per injection |
| `NEEDS_ME_SOURCE_MARKERS` | `来源：\|Source:` | Markers whose trailing text is ignored for fingerprints, `\|`-separated |
| `SESSION_HOOKS_LANG` | `en` | Language of the instruction text |

Format: [`examples/needs-me.example.md`](examples/needs-me.example.md).

**Limits.** Checklist text goes into the model's context as-is. The hook labels it untrusted input, but do not put secrets or text other people can write in it. It only works while a Claude Code session is running; it does not push notifications when no session is open, so wire your own channel for phone alerts. The buckets come from the model; the hook can require that the counts add up, not that each item was sorted correctly.

## What it is not

Not a task system, a reminder service or an archiving tool. Each hook does one thing: put one rule in front of the model at the right moment. Your files and task records stay the source of truth.
