# Task Complexity Routing

Generated target: `warp`
Applied overlay: `none`

This document defines how to route tasks by complexity level to balance quality and efficiency.

## Complexity Levels

### Trivial

Simple, low-risk changes that don't require full process

**Criteria:**
  - lines_changed: <20
  - files_changed: 1
  - risk_level: low

**Examples:**
  - Fix typo in documentation
  - Update version number
  - Add simple log statement
  - Rename variable (single file)

**Process Requirements:**
  - memory_recall: optional
  - test_requirement: manual_only
  - verification: manual_check
  - documentation: inline_comments_only
  - review: optional

**Time Estimate:** 5-10 minutes

### Standard

Normal development tasks with moderate complexity

**Criteria:**
  - lines_changed: 20-100
  - files_changed: 1-5
  - risk_level: medium

**Examples:**
  - Add new CLI command
  - Refactor existing module
  - Fix non-critical bug
  - Add new feature (isolated)

**Process Requirements:**
  - memory_recall: required
  - test_requirement: unit_tests
  - verification: automated_and_manual
  - documentation: update_relevant_docs
  - review: recommended

**Time Estimate:** 30-60 minutes

### Critical

High-risk or complex changes requiring full process

**Criteria:**
  - lines_changed: >100
  - files_changed: >5
  - risk_level: high

**Examples:**
  - Database migration
  - Security-sensitive changes
  - API contract changes
  - Architecture refactoring
  - Data deletion/export logic

**Process Requirements:**
  - memory_recall: required
  - test_requirement: unit_and_integration
  - verification: full_suite
  - documentation: comprehensive
  - review: required
  - cross_verification: recommended

**Time Estimate:** 2+ hours

## Auto-Detection Rules

- path contains 'test/' → `standard` (Test changes are at least standard)
- path contains 'core/security/' → `critical` (Security changes are always critical)
- path is 'README.md' AND lines_changed < 10 → `trivial` (Small doc changes are trivial)
- commit_message contains 'BREAKING CHANGE' → `critical` (Breaking changes are critical)
- path matches '**/path_safety.rb' → `critical` (File system safety is critical)
- function_name matches '(delete|remove|destroy)' → `critical` (Destructive operations are critical)

## Override Policy

Users can override complexity classification with justification:
- "this is urgent, skip full process"
- "treat this as trivial"
- "this needs full review despite being small"
