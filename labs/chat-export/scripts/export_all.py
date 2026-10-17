#!/usr/bin/env python3
"""Run every exporter whose source exists on this machine. Pass --dry-run to only report."""
import importlib
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

EXPORTERS = ["export_claude", "export_codex", "export_cursor", "export_grok"]


def main():
    passthrough = [a for a in sys.argv[1:] if a in ("--dry-run", "--full")]
    for name in EXPORTERS:
        importlib.import_module(name).main(passthrough)
    return 0


if __name__ == "__main__":
    sys.exit(main())
