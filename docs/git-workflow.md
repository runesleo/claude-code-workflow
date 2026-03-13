# Git Workflow for Vibe Repositories

Phase 6 introduces two different kinds of generated files:

1. Disposable staging output produced by `bin/vibe build`
2. Repo-local target files applied with `bin/vibe use` or `bin/vibe switch`

They should not be treated the same in Git.

## Commit these files in this repository

This repository uses Git to publish both the portable source of truth and a checked-in target-facing surface.

Commit the files that define or document the workflow:

- Portable spec and adapter docs: `core/`, `targets/`, `rules/`, `docs/`
- Repo entrypoints: `CLAUDE.md`, `WARP.md`
- Checked-in Warp support files: `.vibe/manifest.json`, `.vibe/target-summary.md`, `.vibe/warp/*`
- Example overlays under `examples/`
- Any other file that is intentionally serving as the repository's live interface for a supported target

In this repository, those files are part of the product surface, not disposable build cache.

## Do not commit these files

Keep disposable output and local state out of Git:

- `generated/` — default staging output from `bin/vibe build`
- `.vibe-target.json` — local marker written by `bin/vibe use` / `bin/vibe switch`
- External staging directories such as `~/.vibe-generated/...`
- Secrets and local environment files such as `.env`, `*.local`, `credentials*`
- Customer-data exports, ad hoc archives, and other temporary artifacts

The default `.gitignore` in this repository intentionally covers the first two items:

```gitignore
/generated/
/.vibe-target.json
```

## Guidance for consuming repositories

When you use this workflow inside another project, distinguish between staging output and live repo configuration:

- Do not commit `generated/<target>/` just because `build` created it.
- Commit files applied into the project root when they are meant to be the team's shared tool interface.
- Typical examples of shared, commit-worthy target files include `WARP.md`, `AGENTS.md`, `.cursor/rules/*`, and `.vibe/<target>/*` after `use` or `switch` places them in the repository root.
- If a target setup is only for one developer's local experiment, keep it outside the repo or isolate it in a personal branch instead of merging it into shared history.

The rule of thumb is simple: commit live repo entrypoints, not staging directories.

## Overlay strategy

Use `.vibe/overlay.yaml` for project-specific deviations from the shared baseline.

- Commit `.vibe/overlay.yaml` when it captures shared policy, permissions, or runtime preferences that should apply to the whole project.
- Keep it out of Git when it is local-only, machine-specific, experimental, or personal.
- For local-only overlays, prefer an external file passed via `--overlay FILE`.
- If you keep a local-only overlay under the repo root anyway, add `.vibe/overlay.yaml` to that repository's `.gitignore`.
- The example overlays in `examples/` are committed because they document supported patterns and serve as fixtures.

## `memory/` is a policy decision, not a blanket ignore rule

Do not assume `memory/` should always be committed or always be ignored.

- In this repository, `memory/` is tracked on purpose as part of the shared workflow materials.
- In a consuming repository, decide whether `memory/` is team-owned project state or private working notes.
- If it is shared project state, commit it intentionally and document ownership.
- If it contains personal notes, machine-specific context, or sensitive material, ignore it or move it outside the repo.

## Recommended `.gitignore` baseline for consuming repositories

Many consuming repos will want a baseline like this:

```gitignore
/generated/
/.vibe-target.json

# Optional: keep local-only overlays and env files out of Git
/.vibe/overlay.yaml
/.env
*.local
```

Adjust that list to your project's actual sharing model.

## Review checklist before commit

Before committing workflow-related files, ask:

1. Is this file a source of truth for the repo, or just staging output?
2. Will teammates and CI need it to get the same behavior?
3. Does it contain secrets, exports, or machine-specific state?
4. Is it a live repo entrypoint such as `WARP.md`, `AGENTS.md`, or `.vibe/<target>/*`, rather than `generated/<target>/`?

If the answer points to shared behavior and durable repo state, commit it. If it points to local staging or local state, ignore it.
