# 仓颉包管理器 cjpm：项目初始化、cjpm.toml、依赖、构建与运行

> **摘要**: 文章 35 讲了单文件编译器 `cjc`；真实项目是多包、带依赖的，这活儿交给 `cjpm`（`Cangjie Package Manager` 1.0.5）。本篇把 `cjpm` 走一遍：`cjpm init` 建工程、`cjpm.toml` 每个字段、**内部多包**与**外部依赖**怎么声明、`cjpm check/update/tree` 管依赖、`cjpm build`/`cjpm run` 构建运行、`cjpm test`/`bench`/`clean`。所有子命令与 `cjpm.toml` 模板、`target/release/bin/main` 产物路径、`cjpm check` 打印的"串行编译顺序"都在 1.0.5 本地实测；运行输出在 Linux CI 核对。**配套示例是一个两包工程**（`main` 依赖同模块内的 `greet` 包）。

## 前置知识

- 已完成《cjc 编译器》（文章 35）——`cjpm` 底层就是在正确时机调用 `cjc`
- 已完成《包、模块与程序入口》（文章 15）——`package`/`import`/`main()`
- 会用 `cjpm.toml`（文章 15 见过雏形），知道"依赖锁定文件"概念（如 `go.mod`/`Cargo.toml`）

> 定位：阶段四"工具链"第二篇。`cjpm` 是仓颉的 `cargo` / `go` + `mod`。

## 1. cjpm 是什么

`cjpm` 是**模块级**的构建与包管理工具，一条命令负责"解析 `cjpm.toml` → 拉/校验依赖 → 按拓扑序把每个包喂给 `cjc` → 链接产物"。你只需要描述"我的模块长什么样、依赖谁"，剩下的编译顺序 `cjpm` 自己算。

```shell
cjpm [subcommand] [option]
```

1.0.5 的全部子命令（`cjpm --help` 实测）：

| 子命令 | 作用 |
|---|---|
| `init` | 初始化一个新模块（生成 `cjpm.toml` + `src/`） |
| `check` | 校验/解析依赖、算编译顺序（**会拉取依赖并生成 `cjpm.lock`**） |
| `update` | 更新 `cjpm.lock`（依赖版本升级） |
| `tree` | 以树状打印包依赖图 |
| `build` | 编译当前模块及全部依赖 |
| `run` | 编译并运行可执行产物（默认产物名 `main`） |
| `test` | 构建并运行单元测试（详见文章 38） |
| `bench` | 运行基准测试 |
| `clean` | 清理 `target/` 产物（不动 `cjpm.toml`/`cjpm.lock`） |
| `install` / `uninstall` | 安装 / 卸载仓颉可执行程序 |

> **⚠️ 1.0.5 没有 `cjpm fetch`**：别被旧印象带偏——"拉取依赖"这件事是 `cjpm check`（顺带生成锁文件）做的，`cjpm build`/`run`/`test` 之前也会先做依赖解析。真要单独更新锁文件用 `cjpm update`。

## 2. cjpm init：搭工程骨架

```shell
cjpm init                       # 在当前目录建模块，包名=目录名
cjpm init --name hello --path hello --type=executable
```

`cjpm init` 生成两样东西：一个 `cjpm.toml` 和一个 `src/`（内含 `main.cj`）。实测 `cjpm init --name cjpmdemo` 生成的 `cjpm.toml` 长这样（字段顺序即 cjpm 生成顺序）：

```toml
[package]
  cjc-version = "1.0.5"
  name = "cjpmdemo"
  description = "nothing here"
  version = "1.0.0"
  target-dir = ""
  output-type = "executable"
  compile-option = ""
  override-compile-option = ""
  link-option = ""
  package-configuration = {}

[dependencies]
```

而 `src/main.cj`：

```cangjie
package cjpmdemo

main(): Int64 {
    println("hello world")
    return 0
}
```

