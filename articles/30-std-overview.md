# 仓颉标准库总览与使用方法

> **摘要**: 仓颉把开箱能力分三层：编译器**隐式导入的 `core`**（`String`/`Int64`/`Array`/`Option`/`Range` 等）、**base SDK 自带的 `std.*` 包**（集合、数学、时间、同步、I/O、文件、反射、单元测试……共几十个）、以及**需 `cjpm` 下载的 `stdx.*` 扩展**（如 HTTP/WebSocket、Python 生态之外的第三方）。本文依据 1.0.5 LTS 实际环境，讲清这三层的边界、`import std.xxx` 的四种写法、**如何查/读标准库 API 文档**（叙事 dev-guide vs 库 API `?url=`）、**版本匹配**（`cjpm.toml` 的 `cjc-version`、LTS/STS 选择），以及读官方示例的正确姿势，配一个跨 3 个 std 包协同的完整示例。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK（含 `cjpm`）
- 已完成《包、模块与程序入口》（`import` 语法、`cjpm` 基础）
- 已大致用过 `Array`、`ArrayList`、`HashMap`、`Option`、`Duration`

## 1. 标准库的三层结构

| 层 | 是什么 | 怎么用 | 是否需要装 |
|---|---|---|---|
| **`core`（预导入）** | 编译器自动隐式导入的公共类型 | **不用 import**，直接用 `String`/`Int64`/`Array`/`Option`/`Range`/`Duration`/`Future`/`print`… | 随 SDK |
| **`std.*`（base 包）** | 官方 base SDK 里带的 `std` 下各子包 | 显式 `import std.<pkg>...` | 随 SDK |
| **`stdx.*`（扩展包）** | 官方 stdx 独立发布的包（HTTP、部分生态集成等） | `cjpm` 拉包，`cjpm.toml` 配依赖后 `import stdx.<pkg>...` | 需下载 |

### 1.1 为什么要分层

- **`core` 隐式导入**：`main.cj` 里不写 import 也能 `println("...")` 与用 `Array`——编译器自动引入 `core` 里所有 `public` 声明（见《包、模块与程序入口》）。
- **`std.*` 按需引**：容器、数学、并发、文件等按需 `import`，避免污染。
- **`stdx.*` 可选装**：把体量较大或迭代较快的能力（如 HTTP/WebSocket）从 base SDK 剥离，随 stdx 独立发行，用 `cjpm` 拉取。

> **💡 判断依据**：如果 `import std.reflect` 之类突然"找不到包"，**先分清是包真不存在、还是你本机 SDK 装得不全**。1.0.5 官方 base SDK 的 std 里其实**有** `std.reflect`（在 CI 里我们实测过），只是有些开发机（如新版 macOS）会拿到残缺包。这种"环境差异"应通过**升级到完整官方 SDK**、或**以 Linux CI 为准**来解决，而不是怀疑语言本身。

## 2. `std.*` 都包括什么（1.0.5 实测清单）

我在 1.0.5 SDK 里 `ls modules/.../std/*.cjo` 得到实际存在的 std 顶层包（不同发行/平台可能略有出入，以你本机为准）：

| 类别 | 包 | 典型用途 |
|---|---|---|
| 语言核心工具 | `core` `convert` `reflect` `runtime` | 基础类型 / 字符串↔数字 / 反射 / 运行时交互 |
| 数据结构 | `collection` `collection.concurrent` `objectpool` | `ArrayList` / `HashMap` / 并发安全集合 / 对象池 |
| 算法 | `sort` | 全局排序 |
| 数学/随机 | `math` `math.numeric` `random` | 数学函数 / 高精度数值 / 伪随机 |
| 文本 | `unicode` `regex` | 字符处理 / 正则 |
| I/O & 文件 | `io` `fs` `console` `binary` | 流 / 文件系统 / 控制台 / 端序 |
| 时间 | `time` | `Duration` 与时刻 |
| 环境/进程 | `env` `posix` `process` `argopt` | 标准输入输出流 / POSIX / 子进程 / 命令行解析 |
| 网络 | `net` | **传输层 Socket**（TCP/UDP；HTTP/WebSocket 属 `stdx.net`，需另装） |
| 并发原语 | `sync` | `Mutex`/`Condition`/`Atomic*`/`Channel`/`SyncCounter` |
| 安全 | `crypto` `crypto.cipher` `crypto.digest` | 对称加解密 / 摘要 |
| 数据库 | `database` `database.sql` | 数据库访问 |
| 单元测试 | `unittest` 及其子模块（`common` `diff` `mock` `prop_test` `testmacro`） | 测试框架与断言/覆盖率/mock |
| 元编程 | `ast` `deriving` 及子模块（`api`/`builtins`/`impl`/`resolve`） | 宏的 `Tokens`/AST / 派生宏框架 |
| 溢出策略 | `overflow` | 整数溢出相关 |
| 引用 | `ref` | 弱引用（**别和 `reflect` 混淆**） |
| 编译期宏 | 见《宏与编译时元编程》里 `macro package` | — |

