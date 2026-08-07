# Session Closeout: turning a long conversation into something the next one can use

**English** · [中文](SESSION-CLOSEOUT.md)

When a long session ends, about 95% of it is worthless to the next one: stale context, abandoned approaches, errors and retries, judgments that were later overturned. The remaining 5% is what actually needs to survive — what changed, what is still open, who approved what.

Closeout is the act of extracting that 5% into files and discarding the rest.

I have run these six steps for over half a year. This is not "write a PROJECT_STATUS.md" — that document does not solve the problems below, and the last section explains why.

## Why saying it in the conversation is not enough

**Said is not written.** The next session is a fresh context; it cannot read this conversation. So "we decided to go with option B," if it only exists in chat, did not happen as far as the next session is concerned.

**Worse, the omission is silent.** Skipping a closeout step never throws. You will not notice at the time. You notice two weeks later, when nobody remembers why a decision was made or what a change was for.

So every step below is judged the same way: **did this step produce a file?** A step with no artifact did not happen, no matter how thoroughly it was discussed.

## The six steps

All three apps (Claude Code / Codex / Cursor) run the same protocol, because they share the same files.

### 1. Code or config changed → commit it, and say why

```bash
scripts/session-manifest-commit.sh --repo <repo> --files "<comma-separated>" --message "<why>"
```

**The problem it solves**: changes scattered across the working tree, with no way to tell later which ones were from this session or what they were for.

Write *why*, not *what* — the *what* is in the diff, the *why* is only in your head.

Skip it if nothing changed. Do not manufacture an empty commit to complete the checklist.

### 2. Open items must land on a task card

Unfinished work has exactly two destinations: some card's `next_action`, or a cross-line `inbox`.

**If you cannot name a destination, you are not allowed to say "remaining / to be confirmed / we'll revisit."** Either finish it now, or state plainly that it is being dropped and why. Dangling items are the single largest cost the next session pays.

⚠️ **Task cards must be written through a locking writer. Never `json.dump` over them.**

```bash
scripts/task-write.py append-inbox <TASK_ID> \
  --field <line>_inbox --entry-json <file> \
  --receipt-id <id> --input-id <id>
```

The lock is not defensive overkill. Task cards are inherently multi-writer — all three apps write the same files, and a "single writer by convention" rule cannot hold that. Measured on 2026-08-02: under 20 concurrent naive read-modify-writes, **one survived. 95% was lost.**

The same day produced a nastier variant: the body was swallowed by the race, but the receipt survived in `external_input_receipts`. Every receipt-based check then reported "delivered," while the card's owner opened it and found nothing — **with no error anywhere in the pipeline.**

So verify both halves after writing:

```bash
scripts/task-write.py verify <TASK_ID> --receipt-id <id>
# requires body_present AND receipt_present to both be true
```

Checking only the receipt gets fooled by that half-written state. Checking only the body fails the other way — if the receipt is missing, every receipt-based check reports "not delivered" while the body is sitting right there in the card. **Neither half throws. The verify return is the only thing that can tell them apart.**

### 3. A gate decision was made → append one precedent line

If this session produced an **explicit approval or rejection** on something that requires human sign-off (deploys, moving money, publishing, destructive cleanup), append a line to the precedent log:

```json
{"date":"...","gate":"...","subset":"...","decision":"approve|reject",
 "reason":"...","consistency_key":"<gate>.<subset phrase>","task":"...","approved_by":"..."}
```

**The problem it solves**: being asked the same class of question over and over. Once enough consistent precedents accumulate under one key, that decision can be proposed as a rule instead of interrupting a human each time.

No gate decision this session? Skip it. Do not invent one.

### 4. A durable artifact was produced → update the matching RECENT.md

**The problem it solves**: the "what happened recently" a session reads at startup. This file is the rollover point.

If there was none, write `recent_update: none` explicitly — **an explicit "none" and a silent omission are different things.** The former proves someone checked.

### 5. Write back to the daily log, and pick the real signals

Append to `daily/YYYY-MM-DD.md`: tasks touched, commits, items still in flight. Then scan this session's delta and pick **0–3** genuine signals for the findings section.

The cap of 3 is deliberate. Recording everything is the same as recording nothing — nobody reads it next time.

⚠️ **Run `date` before writing any date.** The date handed to you at session start is only correct at that instant. On a session that spans days it is simply wrong, and it looks completely normal. I have hit this: a session spanning four days wrote the wrong date into seven artifacts, including the daily filename itself — that day's log went into a file from three days earlier.

### 6. Self-check

```bash
scripts/session-leftover-guard.py --text "<your final message>"
```

It scans your closing message for dangling phrases — "to be confirmed," "we'll revisit," "remaining." If it fires, go back to step 2 and give those items a destination before closing.

## What it buys

- **The next session is productive from its first sentence**, with no need to re-read tens of thousands of tokens of context — whether the one picking it up is a different model or a different person.
- **Token consumption drops noticeably**, because the AI stops re-scanning dead ends that were already abandoned.
- **Cross-model handoff is nearly frictionless**: Codex → Claude → Cursor read the same files, so no handoff note is required.

## How this differs from "just write a PROJECT_STATUS.md"

A status document answers "where are we now." It does not answer these three:

| | Single status doc | This protocol |
|---|---|---|
| Concurrent writes across apps | Last write wins, data lost silently | flock + re-read inside the lock + atomic replace |
| Delivery confirmation | Written means delivered | receipt + two-sided verify; half-written state is detectable |
| Decision capture | Buried in prose, cannot be aggregated | Separate append-only precedent log, aggregatable by key |
| A skipped step | Goes unnoticed | Step 6 catches it |

The difference is not how detailed the document is. It is **whether anything enforces it**. However clearly a rule is written, if no step forces it to happen, it is just well-phrased text.

That is also why this protocol lives in files all three apps load, rather than under one app's workflow directory. An earlier version of mine made exactly that mistake: only one app could see the rule, so for a long time only one app was doing closeout while the other two quietly skipped it — **and skipping steps never throws.**

## Copying this

Start from the six steps. Then add two things of your own: **the lock** (step 2) and **cross-app consistency** (all three apps must read the same files). Without those two, the other four steps work fine for one person in one app, and start losing data the moment you open a second window.

Related: [Task continuity](TASK-CONTINUITY.en.md) · [Architecture](ARCHITECTURE.en.md) · [Daily reports](DAILY-REPORTS.en.md)
