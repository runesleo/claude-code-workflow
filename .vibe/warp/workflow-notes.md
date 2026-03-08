# Warp workflow notes

Generated target: `warp`
Applied overlay: `none`

## Conservative mapping

- Use `WARP.md` as the project-level Warp rule entrypoint.
- Keep repository files as the single source of truth; Warp rules should point back to those files instead of replacing them.
- If you later add Warp workflows, prefer repo-local commands that wrap `bin/vibe` or existing project scripts.
- Keep runtime preferences such as `uv` and `nvm` in project overlays so they stay scoped to the right repositories.
- This generator intentionally stays file-backed and does not try to manage Warp Drive state directly.
