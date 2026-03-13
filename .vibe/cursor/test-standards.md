# Test Coverage Standards

Generated target: `cursor`
Applied overlay: `none`

This document defines minimum test requirements by task complexity and code type.

## Coverage by Complexity

### Trivial

No automated tests required for trivial changes

- Unit coverage: 0%
- Integration coverage: 0%
- Manual verification: required

### Standard

80% unit test coverage for standard tasks

- Unit coverage: 80%
- Integration coverage: 0%
- Manual verification: required

### Critical

90% unit + 50% integration coverage for critical tasks

- Unit coverage: 90%
- Integration coverage: 50%
- Manual verification: required

## Critical Paths

These paths require 100% coverage regardless of complexity:

- `core/security/**` → 100% (Security-sensitive code)
- `**/path_safety.rb` → 100% (File system safety)
- `.*(delete|remove|destroy).*` → 100% (Destructive operations)
- `.*(auth|credential|secret).*` → 100% (Authentication/authorization)

## Test Types

### Unit

Test individual functions/methods in isolation

**Required for:** `standard`, `critical`

**Examples:**
  - Test sanitize_directory_name with special characters
  - Test paths_overlap with symlinks

### Integration

Test multiple components working together

**Required for:** `critical`

**Examples:**
  - Test full CLI command flow
  - Test file generation + validation

### Edge_cases

Test boundary conditions and error cases

**Required for:** `standard`, `critical`

**Must Cover:**
  - Empty input
  - Invalid input
  - Permission denied
  - Resource not found
  - Null/nil values

### Manual

Manual verification steps

**Required for:** `trivial`, `standard`, `critical`

**Examples:**
  - Run command and verify output
  - Check generated files
  - Verify error messages

## Exemptions

- Documentation-only changes: 0% coverage
- Test code itself: optional coverage
- Generated code: optional coverage
