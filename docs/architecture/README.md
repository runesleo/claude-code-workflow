# Vibe Workflow Architecture Documentation

This directory contains architecture decision records (ADRs), analysis, and design documents for the Vibe workflow project.

## Documents

### Architecture Decision Records

| Document | Status | Description |
|----------|--------|-------------|
| [ADR-001: Configuration-Driven Renderer Architecture](adr-001-renderer-refactor.md) | Proposed | Refactor target renderers from imperative code to declarative configuration |
| [ADR-002: Overlay System Improvements](adr-002-overlay-improvements.md) | Proposed | Add schema validation, transparency, and conditional overlays |
| [ADR-003: Template System Design](adr-003-template-system.md) | Proposed | File-based ERB template system with shared partials |

### Analysis and Design

| Document | Description |
|----------|-------------|
| [Current Architecture Analysis](current-architecture-analysis.md) | Detailed analysis of current renderer code, duplication patterns, and root causes |
| [Proposed Architecture Diagram](proposed-architecture-diagram.md) | Visual representation of the new architecture with component details |
| [Configuration Schema](configuration-schema.yaml) | YAML schema for target configuration files |
| [Migration Plan](migration-plan.md) | 6-day incremental migration plan with deliverables |
| [Risk Assessment](risk-assessment.md) | Risk matrix, mitigation strategies, and contingency plans |

## Quick Start

### Understanding the Current State

1. Read [Current Architecture Analysis](current-architecture-analysis.md) for:
   - Code duplication metrics
   - Extension point problems
   - Root cause analysis

2. Review [lib/vibe/target_renderers.rb](../../lib/vibe/target_renderers.rb) (1149 lines) to see the current implementation

### Understanding the Proposed Architecture

1. Read [ADR-001: Configuration-Driven Renderer Architecture](adr-001-renderer-refactor.md) for the high-level design

2. Review [Proposed Architecture Diagram](proposed-architecture-diagram.md) for visual component relationships

3. Examine [Configuration Schema](configuration-schema.yaml) for the declarative format

### Planning Implementation

1. Review [Migration Plan](migration-plan.md) for the 6-day implementation schedule

2. Check [Risk Assessment](risk-assessment.md) for potential issues and mitigations

3. Read [ADR-002](adr-002-overlay-improvements.md) and [ADR-003](adr-003-template-system.md) for supporting improvements

## Key Findings Summary

### Current Problems

- **1149 lines** in `target_renderers.rb` with significant duplication
- **~400 lines** duplicated across global/project mode implementations
- **~240 lines** of nearly identical entrypoint markdown templates
- **164 lines** of complex integration rendering conditionals
- **240 lines** required to add a new target

### Proposed Solution

- **Configuration-driven**: Targets defined in YAML, not code
- **Template-based**: ERB templates with shared partials
- **Plugin architecture**: Integration rendering as plugins
- **Schema validation**: Type-safe overlay application

### Expected Benefits

| Metric | Current | Proposed | Improvement |
|--------|---------|----------|-------------|
| Lines to add target | ~240 | ~40 | 83% reduction |
| Code duplication | 60%+ | <10% | 50%+ reduction |
| Files to modify | 5+ | 2-3 | 40% reduction |
| Test coverage | Low | High | Measurable |

## Implementation Status

This architecture is currently in the **design and proposal** phase. No implementation has begun.

To begin implementation:
1. Review and approve ADRs
2. Assign migration tasks
3. Begin Phase 1 (Infrastructure) per [Migration Plan](migration-plan.md)

## Questions?

See individual documents for detailed information. For questions about:
- **Why**: See ADR documents for decision rationale
- **How**: See Migration Plan for implementation steps
- **What**: See Configuration Schema and Proposed Architecture Diagram
- **Risks**: See Risk Assessment for concerns and mitigations
