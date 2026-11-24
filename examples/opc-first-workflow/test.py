#!/usr/bin/env python3
"""Isolated positive and negative checks of the deterministic replay."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("workflow", ROOT / "run.py")
workflow = importlib.util.module_from_spec(spec)
spec.loader.exec_module(workflow)


def expect_reject(fn):
    try:
        fn()
    except ValueError:
        return
    raise AssertionError("invalid evidence or artifact accepted")


def main():
    with tempfile.TemporaryDirectory(prefix="opc-first-workflow-test-") as tmp:
        root = Path(tmp)
        out = root / "normal"
        result = subprocess.run([sys.executable, str(ROOT / "run.py"), "--out", str(out)],
                                capture_output=True, text=True)
        assert result.returncode == 0 and "OPC_FIRST_WORKFLOW_PASS" in result.stdout, result.stderr
        assert "OPC_VERIFY_PASS" in result.stdout
        assert {p.name for p in out.iterdir()} == {
            "artifact-manifest.json", "content-draft.md", "decision.json",
            "receipt.json", "research.md", "task.json"}
        manifest = json.loads((out / "artifact-manifest.json").read_text())
        workflow.verify_artifacts(out, manifest)
        assert json.loads((out / "decision.json").read_text())["release_authorized"] is False
        bad = json.loads((ROOT / "opportunity.json").read_text())
        bad["facts"][0]["source_ids"] = ["MISSING"]
        bad_out = root / "bad-out"
        expect_reject(lambda: workflow.replay(bad, bad_out))
        assert not bad_out.exists()
        (out / "research.md").write_text("tampered")
        expect_reject(lambda: workflow.verify_artifacts(out, manifest))
        (out / "research.md").unlink()
        expect_reject(lambda: workflow.verify_artifacts(out, manifest))
    print("FIRST_WORKFLOW_FOCUSED_TESTS_OK")


if __name__ == "__main__":
    main()
