# Project Overlays

Phase 5 adds a project-local overlay layer so a consuming repository can customize the generated vibe workflow without editing `core/` directly.

## Discovery Rules

- `bin/vibe use ...` and `bin/vibe switch ...` automatically look for `.vibe/overlay.yaml` in the destination root.
- Any command can also take `--overlay FILE` for an explicit overlay path.
- If neither is provided, the generator falls back to the workflow repo defaults.

## Supported Schema

```yaml
schema_version: 1
name: my-project
description: Short explanation of why this project needs extra routing or safety rules.

profile:
  mapping_overrides:
    critical_reasoner: openai.high-reasoning
    independent_verifier: second-model.manual-review
  note_append:
    - Prefer an independent verifier before merging data migrations.

policies:
  append:
    - id: project-context-is-release-log
      category: project_memory
      enforcement: recommended
      target_render_group: always_on
      summary: Keep PROJECT_CONTEXT.md current for blockers, migrations, and rollback notes.

targets:
  claude-code:
    permissions:
      ask:
        - "Bash(./scripts/deploy:*)"
  cursor:
    permissions:
      deny:
        - "Read(customer-data/**)"
  opencode:
    permission:
      read:
        "**/customer-data/**": "deny"
```

## Merge Semantics

- `profile.mapping_overrides` shallow-merges into the selected target profile mapping.
- `profile.note_append` appends extra profile notes.
- `policies.append` adds or replaces behavior-policy entries by `id`.
- `targets.<target>` deep-merges into the generated target-native config for that host.
- Array values are appended and de-duplicated in order.

## Runtime-preference examples

- `examples/python-uv-overlay.yaml` — prefer `uv` for project env creation, sync, dependency changes, and command execution.
- `examples/node-nvm-overlay.yaml` — prefer `.nvmrc` plus `nvm use` / `nvm install` before `npm` workflows.
- `examples/project-overlay.yaml` — stricter review and sensitive-data example overlay.

These examples are intentionally overlays, not shared defaults. Python and Node projects often need different environment-management assumptions, and overlays keep those preferences scoped to the right repos.

## Recommended Workflow

1. Copy one of the example overlays into your project as `.vibe/overlay.yaml`.
2. Adjust only the deltas that are project-specific.
3. Preview with `bin/vibe inspect --overlay .vibe/overlay.yaml`.
4. Apply with `bin/vibe use ...` or `bin/vibe switch ...`.

Keep shared defaults in `core/`. Use overlays only for project-specific deviations.
