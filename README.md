# 仓颉编程语言学习笔记

> 系统学习仓颉编程语言，输出高质量微信公众号文章

## 项目简介

本仓库用于系统学习仓颉编程语言（Cangjie），并通过AI Agent辅助产出高质量的微信公众号文章系列。目标是覆盖仓颉语言的完整体系，从基础语法到进阶实战，同时与Golang、Java、Swift、Kotlin等语言进行对比，帮助开发者快速上手仓颉编程。

## 目标版本

- **仓颉版本**: 1.0.5 LTS（长期支持版本）
- **官方文档**: https://cangjie-lang.cn/docs

## 仓库结构

```
learn-cangjie/
├── README.md                 # 项目说明
├── AGENT.md                  # AI Agent行为规范
├── rules/                    # 规则文件目录
│   ├── content-quality.md    # 内容质量要求
│   └── git-workflow.md       # Git工作流程
├── specs/                    # 规范文档目录
│   ├── learning-plan.md      # 学习计划
│   └── article-template.md   # 文章模板规范
├── docs/                     # 学习文档目录
│   ├── basics/               # 基础语法
│   ├── advanced/             # 进阶特性
│   ├── ecosystem/            # 生态工具
│   └── comparison/           # 语言对比
├── articles/                 # 文章存储目录
│   ├── README.md             # 文章状态与目录约定
│   ├── drafts/               # 草稿
│   └── templates/            # 文章模板
├── examples/                 # 可测试代码示例的唯一来源
│   └── cangjie/              # 仓颉示例
├── knowledge-base/           # 知识库
│   ├── cheatsheet.md         # 语法速查表
│   └── glossary.md           # 术语表
└── tools/                    # 工具脚本
    ├── publish.sh            # 发布脚本
```

## 工作流程

1. **学习阶段**: 基于官方文档系统学习仓颉语言特性
2. **知识整理**: 将学习内容整理成结构化的知识库
3. **文章撰写**: 基于知识库撰写公众号文章
4. **代码同步**: 在 `examples/` 维护唯一规范源，并同步到文章代码块
5. **代码测试**: 本地测试规范源，确保可运行
6. **审核优化**: 与用户协商修改，确保质量
7. **版本管理**: 本地提交，用户确认后推送到GitHub
8. **自动测试**: GitHub Actions测试规范源并校验文章同步
9. **发布准备**: 确认内容和示例测试通过后，交由用户选择的工具处理

## AI Agent协作

本项目采用AI Agent辅助完成以下任务：
- 知识点梳理和文档整理
- 文章初稿撰写和优化
- 代码示例生成和验证
- 多语言对比分析
- 文章结构和内容质量检查

所有AI Agent的行为规范详见 [AGENT.md](./AGENT.md)


## 快速开始

1. 克隆仓库
2. 阅读 [AGENT.md](./AGENT.md) 了解AI Agent行为规范
3. 查看 [学习计划](./specs/learning-plan.md) 了解学习路径
4. 阅读第一篇文章草稿：[仓颉编程语言简介与特性概览](./articles/drafts/01-cangjie-introduction.md)

## 贡献指南

本项目由用户与AI Agent协作完成，所有决策以用户指令为主。

## 许可证

本项目采用 [MIT License](./LICENSE)
