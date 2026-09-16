# 文章目录（全系列 52 篇）

> 系统学习仓颉编程语言（**1.0.5 LTS**）的公众号文章系列。每篇一份 Markdown、代码示例单一真源于 `examples/`、经 Linux CI 核验。
> 进度：**1–23 已发布**，24–52 为已核验待发草稿。

## 阶段一 · 语言基础（1–15）

| # | 文章 | 状态 |
|---|---|---|
| 1 | [01-cangjie-introduction](./01-cangjie-introduction.md) — 编程语言简介与特性概览 | ✅ 已发布 |
| 2 | [02-development-environment](./02-development-environment.md) — 开发环境搭建与 Hello World | ✅ 已发布 |
| 3 | [03-variables-and-data-types](./03-variables-and-data-types.md) — 变量与数据类型 | ✅ 已发布 |
| 4 | [04-operators-and-expressions](./04-operators-and-expressions.md) — 运算符与表达式 | ✅ 已发布 |
| 5 | [05-control-flow](./05-control-flow.md) — 控制流语句 | ✅ 已发布 |
| 6 | [06-functions](./06-functions.md) — 函数基础 | ✅ 已发布 |
| 7 | [07-struct](./07-struct.md) — 结构类型 | ✅ 已发布 |
| 8 | [08-class](./08-class.md) — 类类型 | ✅ 已发布 |
| 9 | [09-interface](./09-interface.md) — 接口、属性与子类型 | ✅ 已发布 |
| 10 | [10-enum](./10-enum.md) — 枚举类型 | ✅ 已发布 |
| 11 | [11-pattern](./11-pattern.md) — 模式匹配 | ✅ 已发布 |
| 12 | [12-array-tuple-range](./12-array-tuple-range.md) — 数组、元组与区间 | ✅ 已发布 |
| 13 | [13-strings-and-characters](./13-strings-and-characters.md) — 字符串与字符处理 | ✅ 已发布 |
| 14 | [14-collection](./14-collection.md) —  Collection 集合类型 | ✅ 已发布 |
| 15 | [15-package-module-entry](./15-package-module-entry.md) — 包、模块与程序入口 | ✅ 已发布 |

## 阶段二 · 核心语言特性（16–27）

| # | 文章 | 状态 |
|---|---|---|
| 16 | [16-functions-lambda-closure](./16-functions-lambda-closure.md) — 函数类型、Lambda 与闭包 | ✅ 已发布 |
| 17 | [17-overloading](./17-overloading.md) — 函数重载与操作符重载 | ✅ 已发布 |
| 18 | [18-generics](./18-generics.md) — 泛型编程 | ✅ 已发布 |
| 19 | [19-extension](./19-extension.md) — 扩展机制 | ✅ 已发布 |
| 20 | [20-error-option](./20-error-option.md) — 错误处理与 Option | ✅ 已发布 |
| 21 | [21-resource-management](./21-resource-management.md) — 资源管理 | ✅ 已发布 |
| 22 | [22-concurrency-overview](./22-concurrency-overview.md) — 并发模型概述 | ✅ 已发布 |
| 23 | [23-thread-usage](./23-thread-usage.md) — 线程与协程使用 | ✅ 已发布 |
| 24 | [24-sync-primitives](./24-sync-primitives.md) — 同步与并发原语 | 🟢 CI通过·待发 |
| 25 | [25-basic-io](./25-basic-io.md) — 基础 I/O | 🟢 CI通过·待发 |
| 26 | [26-socket](./26-socket.md) —  Socket 网络编程（TCP 与 UDP） | 🟢 CI通过·待发 |
| 27 | [27-macros](./27-macros.md) — 宏与编译时元编程 | 🟢 CI通过·待发 |

## 阶段三 · 运行时·标准库·互操作·工具链（28–40）

