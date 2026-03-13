# Behavior policies

Generated target: `antigravity`
Applied overlay: `none`

> **Note:** Source refs refer to files in the portable workflow repository, not this generated output directory.

- `ssot-first` (state_management, mandatory, group: always_on)
  - Keep repository files as the single source of truth; tool-managed memory is cache.
  - source refs: `rules/behaviors.md`, `README.md`
- `verify-before-claim` (quality, mandatory, group: always_on)
  - Never claim completion without fresh verification evidence.
  - source refs: `skills/verification-before-completion/SKILL.md`, `CLAUDE.md`
- `capability-tier-routing` (routing, mandatory, group: routing)
  - Route by capability tier first, then resolve through the active provider profile.
  - source refs: `rules/behaviors.md`, `docs/task-routing.md`
- `reversible-small-batches` (change_management, recommended, group: always_on)
  - Prefer small, reversible, single-purpose changes over large mixed batches.
  - source refs: `CLAUDE.md`, `rules/behaviors.md`
- `root-cause-debugging` (debugging, mandatory, group: always_on)
  - Investigate root cause before attempting fixes and reassess after repeated failures.
  - source refs: `skills/systematic-debugging/SKILL.md`, `rules/behaviors.md`
- `security-escalation` (safety, mandatory, group: safety)
  - Treat destructive commands, network egress, secret access, and obfuscation as security-sensitive actions.
  - source refs: `core/security/policy.yaml`, `docs/content-safety.md`
- `record-reusable-learning` (memory, recommended, group: always_on)
  - Record user corrections, repeated failures, and counter-intuitive discoveries for reuse.
  - source refs: `rules/behaviors.md`, `skills/experience-evolution/SKILL.md`
- `sunday-rule` (workflow, recommended, group: optional)
  - Batch workflow or system optimization separately from delivery work unless it blocks production.
  - source refs: `rules/behaviors.md`
