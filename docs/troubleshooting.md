# 故障排除指南

**文档版本**: 1.0  
**最后更新**: 2026-03-14

---

## 🔍 快速诊断

### 运行诊断命令

```bash
# 检查环境
vibe doctor

# 查看支持的平台
vibe targets

# 检查当前配置
vibe inspect

# 验证特定平台
vibe inspect claude-code
```

---

## ❌ 常见问题

### 1. 命令不存在或找不到

**症状**:
```
bash: vibe: command not found
```

**解决方案**:
```bash
# 方法 1: 使用完整路径
./bin/vibe --help

# 方法 2: 添加到 PATH
export PATH="$PATH:/path/to/claude-code-workflow/bin"

# 方法 3: 创建别名
alias vibe='/path/to/claude-code-workflow/bin/vibe'
```

---

### 2. 平台不支持

**症状**:
```
Error: Unsupported platform: xxx. Valid options: claude-code, opencode, codex-cli
```

**原因**: 该平台尚未迁移到配置驱动

**解决方案**:
1. 查看支持的平台: `vibe targets`
2. 使用已支持的平台（claude-code, opencode, codex-cli）
3. 等待其他平台完成迁移

---

### 3. 初始化失败

**症状**:
```
Error: Configuration already exists at ~/.claude
```

**解决方案**:
```bash
# 方法 1: 强制重新初始化
vibe init --platform claude-code --force

# 方法 2: 先预览再决定
vibe init --platform claude-code --dry-run

# 方法 3: 备份后重新初始化
mv ~/.claude ~/.claude.backup.$(date +%Y%m%d)
vibe init --platform claude-code
```

---

### 4. 应用配置失败

**症状**:
```
Error: Refusing to use /path as output root: overlaps with /tmp
```

**原因**: 路径安全检查阻止了系统目录的使用

**解决方案**:
```bash
# 使用非系统目录
cd ~
mkdir my-project
cd my-project
vibe apply claude-code

# 或者指定输出目录
vibe apply claude-code --output ./my-project
```

---

### 5. Overlay 不生效

**症状**: Overlay 配置没有被应用到生成的文件

**检查清单**:

1. **文件位置是否正确？**
   ```bash
   # 自动发现需要放在项目根目录
   ls -la .vibe/overlay.yaml
   
   # 或者显式指定
   vibe apply claude-code --overlay ./path/to/overlay.yaml
   ```

2. **YAML 格式是否正确？**
   ```bash
   # 验证 YAML 格式
   ruby -ryaml -e "puts YAML.load_file('.vibe/overlay.yaml').inspect"
   ```

3. **是否使用了正确的键名？**
   ```yaml
   # ❌ 错误
   profile:
     mapping:
       critical_reasoner: xxx
   
   # ✅ 正确
   profile:
     mapping_overrides:
       critical_reasoner: xxx
   ```

4. **检查 overlay 是否被识别**
   ```bash
   vibe inspect --overlay ./.vibe/overlay.yaml
   ```

---

### 6. 测试失败

**症状**:
```
rake test
# 出现失败
```

**解决方案**:

1. **检查 Ruby 版本**
   ```bash
   ruby --version
   # 需要 2.6.0+
   ```

2. **安装依赖**
   ```bash
   bundle install
   ```

3. **运行特定测试**
   ```bash
   ruby test/test_vibe_cli.rb
   ```

4. **查看详细错误**
   ```bash
   rake test VERBOSE=true
   ```

---

### 7. 权限不足

**症状**:
```
Permission denied @ dir_s_mkdir - /path/to/directory
```

**解决方案**:

1. **检查目录权限**
   ```bash
   ls -la /path/to/parent
   ```

2. **使用有权限的目录**
   ```bash
   # 使用用户目录
   cd ~
   vibe apply claude-code
   ```

3. **创建目录并设置权限**
   ```bash
   mkdir -p ~/my-vibe-projects
   vibe apply claude-code --output ~/my-vibe-projects/project1
   ```

---

### 8. 配置验证失败

**症状**:
```
Error: Overlay validation failed
```

**解决方案**:

1. **检查必需字段**
   ```yaml
   schema_version: 1  # 必需
   name: my-overlay   # 可选但推荐
   ```

2. **验证策略格式**
   ```yaml
   policies:
     append:
       - id: my-rule              # 必需
         category: safety         # 必需
         enforcement: mandatory   # 必需
         target_render_group: safety  # 必需
         summary: Description     # 必需
   ```

