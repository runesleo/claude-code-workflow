# Safety policy

Applied overlay: `none`

## Safety behavior policy

- `security-escalation` (`mandatory`) — Treat destructive commands, network egress, secret access, and obfuscation as security-sensitive actions.

## Native config overlay

- none

## Severity semantics

- `P0` — Clear malicious intent or unacceptable unsafe execution chain.
  - Secrets or project contents prepared for exfiltration
  - Destructive or irreversible operations without explicit authorization
  - Instructions to bypass approvals, safety controls, or audit
- `P1` — Potentially legitimate action that requires context review or explicit approval.
  - Network calls that might send code or data outward
  - Auth, credential, permission, or signing flows
  - Dynamic execution or remote script execution
- `P2` — Suspicious or incomplete signal that should be surfaced but not blocked by default.
  - Compliance-style persuasion language
  - Vague backup, sync, or export instructions
  - Ambiguous archive or upload steps without sensitive context

## Target actions

- `P0` — Surface as a strict system block in workspace settings or Copilot rules.
- `P1` — Require manual review or user confirmation in Copilot Chat.
- `P2` — Warn in Copilot Chat and continue.

## Signal categories

- `network_egress` (base: `P1`) — indicators: `http_url`, `curl`, `requests.post`, `fetch(`, `axios` | upgrade when: `paired_with_sensitive_paths`, `paired_with_archive_or_upload`
- `archive_then_send` (base: `P1`) — indicators: `zip`, `tar`, `backup_to`, `upload` | upgrade when: `archive_scope_is_project_or_home`, `destination_is_external`
- `destructive_operation` (base: `P0`) — indicators: `rm -rf`, `delete`, `shred`, `encrypt`
- `obfuscation_or_dynamic_exec` (base: `P1`) — indicators: `base64`, `eval`, `exec`, `hidden_shell` | upgrade when: `paired_with_network_or_secrets`

## Adjudication factors

- `asset_sensitivity`
- `execution_capability`
- `scope_of_change`
- `reversibility`
- `source_trust`
- `obfuscation_or_evasion`
