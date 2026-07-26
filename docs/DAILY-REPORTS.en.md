# Daily reports without daily rituals

[中文](DAILY-REPORTS.md) · **English**

My report, sync, and monitoring jobs still run after Morning, Today, and session-end workflows leave the interactive hot path.

The key is to separate **generation** from **consumption**.

## Recommended boundary

```text
scheduler or cron
    ↓
collect sources → transform → write dated artifact
    ↓
inbox/daily/YYYY-MM-DD.md
    ↓
read on demand / notify on exception / optional short push
```

The interactive agent does not need to regenerate the report, scan every backlog, or build a daily dashboard before answering an unrelated request.

## Delivery modes

### 1. Quiet pull — default

The job writes a dated file and stays silent on success.

Use this when the report is useful but not urgent. Open it directly or ask:

```text
Read today's daily report and return the three items that deserve action.
```

### 2. Exception notification

Stay quiet when generation succeeds. Send a local or external notification only when the report is missing, stale, or degraded.

This is a good default for high-volume feeds because success does not create another notification to clear.

### 3. Opt-in push

At a chosen time, push a short summary or a link to the artifact. Avoid sending the full report unless the destination is designed for long reading.

Public messages, account access, credentials, and scheduler changes should remain explicit operator decisions.

## A practical read contract

Keep the report schema small enough that any agent can inspect it:

```yaml
date: 2026-07-26
generated_at: 2026-07-26T07:32:00+08:00
status: ok | degraded | failed
source_count: 62
```

Then keep the body human-readable:

```markdown
# Daily report

## Worth acting on
## Worth watching
## Source-only
## Generation notes
```

If a model-dependent transformation fails, retain the raw or extractive artifact and mark it `degraded`. A file existing is not proof that every enrichment step succeeded.

## What v3 does not do

This repository does not ship a report generator or scheduler. It defines the boundary so an existing report can continue without becoming a mandatory startup workflow.

In my system, the Daily Rhythm line registers input, routes it to the correct business owner, manages the attention queue, and audits completion. It does not replace business owners or create work merely because a lane is idle.

In one sentence: a report may be generated every day without making a daily AI ritual the price of reading it. Write quietly by default, read when useful, notify on failure, and decide push delivery separately.
