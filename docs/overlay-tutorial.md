# Overlay 使用教程

**文档版本**: 1.0  
**最后更新**: 2026-03-14

---

## 📖 什么是 Overlay？

Overlay 允许你在不修改核心配置的情况下，为特定项目添加自定义配置。这对于以下场景非常有用：

- **项目特定需求**: 某些项目需要特殊的路由配置或安全策略
- **团队规范**: 为团队项目添加统一的规则
- **环境差异**: 开发、测试、生产环境的不同配置
- **临时调整**: 为特定任务临时修改配置

---

## 🚀 快速开始

### 1. 创建 Overlay 文件

在项目根目录创建 `.vibe/overlay.yaml`：

```yaml
schema_version: 1
name: my-project-overlay
description: Custom configuration for my project

profile:
  mapping_overrides:
    critical_reasoner: claude.opus-class
    workhorse_coder: claude.sonnet-class

policies:
  append:
    - id: project-specific-rule
      category: project_memory
      enforcement: recommended
      target_render_group: always_on
      summary: Always check PROJECT_CONTEXT.md before making changes
```

### 2. 应用 Overlay

```bash
# 自动发现 .vibe/overlay.yaml
vibe apply claude-code

# 或者显式指定 overlay 文件
vibe apply claude-code --overlay ./my-overlay.yaml

# 构建时也可以使用 overlay
vibe build claude-code --overlay ./my-overlay.yaml
```

---

## 📋 Overlay 文件格式

### 完整示例

```yaml
schema_version: 1                    # 必需：Schema 版本
name: example-overlay                # 可选：Overlay 名称
description: Example configuration   # 可选：描述

profile:
  mapping_overrides:                 # 覆盖模型映射
    critical_reasoner: openai.gpt-4
    workhorse_coder: anthropic.claude-3
  
  note_append:                       # 追加到配置文件的注释
    - "Use Python 3.11 for this project"
    - "Always run tests before committing"

policies:
  append:                            # 添加自定义策略
    - id: custom-security-check
      category: safety
      enforcement: mandatory
      target_render_group: safety
      summary: Verify all external API calls
      
    - id: project-context-required
      category: project_memory
      enforcement: recommended
      target_render_group: always_on
      summary: Check PROJECT_CONTEXT.md before database migrations

targets:
  claude-code:                       # 平台特定配置
    permissions:
      ask:
        - "Bash(./scripts/deploy:*)"
      deny:
        - "Read(./secrets/**)"
  
  opencode:
    permission:
      read:
        "**/secrets/**": "deny"
      bash:
        "bundle exec rspec*": "allow"
```

---

## 🔧 配置详解

### schema_version

**必需**: 是  
**类型**: 整数  
**说明**: Overlay 文件的 schema 版本，当前为 1

```yaml
schema_version: 1
```

### name

**必需**: 否  
**类型**: 字符串  
**说明**: Overlay 的名称，用于识别和调试

```yaml
name: production-project-overlay
```

### description

**必需**: 否  
**类型**: 字符串  
**说明**: Overlay 的描述，说明用途和适用范围

```yaml
description: Strict security policies for production deployment
```

### profile.mapping_overrides

**必需**: 否  
**类型**: 映射  
**说明**: 覆盖默认的模型映射配置

**⚠️ 注意**: 使用 `mapping_overrides` 而不是 `mapping`

```yaml
profile:
  mapping_overrides:
    critical_reasoner: claude.opus-class    # 关键逻辑使用最强模型
    workhorse_coder: claude.sonnet-class    # 日常编码使用平衡模型
    fast_router: claude.haiku-class         # 快速任务使用轻量模型
```

### profile.note_append

**必需**: 否  
**类型**: 字符串列表  
**说明**: 追加到生成配置文件中的注释

```yaml
profile:
  note_append:
    - "This project uses Python 3.11"
    - "Database migrations require approval"
    - "API keys are in 1Password"
```

### policies.append

**必需**: 否  
**类型**: 策略列表  
**说明**: 添加自定义行为策略

每个策略包含：
- `id`: 唯一标识符
- `category`: 类别（safety, project_memory, routing 等）
- `enforcement`: 执行级别（mandatory, recommended, optional）
- `target_render_group`: 渲染组
- `summary`: 策略描述

```yaml
policies:
  append:
    - id: check-project-context
      category: project_memory
      enforcement: recommended
      target_render_group: always_on
      summary: Always read PROJECT_CONTEXT.md before making changes
      
    - id: no-direct-db-changes
      category: safety
      enforcement: mandatory
      target_render_group: safety
      summary: All database changes must go through migrations
```

### targets

**必需**: 否  
**类型**: 映射  
**说明**: 平台特定的配置

#### Claude Code 权限配置

```yaml
targets:
  claude-code:
    permissions:
      ask:                              # 需要确认的操作
        - "Bash(./scripts/deploy:*)"    # 部署脚本需要确认
      deny:                             # 禁止的操作
        - "Read(./secrets/**)"          # 禁止读取 secrets 目录
        - "Write(./production-db:*)"    # 禁止写入生产数据库
```

#### OpenCode 权限配置

```yaml
targets:
  opencode:
    permission:
      read:
        "**/secrets/**": "deny"        # 禁止读取 secrets
        "**/passwords/**": "deny"      # 禁止读取密码
      bash:
        "bundle exec rspec*": "allow"   # 允许运行测试
        "rm -rf /": "deny"             # 禁止危险命令
```

