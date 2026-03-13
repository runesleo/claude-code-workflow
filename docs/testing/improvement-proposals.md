# 配置改进方案

**基于**: config-effectiveness-test.md 的测试结果
**日期**: 2026-03-07
**状态**: 待实施

---

## 改进目标

在保持高质量标准的同时，降低简单任务的流程成本，提高开发效率。

**核心原则**:
- 保持 P0 规则不变 (Verification, Memory Recall)
- 为简单任务提供"快速通道"
- 明确测试和文档的最低标准
- 保持配置的可理解性和可维护性

---

## 改进方案 1: 任务复杂度分级路由

### 问题
当前所有任务都使用相同的完整流程，导致简单任务的开发时间过长。

### 解决方案
引入三级任务复杂度路由机制。

### 实施细节

创建 `core/policies/task-routing.yaml`:

```yaml
schema_version: 1
name: task-complexity-routing
description: Route tasks by complexity to balance quality and efficiency

complexity_levels:
  trivial:
    description: Simple, low-risk changes that don't require full process
    criteria:
      - lines_changed: "<20"
      - files_changed: "1"
      - risk_level: "low"
      - examples:
          - "Fix typo in documentation"
          - "Update version number"
          - "Add simple log statement"
          - "Rename variable (single file)"

    process_requirements:
      memory_recall: optional  # Can skip if obviously new
      test_requirement: manual_only  # No automated tests required
      verification: manual_check  # Quick manual verification
      documentation: inline_comments_only  # No separate docs
      review: optional  # Can self-merge

    time_estimate: "5-10 minutes"

  standard:
    description: Normal development tasks with moderate complexity
    criteria:
      - lines_changed: "20-100"
      - files_changed: "1-5"
      - risk_level: "medium"
      - examples:
          - "Add new CLI command"
          - "Refactor existing module"
          - "Fix non-critical bug"
          - "Add new feature (isolated)"

    process_requirements:
      memory_recall: required  # Always check for existing solutions
      test_requirement: unit_tests  # Unit tests required
      verification: automated_and_manual  # Run tests + manual check
      documentation: update_relevant_docs  # Update affected docs
      review: recommended  # Peer review recommended

    time_estimate: "30-60 minutes"

  critical:
    description: High-risk or complex changes requiring full process
    criteria:
      - lines_changed: ">100"
      - files_changed: ">5"
      - risk_level: "high"
      - examples:
          - "Database migration"
          - "Security-sensitive changes"
          - "API contract changes"
          - "Architecture refactoring"
          - "Data deletion/export logic"

    process_requirements:
      memory_recall: required
      test_requirement: unit_and_integration  # Full test coverage
      verification: full_suite  # All tests + manual + smoke
      documentation: comprehensive  # Full documentation
      review: required  # Mandatory peer review
      cross_verification: recommended  # Consider second opinion

    time_estimate: "2+ hours"

# Auto-detection rules
auto_detection:
  enabled: true
  rules:
    - if: "contains(path, 'test/')"
      then: "standard"  # Test changes are at least standard

    - if: "contains(path, 'core/security/')"
      then: "critical"  # Security changes are always critical

    - if: "contains(path, 'README.md') AND lines_changed < 10"
      then: "trivial"  # Small doc changes are trivial

    - if: "contains(commit_message, 'BREAKING CHANGE')"
      then: "critical"  # Breaking changes are critical

# Override mechanism
override:
  user_can_override: true
  require_justification: true
  examples:
    - "User says: 'this is urgent, skip full process'"
    - "User says: 'treat this as trivial'"
```

### 集成到现有配置

更新 `rules/behaviors.md`:

```markdown
## Task Complexity Routing

Before starting any task, assess its complexity level:

### Trivial (<20 lines, 1 file, low risk)
- **Memory Recall**: Optional (skip if obviously new)
- **Tests**: Manual verification only
- **Documentation**: Inline comments sufficient
- **Time**: 5-10 minutes

### Standard (20-100 lines, 1-5 files, medium risk)
- **Memory Recall**: Required
- **Tests**: Unit tests required
- **Documentation**: Update relevant docs
- **Time**: 30-60 minutes

### Critical (>100 lines, >5 files, high risk)
- **Memory Recall**: Required
- **Tests**: Unit + integration tests
- **Documentation**: Comprehensive
- **Review**: Mandatory
- **Time**: 2+ hours

**Auto-detection**: System will suggest complexity level based on:
- Lines changed
- Files affected
- Path patterns (e.g., `core/security/` → critical)
- Commit message keywords (e.g., `BREAKING CHANGE` → critical)

**Override**: You can override the suggested level with justification.
```

