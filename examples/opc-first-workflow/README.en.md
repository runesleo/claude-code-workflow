# OPC First Workflow — synthetic replay (experimental)

[中文](README.md) · English

A deterministic replay of a fictional signal into a research brief and an unpublished draft. It reuses the existing OPC receipt verifier. No model calls, credentials, network calls or publication. The content is supplied by the fixture; source reference and file integrity checks do not establish semantic truth.

From the repository root:

```bash
python3 examples/opc-first-workflow/run.py --out "$(mktemp -d)/opc-output"
python3 examples/opc-first-workflow/test.py
```

Use a new output directory. The replay produces six files: research.md, content-draft.md, decision.json, artifact-manifest.json, task.json and receipt.json. The existing OPC verifier must pass. Successful replay prints OPC_FIRST_WORKFLOW_PASS; tests print FIRST_WORKFLOW_FOCUSED_TESTS_OK.

This is a synthetic preparation-task receipt, not a production release or actual multi-agent execution. Failure leaves at most local diagnostic output; only exit zero and the success marker indicate successful replay. Worker failover, semantic handoff, Attention Inbox integration and live Agent runs are future increments.
