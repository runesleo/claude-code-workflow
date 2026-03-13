# Project Knowledge

> **Warm Layer**: Technical pitfalls, cross-project patterns, project-specific architecture decisions.
>
> This file replaces the previous `MEMORY.md` + `patterns.md` combination.
> Updated when counter-intuitive discoveries are made or architecture shifts occur.

## Technical Pitfalls

### YAML Schema Validation
**Issue**: YAML files can be syntactically valid but semantically incorrect (missing required fields, wrong types)
**Solution**: Use JSON Schema to validate YAML structure beyond basic syntax
**Implementation**: Created schemas/ directory with JSON Schema files and bin/validate-schemas script
**Discovered**: 2026-03-07 | **Source**: Review feedback - make validate only checks syntax, not semantics

### Documentation Scattering
**Issue**: Documentation spread across README, docs/, targets/, core/ makes it hard to find information
**Solution**: Create a unified documentation index (docs/README.md) and add navigation table to main README
**Discovered**: 2026-03-07 | **Source**: Review finding P2 - Documentation scattered

## Reusable Patterns

### CI/CD Pipeline for Configuration Projects
**When to use**: Projects with YAML/JSON configuration files that need validation
**Implementation**:
1. YAML syntax validation
2. JSON Schema semantic validation
3. Tool-specific validation (bin/vibe inspect)
4. Generation verification (make generate)
5. Test suite execution
**Example**: See .github/workflows/ci.yml
**Discovered**: 2026-03-07

### Three-Tier Memory Architecture
**When to use**: Any project needing organized note-taking
**Implementation**:
- session.md (hot): Active tasks, daily progress
- project-knowledge.md (warm): Pitfalls, patterns, ADRs
- overview.md (cold): Goals, infrastructure
**Discovered**: 2026-03-07 | **Source**: Architecture optimization refactor

## Architecture Decisions

### ADR-001: JSON Schema for YAML Validation (2026-03-07)
- **Context**: make validate only checks YAML syntax, not structure
- **Decision**: Add JSON Schema validation for core YAML files
- **Consequences**: 
  - Extra maintenance burden (schemas must evolve with YAML)
  - Better error messages for configuration mistakes
  - Can validate required fields and types

### ADR-002: Unified Documentation Index (2026-03-07)
- **Context**: Documentation scattered across multiple directories
- **Decision**: Create docs/README.md as central index, add navigation to README.md
- **Consequences**:
  - Single entry point for all documentation
  - Easier onboarding for new users
  - Requires maintenance when adding new docs

