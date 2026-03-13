# 技能自适应系统设计方案

**文档版本**: 1.0  
**设计日期**: 2026-03-14  
**状态**: 已批准，准备实现

---

## 📋 执行摘要

### 背景
当前项目默认使用 Superpowers 相关技能和 RTK 工具，但缺乏自动适配机制。用户在安装新技能后，需要手动了解技能功能并决定如何适配到项目，门槛较高。

### 目标
1. **自动化技能检测**: 自动发现新安装的技能
2. **智能适配建议**: 根据项目类型和用户需求推荐适配方式
3. **简化配置流程**: 一键式技能适配，降低使用门槛
4. **提升可扩展性**: 支持任意技能包的自动适配

### 核心功能
- `vibe install <skill-pack>`: 安装技能包并自动适配
- `vibe skills check`: 检测并适配新技能
- `vibe skills adapt`: 显式适配特定技能
- 自动集成到 `vibe apply` 和 `vibe doctor`

---

## 🏗️ 架构设计

### 系统架构图

```
┌─────────────────────────────────────────────────────────────┐
│                     Skill Adaptation System                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   Install    │    │    Check     │    │    Adapt     │  │
│  │   Wrapper    │───▶│   Detector   │───▶│   Manager    │  │
│  │              │    │              │    │              │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│         │                   │                   │           │
│         ▼                   ▼                   ▼           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Skill Registry Scanner                   │  │
│  │  (core/skills/registry.yaml + ~/.config/skills/)     │  │
│  └──────────────────────────────────────────────────────┘  │
│                            │                                │
│                            ▼                                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │            Project Skill Configuration                │  │
│  │         (.vibe/skills.yaml + CLAUDE.md)              │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 核心模块

#### 1. SkillInstaller (安装包装器)
**职责**: 包装技能安装流程，安装后触发适配

```ruby
module Vibe
  class SkillInstaller
    def install(skill_pack, platform: nil)
      # 1. 执行原生安装
      success = execute_installation(skill_pack, platform)
      
      # 2. 安装成功后检测新技能
      if success
        new_skills = detect_new_skills(skill_pack)
        
        # 3. 触发适配流程
        if new_skills.any?
          SkillAdapter.new(new_skills).adapt_interactively
        end
      end
      
      success
    end
  end
end
```

#### 2. SkillDetector (技能检测器)
**职责**: 检测新安装的技能包和技能

```ruby
module Vibe
  class SkillDetector
    def detect_new_skills(skill_pack = nil)
      # 1. 读取技能注册表
      registry_skills = load_skill_registry
      
      # 2. 读取项目已适配的技能
      adapted_skills = load_project_skills
      
      # 3. 检测差异
      registry_skills - adapted_skills
    end
    
    def detect_newly_installed_packs
      # 检测 ~/.config/skills/ 目录变化
      # 对比上次检测时间戳
    end
  end
end
```

#### 3. SkillAdapter (技能适配器)
**职责**: 交互式技能适配，更新项目配置

```ruby
module Vibe
  class SkillAdapter
    def adapt_interactively(skills)
      # 1. 批量或逐个适配
      mode = select_adaptation_mode
      
      case mode
      when :batch_suggest
        adapt_all_as_suggest(skills)
      when :batch_mandatory
        adapt_all_as_mandatory(skills)
      when :individual
        adapt_individually(skills)
      end
      
      # 2. 更新项目配置
      update_project_configuration
    end
    
    def adapt_skill(skill, mode)
      # 根据模式适配技能
      # mode: :suggest, :mandatory, :skip
    end
  end
end
```

---

## 📊 数据模型

### 项目技能配置 (.vibe/skills.yaml)

```yaml
schema_version: 1
last_checked: 2026-03-14T10:00:00Z

