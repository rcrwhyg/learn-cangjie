# Git 工作流程规范

> 本文档定义了项目的Git版本控制工作流程

## 分支策略

### 分支类型
```
main          # 主分支，存放已发布的文章
├── draft     # 草稿分支，存放正在撰写的文章
├── feature/  # 特性分支，用于特定主题的学习
│   ├── feature/basics      # 基础语法学习
│   ├── feature/advanced    # 进阶特性学习
│   ├── feature/ecosystem   # 生态工具学习
│   └── feature/comparison  # 语言对比学习
└── hotfix/   # 紧急修复分支
```

### 分支用途
- **main**: 生产分支，只接受合并请求
- **draft**: 开发分支，日常开发使用
- **feature/***: 特性分支，用于特定功能开发
- **hotfix/***: 紧急修复分支，用于修复严重问题

### 分支命名规范
- 使用小写字母和连字符
- 描述性命名
- 包含类型前缀
- 示例: `feature/variables-and-types`, `hotfix/fix-code-example`

## 提交规范

### 提交信息格式
```
<type>(<scope>): <subject>

<body>

<footer>
```

### 类型说明
- **feat**: 新功能或新文章
- **fix**: 修复错误或改进内容
- **docs**: 文档更新
- **style**: 格式调整（不影响代码逻辑）
- **refactor**: 重构内容（既不修复错误也不添加功能）
- **test**: 测试相关
- **chore**: 构建过程或辅助工具的变动
- **perf**: 性能优化
- **ci**: CI配置变更
- **revert**: 回滚提交

### 范围说明
- **article**: 文章相关
- **rule**: 规则相关
- **spec**: 规范相关
- **doc**: 文档相关
- **tool**: 工具相关
- **config**: 配置相关

### 主题说明
- 使用祈使语气
- 不超过50个字符
- 首字母小写
- 不加句号

### 示例
```
feat(article): 添加变量与数据类型文章

- 完成变量声明和类型系统讲解
- 添加与Golang的对比分析
- 包含完整的代码示例

Closes #123
```

## 工作流程

### 日常开发流程

1. **开始工作**
   ```bash
   # 确保在draft分支
   git checkout draft
   git pull origin draft
   
   # 创建新的特性分支
   git checkout -b feature/article-name
   ```

2. **开发工作**
   ```bash
   # 添加文件
   git add .
   
   # 提交更改
   git commit -m "feat(article): 添加文章初稿"
   
   # 推送到远程
   git push origin feature/article-name
   ```

3. **完成工作**
   ```bash
   # 切换到draft分支
   git checkout draft
   
   # 合并特性分支
   git merge --no-ff feature/article-name
   
   # 推送到远程
   git push origin draft
   
   # 删除特性分支
   git branch -d feature/article-name
   git push origin --delete feature/article-name
   ```

### 文章发布流程

1. **文章完成**
   - 文章内容完成并经过审核
   - 代码示例验证通过（本地测试和GitHub Actions测试）
   - 格式排版符合规范

2. **本地测试**
   ```bash
   # 运行本地测试
   ./tools/test-local.sh
   
   # 确认所有测试通过
   ```

3. **本地提交**
   ```bash
   # 添加文件
   git add articles/published/article-name.md
   
   # 提交更改
   git commit -m "feat(article): 发布文章《文章标题》"
   ```

4. **用户确认**
   - 提交信息发送给用户确认
   - 用户确认无误后继续

5. **合并到main**
   ```bash
   # 切换到main分支
   git checkout main
   
   # 合并draft分支
   git merge draft
   
   # 推送到远程
   git push origin main
   ```

6. **GitHub Actions验证**
   - 等待GitHub Actions测试完成
   - 确认所有测试通过
   - 查看测试报告

7. **创建标签**
   ```bash
   # 创建版本标签
   git tag -a v1.0.0 -m "发布文章《文章标题》"
   
   # 推送标签
   git push origin v1.0.0
   ```

### 紧急修复流程

1. **发现问题**
   - 发现文章内容错误
   - 需要立即修复

2. **创建hotfix分支**
   ```bash
   # 从main分支创建hotfix分支
   git checkout main
   git checkout -b hotfix/fix-issue-description
   ```

3. **修复问题**
   ```bash
   # 进行修复
   # ...
   
   # 提交修复
   git commit -m "hotfix(article): 修复文章错误"
   ```

4. **合并修复**
   ```bash
   # 切换到main分支
   git checkout main
   
   # 合并hotfix分支
   git merge --no-ff hotfix/fix-issue-description
   
   # 推送到远程
   git push origin main
   
   # 切换到draft分支
   git checkout draft
   
   # 合并hotfix分支
   git merge --no-ff hotfix/fix-issue-description
   
   # 推送到远程
   git push origin draft
   ```

5. **清理分支**
   ```bash
   # 删除hotfix分支
   git branch -d hotfix/fix-issue-description
   git push origin --delete hotfix/fix-issue-description
   ```

## 版本管理

### 版本号规范
- 使用语义化版本号: `MAJOR.MINOR.PATCH`
- **MAJOR**: 重大内容变更
- **MINOR**: 新增文章或重要更新
- **PATCH**: 错误修复和小幅改进

### 标签管理
- 使用轻量标签或注释标签
- 标签名格式: `v1.0.0`
- 标签信息包含版本说明

### 发布说明
- 每个版本发布都应编写发布说明
- 包含变更内容、新增功能、修复问题
- 使用Markdown格式编写

## 代码审查

### 审查内容
- 技术内容准确性
- 代码示例可运行性
- 格式排版规范性
- 文章结构合理性

### 审查流程
1. 提交代码审查请求
2. 审查者进行审查
3. 提出修改建议
4. 作者进行修改
5. 审查者确认通过

### 审查标准
- 技术内容准确无误
- 代码示例完整可运行
- 格式排版符合规范
- 文章结构清晰合理

## 冲突解决

### 冲突预防
- 及时拉取最新代码
- 避免长时间不提交
- 合理划分工作范围

### 冲突解决流程
1. 拉取最新代码
2. 解决冲突
3. 测试验证
4. 提交解决结果

### 冲突解决工具
- 使用Git内置的合并工具
- 使用可视化合并工具
- 必要时手动解决

## 备份策略

### 备份频率
- 每天工作结束前备份
- 重要变更后立即备份
- 定期备份到远程仓库

### 备份内容
- 所有源代码文件
- 文档和配置文件
- 历史提交记录

### 备份位置
- 本地Git仓库
- GitHub远程仓库
- 其他备份存储

## 协作规范

### 协作流程
1. 拉取最新代码
2. 创建特性分支
3. 进行开发工作
4. 提交代码审查
5. 合并到主分支

### 沟通规范
- 及时沟通工作进展
- 遇到问题及时反馈
- 重要变更提前通知

### 责任分工
- 明确每个人的责任范围
- 避免工作重叠
- 及时处理待办事项

## 工具配置

### Git配置
```bash
# 设置用户信息
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 设置默认编辑器
git config --global core.editor "code --wait"

# 设置差异比较工具
git config --global diff.tool vscode
git config --global difftool.vscode.cmd "code --wait --diff $LOCAL $REMOTE"
```

### 钩子脚本
- **pre-commit**: 提交前检查
- **commit-msg**: 提交信息检查
- **pre-push**: 推送前检查

### 忽略文件
```gitignore
# 系统文件
.DS_Store
Thumbs.db

# 编辑器文件
*.swp
*.swo
*~

# 构建文件
build/
dist/
*.o
*.obj

# 依赖文件
node_modules/
vendor/

# 日志文件
*.log

# 临时文件
tmp/
temp/
```

## 监控和报告

### 监控指标
- 提交频率
- 代码审查时间
- 问题解决时间
- 发布频率

### 报告内容
- 工作进展报告
- 问题解决报告
- 质量评估报告
- 改进建议报告

## 应急处理

### 数据丢失
- 立即停止操作
- 检查备份
- 恢复数据
- 分析原因

### 代码错误
- 立即回滚错误提交
- 修复错误
- 测试验证
- 重新发布

### 协作问题
- 及时沟通
- 寻求帮助
- 调整工作方式
- 总结经验教训

---

*本流程将根据实际情况不断完善*