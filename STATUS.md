# 项目状态

> 仓颉编程语言学习笔记项目 —— 当前状态与进度跟踪。（变更历史见 `CHANGELOG.md`；逐篇核验记录见 `docs/article-reviews.md`；链接核验见 `docs/reference-link-checks.md`。）

## 概览

- **目标版本**：仓颉 **1.0.5 LTS**（基线锁定，见 `specs/version-strategy.md`）
- **写作进度**：**52 篇全部成稿**（编号 01–52 连续、无缺号）
- **发布进度**：公众号已发布至**第 23 篇**（1–23）；**24–52 为已核验待发草稿**
- **CI**：`main` 上两道 workflow 全绿 —— `Test Code Examples`（sync + 编译/运行）与 `Test stdx Web Example`（stdx HTTP/JSON 实跑）
- **示例**：**60 个规范示例**（48 单文件 + 5 cjpm 工程 + 1 stdx 网络 + stdx JSON），全部单一真源、经 CI 编译/运行

## 进度总表

图例：✅ 已发布 ｜ 🟢 初稿完成·CI 通过·待发 ｜ 📄 综述/文档来源篇（无 CI 运行示例，经作者确认）

### 阶段一 · 语言基础（1–15）— 全部 ✅
| # | 标题 | 状态 |
|---|---|---|
| 1 | 仓颉编程语言简介与特性概览 | ✅ |
| 2 | 开发环境搭建与 Hello World | ✅ |
| 3 | 变量与数据类型 | ✅ |
| 4 | 运算符与表达式 | ✅ |
| 5 | 控制流语句 | ✅ |
| 6 | 函数基础 | ✅ |
| 7 | 结构类型 struct | ✅ |
| 8 | 类类型 class | ✅ |
| 9 | 接口、属性与子类型 | ✅ |
| 10 | 枚举类型 enum | ✅ |
| 11 | 模式匹配 | ✅ |
| 12 | 数组、元组与区间 | ✅ |
| 13 | 字符串与字符处理 | ✅ |
| 14 | Collection 集合类型 | ✅ |
| 15 | 包、模块与程序入口 | ✅ |

### 阶段二 · 核心语言特性（16–27）— 16–23 ✅，24–27 🟢
| # | 标题 | 状态 |
|---|---|---|
| 16 | 函数类型、Lambda 与闭包 | ✅ |
| 17 | 函数重载与操作符重载 | ✅ |
| 18 | 泛型编程 | ✅ |
| 19 | 扩展机制 | ✅ |
| 20 | 错误处理与 Option | ✅ |
| 21 | 资源管理 | ✅ |
| 22 | 并发模型概述 | ✅ |
| 23 | 线程与协程使用 | ✅ |
| 24 | 同步与并发原语 | 🟢 |
| 25 | 基础 I/O | 🟢 |
| 26 | Socket 网络编程（TCP/UDP） | 🟢（HTTP/WS 属 stdx → 见 49） |
| 27 | 宏与编译时元编程 | 🟢 |

### 阶段三 · 运行时·标准库·互操作·工具链（28–40）
| # | 标题 | 状态 |
|---|---|---|
| 28 | 反射、注解与动态特性 | 🟢 |
| 29 | 仓颉-C 互操作 | 🟢 |
| 30 | 标准库总览与使用方法 | 🟢 |
| 31 | 标准库数据结构（容器进阶/迭代器/Deque/算法） | 🟢 |
| 32 | 标准库 I/O 与文本处理（编码/convert/regex/内存流） | 🟢 |
| 33 | 标准库数学、时间与随机数 | 🟢（JSON 属 stdx → 见 49） |
| 34 | 标准库系统能力（env/process/端序/POSIX） | 🟢（HTTP/WS 属 stdx → 见 49） |
| 35 | cjc 编译器（流程/产物/参数/诊断/链接） | 🟢 |
| 36 | cjpm 包管理器（init/toml/依赖/构建/运行） | 🟢 |
| 37 | IDE 与语言服务（VS Code） | 📄 文档来源 |
| 38 | 单元测试与覆盖率 | 🟢 |
| 39 | 质量工具链 cjfmt/cjlint/cjdoc | 🟢（cjdoc 本机 SDK 未含，手册为准） |
| 40 | 调试 cjdb / 性能 cjprof / 构建发布 | 📄 无运行示例（调试不支持 macOS、cjprof Linux-only） |