---

## 💡 常见使用场景

### 场景 1: 项目特定的模型偏好

```yaml
schema_version: 1
name: python-project
profile:
  mapping_overrides:
    critical_reasoner: openai.gpt-4     # Python 项目偏好 GPT-4
    workhorse_coder: anthropic.claude-3
  note_append:
    - "Use type hints in all function signatures"
    - "Follow PEP 8 style guide"
```

### 场景 2: 严格的安全策略

```yaml
schema_version: 1
name: high-security-project
policies:
  append:
    - id: no-secrets-in-code
      category: safety
      enforcement: mandatory
      target_render_group: safety
      summary: Never commit API keys or passwords
      
    - id: require-reviewer
      category: safety
      enforcement: mandatory
      target_render_group: safety
      summary: All changes to auth/ require human review

targets:
  claude-code:
    permissions:
      deny:
        - "Read(./.env*)"
        - "Read(./secrets/**)"
```

### 场景 3: 团队规范

```yaml
schema_version: 1
name: team-standards
profile:
  note_append:
    - "Always update CHANGELOG.md for user-facing changes"
    - "Run 'make lint' before committing"
    - "Tag releases with semantic versioning"

policies:
  append:
    - id: changelog-required
      category: project_memory
      enforcement: recommended
      target_render_group: always_on
      summary: Update CHANGELOG.md for all user-facing changes
```

### 场景 4: 环境特定配置

```yaml
schema_version: 1
name: production-environment
profile:
  mapping_overrides:
    critical_reasoner: claude.opus-class  # 生产环境使用最强模型
  note_append:
    - "⚠️ This is PRODUCTION environment"
    - "All changes require approval"
    - "Database migrations must be run during maintenance window"

policies:
  append:
    - id: production-careful
      category: safety
      enforcement: mandatory
      target_render_group: safety
      summary: Triple-check all changes in production
```

---

## ⚠️ 常见错误

### 错误 1: 使用 `mapping` 而不是 `mapping_overrides`

❌ **错误**:
```yaml
profile:
  mapping:                           # ❌ 错误的键名
    critical_reasoner: claude.opus-class
```

✅ **正确**:
```yaml
profile:
  mapping_overrides:                 # ✅ 正确的键名
    critical_reasoner: claude.opus-class
```

**提示**: 如果使用错误的键名，vibe 会显示警告：
```
⚠️  Warning: overlay uses 'profile.mapping' which is ignored.
   Did you mean 'profile.mapping_overrides'?
   See examples/project-overlay.yaml for correct format.
```

### 错误 2: 忘记 schema_version

❌ **错误**:
```yaml
name: my-overlay                    # ❌ 缺少 schema_version
profile:
  mapping_overrides:
    ...
```

✅ **正确**:
```yaml
schema_version: 1                    # ✅ 必需字段
name: my-overlay
profile:
  mapping_overrides:
    ...
```

### 错误 3: 策略缺少必需字段

❌ **错误**:
```yaml
policies:
  append:
    - id: my-rule                   # ❌ 缺少 category, enforcement 等
      summary: My rule
```

✅ **正确**:
```yaml
policies:
  append:
    - id: my-rule
      category: safety              # ✅ 必需字段
      enforcement: mandatory        # ✅ 必需字段
      target_render_group: safety   # ✅ 必需字段
      summary: My rule              # ✅ 必需字段
```

---

## 🔍 调试和验证

### 检查 Overlay 是否生效

```bash
# 查看 overlay 是否被识别
vibe inspect --overlay ./my-overlay.yaml

# 查看详细的配置解析
vibe inspect claude-code --overlay ./my-overlay.yaml --json
```

### 验证 Overlay 格式

```bash
# 使用 Ruby 验证 YAML 格式
ruby -ryaml -e "YAML.load_file('.vibe/overlay.yaml')"
```

### 预览生成结果

```bash
# 构建并查看结果（不应用到项目）
vibe build claude-code --overlay ./my-overlay.yaml --output ./preview
cat ./preview/CLAUDE.md
```

---

## 📚 相关文档

- [项目覆盖层机制](../docs/project-overlays.md) - 官方文档
- [示例 Overlay](../examples/project-overlay.yaml) - 完整示例
- [Python 项目示例](../examples/python-uv-overlay.yaml) - Python 特定示例
- [Node 项目示例](../examples/node-nvm-overlay.yaml) - Node.js 特定示例

---

## 🆘 故障排除

### Overlay 没有被应用

**检查清单**:
1. 文件位置是否正确？（`.vibe/overlay.yaml` 或显式指定）
2. YAML 格式是否正确？
3. `schema_version` 是否设置？
4. 键名是否正确？（`mapping_overrides` 而不是 `mapping`）

### 权限配置不生效

**检查清单**:
1. 目标平台是否正确？（`targets.claude-code` 或 `targets.opencode`）
2. 权限语法是否正确？
3. 平台是否支持该权限类型？

### 策略没有显示

**检查清单**:
1. 策略是否有所有必需字段？
2. `target_render_group` 是否正确？
3. 策略是否被添加到 `policies.append`？

---

## 💬 获取帮助

- 查看示例: `examples/*.yaml`
- 运行测试: `rake test`
- 检查配置: `vibe inspect --overlay ./your-overlay.yaml`
- 提交 Issue: GitHub Issues

---

**提示**: Overlay 是可选功能。如果不确定是否需要，可以先不使用，等遇到具体需求时再添加。
