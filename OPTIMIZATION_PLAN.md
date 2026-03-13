# 优化计划：聚焦双平台（Claude Code + OpenCode）

> 创建时间：2026-03-12
> 目标：从8平台表面支持转向2平台深度支持

---

## 背景

经过深度评审，发现项目存在以下问题：
1. **声称过度**："自动保存"、"自动学习"等功能实际是"提示驱动"
2. **平台过多**：8个平台只有Claude Code真正可用，造成用户困惑
3. **测试不足**：核心渲染模块无测试，覆盖率仅58%
4. **代码冗余**：60%+代码重复，8个平台渲染器高度相似

**决策**：聚焦到 Claude Code + OpenCode 双平台，其他平台暂不维护。

---

## 聚焦策略

### 保留平台

| 平台 | 状态 | 优先级 |
|------|------|--------|
| **Claude Code** | ✅ 生产就绪 | P0 - 核心支持 |
| **OpenCode** | ✅ 生产就绪 | P0 - 核心支持 |

### 暂停平台（暂不删除，仅标记为计划中）

| 平台 | 状态 | 说明 |
|------|------|------|
| Cursor | ⏸️ 计划中 | 社区贡献欢迎 |
| Warp | ⏸️ 计划中 | 社区贡献欢迎 |
| VS Code | ⏸️ 计划中 | 社区贡献欢迎 |
| Kimi Code | ⏸️ 计划中 | 社区贡献欢迎 |
| Codex CLI | ⏸️ 计划中 | 社区贡献欢迎 |
| Antigravity | ⏸️ 计划中 | 社区贡献欢迎 |

---

## 实施阶段

### Phase 0：立即执行（本周）

#### 0.1 平台裁剪
- [ ] 修改 README.md，明确双平台聚焦
- [ ] 限制 `SUPPORTED_TARGETS` 常量
- [ ] 更新安装说明

#### 0.2 诚实化文档
- [ ] 重写 "What This Workflow Provides"
- [ ] 添加 "Known Limitations" 章节
- [ ] 创建 `docs/messaging-guidelines.md`
- [ ] 创建 `docs/faq.md`

**交付物**：诚实反映能力的文档

---

### Phase 1：核心稳定（2周）

#### 1.1 P0 修复 ✅（已完成）
- [x] 修复测试失败
- [x] 消除 Ruby 警告
- [x] 更新 .gitignore

#### 1.2 测试覆盖提升

| 模块 | 当前 | 目标 | 优先级 |
|------|------|------|--------|
| `utils.rb` | 良好 | 80% | P2 |
| `path_safety.rb` | 良好 | 80% | P2 |
| `overlay_support.rb` | 良好 | 80% | P2 |
| `external_tools.rb` | 良好 | 80% | P2 |
| `doc_rendering.rb` | ❌ 无 | 75% | **P1** |
| `target_renderers.rb` | ❌ 无 | 75% | **P1** |
| `native_configs.rb` | ❌ 无 | 75% | **P1** |

**Week 1 任务**：
- [ ] `test/renderers/test_doc_rendering.rb` (6h)
- [ ] `test/renderers/test_target_renderers.rb` (8h)

**Week 2 任务**：
- [ ] `test/unit/test_native_configs.rb` (4h)
- [ ] `test/integration/test_cli.rb` (6h)

#### 1.3 多语言支持

更新核心规则文件支持中英文：

```markdown
## Exit Signals / 退出信号

**English:** "I'm heading out", "Done for today"
**Chinese:** "我要走了", "今天就到这里", "结束了"
```

**文件清单**：
- [ ] `rules/memory-flush.md`
- [ ] `rules/behaviors.md`
- [ ] `rules/skill-triggers.md`

---

### Phase 2：架构简化（2-3周）

#### 2.1 渲染器重构

**目标**：配置驱动，消除重复

```yaml
# config/platforms.yaml
platforms:
  claude-code:
    entrypoint: CLAUDE.md
    doc_types: [behavior, safety, task_routing, test_standards]

  opencode:
    entrypoint: AGENTS.md
    doc_types: [behavior, general, routing, skills, safety, execution]
```