### 阶段四 · 深入原理（41–47）
| # | 标题 | 状态 |
|---|---|---|
| 41 | 类型系统（强类型/类型格/名义子类型/安全保证） | 🟢 |
| 42 | 代数数据类型与模式匹配原理 | 🟢 |
| 43 | const 函数与常量求值 | 🟢 |
| 44 | 值/引用类型与内存管理 | 🟢 |
| 45 | 并发模型与内存模型 | 🟢 |
| 46 | 性能分析与优化 | 🟢 |
| 47 | 语言演进与设计实践 | 📄 综述 |

### 阶段五 · 实战项目（48–52）
| # | 标题 | 状态 |
|---|---|---|
| 48 | 命令行工具实战 | 🟢 |
| 49 | Web 服务实战（stdx.net.http + stdx.encoding.json） | 🟢 **stdx，main CI 实跑** |
| 50 | 并发应用实战 | 🟢 |
| 51 | 跨语言项目实战 | 🟢 |
| 52 | 综合项目与最佳实践（终章复盘） | 📄 综述 |

## 基础设施

- [x] `README.md` / `AGENT.md` / `CONTRIBUTING.md` / `QUICKSTART.md` / `CHANGELOG.md`
- [x] `rules/`（content-quality / official-docs / git-workflow）
- [x] `specs/`（learning-plan 52 篇 / article-template / version-strategy）
- [x] `knowledge-base/`（cheatsheet / glossary）
- [x] `docs/`（article-reviews / reference-link-checks）
- [x] `.github/workflows/code-examples-test.yml`（主 CI：sync + test-local）
- [x] `.github/workflows/stdx-web-test.yml`（stdx CI：源码构建 stdx + 跑 HTTP/JSON）
- [x] `tools/test-local.sh`、`tools/publish.sh`、`.github/scripts/sync_examples.py`
- [x] LICENSE (MIT) / `.gitignore`（含 `target/`）

## CI 与质量门禁（三道）

1. **一致性**：`sync_examples.py` —— 每个 `<!-- example: 路径 -->` 绑定唯一真源文件，双向校验"文件被引用 + 文内块与文件逐字节一致"（当前 60/60）。
2. **编译/运行**：`test-local.sh`（本地 macOS staticlib + `[SKIP-DARWIN]`；Linux CI 编译并运行）；`test_cangjie_projects` 对 cjpm 工程跑 `cjpm build`/`run`/（含 `*_test.cj` 则）`test`。
3. **平台真相**：本机 macOS SDK 残缺（不能链接 std 可执行、缺 `std.reflect`/`stdx`/`cjdoc`），故运行事实以 **Linux CI** 为准。

## 已知平台事实与诚实边界（全系列实测汇总）

- **工具链缺口**：`cjpm` 无 `fetch`（拉依赖=`cjpm check`）、无 `publish`；1.0.5 base SDK **无 `std.json`**（JSON 在 `stdx.encoding.json`）、无 `std.concurrent`/`Channel`、无 `actor` 关键字；`unittest` 断言是宏 `@Expect`/`@Assert`（非 `assertEquals`）；`as` 返回 `Option`（**无 `as?`**）；泛型**不变**、无声明点变体关键字；**`MemoryOrder` 已弃用、内存序不进公开 API**；原子只有默认最强强度。
- **语义坑（均实测）**：`Array` 名义 struct 实为共享 backing（`VArray` 才值拷贝）；`String.size` 是码点；`1..n` 上界不含；`match` 少支=`non-exhaustive`、多余 `_`=死分支告警；Rune 字面量 `r'\n'`；`struct` 构造位置参数；`match` 分支 `=>{}` 会被当 lambda；`throw` 暂不作 const 表达式。
- **stdx**：`stdx.net.http`（HTTP）+ `stdx.encoding.json`（`JsonValue`）已在 main CI 实跑（源码 `build.py` 构建 + `NO_ASPECTCJ=1` 绕开 cjnative 缺 `include/` 的 aspectCJ + OpenSSL3）；`DataModel`/serialization、WebSocket、TLS、argopt 宏、C 回调函数指针类型**未验证 → 不硬编**。

## 风险与维护

- **版本更新**：锁 1.0.5 LTS；升版前重跑 `test-local` + 两道 CI + 复核每篇"版本信息"，弃用告警清零再发。
- **stdx 脆弱性**：stdx workflow 标 `continue-on-error`（源码构建受工具链/OpenSSL 影响，不阻塞主门禁）。
- **技术准确性**：每篇经 `cjc` 本地实测 + Linux CI 运行核对 + 官方链接核验，未验证者如实标注。

---

*本状态文档定期更新；变更历史见 `CHANGELOG.md`。*
