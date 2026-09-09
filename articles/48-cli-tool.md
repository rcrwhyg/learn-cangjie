# 仓颉命令行工具实战：分层设计、手写参数解析、单元测试与交付

> **摘要**: 阶段五实战首篇——把前 47 篇的语言、标准库、工具链**拧成一个真能交付的 CLI 工具**。以"迷你 `wc`（行数/词数/字符数）"为例，讲透四条工程主线：**① 分层**（纯函数核心 / 参数解析 / IO 入口 / 测试各一文件）、**② 参数解析与错误处理**（本文**手写** while 解析、讲清为什么 1.0.5 这里**不用 `std.argopt`**——其宏 API 与内建 `Option` 撞名、本机 SDK 无法在不臆造前提下确认，这是诚实取舍）、**③ 单元测试**（`cjpm test` 跑纯函数）、**④ 构建/运行/交付**（`cjpm build`/`run`/`install`）。整套是一个 cjpm 工程 `examples/cangjie/050-cli-tool/`，**CI 上 `cjpm build`+`cjpm run`+`cjpm test` 全绿**；核心语义（换行计数、`String.size` 是码点）均实测。

## 前置知识

- 已完成《cjpm》（36）、《单元测试与覆盖率》（38）、《字符串》（13，码点 vs 字节）、《I/O》（25/32）、《异常与 Option》（20）
- 读过阶段四原理篇（41–47）会更顺——本文会用到"值/引用（44）""Option 不解包（42）"的判断

> 本篇是**实战**：不再逐条讲 API，而是"做一个真东西"，遇到 API 细节回指前面的实测篇。

## 1. 选题与分层：CLI 工具的第一决策是"边界"

一个 `wc` 风格的命令行工具，最外行写法是把"读参数、读文件、数数、打印"全糊在 `main` 里。能跑，但**测不了**（测就得真造命令行和文件）。工程做法是先切三层边界：

```text
src/
├── wc.cj        ← 纯函数：countLines/countWords/countChars（输入 String、输出 Int64，无副作用）
├── args.cj      ← 参数解析：Array<String> → ParseResult（无 IO）
├── main.cj      ← 入口：解析→分派→退出码（唯一碰 println/exit 的地方）
└── wc_test.cj   ← 单元测试：直接喂字符串给纯函数（不碰 IO/命令行）
```

**收益**：把"算法"关进纯函数，§6 的 `cjpm test` 就能不依赖真文件、真 argv 地测核心。**"可测性"是分层结构换来的**，不是最后补的。承文章 44：这些核心只吃 `String`/返 `Int64`（值类型），没有堆共享、天然好测。

## 2. cjpm 工程骨架

`cjpm init --name clitool` 起，改 `cjpm.toml` 为 `output-type = "executable"`（承 36）：

```toml
[package]
  cjc-version = "1.0.5"
  name = "clitool"
  description = "命令行工具实战：手写参数解析 + 纯函数核心 + 单元测试"
  version = "0.1.0"
  output-type = "executable"

[dependencies]
```

同模块多文件由 `cjpm` 自动按拓扑编（36 §4），这里全在 `package clitool` 一个包内，直接互相可见、无需 `import`。

## 3. 纯函数核心（wc.cj）

计数逻辑与 IO 完全解耦。**两个坑都已在注释里点明**：换行语义（空串 0 行、否则换行数+1），以及 `String.size` 是**码点**不是字节（承 13）。Rune 比较用 `r'\n'`（`r` 前缀，见 §8 FAQ）。

<!-- example: cangjie/050-cli-tool/src/wc.cj -->
```cangjie
package clitool

// 纯函数核心：把"计数逻辑"和"参数解析/IO"分开——这是命令行工具最重要的结构决策，
// 因为它让核心可被 cjpm test 直接测（见 wc_test.cj），不依赖真去读文件。

// 行数：空串算 0 行，否则 = 换行数 + 1
public func countLines(text: String): Int64 {
    if (text.size == 0) {
        return 0
    }
    var lines: Int64 = 1
    for (r in text.runes()) {
        if (r == r'\n') {
            lines += 1
        }
    }
    return lines
}

// 词数：以空白（空格/换行/制表）为分隔，连续非空白算一词
public func countWords(text: String): Int64 {
    var words: Int64 = 0
    var inWord = false
    for (r in text.runes()) {
        if (r == r' ' || r == r'\n' || r == r'\t' || r == r'\r') {
            inWord = false
        } else {
            if (!inWord) {
                words += 1
                inWord = true
            }
        }
    }
    return words
}

// 字符数：码点数（承文章 13：String.size 是码点、不是字节）
public func countChars(text: String): Int64 {
    return text.size
}
```