`--type` 三选一决定 `output-type`：`executable` / `static` / `dynamic`。`--workspace` 只生成一个 workspace 级配置（管理多个子模块，见第 4 节）。

## 3. cjpm.toml 字段逐项

`cjpm.toml` 是**声明式清单**（类比 `Cargo.toml`），核心是 `[package]` 段：

| 字段 | 含义 | 备注 |
|---|---|---|
| `cjc-version` | 期望的 SDK 版本 | `cjpm` 会据此选工具链 |
| `name` | 模块名 | **包路径前缀**（见第 4 节，`package <模块名>.xxx`） |
| `version` | 模块版本 | 语义化版本 |
| `description` | 描述 | 纯元信息 |
| `output-type` | `executable`/`static`/`dynamic` | 决定 `build` 产物类型 |
| `target-dir` | 产物输出目录 | 空串=默认 `target/` |
| `compile-option` | 追加给 `cjc` 的编译选项 | 如 `"-O2"`；与 cjpm 自动加的选项**并存** |
| `override-compile-option` | **完全覆盖**编译选项 | 慎用，会顶掉 cjpm 默认选项 |
| `link-option` | 追加给链接器的选项 | 承文章 35 `--link-options` |
| `package-configuration` | 包级配置（内联表） | 一般留空 |

> **💡 compile-option vs override-compile-option**：前者是"在 cjpm 默认基础上再加"，后者是"我说了算、别加默认的"。99% 情况用 `compile-option` 就够。这些选项最终都转成文章 35 里 `cjc` 的那批命令行参数。

## 4. 依赖：内部多包 + 外部依赖

### 4.1 一个模块内的多个包（本篇示例）

一个 `cjpm` 模块可以在 `src/` 下放**多个包**，互相 `import`。包路径规则：**`<模块名>.<相对 src 的目录>`**。示例工程：

```text
041-cjpm-demo/
├── cjpm.toml            # name = "mpdemo", output-type = "executable"
└── src/
    ├── main.cj          # package mpdemo           →  import mpdemo.greet.*
    └── greet/
        └── greeter.cj   # package mpdemo.greet     →  对外 public 函数
```

`cjpm check` 会自动算出**串行编译顺序**（实测输出）：

```text
The valid serial compilation order is:
    mpdemo.greet -> mpdemo
cjpm check success
```

即"先编被依赖的 `greet`，再编依赖它的 `main`"——你不用手动排。

两个源文件（被文章引用的规范示例）：

<!-- example: cangjie/041-cjpm-demo/src/greet/greeter.cj -->
```cangjie
package mpdemo.greet

// 对外公开的库函数：cjpm 会把 greet 包先编成模块内的依赖，再编 main。
public func greeting(who: String): String {
    return "hello, ${who}"
}

public func add(a: Int64, b: Int64): Int64 {
    return a + b
}
```

<!-- example: cangjie/041-cjpm-demo/src/main.cj -->
```cangjie
package mpdemo

import mpdemo.greet.*

// cjpm 会先编 greet 包、再编本 main（cjpm check 会打印这个串行编译顺序）。
// cjpm run 一条命令搞定"编译 + 运行可执行产物"。
main(): Int64 {
    println(greeting("cangjie"))            // hello, cangjie
    println("add(2, 3) = ${add(2, 3)}")     // add(2, 3) = 5
    return 0
}
```

### 4.2 外部依赖（`[dependencies]` / `[macro-dependencies]`）

模块之间/第三方库写在 `[dependencies]`；宏包写在 `[macro-dependencies]`。**本地路径依赖**的确切写法（本系列文章 27 的宏工程实测用这种嵌套表形式）：

```toml
[dependencies]
  # 本模块内的子目录包（少见，多数同模块内包直接 import 即可）

[macro-dependencies]
  [macro-dependencies.define]
    path = "./src/define"
```