**读法**：想用什么能力，先在表里找包，再去查它的 API 页（见第 4 节）。

## 3. 导入标准库的四种写法

承接《包、模块与程序入口》，用 std 时最常用这四种：

```cangjie
// 1) 精确到名（推荐，可读性最好）
import std.collection.ArrayList
import std.math.sqrt

// 2) 同包多类型
import std.collection.{HashMap, HashSet, ArrayList}

// 3) 通配符导入整包（写起来爽、命名污染重，别在大型项目里到处用）
import std.io.*

// 4) as 重命名（不同包同名冲突时）
import std.collection.ArrayList as AList
```

- **`core` 不用 import**：`println` / `print` / `Array` / `Option` / `Some` / `None` / `Duration` / `spawn` / `Future` / `Result`（**没有**，见《错误处理与 Option》） 都直接可用。
- 只写 `import std.collection` **不带具体项**是**不合法**的（那是导入"整个包作为命名空间"的另一种形式，具体见 FAQ Q2）。

## 4. 怎么查、怎么读官方文档

仓颉官方文档其实有**两种视图**，用途不同：

| 视图 | 地址形态 | 内容 | 适合 |
|---|---|---|---|
| **叙事文档**（dev-guide） | `https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/...` 与 `.../spec/...`、`.../user_manual/...` | 有例子有讲解的 Markdown 章节，可被普通 HTTP 抓取 | 学概念、跟教程 |
| **库 API**（`?url=` 形式） | `https://cangjie-lang.cn/docs?url=%2F1.0.5%2Flibs%2Fstd%2F<pkg>%2F<item>.html` | 每个 `class`/`struct`/`interface`/`func` 的接口签名与说明 | 查具体函数签名/参数 |

### 4.1 读叙事文档

叙事文档按章节组织（"包与模块"、"泛型"、"扩展"、"并发"、"宏"、"反射与注解"、"FFI"…）。**遇到语言级"为什么"就查它**。例如"闭包捕获 `var` 为什么不能作一等公民"在 `function/closure.html`；`@Derived` 派生宏在 `derive/` 章。

### 4.2 读库 API

**API 文档以 `?url=<路径>` 形式访问，是 SPA 单页应用**——浏览器里点目录能看，但**脚本抓取只能拿到壳**（这就是为什么本项目 `docs/reference-link-checks.md` 里 std.collection 那批链接要显式用 `cangjie-lang.cn/docs?url=...` 而不是 `docs.cangjie-lang.cn/...`）。

查一个具体 API 的路径规律：
```
/libs/std/<包名>/<类型或文件>.html
如：/libs/std/collection/arraylist.html      （ArrayList 类）
    /libs/std/collection/hashmap.html        （HashMap 类）
    /libs/std/sync/mutex.html                （Mutex 类）
```
在浏览器地址栏拼上 `https://cangjie-lang.cn/docs?url=%2F1.0.5<上面路径>` 就能打开对应包/类型的 API 页。

> **⚠️ 别把叙事文档当 API**：叙事文档给的是**概念与用法示例**，未必列出所有成员/重载。**签名以库 API 为准**。

## 5. 版本匹配（很重要）

同一份代码在 1.0.5、1.0.6、1.1.0 上行为**未必**完全一致。项目基线是 **1.0.5 LTS**。三层同步：

