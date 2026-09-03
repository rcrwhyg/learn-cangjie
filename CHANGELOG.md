# 更新日志

> 本文档记录仓颉编程语言学习笔记项目的所有重要变更

## 版本格式

本项目遵循[语义化版本](https://semver.org/lang/zh-CN/)规范：
- **主版本号**: 不兼容的API变更
- **次版本号**: 向下兼容的功能性新增
- **修订版本号**: 向下兼容的问题修正

## [未发布]

### 发布进度（2026-08-31）
- 公众号已发布至**文章 17**（阶段一 1-15 + 阶段二 16-17 全部发布）

### 新增
- 文章 1 至文章 8 已发布，覆盖仓颉语言基础阶段前 8 篇文章
- 更新（2026-08-30）：文章 13/14 已发布，阶段一发布进度累计至 1-14
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
- 文章 20《仓颉错误处理与 Option》（初稿，待审核）并配套 `examples/cangjie/025-error-option.cj`，覆盖 Error/Exception、自定义异常、try-catch-finally、try 作表达式、CatchPattern 三形态、try-with-resources、内置运行时异常、Option 定义/糖/自动装箱、四种解构（match/`??`/`?.`/getOrThrow）与错误传播；明确 1.0.5 无 Result 类型
- 文章 21《仓颉资源管理》（初稿，待审核）并配套 `examples/cangjie/026-resource-management.cj`，覆盖手动 close / try-with-resources / 终结器 ~init 三条路径、Resource 契约、终结器 12 条限制、std.runtime.gc 与取舍建议
- 文章 22《仓颉并发模型概述》（初稿，待审核）并配套 `examples/cangjie/027-concurrency-overview.cj`，覆盖语言线程 vs native 线程、1:1 vs M:N 抢占式模型、阻塞再调度、foreign 阻塞注意、`spawn`/`Future.get()` 任务生命周期最小用法（详细线程 API 留给 23）
- 文章 23《仓颉线程与协程使用》（初稿，待审核）并配套 `examples/cangjie/028-thread-usage.cj`，覆盖 spawn/主线程带走子线程、Future 的 get/get(timeout)/tryGet、Thread 访问与 id、cancel + hasPendingCancellation 协作式终止、sleep(Duration)；同步原语留给 24
- 文章 24《仓颉同步与并发原语》（初稿，待审核）并配套 `examples/cangjie/029-sync-primitives.cj`，覆盖 AtomicInt*/Bool/Reference、可重入 Mutex/tryLock、synchronized 语句与表达式、Condition 谓词循环、有界队列模式、ThreadLocal；示例六路输出全为确定值
- 文章 25《仓颉基础 I/O》（初稿，待审核）并配套 `examples/cangjie/030-basic-io.cj`，覆盖流抽象(InputStream/OutputStream/flush)、节点流 vs 处理流、标准流 ConsoleReader/Writer、File 常规操作与文件流/OpenMode/try-with-resources、缓冲流、字符串流
- 文章 26《仓颉 Socket 网络编程（TCP 与 UDP）》（初稿，待审核）并配套 `examples/cangjie/031-socket.cj`，覆盖 StreamSocket/DatagramSocket、TCP bind/accept/connect 与 UDP sendTo/receiveFrom、阻塞式仅阻塞仓颉线程、bindAt:0 临时端口、readExactly 应对分片；HTTP/WebSocket（stdx.net）拆出另篇
- 扩 `tools/test-local.sh`：新增 `test_cangjie_projects`，扫描 `examples/cangjie/*/cjpm.toml` 目录，macOS 走 `cjpm check`、Linux 走 `cjpm build + cjpm run`；配合既有 `sync_examples.py` 的递归 glob，解锁 cjpm 多包（含宏）示例
- 文章 27《仓颉宏与编译时元编程》（初稿，待审核）：以 `examples/cangjie/032-macro-dprint/`（cjpm 项目，含 `macro package`）为可运行示例，讲 `macro package` / `Tokens` / `quote` / 非属性 vs 属性宏 / 嵌套宏
- 文章 28《仓颉反射、注解与动态特性》（初稿，待审核）并配套 `examples/cangjie/033-reflect-annotation.cj`：`TypeInfo`（of/get）、反射读写成员、`@Annotation`+`const init`+`findAnnotation`、`@Overflow*` 三策略；经 Linux CI 核实 `std.reflect` 属 1.0.5 标准库，本地 macOS SDK 不完整故 `test-local.sh` 增加 `[SKIP-DARWIN]` 分支（macOS 跳过含 std.reflect 的示例，Linux CI 权威验证）
- 文章 29《仓颉-C 互操作》（初稿，待审核）并配套 `examples/cangjie/034-c-interop.cj`：foreign/@C/CFunc/inout/unsafe/@CallingConv/类型映射(@C struct·CPointer·CString·VArray·sizeOf)/链接(-L -l)/跨语言副作用；本地 staticlib 编译通过
- 学习计划由 52 篇扩展为 53 篇：文章 16 与 17 拆分定稿后，Stage 2+ 全部编号顺延一位，覆盖矩阵、总览计数同步更新
- 学习计划扩展为 52 篇，明确泛型、标准库与工具链的完整路线，并补充官方章节覆盖矩阵与小阶段复盘门禁
- 文章代码块与规范示例的同步校验流程
- `docs/article-reviews.md`：文章审核记录

### 变更
- 统一使用 `examples/` 管理可测试代码示例
- 重构本地测试和GitHub Actions测试流程
- 修正文章 6 中嵌套函数定义位置与 Go 命名返回值的对比描述

### 新增
- 文章 30《仓颉标准库总览与使用方法》（初稿，待审核）并配套 `examples/cangjie/035-std-overview.cj`：三层结构（core 隐式/std.* base/stdx.* 下载）、import 四写法、叙事 vs 库API 两种文档视图、版本匹配(锁 LTS)、跨 3 包协同示例

- 文章 31《仓颉标准库数据结构：容器进阶、迭代器、双端队列与集合算法》（复盘补齐 ArrayList/HashMap/HashSet 进阶，含 std.sort 替代弃用的 ArrayList.sort、HashMap[]+Option 返回、HashSet.subsetOf；cjc 逐条实测）（初稿，待审核）并配套 `examples/cangjie/036-collections-advanced.cj`：Iterable/Iterator 协议与 for-in 脱糖、自定义可迭代类型、ArrayDeque、filter/map/reduce/any/all 管道算法；API 全部经本地 cjc 实证

- 文章 33《仓颉标准库：数学、时间与随机数》（初稿，待审核）并配套 `examples/cangjie/038-math-time-random.cj`：std.math/std.time(Duration·DateTime.UnixEpoch)/std.random(种子可复现)；JSON 属 stdx 明确不覆盖；π 常量名未臆造
- 文章 32《仓颉标准库：编码、转换、正则与内存流》（初稿，待审核）并配套 `examples/cangjie/037-io-text.cj`：String↔UTF-8 字节、`std.convert`(parse/tryParse/toString(radix)/StringBuilder)、`std.regex`(find/findAll/raw string)、`std.io`(ByteBuffer+readToEnd)；API 全部 cjc 实测

### 变更
- 学习计划：删除并不存在的"仓颉-Python 互操作"篇（用户核实 1.0.5 无此能力），53 篇→52 篇；阶段三末尾与阶段四、五编号 -1；跨语言实战篇改为"C 互操作"

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