**Git / 远端仓库依赖**（`cjpm` 从 git 拉取、按锁文件钉版本）属于 `cjpm` 手册的完整能力，字段形态较多——本文**不臆造其确切键名**，请以官方《包管理工具》手册为准；日常用 `cjpm` 从包仓库添加依赖时，一条 `cjpm add <包>`（若有）或改 `cjpm.toml` 后 `cjpm check` 拉取即可。

> **`cjpm.lock` 是什么**：依赖解析结果被钉进 `cjpm.lock`（实测内容：`version = 0` + `[requires]`，无外部依赖时基本为空）。它保证"你机器和同事机器拉到同一版本"——类似 `Cargo.lock`/`go.sum`，**应提交进版本库**。`cjpm update` 才会改锁。

依赖树可视化：

```shell
cjpm tree                 # 打印包依赖树
cjpm tree --depth 2       # 限制深度
cjpm tree --no-tests      # 排除测试依赖
```

## 5. 构建与运行

```shell
cjpm build                # 编译整个模块 + 依赖，产物在 target/
cjpm build -i             # 增量编译（只重编变了的包）
cjpm build -j 8           # 8 路并行
cjpm build -g             # debug 版（产物进 target/debug/）
cjpm run                  # 编译并运行可执行产物（默认名 main）
cjpm run --run-args "a b" # 给 main(args) 传参
cjpm run --skip-build     # 只跑已编好的，不重编
```

实测 `cjpm build`（`output-type=executable`）最终会链接到 **`target/release/bin/main`**（`cjpm run` 再执行它）。加 `-g` 走 `target/debug/`。

> **⚠️ 本机 macOS 链不动**：和文章 35 同因——`cjpm build` 在 macOS 会卡在 `ld64.lld: ... incompatible with arm64`（SDK 链接问题，非代码问题）。**Linux CI 上 `cjpm build`+`cjpm run` 正常**，本篇示例的运行输出以 CI 为准。本地可用 `cjpm check` 验证依赖解析与包结构无误（能过 `cjpm check` = 语法/跨包 import 都对）。

`cjpm clean` 清 `target/`：

```shell
cjpm clean            # 清 release
cjpm clean -g         # 只清 debug 产物
```

## 6. 测试与基准（点到为止，详见文章 38）

`cjpm test` 构建并运行模块内所有包的单测（`*_test.cj` / `@Test`），`cjpm bench` 跑基准：

```shell
cjpm test                     # 全部包的单测
cjpm test src/greet           # 只测指定包
cjpm test --coverage          # 带覆盖率（配合 cjcov，文章 39）
cjpm bench                    # 基准测试
```

测试结构、断言、`--filter`、覆盖率分析放在**文章 38《单元测试与覆盖率》**细讲。

## 7. 与 cargo / go 对照

| 动作 | 仓颉 `cjpm` | Rust `cargo` | Go |
|---|---|---|---|
| 新建工程 | `cjpm init` | `cargo new` | `go mod init` |
| 清单文件 | `cjpm.toml` | `Cargo.toml` | `go.mod` |
| 锁文件 | `cjpm.lock` | `Cargo.lock` | `go.sum` |
| 校验/解析依赖 | `cjpm check` | `cargo check` | `go mod tidy` |
| 更新锁 | `cjpm update` | `cargo update` | `go get -u` |
| 依赖树 | `cjpm tree` | `cargo tree` | `go mod graph` |
| 构建 | `cjpm build` | `cargo build` | `go build` |
| 运行 | `cjpm run` | `cargo run` | `go run .` |
| 测试 | `cjpm test` | `cargo test` | `go test ./...` |
| 产物目录 | `target/` | `target/` | 无（当前目录/`GOBIN`） |

`cjpm` 的子命令命名和 `cargo` 几乎一一对应（连 `check`/`build`/`run`/`test`/`tree`/`update` 和 `target/` 都一样），会 `cargo` 的可以直接迁移；区别是 `cjpm check` 顺带做了 Go 里 `go mod tidy` 的"拉依赖+写锁"。