---

## 改进方案 2: Memory Recall 豁免条件

### 问题
对于明显的新功能，Memory Recall 可能浪费时间。

### 解决方案
定义明确的豁免条件。

### 实施细节

更新 `skills/systematic-debugging/SKILL.md`:

```markdown
## Memory Recall - When to Skip

Memory Recall is **mandatory by default**, but can be skipped in these cases:

### Automatic Exemptions
1. **User Explicit Skip**
   - User says: "don't check history"
   - User says: "this is brand new"
   - User says: "skip memory recall"

2. **Obviously New Feature**
   - Feature name doesn't exist in codebase
   - No similar patterns in project
   - User confirms it's a new concept

3. **Time-Sensitive Emergency**
   - Production outage
   - Security hotfix
   - User explicitly marks as "urgent"

### Conditional Exemptions
4. **Trivial Task** (see task-routing.yaml)
   - <20 lines changed
   - Single file
   - Low risk (docs, comments, etc.)

### When in Doubt
If unsure whether to skip, **always do Memory Recall**. The cost is low (1-2 minutes) compared to the risk of duplicating work.

### Exemption Log
When skipping Memory Recall, log the reason:
```markdown
# memory/today.md
## Skipped Memory Recall
- Task: Add new feature X
- Reason: User confirmed it's brand new, no similar patterns exist
- Time saved: ~2 minutes
```
```

---

## 改进方案 3: 明确测试覆盖率标准

### 问题
当前配置要求写测试，但没有明确覆盖率标准。

### 解决方案
定义分级测试标准。

### 实施细节

创建 `core/policies/test-standards.yaml`:

```yaml
schema_version: 1
name: test-coverage-standards
description: Define minimum test requirements by task complexity and code type

# Minimum coverage by complexity
coverage_by_complexity:
  trivial:
    unit_coverage: 0%  # No automated tests required
    integration_coverage: 0%
    manual_verification: required

  standard:
    unit_coverage: 80%  # 80% of new code
    integration_coverage: 0%  # Optional
    manual_verification: required

  critical:
    unit_coverage: 90%  # 90% of new code
    integration_coverage: 50%  # 50% of critical paths
    manual_verification: required

# Critical paths (always 100% coverage)
critical_paths:
  - path_pattern: "core/security/**"
    coverage: 100%
    reason: "Security-sensitive code"

  - path_pattern: "**/path_safety.rb"
    coverage: 100%
    reason: "File system safety"

  - function_pattern: ".*delete.*|.*remove.*|.*destroy.*"
    coverage: 100%
    reason: "Destructive operations"

  - function_pattern: ".*auth.*|.*credential.*|.*secret.*"
    coverage: 100%
    reason: "Authentication/authorization"

# Test types required
test_types:
  unit:
    description: "Test individual functions/methods in isolation"
    required_for: ["standard", "critical"]
    examples:
      - "Test sanitize_directory_name with special characters"
      - "Test paths_overlap with symlinks"

  integration:
    description: "Test multiple components working together"
    required_for: ["critical"]
    examples:
      - "Test full CLI command flow"
      - "Test file generation + validation"

  edge_cases:
    description: "Test boundary conditions and error cases"
    required_for: ["standard", "critical"]
    must_cover:
      - "Empty input"
      - "Invalid input"
      - "Permission denied"
      - "Resource not found"
      - "Null/nil values"

  manual:
    description: "Manual verification steps"
    required_for: ["trivial", "standard", "critical"]
    examples:
      - "Run command and verify output"
      - "Check generated files"
      - "Verify error messages"

# Exemptions
exemptions:
  - type: "documentation_only"
    coverage: 0%
    reason: "No code changes"

  - type: "test_code_itself"
    coverage: "optional"
    reason: "Tests don't need tests"

  - type: "generated_code"
    coverage: "optional"
    reason: "Auto-generated code"
```

### 集成到现有配置

更新 `CLAUDE.md`:

```markdown
## Testing Standards

### Minimum Coverage
- **Trivial tasks**: Manual verification only
- **Standard tasks**: 80% unit test coverage
- **Critical tasks**: 90% unit + 50% integration coverage

### Critical Paths (100% coverage required)
- Security-sensitive code (`core/security/**`)
- File system operations (`path_safety.rb`)
- Destructive operations (delete, remove, destroy)
- Authentication/authorization logic

### Required Test Types
- **Unit tests**: Test individual functions in isolation
- **Edge cases**: Empty input, invalid input, errors
- **Integration tests**: (Critical tasks only) Test component interactions
- **Manual verification**: Always required

### Example
```ruby
# For a new function sanitize_directory_name:
def test_sanitize_with_special_chars  # Normal case
def test_sanitize_with_empty_string   # Edge case
def test_sanitize_with_unicode        # Edge case
def test_sanitize_with_only_special   # Edge case
```
```

---

## 改进方案 4: 文档更新阈值

### 问题
每个小改动都更新 `today.md` 可能过于频繁。

### 解决方案
定义"值得记录"的阈值。

### 实施细节

更新 `rules/behaviors.md`:

```markdown
## Documentation Update Thresholds

### When to Update `memory/today.md`

**Always record**:
- New module created
- Important architectural decision
- Counter-intuitive solution
- User correction (you were wrong)
- Repeated issue (>2 times)

**Record if threshold met**:
- Lines changed: >50
- Files changed: >3
- Time spent: >30 minutes
- Complexity: Standard or Critical

**Optional to record**:
- Trivial changes (<20 lines)
- Routine bug fixes
- Documentation updates
- Dependency updates

### When to Update `memory/patterns.md`

**Always record**:
- Reusable pattern discovered
- Common pitfall identified
- Project-specific convention
- Tool/library quirk

**Example**:
```markdown
# memory/patterns.md

## Path Safety Pattern
When working with file paths:
1. Always use File.realpath to resolve symlinks
2. Always validate paths are within expected boundaries
3. Reuse lib/vibe/path_safety.rb module

Discovered: 2026-03-06
Reason: Symlinks can bypass string-based path checks
```

### When to Update Project Docs

**Always update**:
- New CLI command → Update README.md
- New configuration option → Update docs/
- API changes → Update relevant docs
- Breaking changes → Update CHANGELOG.md

**Optional**:
- Internal refactoring (no user-facing changes)
- Test additions
- Code comments (self-documenting)
```

---

## 实施计划

### Phase 1: 核心改进 (Week 1)
- [ ] 创建 `core/policies/task-routing.yaml`
- [ ] 更新 `rules/behaviors.md` 添加任务分级
- [ ] 更新 `skills/systematic-debugging/SKILL.md` 添加豁免条件
- [ ] 测试新流程 (用简单任务验证)

### Phase 2: 测试标准 (Week 2)
- [ ] 创建 `core/policies/test-standards.yaml`
- [ ] 更新 `CLAUDE.md` 添加测试标准
- [ ] 创建测试模板和示例
- [ ] 验证现有测试是否符合标准

### Phase 3: 文档优化 (Week 3)
- [ ] 更新 `rules/behaviors.md` 添加文档阈值
- [ ] 创建文档模板
- [ ] 清理现有 memory/ 目录
- [ ] 建立文档审查流程

### Phase 4: 验证和调优 (Week 4)
- [ ] 用真实任务测试新流程
- [ ] 收集反馈
- [ ] 调整阈值和标准
- [ ] 更新文档

---

## 成功指标

### 效率指标
- 简单任务开发时间: 从 30 分钟降至 10 分钟 (-67%)
- 标准任务开发时间: 保持 30-60 分钟
- 关键任务开发时间: 保持 2+ 小时

### 质量指标
- 测试覆盖率: 保持 >80%
- 生产事故: 保持 0
- Code review 通过率: >90%

### 体验指标
- 开发者满意度: >8/10
- 配置理解度: >9/10
- 流程遵守率: >95%

---

## 风险和缓解

### 风险 1: 开发者滥用"快速通道"
**缓解**:
- 明确定义 trivial 标准
- 要求 override 时提供理由
- 定期审查 trivial 任务的质量

### 风险 2: 测试覆盖率下降
**缓解**:
- 自动化覆盖率检查
- CI/CD 集成
- 定期覆盖率报告

### 风险 3: 文档质量下降
**缓解**:
- 保持关键决策的强制记录
- 定期文档审查
- 提供文档模板

---

## 附录: 配置文件清单

### 新增文件
- `core/policies/task-routing.yaml`
- `core/policies/test-standards.yaml`
- `docs/testing/config-effectiveness-test.md` (已创建)
- `docs/testing/improvement-proposals.md` (本文件)

### 修改文件
- `rules/behaviors.md` (添加任务分级、文档阈值)
- `skills/systematic-debugging/SKILL.md` (添加豁免条件)
- `CLAUDE.md` (添加测试标准)

### 保持不变
- `skills/verification-before-completion/SKILL.md` (P0 规则)
- `core/security/policy.yaml` (安全策略)
- 其他现有配置文件
