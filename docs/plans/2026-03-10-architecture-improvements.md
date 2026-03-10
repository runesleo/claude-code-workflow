# Architecture Improvements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Improve code quality, maintainability, and robustness based on architecture review findings.

**Architecture:** Add type validation, thread safety, dependency injection, test coverage reporting, and reduce code duplication.

**Tech Stack:** Ruby 2.6+, minitest, SimpleCov

---

## Phase 1: Critical Type Safety and Thread Safety (P1)

### Task 1: Add Parameter Type Validation to Utils

**Files:**
- Modify: `lib/vibe/utils.rb:15-50`
- Test: `test/test_vibe_utils.rb`

**Step 1: Write failing tests for type validation**

Create `test/test_vibe_utils_validation.rb`:

```ruby
require "minitest/autorun"
load File.expand_path("../bin/vibe", __dir__)

class TestVibeUtilsValidation < Minitest::Test
  def setup
    @repo_root = File.expand_path("..", __dir__)
    @cli = VibeCLI.new(@repo_root)
  end

  def test_deep_merge_validates_base_type
    assert_raises(Vibe::ValidationError) do
      @cli.send(:deep_merge, "invalid", {})
    end
  end

  def test_deep_merge_validates_extra_type
    assert_raises(Vibe::ValidationError) do
      @cli.send(:deep_merge, {}, "invalid")
    end
  end

  def test_deep_copy_validates_value_type
    # Should accept any value, but test the method exists
    result = @cli.send(:deep_copy, { a: 1 })
    assert_equal({ a: 1 }, result)
  end
end
```

**Step 2: Run test to verify it fails**

Run: `cd .worktrees/architecture-improvements && bundle exec ruby test/test_vibe_utils_validation.rb`
Expected: FAIL with "ValidationError not raised"

**Step 3: Add type validation to deep_merge**

Modify `lib/vibe/utils.rb`:

```ruby
def deep_merge(base, extra)
  # Type validation
  unless base.nil? || base.is_a?(Hash) || base.is_a?(Array)
    raise ValidationError, "base must be a Hash, Array, or nil, got #{base.class}"
  end
  unless extra.nil? || extra.is_a?(Hash) || extra.is_a?(Array)
    raise ValidationError, "extra must be a Hash, Array, or nil, got #{extra.class}"
  end
  
  return deep_copy(extra) if base.nil?
  return deep_copy(base) if extra.nil?

  if base.is_a?(Hash) && extra.is_a?(Hash)
    merged = deep_copy(base)
    extra.each do |key, value|
      merged[key] = merged.key?(key) ? deep_merge(merged[key], value) : deep_copy(value)
    end
    merged
  elsif base.is_a?(Array) && extra.is_a?(Array)
    (base + extra).uniq
  else
    deep_copy(extra)
  end
end
```

**Step 4: Run test to verify it passes**

Run: `cd .worktrees/architecture-improvements && bundle exec ruby test/test_vibe_utils_validation.rb`
Expected: PASS

**Step 5: Commit**

```bash
cd .worktrees/architecture-improvements
git add lib/vibe/utils.rb test/test_vibe_utils_validation.rb
git commit -m "feat(utils): add parameter type validation to deep_merge"
```

---

### Task 2: Add Thread Safety to Lazy-Loaded Properties

**Files:**
- Modify: `lib/vibe/utils.rb:1-10`
- Test: `test/test_vibe_utils.rb`

**Step 1: Write failing test for thread safety**

Add to `test/test_vibe_utils.rb`:

```ruby
def test_tiers_doc_is_thread_safe
  threads = 10.times.map do
    Thread.new { @cli.tiers_doc }
  end
  results = threads.map(&:value)
  
  # All threads should get the same object
  assert_equal 1, results.map(&:object_id).uniq.length
end
```

**Step 2: Run test to verify behavior**

Run: `cd .worktrees/architecture-improvements && bundle exec ruby test/test_vibe_utils.rb -n test_tiers_doc_is_thread_safe`
Expected: May pass or fail depending on race condition

**Step 3: Add thread safety with Mutex**

Modify `bin/vibe`:

Add at the top after requires:

```ruby
require "thread"

class VibeCLI
  include Vibe::Utils
  # ... other includes ...
  
  def initialize(repo_root)
    @repo_root = repo_root
    @skip_integrations = false
    @yaml_mutex = Mutex.new
  end
  
  def tiers_doc
    @yaml_mutex.synchronize do
      @tiers_doc ||= read_yaml("core/models/tiers.yaml")
    end
  end

  def providers
    @yaml_mutex.synchronize do
      @providers ||= read_yaml("core/models/providers.yaml")
    end
  end

  def skills_doc
    @yaml_mutex.synchronize do
      @skills_doc ||= read_yaml("core/skills/registry.yaml")
    end
  end

  def security_doc
    @yaml_mutex.synchronize do
      @security_doc ||= read_yaml("core/security/policy.yaml")
    end
  end

  def policies_doc
    @yaml_mutex.synchronize do
      @policies_doc ||= read_yaml("core/policies/behaviors.yaml")
    end
  end

  def task_routing_doc
    @yaml_mutex.synchronize do
      @task_routing_doc ||= read_yaml("core/policies/task-routing.yaml")
    end
  end

  def test_standards_doc
    @yaml_mutex.synchronize do
      @test_standards_doc ||= read_yaml("core/policies/test-standards.yaml")
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `cd .worktrees/architecture-improvements && bundle exec ruby test/test_vibe_utils.rb -n test_tiers_doc_is_thread_safe`
Expected: PASS consistently

**Step 5: Commit**

```bash
cd .worktrees/architecture-improvements
git add bin/vibe test/test_vibe_utils.rb
git commit -m "feat(cli): add thread safety to lazy-loaded YAML properties"
```

---

### Task 3: Integrate SimpleCov for Test Coverage

**Files:**
- Modify: `Gemfile`
- Create: `test/test_helper.rb`
- Modify: All test files

**Step 1: Add SimpleCov to Gemfile**

Modify `Gemfile`:

```ruby
source "https://rubygems.org"

group :development, :test do
  gem "minitest", "~> 5.25"
  gem "simplecov", "~> 0.22"
end
```

**Step 2: Install dependencies**

Run: `cd .worktrees/architecture-improvements && bundle install`

**Step 3: Create test helper with SimpleCov**

Create `test/test_helper.rb`:

```ruby
require "simplecov"
SimpleCov.start do
  add_filter "/test/"
  add_filter "/vendor/"
  add_group "Libraries", "lib/vibe"
  add_group "CLI", "bin/vibe"
  minimum_coverage 80
end