## 4. 手写参数解析（args.cj）

**为什么不用 `std.argopt`（诚实取舍）**：argopt 是仓颉官方的声明式参数解析库，本机 SDK 里 `std.argopt` 模块**存在**，但它的字段注解宏（`@Option` 之类）在 1.0.5 上**与内建 `Option<T>` 类型撞名**（实测 `@Option` 报"期望宏定义 'Option'、却发现另一个声明"），且参考文档此刻取不到——**在本项目"不臆造未验证 API"的纪律下**，我选择**手写**朴素解析：逻辑透明、零依赖、跨版本稳，且正好演示"参数解析 + 错误处理"。生产上若 argopt 可用，换成它更省心（见 §8 FAQ）。

解析用一个 `ParseResult` 把三件事一次性带回（帮助请求 / 错误消息 / 配置），避免在 `Option` 上层层嵌套判断。结构体构造走**位置参数**（`Config(verbose, text)`——实测 struct 构造函数命名参数不被接受，见 FAQ）。

<!-- example: cangjie/050-cli-tool/src/args.cj -->
```cangjie
package clitool

// 手写参数解析：演示"参数解析 + 错误处理"。没依赖 std.argopt——它的宏 API
// （@Option 等）在本机 1.0.5 SDK 上与内建 Option 类型撞名、无法在不臆造前提下确认，
// 故用最朴素、最可移植的 while + 分支手写（见文章 48 正文对 argopt 的说明）。

public struct Config {
    public let verbose: Bool
    public let text: String          // 为让 CI 输出确定，把待统计文本作为位置参数直接传入
    public init(verbose: Bool, text: String) {
        this.verbose = verbose
        this.text = text
    }
}

public struct ParseResult {
    public let help: Bool
    public let error: Option<String>
    public let config: Option<Config>
    public init(help: Bool, error: Option<String>, config: Option<Config>) {
        this.help = help
        this.error = error
        this.config = config
    }
}

// 规则：-h/--help 帮助；-v/--verbose 详细；单个位置参数=待统计文本；
// 无位置参数按"帮助"处理（CI 的 cjpm run 不带参数时退出码为 0）。
public func parseArgs(args: Array<String>): ParseResult {
    var verbose = false
    var gotText = false
    var text = ""
    var i = 0
    while (i < args.size) {
        let a = args[i]
        if (a == "-h" || a == "--help") {
            return ParseResult(true, None, None)
        }
        if (a == "-v" || a == "--verbose") {
            verbose = true
        } else if (a.startsWith("-")) {
            return ParseResult(false, Some("unknown option: ${a}"), None)
        } else {
            if (gotText) {
                return ParseResult(false, Some("only one <text> argument expected"), None)
            }
            text = a
            gotText = true
        }
        i += 1
    }
    if (!gotText) {
        return ParseResult(true, None, None)
    }
    return ParseResult(false, None, Some(Config(verbose, text)))
}
```

要点：**无参数当"帮助"处理**——这样 CI 里 `cjpm run`（不带 argv）会打印 usage 并**返回 0**，不会把流水线判红；这是"让示例在 CI 里可复现"的一个小设计。错误路径返回带消息的 `Some(...)`，由入口决定退出码（Unix 惯例：出错非 0）。

## 5. 入口与错误处理（main.cj）

`main(args)` 是**唯一**做 IO 的地方（承 15 的 `main(args)`）。三条出口：帮助→0、错误→1（走 `eprintln` 到 stderr）、成功→0 打印计数。

> **⚠️ 一个 Cangjie 语法坑**：`match` 分支 `=> { ... }`（花括号块）会被解析器当成 **lambda**，导致块里的语句/宏报 `expected '=>' in lambda`。所以多语句逻辑一律**提成函数**（`usage`/`fail`/`run`），分支只写单个表达式或 `return`。测试文件里同理（§6）。