**代码简化**：
- 从 ~1149行 减少到 ~300行
- 通用 `render_platform` 方法
- 删除6个暂停平台的渲染代码

#### 2.2 集成渲染简化

**当前**：164行嵌套条件
**目标**：~50行模板驱动

```ruby
# lib/vibe/integration_renderer.rb
TEMPLATES = {
  'claude-code' => { superpowers: 'templates/claude-code/superpowers.md.erb' },
  'opencode' => { superpowers: 'templates/opencode/superpowers.md.erb' }
}
```

#### 2.3 清理代码

- [ ] 删除暂停平台的渲染代码
- [ ] 删除相关测试
- [ ] 清理文档引用

---

### Phase 3：功能增强（2周）

#### 3.1 结构化记忆（YAML格式）

**替代**：`memory/project-knowledge.md` → `memory/knowledge.yaml`

```yaml
schema_version: 1

lessons:
  - id: yaml-validation
    keywords: [yaml, validation, YAML, 验证]
    issue: "YAML files can be syntactically valid but semantically incorrect"
    issue_zh: "YAML文件语法正确但语义可能错误"
    solution: "Use JSON Schema"
    solution_zh: "使用JSON Schema验证"
    times_used: 0
```

**优势**：
- 多语言关键词匹配
- 使用频率追踪
- 结构化查询

#### 3.2 Session 捕获脚本（可选）

```bash
# scripts/session-capture.sh
# 手动调用保存会话状态
```

---

### Phase 4：文档完善（1周）

#### 4.1 文档结构重组

```
docs/
├── README.md
├── getting-started/
│   ├── claude-code.md
│   └── opencode.md
├── configuration/
│   ├── overlays.md
│   └── skills.md
└── reference/
    ├── messaging-guidelines.md
    └── faq.md
```

#### 4.2 双平台快速开始指南

**Claude Code**：
```bash
bin/vibe init --platform claude-code
cd your-project && vibe switch --platform claude-code
claude
```

**OpenCode**：
```bash
bin/vibe init --platform opencode
cd your-project && vibe switch --platform opencode
opencode
```

---

## 时间线

| 阶段 | 时长 | 开始 | 结束 | 关键交付 |
|------|------|------|------|----------|
| Phase 0 | 1周 | W1 | W1 | 诚实文档、平台聚焦 |
| Phase 1 | 2周 | W2 | W3 | 测试覆盖率75%+ |
| Phase 2 | 2-3周 | W4 | W6 | 架构简化、代码清理 |
| Phase 3 | 2周 | W7 | W8 | 结构化记忆、功能增强 |
| Phase 4 | 1周 | W9 | W9 | 文档完善 |

**总计：8-9周**

---

## 成功标准

- [ ] 仅支持 Claude Code 和 OpenCode（明确无困惑）
- [ ] 测试覆盖率 ≥ 75%
- [ ] 零 Ruby 警告
- [ ] 所有测试通过
- [ ] 文档诚实反映能力
- [ ] 中英文关键词支持
- [ ] 结构化记忆系统（YAML）

---

## Agent团队交付物索引

本计划基于以下Agent分析：

| 角色 | Agent ID | 交付物 |
|------|----------|--------|
| 开发工程师 | a33938709 | P0修复代码 |
| 产品经理 | a24b5a96 | README重写、FAQ、messaging-guidelines |
| 测试工程师 | ab92d3be | 测试策略、覆盖率分析 |
| 架构师 | a69b31e2 | 架构重构设计、ADR文档 |
| 质量控制 | a2e3b644 | 代码质量审计 |

**相关文件**：
- `docs/architecture/` - 架构设计文档
- `docs/messaging-guidelines.md` - 消息指南（待创建）
- `docs/faq.md` - 常见问题（待创建）

---

## 下一步行动

1. **今天**：修改README，聚焦双平台
2. **明天**：应用诚实文档
3. **本周**：限制SUPPORTED_TARGETS
4. **下周**：开始编写渲染器测试

**准备工作已完成，可以开始执行。**