| # | 文章 | 状态 |
|---|---|---|
| 28 | [28-reflect-annotation](./28-reflect-annotation.md) — 反射、注解与动态特性 | 🟢 CI通过·待发 |
| 29 | [29-c-interop](./29-c-interop.md) — -C 互操作 | 🟢 CI通过·待发 |
| 30 | [30-std-overview](./30-std-overview.md) — 标准库总览与使用方法 | 🟢 CI通过·待发 |
| 31 | [31-collections-advanced](./31-collections-advanced.md) — 标准库数据结构：容器进阶、迭代器、双端队列与集合算法 | 🟢 CI通过·待发 |
| 32 | [32-io-text](./32-io-text.md) — 标准库：编码、转换、正则与内存流（文本处理工具箱） | 🟢 CI通过·待发 |
| 33 | [33-math-time-random](./33-math-time-random.md) — 标准库：数学、时间与随机数 | 🟢 CI通过·待发 |
| 34 | [34-system](./34-system.md) — 标准库：系统能力（环境 / 进程 / 端序 / POSIX） | 🟢 CI通过·待发 |
| 35 | [35-cjc-compiler](./35-cjc-compiler.md) — 编译器 cjc：编译流程、产物、参数、诊断与链接 | 🟢 CI通过·待发 |
| 36 | [36-cjpm](./36-cjpm.md) — 包管理器 cjpm：项目初始化、cjpm.toml、依赖、构建与运行 | 🟢 CI通过·待发 |
| 37 | [37-ide](./37-ide.md) —  IDE 与语言服务：VS Code 插件的补全、诊断、构建、调试与检查 | 📄 综述·待发 |
| 38 | [38-unittest](./38-unittest.md) — 单元测试与覆盖率：cjpm test、@Test/@TestCase、断言宏与 cjcov | 🟢 CI通过·待发 |
| 39 | [39-quality-tools](./39-quality-tools.md) — 质量工具链：cjfmt 格式化、cjlint 静态检查与 cjdoc 文档 | 🟢 CI通过·待发 |
| 40 | [40-debug-perf-build](./40-debug-perf-build.md) — 工具链补全：cjdb 调试、cjprof 性能分析与构建发布 | 📄 综述·待发 |

## 阶段四 · 深入原理（41–47）

| # | 文章 | 状态 |
|---|---|---|
| 41 | [41-type-system](./41-type-system.md) — 类型系统：静态强类型、类型格、名义子类型与类型安全保证 | 🟢 CI通过·待发 |
| 42 | [42-adt-pattern](./42-adt-pattern.md) — 代数数据类型与模式匹配原理：和之积、穷尽性、不可反驳性与死分支 | 🟢 CI通过·待发 |
| 43 | [43-const-eval](./43-const-eval.md) — const 函数与常量求值：把计算搬到编译期 | 🟢 CI通过·待发 |
| 44 | [44-value-ref-memory](./44-value-ref-memory.md) — 值类型、引用类型与内存管理：赋值语义、浅拷贝穿透与 GC | 🟢 CI通过·待发 |
| 45 | [45-concurrency-model](./45-concurrency-model.md) — 并发模型与内存模型：SeqCst 原语、happens-before 与死锁原理 | 🟢 CI通过·待发 |
| 46 | [46-performance](./46-performance.md) — 性能分析与优化：先测量、少分配、看 GC | 🟢 CI通过·待发 |
| 47 | [47-evolution-practice](./47-evolution-practice.md) — 语言演进与设计实践：从语言取舍到工程清单 | 📄 综述·待发 |

## 阶段五 · 实战项目（48–52）

| # | 文章 | 状态 |
|---|---|---|
| 48 | [48-cli-tool](./48-cli-tool.md) — 命令行工具实战：分层设计、手写参数解析、单元测试与交付 | 🟢 CI通过·待发 |
| 49 | [49-web-service](./49-web-service.md) —  Web 服务实战：用 stdx.net.http + stdx.encoding.json（CI 实跑验证） | 🟢 CI通过·待发 |
| 50 | [50-concurrency-app](./50-concurrency-app.md) — 并发应用实战：任务拆分、队列通信、原子归约与屏障 | 🟢 CI通过·待发 |
| 51 | [51-cross-language](./51-cross-language.md) — 跨语言项目实战：C 互操作的 ABI、资源所有权与构建链接 | 🟢 CI通过·待发 |
| 52 | [52-final-best-practices](./52-final-best-practices.md) — 综合项目与最佳实践：一条完整工程流水线的复盘 | 📄 综述·待发 |

---

图例：✅ 已发布 ｜ 🟢 初稿完成·CI 通过·待发布 ｜ 📄 综述/文档来源篇（无 CI 运行示例，经作者确认）

> 逐篇核验记录见 `../docs/article-reviews.md`；进度总览见 `../STATUS.md`；变更历史见 `../CHANGELOG.md`。