<!-- example: cangjie/050-cli-tool/src/main.cj -->
```cangjie
package clitool

// CLI 入口：只做"解析 → 分派 → 退出码"。多语句逻辑放进各函数，避免 match 分支里写块。

func usage(): Int64 {
    println("usage: clitool [-v] <text>")
    return 0
}

func fail(msg: String): Int64 {
    eprintln("error: ${msg}")
    return 1
}

func run(cfg: Config): Int64 {
    println("lines=${countLines(cfg.text)} words=${countWords(cfg.text)} chars=${countChars(cfg.text)}")
    if (cfg.verbose) {
        println("verbose: text_len=${cfg.text.size}")
    }
    return 0
}

main(args: Array<String>): Int64 {
    let res = parseArgs(args)
    if (res.help) {
        return usage()
    }
    match (res.error) {
        case Some(e) => return fail(e)
        case None => ()
    }
    match (res.config) {
        case Some(cfg) => return run(cfg)
        case None => return 2
    }
}
```

## 6. 单元测试（wc_test.cj）

`_test.cj` 结尾 → `cjpm test` 才编它（38）。直接喂字符串给纯函数断言，**不碰命令行/文件**——这就是 §1 分层的兑现。断言宏 `@Expect` 同样**不写进 match 分支**（先 match 取值、再断言）。

