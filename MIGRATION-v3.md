# Migrating from v2 to v3

v3 is intentionally breaking. It removes the assumption that every AI session must pass through automatic routing, daily memory, and closeout workflows.

The migration is reversible: disable first, use the lean setup for real work, and restore only the capability you actually miss.

## 1. Take an inventory

Before changing anything, record the active instruction surfaces for each client:

```bash
./scripts/inventory.sh
```

The inventory is read-only. It lists known instruction files plus every symlink, including whole-directory links such as `rules`, `commands`, and `skills`. To inspect non-default roots, pass them explicitly.

Also note any scheduled report generator separately. A report job and an interactive agent workflow are different systems.

## 2. Disable the v2 hot path

Move old workflow assets to a dated directory outside their discovery path. Do not delete them yet.

Typical v2 assets include:

- always-loaded behavior and skill-trigger rules;
- automatic memory-flush rules;
- Morning, Today, session-end, today-end, and weekly-end skills or commands;
- hooks that remind, route, or persist those workflows;
- `AGENTS.override.md` or local instruction files that take precedence over the lean baseline;
- symlinked rules, skills, and commands whose targets remain active elsewhere;
- duplicate copies of the same skill across clients.

Use explicit source and destination paths for each move. Avoid broad wildcards. If an entry does not exist, skip it.

Example pattern (set the client config directory explicitly first):

```bash
CLIENT_CONFIG="${CLIENT_CONFIG:?set this to the client config directory}"
mkdir -p "$CLIENT_CONFIG/skills_disabled/v3-migration"
mv "$CLIENT_CONFIG/skills/session-end" "$CLIENT_CONFIG/skills_disabled/v3-migration/session-end"
```

Repeat only for the entries you verified. Keep safety guards that block secrets, dangerous commands, or public/production actions unless you have an equivalent mechanical control.

## 3. Keep daily reports independent

If a scheduler already writes a useful daily artifact, leave it untouched and verify its latest output separately.

Remove only the rule that says an interactive session must run Morning or Today before work. Choose a delivery mode separately:

- **quiet pull:** write `inbox/daily/YYYY-MM-DD.md`; read it when wanted;
- **exception notification:** stay quiet on success, notify on failure or degraded output;
- **opt-in push:** send a short summary or link at a fixed time.

Do not stop or mutate a scheduler merely to migrate agent instructions.

## 4. Preview the v3 install

```bash
./scripts/install.sh --dry-run --claude --codex
./scripts/install.sh --dry-run --cursor-project /path/to/project
```

Review every target and backup path. Then apply only the clients you use:

```bash
./scripts/install.sh --apply --claude --codex
./scripts/install.sh --apply --cursor-project /path/to/project
```

## 5. Restart and use it normally

Open a new client session and give it a real task. There is no startup command.

For one or two weeks, record only concrete misses:

- state was genuinely lost;
- a risky action lacked a useful stop;
- the agent repeatedly needed the same project fact;
- a report became hard to discover.

Restore the smallest missing capability. Do not restore an entire pipeline because one behavior was useful.

## Rollback

The installer places a sibling backup beside every overwritten file:

```text
CLAUDE.md.bak-ai-workflow-<timestamp>
AGENTS.md.bak-ai-workflow-<timestamp>
lean-workflow.mdc.bak-ai-workflow-<timestamp>
```

To roll back, move the current file aside and restore the exact backup you selected. Old skills and commands can likewise be moved back from their dated disabled directory one at a time.

Restart the affected client after restoring files.
