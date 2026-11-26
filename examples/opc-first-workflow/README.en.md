# OPC First Workflow — synthetic replay (experimental)

[中文](README.md) · English

A deterministic replay of a fictional signal into a research brief and an unpublished draft. Two independent Python processes demonstrate worker handoff using the existing OPC verifier. No model calls, credentials, network calls or publication. Fixture-supplied content and integrity checks do not establish semantic truth.

From the repository root:

```bash
out="$(mktemp -d)/opc-output"
printf 'Keep this output path: %s\n' "$out"
python3 examples/opc-first-workflow/run.py --out "$out"
python3 examples/opc-first-workflow/test.py
```

Demonstrate interruption and recovery:

```bash
out="$(mktemp -d)/opc-output"
printf 'Keep this output path: %s\n' "$out"
python3 examples/opc-first-workflow/run.py --out "$out" --phase prepare --simulate-failover
# Expected exit 75; checkpoint/ retains the brief, task, handoff and integrity metadata.
python3 examples/opc-first-workflow/run.py --out "$out" --phase resume
# Expected exit 0 with OPC_FIRST_WORKFLOW_PASS.
```

Alternatively, pass `--simulate-failover` without specifying a phase to run both steps. Use a new output directory for the initial run. The second process validates the sample, research digest and task identity, accepts the synthetic handoff and generates the brief, draft, decision, artifact manifest, failover snapshot, final task and receipt. Only after all checks pass does it atomically rename the staged directory to `result/`. The final task status is `archived`; the preparation receipt outcome is `completed`, not publication authorization.

A failure before the atomic commit may leave `checkpoint/` without creating `result/`; an existing result cannot be resumed again. A successful run exits zero and prints `OPC_FIRST_WORKFLOW_PASS`; tests print `FIRST_WORKFLOW_FOCUSED_TESTS_OK`.

### Lost acknowledgement after commit: reconcile before replaying

A nonzero exit or missing success marker does not establish that the result was never committed. Record and retain each run's `$out` path before starting (as shown above), so you can recover it after losing the terminal. If you used the root README's quick-start command and cannot establish the original output directory, do not guess or reconcile another run's result; preserve the state and mark it as requiring verification. Once the previous worker has stopped, set `$out` to the recorded original path and inspect it:

- No `result/` and a complete `checkpoint/` (containing `checkpoint.json`, `task.json`, `handoff.json`, `research.md`): resume the original task with the original sample using the `--phase resume` command above; the built-in checks must still pass. If the checkpoint is missing or incomplete, or resume is rejected, preserve the state, mark it as requiring verification and do not replay automatically.
- `result/` already exists: do not replay the same task in a new directory or overwrite the existing artifacts. Use the original directory, its checkpoint and the existing read-only strict verifier:

```bash
python3 labs/opc-company/scripts/opc.py verify \
  --task "$out/result/task.json" \
  --receipt "$out/result/receipt.json" \
  --strict-proof --artifact-root "$out/result" \
  --manifest "$out/result/artifact-manifest.json" \
  --handoff "$out/checkpoint/handoff.json"
```

Exit zero with `OPC_VERIFY_PASS scope=local_artifacts_and_ack` revalidates the manifest-listed local artifacts and handoff acknowledgement, allowing you to reconcile the committed result. If verification fails or evidence is missing, preserve the state, mark it as requiring verification and do not replay automatically. This does not establish the integrity of every file in the result directory, real model collaboration, semantic truth or external effects, and is not publication authorization.

This is a real local process test of simulated interruption and handoff acknowledgement, not independent model collaboration or editorial review. Attention Inbox is integrated into the offline example; live Agent runs are not yet verified.

## Founder attention

After OPC verification, the example calls the existing Attention Inbox `batch` command. Three local outputs are added: `publish-gate.json` (synthetic release review gate, OPEN), `attention-events.jsonl` (four synthetic events) and `attention-output.txt` (original CLI output). The gate references the draft SHA256 and is not publication authorization.

Expected output:

```text
SUPPRESS reason=no_concrete_user_decision
SUPPRESS reason=routine_completion
ACTION_REQUIRED task=synthetic-ai-tool-trial gate=synthetic_publish_review
SUPPRESS reason=duplicate event=synthetic-ai-tool-trial:review-duplicate
```

This demonstrates internal waiting, routine completion, synthetic human review and deduplication of the same revision within one batch. There is no real notification, approval execution, or persistent deduplication across runs. No action publishes anything. Invalid events fail verification, leaving the checkpoint without committing `result/`.