require "minitest/autorun"
```

**Step 4: Update all test files to use test_helper**

Update first line of each test file from:
```ruby
require "minitest/autorun"
```

To:
```ruby
require_relative "test_helper"
```

Files to update:
- `test/test_vibe_cli.rb`
- `test/test_vibe_overlay.rb`
- `test/test_vibe_init.rb`
- `test/test_vibe_external_tools.rb`
- `test/test_path_overlap_calculation.rb`
- `test/test_cli_path_safety_guards.rb`
- `test/test_vibe_utils.rb`
- `test/test_yaml_safety.rb`
- `test/test_recommendations.rb`

**Step 5: Run tests with coverage**

Run: `cd .worktrees/architecture-improvements && bundle exec ruby test/test_vibe_utils.rb`
Expected: PASS with coverage report generated

**Step 6: Add coverage directory to gitignore**

Add to `.gitignore`:
```
# Test coverage
/coverage/
```

**Step 7: Commit**

```bash
cd .worktrees/architecture-improvements
git add Gemfile Gemfile.lock test/test_helper.rb test/*.rb .gitignore
git commit -m "feat(test): integrate SimpleCov for test coverage reporting"
```

---

## Phase 2: Dependency Injection and Performance (P1)

### Task 4: Introduce Dependency Injection Container

**Files:**
- Create: `lib/vibe/container.rb`
- Modify: `bin/vibe`
- Test: `test/test_vibe_container.rb`

**Step 1: Write failing test for DI container**

Create `test/test_vibe_container.rb`:

```ruby
require_relative "test_helper"
load File.expand_path("../bin/vibe", __dir__)

class TestVibeContainer < Minitest::Test
  def test_container_provides_utils
    container = Vibe::Container.new("/tmp/test")
    assert_instance_of Module, container.utils
  end

  def test_container_provides_yaml_loader
    container = Vibe::Container.new("/tmp/test")
    assert container.respond_to?(:yaml_loader)
  end
end
```

**Step 2: Run test to verify it fails**

Run: `cd .worktrees/architecture-improvements && bundle exec ruby test/test_vibe_container.rb`
Expected: FAIL with "uninitialized constant Vibe::Container"

**Step 3: Create dependency injection container**

Create `lib/vibe/container.rb`:

```ruby
# frozen_string_literal: true

require_relative "utils"
require_relative "errors"
require_relative "doc_rendering"
require_relative "native_configs"
require_relative "overlay_support"
require_relative "path_safety"
require_relative "target_renderers"
require_relative "external_tools"
require_relative "init_support"

module Vibe
  # Simple dependency injection container for Vibe components.
  # Allows easier testing and configuration management.
  class Container
    attr_reader :repo_root

    def initialize(repo_root)
      @repo_root = repo_root
      @services = {}
    end

    def utils
      @services[:utils] ||= Utils
    end

    def yaml_loader
      @services[:yaml_loader] ||= ->(path) { YAML.load_file(File.join(@repo_root, path)) }
    end

    def register(name, service)
      @services[name] = service
    end

    def resolve(name)
      @services[name] || raise(ConfigurationError, "Service #{name} not registered")
    end
  end
end
```

**Step 4: Update bin/vibe to use container**

Modify `bin/vibe`:

```ruby
require_relative "../lib/vibe/container"

class VibeCLI
  def initialize(repo_root, container: nil)
    @repo_root = repo_root
    @skip_integrations = false
    @yaml_mutex = Mutex.new
    @container = container || Vibe::Container.new(repo_root)
  end
  
  # ... rest of the code ...
end
```

**Step 5: Run test to verify it passes**

Run: `cd .worktrees/architecture-improvements && bundle exec ruby test/test_vibe_container.rb`
Expected: PASS

**Step 6: Commit**

```bash
cd .worktrees/architecture-improvements
git add lib/vibe/container.rb bin/vibe test/test_vibe_container.rb
git commit -m "feat(di): introduce dependency injection container"
```

---

### Task 5: Add Performance Benchmarks

**Files:**
- Create: `test/benchmark/utils_benchmark.rb`
- Create: `test/benchmark/yaml_loading_benchmark.rb`

**Step 1: Create benchmark for utils methods**

Create `test/benchmark/utils_benchmark.rb`:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "benchmark"
require_relative "../../bin/vibe"

repo_root = File.expand_path("../..", __dir__)
cli = VibeCLI.new(repo_root)

n = 10_000

Benchmark.bmbm do |x|
  x.report("deep_merge:") do
    n.times do
      cli.send(:deep_merge, { a: 1, b: { c: 2 } }, { b: { d: 3 }, e: 4 })
    end
  end

  x.report("deep_copy:") do
    n.times do
      cli.send(:deep_copy, { a: 1, b: [2, 3], c: { d: 4 } })
    end
  end
end
```

**Step 2: Create benchmark for YAML loading**

Create `test/benchmark/yaml_loading_benchmark.rb`:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "benchmark"
require_relative "../../bin/vibe"

repo_root = File.expand_path("../..", __dir__)
cli = VibeCLI.new(repo_root)

n = 100

Benchmark.bmbm do |x|
  x.report("tiers_doc (first load):") do
    n.times do
      new_cli = VibeCLI.new(repo_root)
      new_cli.tiers_doc
    end
  end

  x.report("tiers_doc (cached):") do
    n.times do
      cli.tiers_doc
    end
  end
end
```

**Step 3: Run benchmarks to establish baseline**

Run: 
```bash
cd .worktrees/architecture-improvements
chmod +x test/benchmark/*.rb
ruby test/benchmark/utils_benchmark.rb
ruby test/benchmark/yaml_loading_benchmark.rb
```

**Step 4: Commit**

```bash
cd .worktrees/architecture-improvements
git add test/benchmark/
git commit -m "feat(perf): add performance benchmarks for critical operations"
```

---

## Phase 3: Code Quality Improvements (P2)

### Task 6: Refactor bin/vibe to Reduce Duplication

**Files:**
- Modify: `bin/vibe:84-200`
- Test: `test/test_vibe_cli.rb`

**Step 1: Identify duplication patterns**

Current pattern in `bin/vibe`:
```ruby
when "build"
  run_build(argv)
when "use"
  run_use(argv, switch_mode: false)
when "switch"
  run_use(argv, switch_mode: true)
# ... more cases
```

**Step 2: Extract command registry pattern**

Add to `bin/vibe`:

```ruby
class VibeCLI
  COMMAND_REGISTRY = {
    "build" => :run_build,
    "use" => :run_use_with_switch_false,
    "switch" => :run_use_with_switch_true,
    "inspect" => :run_inspect,
    "init" => :run_init_command,
    "quickstart" => :run_quickstart_command,
    "targets" => :run_targets_command
  }.freeze

  def run(argv)
    command = argv.shift
    
    if COMMAND_REGISTRY.key?(command)
      send(COMMAND_REGISTRY[command], argv)
    else
      usage_exit("Unknown command: #{command}")
    end
  end

  private

  def run_use_with_switch_false(argv)
    run_use(argv, switch_mode: false)
  end

  def run_use_with_switch_true(argv)
    run_use(argv, switch_mode: true)
  end
end
```

**Step 3: Run all tests to verify no regression**

Run: `cd .worktrees/architecture-improvements && bundle exec ruby test/test_vibe_cli.rb`
Expected: PASS

**Step 4: Commit**

```bash
cd .worktrees/architecture-improvements
git add bin/vibe
git commit -m "refactor(cli): extract command registry pattern to reduce duplication"
```

---

### Task 7: Improve Error Messages with Context

**Files:**
- Modify: `lib/vibe/errors.rb`
- Modify: `lib/vibe/path_safety.rb`
- Test: `test/test_cli_path_safety_guards.rb`

**Step 1: Enhance error classes with context**

Modify `lib/vibe/errors.rb`:

```ruby
# frozen_string_literal: true

module Vibe
  class Error < StandardError
    attr_reader :context

    def initialize(message, context: {})
      @context = context
      super(message)
    end

    def to_s
      return super if context.empty?
      "#{super} [Context: #{context.inspect}]"
    end
  end

  class PathSafetyError < Error; end
  class SecurityError < Error; end
  
  class ValidationError < Error
    attr_reader :field, :value

    def initialize(message, field: nil, value: nil, context: {})
      @field = field
      @value = value
      super(message, context: context)
    end

    def to_s
      msg = super
      msg = "#{msg} (field: #{field})" if field
      msg
    end
  end

  class ConfigurationError < Error; end
  class ExternalToolError < Error; end
end
```

**Step 2: Update path_safety to use enhanced errors**

Modify `lib/vibe/path_safety.rb`:

```ruby
def ensure_safe_output_path!(output_root)
  expanded = normalize_path(output_root)
  home = File.expand_path(Dir.home)
  repo = File.expand_path(@repo_root)

  # ... existing checks ...

  if expanded == repo || (expanded.start_with?("#{repo}/") && !expanded.start_with?("#{repo}/generated/"))
    raise PathSafetyError.new(
      "Refusing to use output root that overlaps with source repo",
      context: {
        output_path: expanded,
        repo_path: repo,
        suggestion: "Use a path under generated/ or an external directory"
      }
    )
  end
  
  # ... rest of method ...
end
```

**Step 3: Add test for enhanced error messages**

Add to `test/test_cli_path_safety_guards.rb`:

```ruby
def test_path_safety_error_includes_context
  error = assert_raises(Vibe::PathSafetyError) do
    @cli.send(:ensure_safe_output_path!, @repo_root)
  end
  
  assert_includes error.message, "overlaps with source repo"
  assert error.context[:suggestion]
end
```

**Step 4: Run test to verify it passes**

Run: `cd .worktrees/architecture-improvements && bundle exec ruby test/test_cli_path_safety_guards.rb -n test_path_safety_error_includes_context`
Expected: PASS

**Step 5: Commit**

```bash
cd .worktrees/architecture-improvements
git add lib/vibe/errors.rb lib/vibe/path_safety.rb test/test_cli_path_safety_guards.rb
git commit -m "feat(errors): add context support to error classes for better debugging"
```

---

### Task 8: Add Code Quality Checks to CI

**Files:**
- Modify: `.github/workflows/ci.yml`
- Create: `.rubocop.yml` (optional)

**Step 1: Add SimpleCov enforcement to CI**

Modify `.github/workflows/ci.yml`:

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '2.6'
        bundler-cache: true
    
    - name: Run tests with coverage
      run: |
        bundle exec ruby test/test_vibe_cli.rb
        bundle exec ruby test/test_vibe_utils.rb
        bundle exec ruby test/test_vibe_overlay.rb
        bundle exec ruby test/test_vibe_init.rb
        bundle exec ruby test/test_vibe_external_tools.rb
        bundle exec ruby test/test_path_overlap_calculation.rb
        bundle exec ruby test/test_cli_path_safety_guards.rb
        bundle exec ruby test/test_yaml_safety.rb
        bundle exec ruby test/test_recommendations.rb
    
    - name: Check coverage threshold
      run: |
        if [ -f coverage/.last_run.json ]; then
          coverage=$(ruby -rjson -e "puts JSON.parse(File.read('coverage/.last_run.json'))['result']['covered_percent']")
          echo "Coverage: ${coverage}%"
          if (( $(echo "$coverage < 80.0" | bc -l) )); then
            echo "Coverage ${coverage}% is below threshold 80%"
            exit 1
          fi
        fi
    
    - name: Run smoke test
      run: bin/vibe-smoke
```

**Step 2: Run CI locally to verify**

Run: 
```bash
cd .worktrees/architecture-improvements
# Run all tests
bundle exec ruby test/test_*.rb
```

**Step 3: Commit**

```bash
cd .worktrees/architecture-improvements
git add .github/workflows/ci.yml
git commit -m "ci: add coverage threshold check and improve test coverage"
```

---

## Final Verification

### Task 9: Run Full Test Suite and Coverage Report

**Step 1: Run all tests**

Run:
```bash
cd .worktrees/architecture-improvements
bundle exec ruby test/test_vibe_cli.rb
bundle exec ruby test/test_vibe_utils.rb
bundle exec ruby test/test_vibe_overlay.rb
bundle exec ruby test/test_vibe_init.rb
bundle exec ruby test/test_vibe_external_tools.rb
bundle exec ruby test/test_path_overlap_calculation.rb
bundle exec ruby test/test_cli_path_safety_guards.rb
bundle exec ruby test/test_yaml_safety.rb
bundle exec ruby test/test_recommendations.rb
bundle exec ruby test/test_vibe_container.rb
```

Expected: All tests PASS

**Step 2: Generate coverage report**

Run:
```bash
cd .worktrees/architecture-improvements
bundle exec ruby test/test_vibe_utils.rb
open coverage/index.html  # macOS
```

Expected: Coverage report shows >= 80% coverage

**Step 3: Run benchmarks**

Run:
```bash
cd .worktrees/architecture-improvements
ruby test/benchmark/utils_benchmark.rb
ruby test/benchmark/yaml_loading_benchmark.rb
```

Expected: Benchmarks complete successfully

**Step 4: Run smoke test**

Run:
```bash
cd .worktrees/architecture-improvements
bin/vibe-smoke
```

Expected: All smoke tests PASS

**Step 5: Final commit**

```bash
cd .worktrees/architecture-improvements
git add -A
git commit -m "docs: update architecture with improvements and coverage reports"
```

---

## Success Criteria

- [ ] All existing tests pass
- [ ] New tests for type validation pass
- [ ] Thread safety tests pass consistently
- [ ] SimpleCov coverage >= 80%
- [ ] Performance benchmarks establish baseline
- [ ] DI container enables easier testing
- [ ] Error messages include helpful context
- [ ] CI enforces coverage threshold
- [ ] Code duplication reduced
- [ ] Documentation updated

---

## Rollback Plan

If any task causes issues:

1. `git log --oneline` to see recent commits
2. `git revert <commit-sha>` to revert specific commit
3. Or `git reset --hard <commit-sha>` to reset to specific point
4. Run tests to verify rollback successful

---

## Notes

- Each task is designed to be independent and reversible
- Tests are written before implementation (TDD)
- Commits are frequent and atomic
- Coverage reports help identify untested code
- Benchmarks help detect performance regressions