1. **本机 SDK 与 CI SDK 保持同版本**：`cjc --version` 与 CI 下载包版本一致。
2. **cjpm 项目锁版本**：`cjpm.toml` 里 `cjc-version = "1.0.5"`（1.0.5 之后 cjc 会强校验这个字段是否为空）。
3. **文章里明确写"基于 1.0.5 LTS"**：读者按此版本装；跨版本差异以番外形式补。

> **💡 LTS vs STS**：截至本文写作时（2026-08），官方 1.0.5 仍是**最新的 LTS**；另有 1.1.0/1.1.3 STS 快速演进。**教程/生产建议锁 LTS**（本文所有事实都对齐 1.0.5 官方文档），STS 用来尝鲜，别混进基线。

## 6. 读官方示例的正确姿势

- **官方例子是"骨架"，不是"作业"**：文档里的 `class Foo`、`main()` 只演示 API，不处理输入校验、异常、边界——抄过来要自己补。
- **先跑再改**：把官方例子原样粘到一个新 `.cj` 里，`cjc hello.cj -o hello && ./hello`（或 `cjpm run`）跑通，再改造成你的场景。
- **不确定就回来查表**：`std.*` 有哪些包、`stdx.*` 有什么、`import` 怎么写、`cjpm.toml` 怎么配——本文就是给你随时回看的地图。

## 7. 完整可运行示例（跨包协同）

同一个 `main` 里协同 3 个 std 包：`std.collection`（容器）、`std.math`（数学）、`std.sync`（原子）。所有都是 base SDK 自带，本地 `cjc --output-type staticlib` 能编过、CI 会真跑。

<!-- example: cangjie/035-std-overview.cj -->
```cangjie
// 标准库总览示例：跨多个 std.* 包协同完成一个小任务
// 目的：演示"标准库分层"的实际使用——按需 import、只依赖 base SDK 自带包
// 覆盖：std.collection（容器）、std.math（数学函数）、std.sync（并发原语）
//
// 说明：这些都是 1.0.5 base SDK 自带的包，无需下载 stdx；本示例本地上
// 也能 `cjc --output-type staticlib` 编过。

import std.collection.{ArrayList, HashMap}   // 精确导入两个类型
import std.math.sqrt                         // 只导一个函数
import std.sync.AtomicInt64                  // 原子计数

main(): Int64 {
    // 1) std.collection：容器（数组式 + 键值）
    let list = ArrayList<Int64>([3, 1, 4, 1, 5])
    var sum: Int64 = 0
    for (x in list) {
        sum += x
    }
    let map = HashMap<String, Int64>([("a", 1), ("b", 2)])
    println("collection: sum=${sum}, map.size=${map.size}")   // collection: sum=14, map.size=2

    // 2) std.math：数学函数。Float64 插值以六位小数打印（本文实测格式）
    println("math: sqrt(16)=${sqrt(16.0)}")                   // math: sqrt(16)=4.000000

    // 3) std.sync：并发原语（此处顺序调用，输出确定）
    let cnt = AtomicInt64(0)
    for (_ in 0..10) {
        cnt.fetchAdd(1)
    }
    println("sync: count=${cnt.load()}")                      // sync: count=10

    return 0
}
```

预期输出：

```text
collection: sum=14, map.size=2
math: sqrt(16)=4.000000
sync: count=10
```

## 8. 语言对比

| 生态 | 顶层分法 | 装包方式 | 版本锁定 |
|---|---|---|---|
| **仓颉** | `core`（隐式）/ `std.*`（base SDK 自带）/ `stdx.*`（cjpm 下载） | `cjpm` + `[dependencies]` / `[macro-dependencies]`；`cjpm.toml` 里 `cjc-version` | `cjpm.toml` |
| Go | `builtin` / std lib / module | `go get` + `go.mod` | `go.mod` 里 `go` 指令 |
| Rust | `core` / `std` / crates.io | `cargo add` + `Cargo.toml` | `Cargo.lock` + `rust-toolchain` |
| Java | JDK 类库 / 模块化 API | Maven/Gradle + `pom.xml`/`build.gradle` | JDK 版本 + 依赖锁 |