<!-- example: cangjie/050-cli-tool/src/wc_test.cj -->
```cangjie
package clitool

import std.unittest.*
import std.unittest.testmacro.*

// 单元测试：文件名以 _test.cj 结尾 → cjpm test 才编它（承文章 38）。
// 核心纯函数好测——这正是 wc.cj 把计数与 IO 分开的收益。
// 注：@Expect/@Fail 等断言宏不写在 match 分支里（`=> {` 会被当作 lambda），
// 而是先用 match 把值取出、再断言。

@Test
public class WcTests {
    @TestCase
    public func counts() {
        @Expect(countLines("a\nb\nc"), 3)         // 2 个换行 → 3 行
        @Expect(countWords("hello world foo"), 3)
        @Expect(countChars("hi"), 2)
    }

    @TestCase
    public func edges() {
        @Expect(countLines(""), 0)                 // 空串 0 行
        @Expect(countWords("   "), 0)              // 全空白 0 词
        @Expect(countLines("no newline"), 1)       // 无换行仍是 1 行
    }
}

@Test
public class ArgTests {
    @TestCase
    public func ok() {
        let parsed = parseArgs(["-v", "hello world"])
        let cfg = match (parsed.config) {
            case Some(c) => c
            case None => Config(false, "")
        }
        @Expect(cfg.verbose, true)
        @Expect(cfg.text, "hello world")
    }

    @TestCase
    public func unknownOptionIsError() {
        let gotErr = match (parseArgs(["-x"]).error) {
            case Some(_) => true
            case None => false
        }
        @Expect(gotErr, true)
    }

    @TestCase
    public func noArgsMeansHelp() {
        @Expect(parseArgs([]).help, true)          // CI 的 cjpm run（无参）走这里、退出 0
    }
}
```

`cjpm test` 预期：**5 个用例全 PASSED**（WcTests 的 counts/edges + ArgTests 的 ok/unknownOptionIsError/noArgsMeansHelp），承 38 的 `PASSED: 5, FAILED: 0`。

## 7. 构建、运行、交付

```shell
cd examples/cangjie/050-cli-tool
cjpm check                 # 解析依赖 + 校验结构
cjpm build                 # 编译 → target/release/bin/main
cjpm run                   # 无参 → 打印 usage、退出 0（CI 就是这么跑的）
cjpm run --run-args "-v hello world"   # 带参：数 hello world
cjpm test                  # 跑 5 个单测
cjpm build -l              # 顺带 cjlint（39）
cjpm install --root ./bin  # 把可执行装到本地 bin（40）
```

`cjpm run --run-args "-v hello world"` 的输出：

```text
lines=1 words=2 chars=11
verbose: text_len=11
```

（"hello world" 是 1 行、2 词、11 码点。）发布形态承文章 40：可执行用 `cjpm install`、库形态用 `.a`/`.so` + git/path 依赖——1.0.5 **无 `cjpm publish`**。

## 8. 与其它语言 CLI 对照

| 维度 | 本文（仓颉） | Rust `clap` | Go `flag`/`cobra` |
|---|---|---|---|
| 参数解析 | 手写 while（argopt 本机不便用） | 过程宏 derive | 标准库 `flag` |
| 纯核心可测 | ✅ wc.cj 喂字符串 | ✅ | ✅ |
| 测试 | `cjpm test` + `@Test` | `#[test]` | `go test` |
| 构建/运行 | `cjpm build/run` | `cargo build/run` | `go build/run` |
| 装可执行 | `cjpm install` | `cargo install` | `go install` |
| 静态检查 | `cjpm build -l`(cjlint) | `clippy` | `vet` |

分层思路（纯核心 + 薄 IO 壳 + 独立 argv 解析）跨语言通用；仓颉这版**没借第三方解析库**，标准库 + `cjpm` 就够造一个可交付 CLI。

## 9. FAQ

### Q1: 为什么不用 `std.argopt`？它不是官方库吗？

是官方库、本机也在。但 1.0.5 上它的字段宏 `@Option` 与内建 `Option<T>` **撞名**（实测编译错），且 API 参考此刻不可达——按"不臆造未验证 API"的纪律，本文**手写**解析并在正文注明。等 argopt 用法可确认时，换成它会更省心：声明一个带注解的 struct、一个 `parse` 调用即可。

### Q2: struct 构造为什么 `Config(false, "")` 不带字段名？

实测：Cangjie **struct** 构造函数在此 SDK 上按**位置**传参；写成命名参数 `Config(verbose: false, ...)` 报 `invalid named arguments prefix`。`class` 构造（承 12）可命名，`struct` 这里用位置——记一条差异即可。

### Q3: `r'\n'` 前面那个 `r` 是什么？

Rune 字面量前缀。`'\n'`（单引号、无 `r`）在仓颉里是 **String**、拿它和 Rune 比会报 `Rune == Struct-String`；Rune 要写 `r'\n'`、`r' '`、`r'A'`（承 13 的 Rune 字面量）。

### Q4: match 分支里为啥不直接写一段带 println 的块？

`case X => { ... }` 的花括号会被当 **lambda 起始**（`=>` 后紧跟 `{`）。多语句请提成函数（本文 `run`/`fail`/`usage`），或在表达式里用一个 `match` 取值再往下写。断言宏 `@Expect` 放 match 分支里也会撞上同一条解析规则。

### Q5: CI 里 `cjpm run` 不带参数，会不会因为"缺参数"退出非 0、把流水线弄红？

不会——特意把"无参数"设计成"打印 usage + 退出 0"（§4）。真正的缺参/错参在带 argv 调用时才报错走 `eprintln`+非 0。CI 只跑裸 `cjpm run`，故稳定绿。

### Q6: 想真的读文件而不是传字符串？

把 `main` 里"文本来自位置参数"换成 `std.fs` 读文件（承 25/32）即可，纯函数 `countLines` 等**不用动**——这就是分层的价值：IO 换实现、核心与测试不动。为了 CI 输出确定，示例走"字符串入参"。

## 10. 总结

1. **分层**：纯函数核心（`wc.cj`）/ 参数解析（`args.cj`）/ IO 入口（`main.cj`）/ 测试（`_test.cj`）——可测性是结构换来的。
2. **参数解析**：1.0.5 上 `std.argopt` 宏与 `Option` 撞名、本机不可靠 → **手写** while 解析 + `ParseResult` 一次带回，透明可测；诚实标注 argopt 为未来更优解。
3. **语法坑**（实测）：Rune 字面量 `r'\n'`；struct 构造用位置参数；`match` 分支别放花括号块（会当 lambda），多语句提函数。
4. **测试与交付**：`cjpm test` 喂字符串断言纯函数（5 用例）；`cjpm build/run/install/-l` 串成"构建→测→检查→装"闭环（承 36/38/39/40）。
5. **CI 可复现**：无参→usage 退出 0，保证 `cjpm run` 不判红。

## 参考资料

1. cjpm 包管理（init/build/run/test/install）：articles/36-cjpm.md ｜ 手册：https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/tools/cjpm_manual_cjnative_community.html
2. 单元测试（@Test/@TestCase/@Expect、cjpm test）：articles/38-unittest.md
3. 字符串与 Rune（码点、Rune 字面量）：articles/13-strings-and-characters.md
4. 程序入口 `main(args)`（承 15）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/package/entry.html
5. 构建交付（cjpm install、无 publish）：articles/40-debug-perf-build.md

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写。分层/手写解析/Rune 字面量 `r'\n'`/struct 位置构造/match 块解析坑/断言宏不入 match 分支 等均本地 `cjc` 实测；`std.argopt` 在 1.0.5 的宏撞名问题如实记录、故改用标准库手写实现。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