## 8. 完整示例运行

上面的两包工程 `041-cjpm-demo`，Linux 下：

```shell
cd examples/cangjie/041-cjpm-demo
cjpm check        # 打印编译顺序 mpdemo.greet -> mpdemo
cjpm run          # 编译并运行
```

预期输出（CI 核对）：

```text
hello, cangjie
add(2, 3) = 5
```

## 9. 常见问题（FAQ）

### Q1: `cjpm` 和 `cjc` 到底谁调用谁？

`cjpm` 在上层：它读 `cjpm.toml`、算依赖顺序，再**多次调用 `cjc`**（文章 35）编每个包、最后链接。单文件玩具用 `cjc` 够了，多包/有依赖就交给 `cjpm`。

### Q2: 改了 `cjpm.toml` 里依赖版本，没生效？

要 `cjpm update` 重新解析并刷新 `cjpm.lock`；锁文件没更新，`build` 仍按旧锁拉版本。

### Q3: `cjpm check` 报找不到包 / import 不对？

检查**包路径**：`src/` 下某目录的包，其 `package` 声明必须是 `<模块名>.<该相对路径>`（示例里 `src/greet/` → `package mpdemo.greet`）。模块名取自 `cjpm.toml` 的 `name`。

### Q4: 产物叫啥、在哪？

`output-type=executable` 时，`cjpm build` 产物默认 `target/release/bin/main`（`-g` 则 `target/debug/`）；`cjpm run` 就是跑它。要多产物/改名，看 `cjpm run --name`。

### Q5: 本地 `cjpm build` 在 macOS 报一堆 `undefined symbol`？

那是本机 SDK 与 `lld` 的链接兼容问题（文章 35 第 6 节），**不是你的代码错**。用 `cjpm check` 在本地验依赖/语法，运行交给 Linux CI。

### Q6: workspace 是干嘛的？

`cjpm init --workspace` 建一个"多模块工作区"，用一个顶层 `cjpm.toml` 管理多个子模块（类似 cargo workspace），`build`/`test` 时用 `-m <成员>` 指定子模块。日常单模块用不上。

## 10. 总结

1. **`cjpm` = 模块级构建+包管理**，底层按拓扑序调 `cjc`；子命令 `init/check/update/tree/build/run/test/bench/clean/install/uninstall`（**1.0.5 无 `fetch`**）。
2. **`cjpm init`** 生成 `cjpm.toml` + `src/main.cj`；`--type=executable|static|dynamic` 定 `output-type`。
3. **`cjpm.toml`** 的 `[package]` 管元信息 + `compile-option`/`link-option`（转成 `cjc` 参数）；`name` 是**包路径前缀**。
4. **依赖**：同模块多包直接 `import <模块名>.<子包>`，`cjpm check` 自动排编译顺序；外部依赖写 `[dependencies]`/`[macro-dependencies]`，钉进 `cjpm.lock`（要提交）。
5. **构建/运行**：`cjpm build`（`-i` 增量、`-j` 并行、`-g` debug）→ `target/release/bin/main`；`cjpm run` 一把梭。macOS 链接坑、以 Linux CI 为准。

## 参考资料

1. cjpm 介绍（开发指南）：https://docs.cangjie-lang.cn/cjnative/user_manual/source_zh_cn/Compile-And-Build/cjpm_usage_OHOS.html
2. 包管理工具手册（cjpm 全量子命令/字段）：https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/tools/cjpm_manual_cjnative_community.html
3. cjc 编译选项（cjpm.toml 里 compile-option 转成的参数）：https://docs.cangjie-lang.cn/cjnative/user_manual/source_zh_cn/Appendix/compile_options.html
4. 上一篇：cjc 编译器（articles/35-cjc-compiler.md）

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写（`Cangjie Package Manager: 1.0.5`）。工具链类文档官方仅以 `/cjnative/`（latest）路径发布，无 `/docs/1.0.5/` 版本化存档。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
