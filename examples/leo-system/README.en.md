# Leo System: sanitized current structure

[中文](README.md) · **English**

This is not a fictional Product/Research demo. It is a sanitized version of Leo's current AI work system.

It preserves nine stable business lines, per-task sources of truth, stable owners, replaceable workers, expiring claims, one repository writer, delivery receipts, and explicit wake-up triggers.

It removes absolute paths, thread UUIDs, live tasks, accounts, positions, health records, customers, and production controls.

Files:

- `AGENTS.private.example.md`: stable preferences and pointers only;
- `business-lines.example.json`: Leo's real nine-line topology;
- `task.example.json`: a synthetic task that preserves the real contracts;
- `writer-lock.example.json`: acquire/release contract;
- `readout.example.txt`: bounded owner summary and exact task readout.

The task and readout content are synthetic, not Leo's current runtime state. Their fields, boundaries, and read/write relationships come from the working system.

Start with one real workspace and one real task. Add more lines, claims, or writer locks only after your work actually needs them.
