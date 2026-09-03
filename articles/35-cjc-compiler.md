# 仓颉编译器 cjc：编译流程、产物、参数、诊断与链接

> **摘要**: 前面 30 多篇一直在"敲 `cjc` 把代码编出来"，本篇把这台工具本身讲透：`cjc` 的**编译流程**（`cjc-frontend` 前端 → LLVM IR → 后端 → 链接）、**四种产物**（`exe`/`staticlib`/`dylib` 与默认输出文件名）、**常用参数**（优化级别、`-g`、`--int-overflow`、警告开关、`--import-path`）、**诊断格式**（default/noColor/**json**，含真实 JSON 结构）、**链接与运行时配置**（静态/动态链接 std、`-l`/`-L`、四个环境变量）、以及**交叉编译**（`--target` triple + `--sysroot`）。所有命令与产物名均在 1.0.5 SDK 本地实测；运行输出在 Linux CI 核对。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK 并 `source envsetup.sh`（文章 2 的环境）
- 写过并编译过 `main.cj`（文章 6 起）
- 了解"编译前端/后端、静态库/动态库、符号链接"等基础概念

> 定位：这是阶段四"工具链"的第一篇。`cjpm`（包管理）已在文章 15、32 用过，本篇专讲它底层调用的 `cjc`。

## 1. cjc 是什么、编译流程怎么走

`cjc` 是仓颉的**编译驱动命令**（`cangjie compile` 的缩写），使用方式：

```shell
cjc [option] file...
```

一条 `cjc hello.cj` 背后，其实串起了**前端 → 中端 → 后端 → 链接**四个阶段：

```
hello.cj
  │  cjc-frontend（前端）：词法/语法/语义检查 → 生成仓颉中间表示 CHIR → LLVM IR
  ▼
hello.bc / .o（目标码）
  │  后端：基于 LLVM 生成平台机器码（cjnative 后端，产出本地 .o）
  ▼
  │  链接：ld.lld / ld64.lld 把 .o + 仓颉运行时 + 标准库链成产物
  ▼
main（可执行文件）/ libxxx.a / libxxx.so
```

- **`cjc-frontend`** 是随 SDK 一起提供的**前端编译器**，它只把源码编译到 **LLVM IR** 就停止，不做后端和链接。仓颉把 `.cj → LLVM IR` 这一步单独封装成前端实体，主要供编译器开发者调试；**普通开发一律用 `cjc`**（它会自动把前端、后端、链接全跑完）。
- 前端和 `cjc` **共享大部分编译选项**（文档里带 `[frontend]` 上标的就是两者通用的）。
- 想看每一步真正执行的命令，加 `--verbose`（`-V`），`cjc` 会打印编译器版本、工具链依赖、以及它调用 `cjc-frontend`/`ld` 的完整命令行——排查"到底链接了哪个库"最有用。

> **⚠️ 平台小坑（macOS M1）**：官方文档明确提示——在 macOS M1 上 `cjc` 可能因 CPU 利用率波动出现**编译性能抖动**，重启或静置可缓解。这也是本系列把**运行输出交给 Linux CI 核对**的原因之一：本地 macOS 有时连可执行文件都**链接不动**（见第 6 节），但**前端 + 编译到 `.o`/`.a`** 始终可跑，足以验证语法与 API。

## 2. 产物类型与默认输出名

`--output-type` 决定 `cjc` 编出什么（**默认 `exe`**）：

| `--output-type` | 产物 | 默认文件名（单文件 `tool.cj`） | 用途 |
|---|---|---|---|
| `exe`（默认） | 可执行文件 | **`main`** | 直接运行 |
| `staticlib` | 静态库 | `libtool.a` | 参与其它程序的链接 |
| `dylib` | 动态库 | `libtool.so` / `.dylib` / `.dll` | 运行时加载（跨语言/插件） |

> 动态库扩展名随平台：Linux `.so`、macOS `.dylib`、Windows `.dll`；静态库统一 `.a`（Windows 也有对应库格式）。**文件基础名默认取 `main`（exe）或 `lib<输入名>`（库）**，可用 `-o` 改。

```shell
cjc hello.cj                            # → 生成可执行文件 main
cjc hello.cj -o a.out                   # → 指定产物名 a.out
cjc hello.cj --output-type=staticlib    # → libhello.a
cjc hello.cj --output-type=dylib        # → libhello.so(Linux)/libhello.dylib(macOS)
```

**整包编译 + 分步链接**（`--package`/`-p`）：把一个包的源码编成静态库，再用它链接主程序——这是 `cjpm` 底层做的事：

```shell
cjc -p log --output-type=staticlib      # 把 log 包编成 liblog.a
cjc main.cj liblog.a                    # main.cj 与 liblog.a 一起链成可执行文件 main
```

> **💡 中间文件**：`cjc` 编译过程中会产生 `.bc`（LLVM IR）、`.o`（目标码）、`.cjo`（包导出 AST）等中间文件，默认放在临时目录并清理。想保留下来研究，用 `--save-temps <dir>`；想统一输出目录，用 `--output-dir <dir>`（此时 `-o` 必须是**相对路径**）。

## 3. 常用参数速查

`cjc --help` 有上百个选项，日常高频的就这些：

| 参数 | 作用 | 备注 |
|---|---|---|
| `-O0` / `-O`（=O1）/ `-O1` / `-O2` / `-Os` / `-Oz` | 代码优化级别 | **默认 `-O0`**；`-O2` 额外开常量传播/内联/去虚化；`-Os`/`-Oz` 体积优先 |
| `-g` | 生成调试信息 | **只能配 `-O0`**，否则调试异常 |
| `--int-overflow=<throwing\|wrapping\|saturating>` | 定点整数溢出策略 | **默认 `throwing`**（溢出抛异常）；`wrapping` 回绕；`saturating` 取极值 |
| `--lto=<full\|thin>` | 链接时优化 | **macOS/Windows 不支持**；不能对 `dylib` 用；不能与 `-Os`/`-Oz` 并用 |
| `-Woff <组别\|all>` / `-Won ...` | 关/开警告 | **顺序敏感**，后设的覆盖先设的（见第 4 节） |
| `--error-count-limit <N\|all>` | 最多打印几个错误 | 默认 **8** |
| `--import-path <dir>` | 导入模块 AST（`.cjo`）搜索路径 | 等价 `CANGJIE_PATH` 环境变量，且优先级更高 |
| `-l <name>` / `-L <dir>` | 链接库 / 库搜索目录 | 给 C 库、`.a`/`.so` 用（见第 5 节） |
| `--strip-all`（`-s`） | 剥离符号表 | 减小 exe/dylib 体积 |
| `-j <N>` | 并行编译最大并行数 | `--jobs 1` = 强制串行 |
| `--target=<triple>` | 交叉编译目标平台 | 见第 7 节 |
| `--version` / `--help` / `-V` | 版本 / 选项 / 详细过程 | 这三者不编译任何输入文件 |

> **⚠️ 长/短选项写法**：`--xxxx=<value>` 与 `--xxxx <value>` 等价；短选项 `-o a.out` 与 `-oa.out` 等价。

## 4. 诊断信息：default / noColor / json

`--diagnostic-format` 控制错误/警告怎么打（默认 `default`，**带颜色**；Windows 版不支持彩色）：

```shell
cjc --diagnostic-format=noColor bad.cj   # 纯文本、无颜色（适合贴日志/CI）
cjc --diagnostic-format=json bad.cj       # 机器可读 JSON（工具/IDE 解析用）
```

对一个"把字符串赋给 `Int64`"的错误文件，`cjc` 报的错误文本是（实测）：

```text
error: mismatched types
  |                    ^^^^^^^^^^^^ expected 'Int64', found 'Struct-String'
```

切到 `json` 格式，同一错误的结构是这样的（字段名首字母大写，实测）：

```json
{
  "Diags": [
    {
      "DiagKind": "sema_mismatched_types",
      "Severity": "error",
      "DiagCategory": "sema",
      "Message": "mismatched types",
      "Location": { "File": "bad.cj", "Line": 2, "Column": 20 },
      "MainHint": { "Content": "expected 'Int64', found 'Struct-String'" }
    }
  ]
}
```

**警告按组别开关**（`-Woff`/`-Won`）。每个警告结尾都有一行 `#note` 告诉你它属于哪个组、怎么关。比如"未使用变量/函数"属于 `unused` 组：

```shell
cjc --output-type=staticlib -Woff unused demo.cj -o demo   # 屏蔽所有 unused 警告
cjc -Woff all -Won deprecate demo.cj                        # 只保留"弃用"警告
```

> **⚠️ 顺序敏感**：`-Woff all -Won X` = "只开 X"；写成 `-Won X -Woff all` = "全关"——后一条覆盖了前一条。本系列 CI 编译大量示例时看到满屏 `unused variable/main` 警告，就是 `unused` 组没关；它们是**警告不是错误**，不影响产物。

## 5. 链接与运行时配置

**链接标准库的方式**（仅对 exe/dylib 生效，默认**全部静态链接**）：

| 参数 | 含义 |
|---|---|
| `--static-std` / `--dy-std` | 静态 / 动态 链接 `std` 模块 |
| `--static-libs` / `--dy-libs` | 静态 / 动态 链接 std 之外的其它仓颉模块 |

叠加时**最后一条生效**；`--dy-std` 与 `--static-libs`、`--static-std` 与 `--dy-libs` 互斥（同时用会报错）。

**链接外部（C）库**：`-l` 指定库名（找 `lib<name>.a`/`.so`）、`-L` 指定搜索目录。官方给的 C 交互例子——把 `libcProg.so` 链进来：

```shell
cjc main.cj -L . -l cProg        # 生成可执行文件 main
LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH ./main   # 运行时能加载 libcProg.so
```

**四个和 `cjc` / 运行相关的环境变量**：

| 环境变量 | 何时起作用 | 说明 |
|---|---|---|
| `CANGJIE_HOME` | 编译/运行 | SDK 根目录（`envsetup.sh` 会设） |
| `CANGJIE_PATH` | 编译 | 导入模块 `.cjo` 的搜索路径；`--import-path` 可覆盖它且优先级更高 |
| `LIBRARY_PATH` | 链接期 | 链接器额外搜索目录；`-L` 优先级更高 |
| `LD_LIBRARY_PATH` | **运行期**（Linux） | 动态链接器找 `.so`；产物**动态**链接了运行时/std 时必须设对 |

> **💡 为什么 CI 里要设 `LD_LIBRARY_PATH`**：`cjc` 默认把 std **静态**链进产物，运行不依赖外部 `.so`；但 `cjpm` 的宏库、或加了 `--dy-std` 的产物会**动态**依赖 `libcangjie-runtime.so` 等——运行时若找不到就报 "cannot open shared object file"。本项目的 `.github/workflows/code-examples-test.yml` 正是把 `.../runtime/lib/linux_x86_64_cjnative` 加进 `LD_LIBRARY_PATH` 才跑通。**`--set-runtime-rpath`** 可把运行时目录写进产物的 rpath，免去每次设环境变量（部署友好）。

## 6. 本地 macOS vs CI Linux（诚实说明）

本篇配套的 `040-cjc-compile.cj` 在本地 macOS 用 `--output-type=staticlib` **能编过**（验证语法与选项被接受），但 `cjc 040... -o exe`（生成可执行文件）在本机 macOS 上会卡在链接：

```text
ld64.lld: error: ...MacOSX26.5.sdk/.../libSystem.tbd is incompatible with arm64 (macOS)
```

这是**本机 macOS SDK 与 SDK 自带 lld 的链接兼容问题**，与仓颉代码无关——**Linux CI 上同一份源码链接、运行都正常**，本系列的运行输出一律以 Linux CI 为准（见第 8 节"预期输出"）。

## 7. 交叉编译：--target

`--target=<triple>` 指定目标平台，triple 格式：`<arch>(-<vendor>)-<os>(-<env>)`，例如 `aarch64-unknown-linux-gnu`、`x86_64-linux-gnu`：

- `<arch>`：`x86_64`、`aarch64` …
- `<os>`：`Linux`、`Win32`、`darwin` …
- `<env>`：`gnu`、`musl`、`ohos` …（同 OS 细分 ABI）

交叉编译前要准备好**目标平台的工具链**和**能在本机运行、面向该目标的 Cangjie SDK**。指向一个目录结构规整的工具链时，一条 `--sysroot` 就够（自动找 bin/lib）：

```shell
cjc --target=arch-os-env --sysroot /usr/sdk/arch-os-env hello.cj -o hello
# 等价手动指定：
cjc --target=arch-os-env -B/usr/sdk/arch-os-env/bin -B/usr/sdk/arch-os-env/lib \
    -L/usr/sdk/arch-os-env/lib hello.cj -o hello
```

`--target-cpu`（需 `--experimental`）进一步针对具体 CPU 生成扩展指令，代价是可能失去可移植性。

## 8. 完整示例（被各种 cjc 选项编译的同一份源码）

下面这份 `040-cjc-compile.cj` 故意**不含整数溢出、结果与优化级别无关**——所以无论用什么选项编，运行输出恒定，正好用来对照"编译器变了、程序语义不变"：

<!-- example: cangjie/040-cjc-compile.cj -->
```cangjie
// 《cjc 编译器》配套示例：一个"被各种 cjc 选项反复编译"的最小确定性程序。
// 正文用它演示 cjc 的默认产物名、--output-type、-O 优化级别、诊断格式、链接与运行时配置等。
// 关键点：本程序不含任何整数溢出（默认 --int-overflow=throwing 下也安全），
// 且结果与优化级别无关——无论 -O0 / -O2，输出恒定，方便和编译器行为对照。
main(): Int64 {
    // 1) 定点整数求和：1..=10 -> 55（不溢出）
    var sum = 0
    for (i in 1..=10) {
        sum += i
    }
    println("sum(1..=10) = ${sum}")     // sum(1..=10) = 55

    // 2) 简单乘法：优化级别不同结果不变
    let product = 6 * 7
    println("6 * 7 = ${product}")       // 6 * 7 = 42

    // 3) 收尾标记，确认"编译产物能跑起来"
    println("cjc demo ok")              // cjc demo ok
    return 0
}
```

编译并运行（Linux）：

```shell
cjc 040-cjc-compile.cj -o demo && ./demo        # 默认 exe：产物名是 demo，-O0
cjc 040-cjc-compile.cj -o demo -O2 && ./demo    # -O2 优化，输出不变
```

预期输出（三种编法都一样）：

```text
sum(1..=10) = 55
6 * 7 = 42
cjc demo ok
```

## 9. 与其它语言编译器对照

| 维度 | 仓颉 `cjc` | Rust `rustc` | Go `go build` | C/C++ `clang` |
|---|---|---|---|---|
| 前端产物 | LLVM IR | LLVM IR | SSA | LLVM IR |
| 默认可执行名 | `main` | 输出 `.exe`/裸名 | `<包名>` | `a.out` |
| 静态库 | `.a`（`staticlib`） | `.rlib` | `.a` | `.a` |
| 动态库 | `dylib`→`.so` | `.so`/`cdylib` | 插件 | `.so` |
| 优化 | `-O0/-O1/-O2/-Os/-Oz` | `-O0..-O3` | 无级别开关 | `-O0..-O3/-Os` |
| 整数溢出默认 | **抛异常**（`throwing`） | Debug 检查/Release 回绕 | 回绕 | UB |
| 链接第三方库 | `-l`/`-L` | `#[link]`/`-l` | cgo | `-l`/`-L` |
| LTO | `--lto=full/thin` | `-Clinker-plugin-lto` | 自动 | `-flto` |

**最值得一提的是整数溢出默认**：`cjc` 默认 `throwing`，比 C/C++ 的"未定义行为"、Go/Rust-release 的"默默回绕"更安全，代价是溢出检查的运行时开销——性能敏感处可用 `--int-overflow=wrapping` 显式切换。

## 10. 常见问题（FAQ）

### Q1: `cjc` 和 `cjpm` 什么时候用哪个？

单文件/少量文件、想手搓编译链接命令 → `cjc`；有 `cjpm.toml`、多包依赖、要 `build/run/test/add-dep` → `cjpm`（它本质是帮你按正确顺序调用 `cjc` + 管依赖）。文章 15/32 已用过 `cjpm`。

### Q2: 为什么我 `cjc hello.cj` 出来的文件叫 `main`，不是我文件的名字？

这是设计如此：`exe` 模式**默认产物名固定为 `main`**，要别的名字用 `-o myname`。库模式才用 `lib<输入名>`。

### Q3: `-g` 调试信息为啥不生效？

`-g` 只能配 `-O0`。若同时写了 `-O2`，调试信息会失真——去掉优化级别即可。

### Q4: `--lto` 在 macOS 上编不过？

对——`--lto` **不支持 macOS 和 Windows**，也不支持 `--output-type=dylib`，还不能和 `-Os`/`-Oz` 同用。只能在 Linux 上对 exe/静态库用。

### Q5: 满屏 `warning: unused ...` 会不会导致编译失败？

不会，是警告。要清静：`-Woff unused`（或 `-Woff all`）。见第 4 节。

### Q6: 生成的可执行文件换台机器报"找不到 .so"？

产物若**动态**链接了运行时/std，需要运行时能找到 `libcangjie-runtime.so`：设 `LD_LIBRARY_PATH`，或编译时 `--set-runtime-rpath` 把路径写进产物，或干脆**默认静态链接**（不加 `--dy-std`）。见第 5 节。

### Q7: 溢出到底默认抛不抛？想让它回绕？

默认 `throwing`——溢出抛异常。要"绕回"改 `--int-overflow=wrapping`，要"卡极值"改 `saturating`。这是**编译期**决定、写死进产物的。

## 11. 总结

1. **流程**：`cjc` = 前端(`cjc-frontend`→LLVM IR) + 后端(cjnative 机器码) + 链接(lld)；`-V` 看全过程；普通开发用 `cjc` 不用裸 `cjc-frontend`。
2. **产物**：`--output-type` = `exe`(默认，名 `main`) / `staticlib`(`.a`) / `dylib`(`.so`/`.dylib`/`.dll`)；`-o` 改名；`-p` 整包。
3. **常用参数**：优化 `-O0..-Oz`（默认 O0）、`-g`(须 O0)、`--int-overflow`(默认 throwing)、`--lto`(非 macOS)、`-Woff`、`--import-path`。
4. **诊断**：`--diagnostic-format=json` 给机器读（`Severity`/`Message`/`Location`），`noColor` 给日志；`--error-count-limit` 默认 8。
5. **链接/运行时**：std 默认静态链，`-l`/`-L` 链外库；四个环境变量 `CANGJIE_HOME`/`CANGJIE_PATH`/`LIBRARY_PATH`/`LD_LIBRARY_PATH`；`--set-runtime-rpath` 免设 `LD_LIBRARY_PATH`。
6. **交叉编译**：`--target=<triple>` + `--sysroot`。

## 参考资料

1. cjc 使用（编译流程/基本用法）：https://docs.cangjie-lang.cn/cjnative/user_manual/source_zh_cn/Compile-And-Build/cjc_usage.html
2. cjc 编译选项（全量选项，正文速查表来源）：https://docs.cangjie-lang.cn/cjnative/user_manual/source_zh_cn/Appendix/compile_options.html
3. runtime 环境变量使用手册：https://docs.cangjie-lang.cn/cjnative/user_manual/source_zh_cn/Appendix/runtime_env.html
4. 条件编译（`--cfg`）：https://docs.cangjie-lang.cn/cjnative/user_manual/source_zh_cn/Compile-And-Build/conditional_compilation.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写（`Cangjie Compiler: 1.0.5 (cjnative)`）。注：编译器 user_manual 官方仅以 `/cjnative/`（latest）路径发布，无 `/docs/1.0.5/` 版本化存档，故本篇链接路径与前文 dev-guide 略不同。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
