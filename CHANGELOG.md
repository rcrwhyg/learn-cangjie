# 更新日志

> 本文档记录仓颉编程语言学习笔记项目的所有重要变更

## 版本格式

本项目遵循[语义化版本](https://semver.org/lang/zh-CN/)规范：
- **主版本号**: 不兼容的API变更
- **次版本号**: 向下兼容的功能性新增
- **修订版本号**: 向下兼容的问题修正

## [未发布]

### 新增
- 文章 1 至文章 8 已发布，覆盖仓颉语言基础阶段前 8 篇文章
- 文章 5《仓颉控制流语句》（已发布）并配套 `examples/cangjie/009-control-flow.cj`
- 文章 6《仓颉函数基础》（已发布）并配套 `examples/cangjie/010-functions.cj`
- 文章 7《仓颉结构类型 struct》（已发布）并配套 `examples/cangjie/011-struct.cj`
- 文章 8《仓颉类类型 class》（已发布）并配套 `examples/cangjie/012-class.cj`
- 文章 9《仓颉接口、属性与子类型》（已发布）并配套 `examples/cangjie/013-interface.cj`
- 文章 10《仓颉枚举类型 enum》（已发布）并配套 `examples/cangjie/014-enum.cj`
- 文章 11《仓颉模式匹配》（已发布）并配套 `examples/cangjie/015-pattern.cj`
- 文章 12《仓颉数组、元组与区间》（已发布）并配套 `examples/cangjie/016-array-tuple-range.cj`
- 文章 13《仓颉字符串与字符处理》（待审核）并配套 `examples/cangjie/017-strings-and-characters.cj`
- 文章 14《仓颉 Collection 集合类型》（待审核）并配套 `examples/cangjie/018-collection.cj`
- 文章 15《仓颉包、模块与程序入口》（待审核）并配套 `examples/cangjie/019-package-module-entry.cj`
- 文章 16《仓颉函数类型、Lambda 与闭包》（初稿，待审核）并配套 `examples/cangjie/021-functions-lambda-closure.cj`，覆盖函数类型/一等公民、嵌套函数、Lambda、闭包与函数调用语法糖；函数重载与操作符重载按约定拆分为独立专题
- 文章 17《仓颉函数重载与操作符重载》（初稿，待审核）并配套 `examples/cangjie/022-overloading.cj`，覆盖函数重载判定与决议、构造器重载、`operator func`（一元/二元/`[]`/`()`）、复合赋值与限制清单
- 文章 18《仓颉泛型编程》（初稿，待审核）并配套 `examples/cangjie/023-generics.cj`，覆盖泛型函数/class/struct/enum/interface、`where` 约束、静态成员不能引用类型形参、不型变与内建型变例外、类型别名与泛型别名
- 文章 19《仓颉扩展机制》（初稿，待审核）并配套 `examples/cangjie/024-extension.cj`，覆盖直接扩展、泛型扩展、条件能力、接口扩展、访问/遮盖/修饰符规则、孤儿规则、导入导出
- 学习计划由 52 篇扩展为 53 篇：文章 16 与 17 拆分定稿后，Stage 2+ 全部编号顺延一位，覆盖矩阵、总览计数同步更新
- 学习计划扩展为 52 篇，明确泛型、标准库与工具链的完整路线，并补充官方章节覆盖矩阵与小阶段复盘门禁
- 文章代码块与规范示例的同步校验流程
- `docs/article-reviews.md`：文章审核记录

### 变更
- 统一使用 `examples/` 管理可测试代码示例
- 重构本地测试和GitHub Actions测试流程
- 修正文章 6 中嵌套函数定义位置与 Go 命名返回值的对比描述

### 待办
- 第九篇文章：仓颉接口、属性与子类型（待审核）
- 第十篇文章：仓颉枚举类型 enum（待审核）
- 第十一篇文章：仓颉模式匹配（待审核）
- 第十二篇文章：仓颉数组、元组与区间（待审核）
- 第十三篇文章：仓颉字符串与字符处理（待审核）
- 第十四篇文章：仓颉 Collection 集合类型（待审核）
- 第十五篇文章：仓颉包、模块与程序入口（待审核）
- 学习文档编写
- 知识库完善

### 发布记录
- 截止 2026-08-26：阶段一文章 1 至文章 11 已发布（共 11/15 篇）
- 2026-08-25：文章 7《仓颉结构类型 struct》完成用户审核并发布
- 2026-08-25：文章 8《仓颉类类型 class》完成用户审核并发布
- 2026-08-26：文章 9《仓颉接口、属性与子类型》完成用户审核并发布
- 2026-08-26：文章 10《仓颉枚举类型 enum》完成用户审核并发布
- 2026-08-26：文章 11《仓颉模式匹配》完成用户审核并发布
- 2026-08-26：文章 12《仓颉数组、元组与区间》完成用户审核并发布

## [1.0.0] - 2024-01-XX

### 新增
#### 项目基础设施
- 创建项目README.md
- 建立AI Agent行为规范（AGENT.md）
- 设计文章风格规范（rules/article-style.md）
- 制定内容质量要求（rules/content-quality.md）
- 建立Git工作流程规范（rules/git-workflow.md）

#### 学习计划
- 制定系统学习计划（specs/learning-plan.md）
- 设计文章模板规范（specs/article-template.md）
- 建立版本管理策略（specs/version-strategy.md）

#### 知识库
- 创建仓颉语法速查表（knowledge-base/cheatsheet.md）
- 建立术语表（knowledge-base/glossary.md）

#### 工具
- 开发文章发布脚本（tools/publish.sh）
- 创建文章模板（articles/templates/）

#### 文档
- 创建贡献指南（CONTRIBUTING.md）
- 建立更新日志（CHANGELOG.md）
- 设置项目状态跟踪（STATUS.md）

#### 配置
- 添加MIT许可证（LICENSE）
- 配置.gitignore文件

### 变更
- 无

### 废弃
- 无

### 移除
- 无

### 修复
- 无

### 安全
- 无

## �本说明

### 版本策略
- 使用LTS（长期支持）版本：仓颉1.0.5 LTS
- 内容针对稳定版本，避免频繁更新
- 定期检查版本兼容性

### 更新频率
- **主版本**: 重大架构变更或内容重构
- **次版本**: 新增文章或重要功能
- **修订版本**: 错误修复和小幅改进

### 变更记录格式
```
## [版本号] - 日期

### 新增
- 新功能或新内容

### 变更
- 现有功能的变更

### 废弃
- 即将移除的功能

### 移除
- 已移除的功能

### 修复
- 错误修复

### 安全
- 安全相关的变更
```

## 版本发布流程

### 发布准备
1. 确认所有变更已记录
2. 检查版本号是否正确
3. 验证内容质量
4. 更新相关文档

### 发布步骤
1. 更新版本号
2. 更新CHANGELOG.md
3. 创建Git标签
4. 推送到远程仓库
5. 创建GitHub Release

### 发布后
1. 监控社区反馈
2. 处理问题报告
3. 规划下一版本
4. 更新项目状态

---

*本日志将随项目发展不断更新*