adapted_skills:
  superpowers/tdd:
    mode: suggest
    adapted_at: 2026-03-14T10:00:00Z
    adapted_by: user_choice
    
  superpowers/brainstorm:
    mode: mandatory
    adapted_at: 2026-03-14T10:05:00Z
    adapted_by: user_choice
    
  builtin/systematic-debugging:
    mode: mandatory
    adapted_at: 2026-03-14T09:00:00Z
    adapted_by: auto_detect

skipped_skills:
  - id: superpowers/optimize
    skipped_at: 2026-03-14T10:10:00Z
    reason: user_choice
    
  - id: project/legacy-migration
    skipped_at: 2026-03-14T10:15:00Z
    reason: not_applicable

installed_packs:
  superpowers:
    version: "1.2.3"
    installed_at: 2026-03-14T10:00:00Z
    skills_adapted: 5
    skills_skipped: 2
    
  custom-pack:
    version: "0.1.0"
    installed_at: 2026-03-14T11:00:00Z
    skills_adapted: 0
    skills_skipped: 0
```

### 技能元数据

```ruby
{
  id: "superpowers/tdd",
  namespace: "superpowers",
  name: "Test-Driven Development",
  description: "Systematic TDD workflow with red-green-refactor cycle",
  intent: "Implement features using test-driven development",
  trigger_mode: "suggest",  # 适配后设置
  priority: "P1",
  requires_tools: ["Read", "Grep", "Bash"],
  supported_targets: {
    "claude-code" => "native-skill",
    "opencode" => "native-skill",
    "codex-cli" => "agents-md-or-wrapper"
  },
  entrypoint: "skills/tdd/SKILL.md",
  safety_level: "trusted_external"
}
```

---

## 🎨 用户交互设计

### 命令行界面

#### 1. vibe install <skill-pack>

```bash
$ vibe install superpowers

🚀 Installing Superpowers Skill Pack
============================================================

📦 Skill Pack: superpowers
📍 Install Location: ~/.config/skills/superpowers
🔧 Platform: claude-code (auto-detected)

Cloning from https://github.com/obra/superpowers.git...
✓ Cloned successfully

Creating skill symlinks in ~/.claude/skills/...
✓ Created 7 skill symlinks

🎉 Installation Complete!

🔍 Detecting Available Skills...
Found 7 new skills in superpowers pack:

  1. ✅ superpowers/tdd
     Test-driven development workflow
     
  2. ✅ superpowers/brainstorm
     Design exploration and ideation
     
  3. ✅ superpowers/refactor
     Systematic code refactoring
     
  4. ✅ superpowers/debug
     Root cause analysis
     
  5. ✅ superpowers/architect
     Architecture design
     
  6. ✅ superpowers/review
     Code review workflow
     
  7. ✅ superpowers/optimize
     Performance optimization

🤔 How would you like to adapt these skills?

[1] ⚡ Quick Setup - Adapt all as suggest (recommended)
[2] 🔒 Strict Mode - Adapt all as mandatory
[3] 🔍 Review Each - Decide individually
[4] ⏭️  Skip - Don't adapt now (you can adapt later)
[5] ❓ Help - Learn more about skill adaptation

Your choice [1/2/3/4/5]: 3

Reviewing skills individually:
------------------------------------------------------------

📦 Skill 1/7: superpowers/tdd
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Name: Test-Driven Development
Intent: Implement features using test-driven development

Description:
  Enforces red-green-refactor cycle. Requires tests before
  implementation. Validates coverage before completion.

Trigger Conditions:
  - When implementing new features
  - When fixing bugs
  - When adding tests

Required Tools: Read, Grep, Bash (for running tests)
Safety Level: trusted_external

💡 Recommendation: Suggest mode for most projects

Adapt this skill as:
  [s] Suggest    - Recommend when relevant (recommended)
  [m] Mandatory  - Always use this skill
  [i] Ignore     - Skip this skill
  [v] View Docs  - Read full documentation
  [?] Help       - Explain adaptation modes

Your choice [s/m/i/v/?]: s

✅ Adapted as: suggest
   The skill will be suggested when relevant to your task.

Press Enter to continue to next skill...