3. **使用验证工具**
   ```bash
   ruby bin/validate-platform-config
   ```

---

### 9. 生成文件不正确

**症状**: 生成的 CLAUDE.md 或 AGENTS.md 内容不正确

**检查清单**:

1. **检查 manifest**
   ```bash
   vibe inspect --json | jq '.targets[0]'
   ```

2. **检查 profile 配置**
   ```bash
   cat core/models/providers.yaml | grep -A 10 "claude-code:"
   ```

3. **重新生成**
   ```bash
   rm -rf .vibe/ CLAUDE.md
   vibe apply claude-code
   ```

---

### 10. 性能问题

**症状**: 命令执行缓慢

**诊断**:
```bash
# 测量执行时间
time vibe build claude-code --output /tmp/test

# 检查文件数量
find .vibe -type f | wc -l
```

**优化建议**:

1. **减少运行时目录**
   ```yaml
   # platforms.yaml
   runtime_dirs:
     - rules
     # 移除不需要的目录
   ```

2. **使用缓存**
   ```ruby
   # 已经内置 YAML 缓存
   ```

3. **避免大目录**
   ```bash
   # 不要在包含大量文件的目录运行
   cd ~/small-project
   vibe apply claude-code
   ```

---

## 🛠️ 高级调试

### 启用调试模式

```bash
# 设置调试环境变量
export VIBE_DEBUG=1

# 运行命令
vibe apply claude-code
```

### 检查生成的 manifest

```bash
# 查看 manifest 内容
cat .vibe/manifest.json | jq .

# 检查特定字段
cat .vibe/manifest.json | jq '.overlay'
cat .vibe/manifest.json | jq '.profile_mapping'
```

### 验证配置文件

```bash
# 验证 platforms.yaml
ruby bin/validate-platform-config

# 验证 overlay
ruby -ryaml -e "YAML.load_file('.vibe/overlay.yaml')"
```

### 检查 Git 状态

```bash
# 查看修改的文件
git status

# 查看具体修改
git diff

# 查看提交历史
git log --oneline -10
```

---

## 📊 收集诊断信息

如果以上方法都无法解决问题，请收集以下信息：

```bash
# 1. 环境信息
echo "Ruby version: $(ruby --version)"
echo "Platform: $(uname -a)"

# 2. 项目状态
git status
git log --oneline -5

# 3. 测试结果
rake test 2>&1 | tail -20

# 4. 配置检查
vibe doctor
vibe targets
vibe inspect --json 2>&1 | head -50

# 5. 文件列表
ls -la
cat .vibe/manifest.json 2>/dev/null || echo "No manifest"
```

---

## 🆘 获取帮助

### 自助资源

1. **查看文档**
   - README.md - 项目概览
   - docs/ - 详细文档
   - examples/ - 示例配置

2. **运行诊断**
   ```bash
   vibe doctor
   vibe inspect
   ```

3. **检查示例**
   ```bash
   ls examples/
   cat examples/project-overlay.yaml
   ```

### 提交 Issue

如果问题仍然无法解决，请提交 Issue 并包含：

1. **问题描述**: 清晰描述问题
2. **复现步骤**: 如何重现问题
3. **环境信息**: Ruby 版本、操作系统
4. **错误信息**: 完整的错误消息
5. **诊断输出**: 上述收集的诊断信息

**提交位置**: GitHub Issues

---

## 💡 最佳实践

### 预防问题

1. **定期更新**
   ```bash
   git pull origin main
   ```

2. **备份配置**
   ```bash
   cp -r ~/.claude ~/.claude.backup.$(date +%Y%m%d)
   ```

3. **使用版本控制**
   ```bash
   git add .vibe/ CLAUDE.md
   git commit -m "Update vibe configuration"
   ```

4. **测试变更**
   ```bash
   # 先预览
   vibe init --platform claude-code --dry-run
   
   # 再应用
   vibe init --platform claude-code
   ```

---

## ✅ 检查清单

在提交 Issue 前，请确认：

- [ ] 已阅读相关文档
- [ ] 已运行 `vibe doctor`
- [ ] 已检查 `vibe targets`
- [ ] 已验证 YAML 格式
- [ ] 已尝试 `--force` 或 `--dry-run`
- [ ] 已收集诊断信息
- [ ] 已搜索现有 Issue

---

**记住**: 大多数问题都可以通过仔细检查配置和路径解决。保持耐心，逐步排查！
