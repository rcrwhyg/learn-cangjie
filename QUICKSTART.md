# 快速开始指南

> 本指南帮助您快速了解和使用仓颉编程语言学习笔记项目

## 项目简介

本项目是一个系统学习仓颉编程语言的开源项目，通过AI Agent辅助产出高质量的微信公众号文章系列，帮助开发者快速上手仓颉编程。

## 主要特性

### 🎯 系统学习路径
- 52篇精心规划的文章
- 5个循序渐进的学习阶段
- 从入门到精通的完整覆盖

### 📚 丰富学习资源
- 统一的文章模板
- 完整的代码示例
- 详细的术语解释
- 实用的速查表

### 🤖 AI Agent协作
- 智能内容生成
- 代码示例验证
- 多语言对比分析
- 质量自动检查

### 📱 公众号文章
- 内容结构清晰
- 技术信息准确
- 代码示例经过验证
- 使用用户选择的工具完成发布

## 快速开始

### 1. 克隆项目

```bash
# 克隆仓库
git clone https://github.com/rcrwhyg/learn-cangjie.git

# 进入项目目录
cd learn-cangjie
```

### 2. 了解项目结构

```
learn-cangjie/
├── README.md                 # 项目说明
├── AGENT.md                  # AI Agent行为规范
├── CONTRIBUTING.md           # 贡献指南
├── CHANGELOG.md              # 更新日志
├── QUICKSTART.md             # 快速开始指南
├── STATUS.md                 # 项目状态
├── rules/                    # 规则文件
│   ├── content-quality.md    # 内容质量要求
│   └── git-workflow.md       # Git工作流程
├── specs/                    # 规范文档
│   ├── learning-plan.md      # 学习计划
│   ├── article-template.md   # 文章模板规范
│   └── version-strategy.md   # 版本策略
├── docs/                     # 学习文档
├── articles/                 # 文章存储
│   ├── README.md             # 文章目录约定
│   ├── 01-cangjie-introduction.md
│   ├── 02-development-environment.md
│   ├── 03-variables-and-data-types.md
│   ├── 04-operators-and-expressions.md
│   ├── 05-control-flow.md
│   └── templates/            # 文章模板
├── knowledge-base/           # 知识库
│   ├── cheatsheet.md         # 速查表
│   └── glossary.md           # 术语表
└── tools/                    # 工具脚本
    └── publish.sh            # 发布脚本
```

### 3. 查看学习计划

打开 `specs/learning-plan.md` 查看完整的学习计划，了解：
- 学习目标和路径
- 文章规划和进度
- 学习资源和建议

### 4. 选择学习起点

根据您的背景选择起点：

#### 有编程经验
- 直接从文章3《变量与数据类型》开始（文章1和文章3当前仍在规划/撰写中）
- 重点关注仓颉与其他语言的差异
- 快速浏览基础语法部分

#### 编程新手
- 从文章1《仓颉编程语言简介》开始
- 循序渐进学习每个知识点
- 多做练习，多写代码

#### 从其他语言迁移
- 查看语言对比部分
- 重点关注迁移建议
- 实践迁移案例

### 5. 开始学习

当前可阅读的第一篇内容是 [文章1](./articles/01-cangjie-introduction.md)。文章会在同一份文件上持续修改，确认后直接交给公众号工具发布。

#### 阅读文章
1. 选择要学习的文章
2. 阅读理论知识
3. 理解代码示例
4. 动手实践

#### 动手实践
1. 安装仓颉SDK
2. 运行代码示例
3. 修改示例代码
4. 编写自己的代码

#### 参与贡献
1. 阅读贡献指南
2. 选择贡献方式
3. 提交Pull Request
4. 参与社区讨论

## 学习建议

### 学习原则
1. **循序渐进**: 按照学习路径逐步深入
2. **动手实践**: 每个知识点都要动手实践
3. **对比学习**: 与熟悉语言进行对比学习
4. **项目驱动**: 通过实际项目巩固知识
5. **社区参与**: 参与社区讨论和贡献

### 学习方法
1. **预习**: 快速浏览文章结构
2. **学习**: 仔细阅读理论知识
3. **实践**: 运行和修改代码示例
4. **总结**: 总结核心知识点
5. **应用**: 在实际项目中应用

### 学习工具
1. **IDE**: VS Code + 仓颉插件
2. **终端**: 命令行工具
3. **文档**: 官方文档和本项目
4. **社区**: GitHub和论坛

## 常见问题

### Q: 如何安装仓颉SDK？
A: 访问仓颉官网下载页面：https://cangjie-lang.cn/download

### Q: 如何运行代码示例？
A: 
```bash
# 创建源文件
vim hello.cj

# 编译运行
cjc hello.cj -o hello
./hello
```

### Q: 如何参与项目贡献？
A: 参考 `CONTRIBUTING.md` 贡献指南

### Q: 如何反馈问题？
A: 在GitHub上创建Issue：https://github.com/rcrwhyg/learn-cangjie/issues

### Q: 文章更新频率？
A: 计划每周1-2篇，具体根据实际情况调整

## 获取帮助

### 文档资源
- [项目README](./README.md)
- [AI Agent规范](./AGENT.md)
- [学习计划](./specs/learning-plan.md)
- [贡献指南](./CONTRIBUTING.md)

### 社区支持
- [GitHub Issues](https://github.com/rcrwhyg/learn-cangjie/issues)
- [GitHub Discussions](https://github.com/rcrwhyg/learn-cangjie/discussions)

### 官方资源
- [仓颉官网](https://cangjie-lang.cn)
- [官方文档](https://cangjie-lang.cn/docs)
- [官方仓库](https://gitcode.com/Cangjie/cangjie_docs)

## 下一步

### 立即开始
1. 克隆项目
2. 阅读学习计划
3. 选择第一篇文章
4. 开始学习

### 参与贡献
1. 阅读贡献指南
2. 选择贡献方式
3. 提交第一个PR
4. 成为贡献者

### 关注项目
1. Star项目仓库
2. Watch项目更新
3. 参与社区讨论
4. 分享给朋友

---

**祝您学习愉快！** 🎉

如有任何问题，欢迎在GitHub上提出Issue或参与讨论。
