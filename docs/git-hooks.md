# Git 钩子使用指南

> 本文档说明如何安装和使用Git钩子来自动执行代码测试

## 什么是Git钩子？

Git钩子是Git在特定事件发生时自动执行的脚本。本项目使用Git钩子来自动执行代码测试，确保代码质量。

## 钩子列表

### pre-push

**功能**: 在推送到远程仓库前自动运行测试

**触发时机**: 执行 `git push` 命令时

**执行内容**:
1. 检查是否在项目根目录
2. 运行本地测试脚本 `./tools/test-local.sh`
3. 如果测试失败，阻止推送

**绕过方法**（不推荐）:
```bash
git push --no-verify
```

## 安装钩子

### 方法一：自动安装（推荐）

使用项目提供的安装脚本：

```bash
# 运行安装脚本
./tools/install-hooks.sh
```

### 方法二：手动安装

1. 进入项目目录
2. 复制钩子文件到 `.git/hooks/` 目录
3. 添加执行权限

```bash
# 复制pre-push钩子
cp hooks/pre-push .git/hooks/pre-push

# 添加执行权限
chmod +x .git/hooks/pre-push
```

## 使用钩子

### pre-commit

提交前会依次执行：

- 文章与 `examples/` 同步检查
- 仓颉示例本地测试
- 微信发布器 TypeScript 类型检查和单元测试

如果发布器依赖未安装，提交会被阻止。安装依赖：

```bash
npm install --prefix tools/wechat-publisher
```

### 正常使用

```bash
# 推送代码（会自动运行测试）
git push

# 如果测试通过，推送成功
# 如果测试失败，推送被阻止
```

### 查看测试报告

```bash
# 检查文章和规范示例同步
python3 .github/scripts/sync_examples.py

# 运行本地测试
./tools/test-local.sh
```

### 跳过测试（不推荐）

```bash
# 跳过测试直接推送
git push --no-verify
```

**警告**: 跳过测试可能导致错误的代码进入仓库，请谨慎使用。

## 钩子工作原理

### pre-push钩子执行流程

```
用户执行 git push
       ↓
Git调用 pre-push 钩子
       ↓
钩子检查是否在项目根目录
       ↓
钩子运行 ./tools/test-local.sh
       ↓
测试脚本检查文章与 examples/ 的同步
        ↓
测试脚本编译和运行 examples/ 中的规范源
       ↓
如果测试通过 → 允许推送
如果测试失败 → 阻止推送
```

## 故障排除

### 问题1: 钩子没有执行

**原因**: 钩子文件没有执行权限

**解决方案**:
```bash
# 添加执行权限
chmod +x .git/hooks/pre-push
```

### 问题2: 测试脚本未找到

**原因**: 不在项目根目录

**解决方案**:
```bash
# 切换到项目根目录
cd /path/to/learn-cangjie

# 再次尝试推送
git push
```

### 问题3: 测试失败

**原因**: 代码示例无法编译或运行

**解决方案**:
1. 查看同步检查和编译器诊断
2. 修复 `examples/` 中的规范源及文章同步内容
3. 重新运行测试: `./tools/test-local.sh`
4. 测试通过后再次推送

### 问题4: 想要跳过测试

**解决方案**:
```bash
# 跳过测试直接推送（不推荐）
git push --no-verify
```

## 最佳实践

### 1. 始终使用钩子
- 不要跳过测试
- 不要禁用钩子
- 让钩子自动执行

### 2. 及时修复问题
- 测试失败时立即修复
- 不要推送失败的代码
- 保持代码质量

### 3. 定期更新钩子
- 定期更新钩子脚本
- 跟进项目更新
- 保持钩子功能正常

### 4. 团队协作
- 团队成员都安装钩子
- 统一测试标准
- 共享最佳实践

## 自定义钩子

### 修改测试逻辑

编辑 `.git/hooks/pre-push` 文件，修改测试逻辑：

```bash
#!/bin/bash

# 自定义测试逻辑
echo "运行自定义测试..."

# 运行测试
./tools/test-local.sh

# 其他自定义逻辑
# ...
```

### 添加新的钩子

创建新的钩子文件：

```bash
# 创建pre-commit钩子
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "运行代码格式检查..."
# 添加格式检查逻辑
EOF

# 添加执行权限
chmod +x .git/hooks/pre-commit
```

## 相关文档

- [Git工作流程规范](../rules/git-workflow.md)
- [代码测试规范](../rules/code-testing.md)
- [本地测试脚本](../tools/test-local.sh)

---

*本文档将根据实际情况不断完善*