**共同套路**：都有"语言内建 / 官方标准库 / 中心仓生态"三层；都用清单文件锁版本。仓颉的差别在于**"std" 与 "stdx" 明确分成两半**：base SDK 里那批是 std，扩展库另发（如 `stdx.net` 的 HTTP/WebSocket）。

## 9. 常见问题（FAQ）

### Q1: `Array`、`Option`、`Duration`、`print` 我不用 import 就能用，是不是 bug？

不是。它们是 `core` 里的 `public` 类型/函数，编译器**自动隐式导入** `core` 全部 `public` 声明。

### Q2: `import std.collection;`（后面不接具体项）行吗？

`import 包名.成员` 需要具体项；只写 `import std.collection` 表示把整包作为**命名空间**（用 `std.collection.ArrayList` 全限定访问）。多数场景建议 `import std.collection.ArrayList` 或 `{A, B}` 精确导入。

### Q3: `std.net` 和 `stdx.net` 到底哪个是 HTTP？

- **`std.net`**（base SDK）：**传输层 Socket**——`TcpSocket`/`UdpSocket`/`TcpServerSocket`。
- **`stdx.net`**（需 `cjpm` 下载）：**HTTP/WebSocket**——`ServerBuilder`/`ClientBuilder`。

同理，`std.reflect`（反射）在 base SDK，但个别 macOS 发行包会缺失——以 CI 或重新装完整 SDK 为准。

### Q4: 我怎么确认某个 API 到底属于哪层？

**先跑一遍**：写最小 `import` 试着编。若"can not find package"→ base SDK 未含该包（可能要下 stdx）；若"cannot find member 'X' in 'pkg'"→ 包在但类型不在（拼错或版本迁移）。或直接查库 API 文档。

### Q5: 我用的 1.0.5，官方已经出 1.1.x 了，需要升级吗？

看用途。**学习和生产**建议**锁 LTS**（本文与整个系列都是 1.0.5）；想尝新用 STS，但**别混进基线**（详见《版本策略》与《宏与编译时元编程》篇）。

### Q6: `cjpm.toml` 的 `cjc-version` 有什么用？

cjpm 会校验它，避免"你以为在用 A 版、实际是 B 版"的错乱。团队协作时锁版本 + 锁 lockfile，构建更稳。

### Q7: 叙事文档和库 API 文档冲突以哪个为准？

**语义/概念看叙事文档、接口签名看库 API**。API 页是 cjc 与 std 的接口清单；叙事文档可能滞后。冲突时以官方发行说明为准。

### Q8: 官方 base SDK 是不是包含所有官方库？

不是。`std` 是 base SDK 自带；`stdx`（如 `stdx.net.http`）要 `cjpm` 下载并配 `cjpm.toml`。选库先分清属于哪一层。

## 10. 总结

1. 标准库分三层：**`core`（隐式导入）→ `std.*`（base SDK 自带）→ `stdx.*`（cjpm 下载）**。
2. 常用 `import`：`import std.pkg.name` / `{a,b}` / `.*` / `as`；只写 `import std.pkg` 是把整包作命名空间。
3. 文档两种视图：**叙事 dev-guide**（学概念，可脚本抓）与 **库 API `cangjie-lang.cn/docs?url=...`**（查签名，SPA 页）。
4. **版本匹配三层锁**：本机 SDK = CI SDK = `cjpm.toml` 的 `cjc-version`；**基线锁 LTS**（本文 1.0.5），STS 只尝鲜。
5. 官方示例是骨架，先跑通再改造；判包层次：**能不能编 + 查 API 文档**最靠谱。
6. 常见坑：`std.net`(socket) vs `stdx.net`(http)、`std.ref`(弱引用) vs `std.reflect`(反射)、base SDK 缺失包（升级完整 SDK 或以 CI 为准）。

## 参考资料

1. 仓颉 1.0.5 LTS 包的概述：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/package/package_overview.html
2. 仓颉 1.0.5 LTS 使用 import 语句导入其他包中的声明或定义：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/package/import.html
3. 仓颉 1.0.5 LTS 库文档入口（叙事/API）：https://docs.cangjie-lang.cn/docs/1.0.5/
4. 仓颉 1.0.5 LTS 官方下载中心：https://cangjie-lang.cn/download/1.0.5

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