📦 Skill 2/7: superpowers/optimize
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Name: Performance Optimization
Intent: Optimize code performance when needed

Description:
  Systematic performance analysis and optimization workflow.
  Includes profiling, bottleneck identification, and fixes.

💡 Recommendation: Suggest mode unless working on performance-critical code

Adapt this skill as: [s/m/i/v/?]: i

⏸️  Skipped
   You can adapt this skill later with:
   vibe skills adapt superpowers/optimize

...

📊 Adaptation Summary
============================================================

✅ Adapted (5 skills):
   • superpowers/tdd (suggest)
   • superpowers/brainstorm (suggest)
   • superpowers/refactor (suggest)
   • superpowers/debug (suggest)
   • superpowers/review (mandatory)

⏸️  Skipped (2 skills):
   • superpowers/optimize
   • superpowers/architect

📝 Project Configuration Updated!
   Skills configuration saved to: .vibe/skills.yaml

🚀 Next Steps:
   1. Review adapted skills: vibe skills list
   2. Apply to project: vibe apply claude-code
   3. View skill docs: vibe skills docs superpowers/tdd

✨ Happy coding with your new skills!
```

#### 2. vibe skills check

```bash
$ vibe skills check

🔍 Checking for New Skills
============================================================

Last checked: 2026-03-13T15:30:00Z (24 hours ago)

Scanning skill registries...
✓ Checked core/skills/registry.yaml
✓ Checked ~/.config/skills/

📦 Results:
   No new skills found.

   You have 12 skills adapted:
   • 5 mandatory skills
   • 7 suggest skills

💡 Tip: Run 'vibe skills list' to see all adapted skills.
```

#### 3. vibe skills list

```bash
$ vibe skills list

📋 Adapted Skills
============================================================

🔒 Mandatory Skills (always active):
   • builtin/systematic-debugging
   • builtin/verification-before-completion
   • superpowers/review

💡 Suggest Skills (recommended when relevant):
   • builtin/session-end
   • builtin/planning-with-files
   • superpowers/tdd
   • superpowers/brainstorm
   • superpowers/refactor
   • superpowers/debug

⏸️  Skipped Skills (not adapted):
   • superpowers/optimize
   • superpowers/architect

📊 Summary: 8 active, 2 skipped, 3 available but not adapted

💡 Commands:
   vibe skills adapt <id>     - Adapt a skipped skill
   vibe skills skip <id>      - Skip an available skill
   vibe skills docs <id>      - View skill documentation
```

---

## 🔧 实现细节

### 文件结构

```
lib/vibe/
├── skill_installer.rb          # 安装包装器
├── skill_detector.rb           # 技能检测器
├── skill_adapter.rb            # 技能适配器
├── skill_manager.rb            # 统一管理入口
└── cli/
    └── skills_commands.rb      # CLI 命令实现
```

### 核心算法

#### 技能差异检测

```ruby
def detect_skill_changes
  # 1. 加载注册表技能
  registry = load_skill_registry
  
  # 2. 加载项目配置
  project = load_project_skills
  
  # 3. 计算差异
  {
    new: registry - project.adapted - project.skipped,
    updated: detect_updates(registry, project),
    removed: project.adapted - registry
  }
end
```

#### 智能推荐算法

```ruby
def recommend_adaptation_mode(skill, project_context)
  # 基于项目类型推荐
  case project_context[:type]
  when :python
    return :mandatory if skill.id == 'superpowers/tdd'
    return :suggest if skill.id.include?('test')
  when :performance_critical
    return :mandatory if skill.id == 'superpowers/optimize'
  end
  
  # 基于技能优先级
  case skill.priority
  when 'P0' then :mandatory
  when 'P1' then :suggest
  else :suggest
  end
end
```

---

## 🧪 测试策略

### 单元测试

```ruby
# test/skill_detector_test.rb
def test_detect_new_skills
  # 模拟注册表有3个技能，项目已适配2个
  registry = [skill_a, skill_b, skill_c]
  project = { adapted: [skill_a, skill_b] }
  
  detector = SkillDetector.new(registry, project)
  new_skills = detector.detect_new_skills
  
  assert_equal [skill_c], new_skills
