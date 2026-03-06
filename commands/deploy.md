# Deployment Checklist

Before deploying to production, execute these checks.

## 1. Code Quality Check

```bash
# Replace with your project's commands:
<your-lint-command>    # e.g. npm run lint, ruff check ., cargo clippy
<your-build-command>   # e.g. npm run build, uv run build, cargo build
<your-test-command>    # e.g. npm test, pytest, cargo test
```

## 2. Environment Variable Check

Confirm all required env vars are set on deployment platform:
- [ ] Compare `.env.example` with deployment platform settings
- [ ] Confirm API keys are correct and not expired
- [ ] Confirm environment identifier is correct (production/staging)

## 3. Git Status Check

```bash
git status  # Confirm no uncommitted changes
git log -3  # Confirm recent commits are correct
git diff main...HEAD  # Check complete changeset
```

## 4. Pre-deploy Confirmation

Please confirm:
- [ ] Changes have been tested in staging?
- [ ] Rollback plan exists?
- [ ] Need to notify team members?

## 5. Execute Deployment

If all above confirmed, execute deploy command.

## 6. Post-deploy Verification

After deployment completes:
- [ ] Visit production URL, confirm accessible
- [ ] Check critical functionality works
- [ ] Check error monitoring for new errors