end

def test_recommend_adaptation_mode
  adapter = SkillAdapter.new
  
  # P0 技能推荐 mandatory
  p0_skill = Skill.new(priority: 'P0')
  assert_equal :mandatory, adapter.recommend_mode(p0_skill)
  
  # P1 技能推荐 suggest
  p1_skill = Skill.new(priority: 'P1')
  assert_equal :suggest, adapter.recommend_mode(p1_skill)
end
```

### 集成测试

```ruby
# test/skill_installation_flow_test.rb
def test_full_installation_and_adaptation_flow
  # 1. 安装技能包
  installer = SkillInstaller.new
  assert installer.install('superpowers')
  
  # 2. 检测新技能
  detector = SkillDetector.new
  new_skills = detector.detect_new_skills
  assert new_skills.any?
  
  # 3. 适配技能
  adapter = SkillAdapter.new(new_skills)
  adapter.adapt_all_as(:suggest)
  
  # 4. 验证配置更新
  config = load_project_skills
  assert config[:adapted_skills].any?
end
```

---

## 📈 性能考虑

### 优化策略

1. **缓存机制**
   - 缓存技能注册表解析结果
   - 缓存项目技能配置
   - 定期刷新（默认24小时）

2. **增量检测**
   - 只检测变化的技能包
   - 使用时间戳对比
   - 避免全量扫描

3. **异步处理**
   - 大型技能包适配可异步进行
   - 不阻塞主流程

### 性能指标

- 技能检测: < 100ms
- 配置更新: < 50ms
- 交互响应: < 10ms

---

## 🔒 安全考虑

### 安全措施

1. **技能来源验证**
   - 只接受可信来源的技能
   - 验证技能包签名（未来）

2. **权限控制**
   - 适配前确认用户权限
   - 不自动适配高风险技能

3. **配置备份**
   - 更新前备份原配置
   - 支持回滚操作

---

## 🚀 部署计划

### Phase 1: 基础功能 (3-4 天)

1. **Day 1-2**: 实现 SkillInstaller 和 SkillDetector
2. **Day 3**: 实现基础 SkillAdapter
3. **Day 4**: 集成测试和调试

### Phase 2: 交互功能 (4-5 天)

1. **Day 1-2**: 实现交互式适配界面
2. **Day 3**: 实现批量适配模式
3. **Day 4**: 智能推荐算法
4. **Day 5**: 集成测试

### Phase 3: 增强功能 (2-3 天)

1. **Day 1**: 实现 vibe skills 子命令
2. **Day 2**: 集成到 vibe apply 和 vibe doctor
3. **Day 3**: 文档和示例

### 总计: 9-12 天

---

## 📝 后续优化

### 未来功能

1. **技能市场**
   - 浏览和搜索技能包
   - 评分和评论系统

2. **自动更新**
   - 检测技能包更新
   - 自动适配新技能

3. **团队协作**
   - 共享技能配置
   - 团队技能标准

4. **AI 推荐**
   - 基于代码分析推荐技能
   - 学习用户偏好

---

## ✅ 验收标准

### 功能验收

- [ ] `vibe install superpowers` 安装并适配技能
- [ ] `vibe skills check` 检测新技能
- [ ] `vibe skills list` 显示已适配技能
- [ ] `vibe skills adapt` 显式适配技能
- [ ] `vibe apply` 自动检测技能变化
- [ ] `vibe doctor` 包含技能状态检查

### 质量验收

- [ ] 测试覆盖率 > 80%
- [ ] 所有测试通过
- [ ] 文档完整
- [ ] 性能达标

### 用户体验验收

- [ ] 交互流畅，响应迅速
- [ ] 错误提示清晰
- [ ] 帮助文档完整
- [ ] 示例充分

---

**设计完成，准备进入实现阶段！**
