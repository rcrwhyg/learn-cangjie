# 仓颉跨语言项目实战：C 互操作的 ABI、资源所有权与构建链接

> **摘要**: 文章 29 是"仓颉-C 互操作的**语法课**"（`foreign`/`@C`/`CString`/`CPointer`/`inout`）。本篇是"**工程课**"——把 C 互操作用进真项目，回答三件 29 没展开的事：**① ABI 与内存布局**（`@C struct` 怎么和 C 结构体逐字节对齐、`sizeOf` 验证、标量宽度 `IntNative`/`UIntNative` 对应 C 的 `size_t`/`intptr`）；**② 资源所有权配对**（`mallocCString`↔`free`、谁分配谁释放、跨界内存不受 GC 管）；**③ 构建与链接**（跑通只需 libc 自动链接；链**自定义 C 库**时 `-L`/`-l`/`--import-path`、动态库的 `LD_LIBRARY_PATH`/rpath——承文章 35 的链接参数）。示例 `053-cross-language.cj` 只用 libc 符号（`strlen`/`atoi`），与其它示例一样 **CI 直编直跑**。**诚实边界见文末**：把"仓颉函数指针交给 C 回调"（如 `qsort`）所需的 C 函数指针类型，本 1.0.5 环境未能在不臆造前提下确认，故未纳入示例。

## 前置知识

- 已完成《仓颉-C 互操作》（29）——本篇假定你已会 `foreign`/`@C`/`unsafe` 的基本写法，只谈工程维度
- 已完成《资源管理》（21）——`Resource`/`try-with-resources`；本篇把"手动 free"与之对照
- 已完成《cjc 编译器》（35）——`-L`/`-l`/`--import-path`/`LD_LIBRARY_PATH`/`--set-runtime-rpath` 等链接运行时参数，本篇直接复用

> 定位：阶段五第四篇实战。29 教你"怎么写一个 foreign 调用"，51 教你"怎么在一个项目里正确地、可维护地跨语言"。

## 1. ABI 第一课：`@C struct` 的内存布局必须和 C 一致

跨语言的根，是**两边对同一段内存的字节解释一致**。`@C` 修饰的仓颉 struct 走 C 的布局规则（成员按声明顺序、C 的对齐填充），不是仓颉普通 struct 的布局：

```cangjie
@C
struct Vec2 {
    var x: Int64 = 0
    var y: Int64 = 0
    init(x: Int64, y: Int64) { this.x = x; this.y = y }
}
// sizeOf<Vec2>() == 16  ← 两个 8 字节 Int64，与 C 的 struct{int64_t x,y;} 完全对齐
```

`@C struct` 的约束（承 29）：成员类型都得是 **CType**（`Int8..Int64`/`UInt*`/`Float*`/`Bool`/裸指针/`@C enum`/定长数组），不能塞 `String`、`class`、`Option`、闭包——那些是仓颉托管对象、没有 C 布局。这也是文章 41 说的"struct 不进子类型格 / 值类型"在这里成了**优点**：`@C struct` 是纯值、可按字节 memcpy 过界。

> **验证布局**：用 `sizeOf<T>()` 对齐 C 侧 `sizeof(struct ...)`。两边不等就是 ABI 出错（对齐/填充/字段序），传过去会读脏——这是跨语言 bug 的头号来源。

## 2. 标量宽度：`IntNative`/`UIntNative` 对齐 C 的 `size_t`/`intptr_t`

C 的 `size_t`（`strlen` 返回）在 64 位平台是 64 位、32 位平台 32 位。仓颉用**平台字长**类型接它：

```cangjie
foreign func strlen(s: CString): UIntNative    // UIntNative = C 的 size_t（平台字长）
foreign func atoi(s: CString): Int32           // atoi 返回 int → 固定 Int32，别用 Int64
```

对应关系（承 29 的表）：C `int`↔`Int32`、`long`(Linux)↔`Int64`/`IntNative`、`size_t`↔`UIntNative`、指针↔`CPointer`。**把 C 的 `int` 声明成仓颉 `Int64`**（默认字面量类型）是隐蔽 ABI bug——`atoi` 明明返回 32 位，你按 64 位读会串位。本篇示例特意让 `atoi: Int32`、`strlen: UIntNative`，就是在示范这个纪律。

## 3. 资源所有权：跨界内存不归 GC 管

仓颉的堆由 GC 管；**但 `LibC.malloc`/`mallocCString` 拿来的 C 堆内存，GC 完全不认**，必须手动 `free`，且**谁分配谁释放、成对出现**（否则要么泄漏、要么双重释放）：

```cangjie
let cs = unsafe { LibC.mallocCString("  42abc") }   // 分配 + 拷入 UTF-8
let num = unsafe { atoi(cs) }
let len = unsafe { strlen(cs) }
unsafe { LibC.free(cs) }                            // 用完立刻 free，紧贴分配的作用域
```

> **⚠️ 悬垂指针（dangling）**：`free` 之后 `cs` 仍持有那块地址，再用它就是 UB。规则：`free` 后让该指针离开作用域/置空，绝不再 `unsafe` 解引用。若一段 C 内存要活很久、多处用，考虑**包进一个实现 `Resource` 的仓颉对象**，用 `try-with-resources`（21）在作用域结束自动 `free`——把"手动配对"降级成"作用域保证"，是跨语言项目防泄漏的正解。

`inout`（把仓颉变量地址临时借给 C 函数就地改）则不同：那块内存**仍是仓颉托管的**，C 只是借用地址，函数返回即归还，无需也不该 free：

```cangjie
var v = Vec2(3, 4)
unsafe { scale(inout v) }   // scale 是 @C 函数，就地改 v；不分配、不 free
```

## 4. 让 C 侧能调仓颉：`@C` 导出

反向（C 调仓颉）用 `@C` 标注仓颉函数，它按 C 调用约定导出符号、形参/返回用 CType。示例里的 `scale` 既是仓颉能 `inout` 调的函数，也是"若链进 C 程序、C 能回调的那个函数"：

```cangjie
@C
func scale(p: CPointer<Vec2>): Unit {
    let v = unsafe { p.read() }
    unsafe { p.write(Vec2(v.x * 2, v.y * 3)) }
}
```

把整个仓颉模块编成动态库（`cjpm` 的 `output-type = "dynamic"`，或 `cjc --output-type dylib`，承 35/36）后，C 程序就能 `-l你的库` 链接并调用这些 `@C` 符号。

## 5. 构建与链接：本项目 vs 真链 C 库

**本示例**只用 `strlen`/`atoi`——它们是 **libc 符号，`cjc` 自动链接**（和 29 一样），所以 `cjc 053... -o x && ./x` 即可、CI 零额外配置。

**真项目**里链一个自定义 C 库（承文章 35 的链接参数）：

```shell
# 假设有编译好的 libfoo.so / libfoo.a 在 ./c/lib
cjc main.cj -L ./c/lib -l foo -o app            # -L 搜索目录、-l 链接 libfoo.{a,so}
# 若链的是 .so（动态），运行时要能找到它：
LD_LIBRARY_PATH=./c/lib:$LD_LIBRARY_PATH ./app  # 或编译期 --set-runtime-rpath / -Wl,-rpath
```

cjpm 工程里，这些走 `cjpm.toml` 的 `link-option`（`-l`）/`compile-option`（`-L`）或 `[target...bin-dependencies]`（36）。仓颉模块被别处当库用时，还要 `--import-path`/`CANGJIE_PATH` 找 `.cjo`（35/36）。**动态 C 库的"构建能过、运行找不到"是最高频坑**——正是文章 35 §4–5 那套 `LD_LIBRARY_PATH`/rpath 的用武之地。

## 6. 完整示例（libc-only，CI 可直跑）

`053-cross-language.cj`：`atoi`/`strlen` 过界 + `@C struct` 就地改 + `malloc/free` 配对 + `sizeOf` 验布局：

<!-- example: cangjie/053-cross-language.cj -->
```cangjie
package xlang

// 跨语言项目实战（配合文章 51）。文章 29 讲"foreign/@C/CString 的 API 怎么写"；
// 本篇把 C 互操作落到"工程视角"：ABI 布局、内存与资源的所有权配对、构建期如何链自定义 C 库。
// 运行只用 libc 自动链接的符号（strlen/atoi），无需自定义 .c 或 -l，故与其它示例一样可被 CI 直编直跑。
// 诚实说明：把"仓颉函数指针交给 C 回调"（如 qsort）所需的 C 函数指针类型写法，本 1.0.5 环境未能
// 在不臆造前提下确认，故示例不使用它，改在正文 §5 以"已验证的 @C 导出方向 + 构建链接"承担项目主题。

// —— foreign 声明：只有签名、无实现；libc 符号自动链接 ——
foreign func strlen(s: CString): UIntNative     // C: size_t strlen(const char*)
foreign func atoi(s: CString): Int32            // C: int atoi(const char*)

// —— @C struct：与 C 结构体逐字节兼容的内存布局；成员须满足 CType ——
@C
struct Vec2 {
    var x: Int64 = 0
    var y: Int64 = 0
    init(x: Int64, y: Int64) { this.x = x; this.y = y }
}

// —— @C 导出函数：可作为 C 侧回调/入口；形参用 CPointer，读写要 unsafe ——
@C
func scale(p: CPointer<Vec2>): Unit {
    let v = unsafe { p.read() }
    unsafe { p.write(Vec2(v.x * 2, v.y * 3)) }
}

main(): Int64 {
    // 1) 字符串跨界的资源配对：malloc 出来的 CString 必须 free（承 29、资源管理 21）
    let cs = unsafe { LibC.mallocCString("  42abc") }
    let num = unsafe { atoi(cs) }          // C 语义：跳过前导空白、取 42、遇 'a' 停
    let len = unsafe { strlen(cs) }        // "  42abc" 共 7 字节
    unsafe { LibC.free(cs) }               // 谁 malloc 谁 free，成对出现
    println("atoi=${num} strlen=${len}")   // atoi=42 strlen=7

    // 2) 结构体按引用过界：inout 把仓颉变量的地址交给 @C 函数，就地改
    var v = Vec2(3, 4)
    unsafe { scale(inout v) }              // x*2=6, y*3=12
    println("scaled=(${v.x},${v.y}) sizeOf=${sizeOf<Vec2>()}")   // scaled=(6,12) sizeOf=16
    return 0
}
```

编译并运行（Linux）：

```shell
cjc 053-cross-language.cj -o x && ./x
```

预期输出：

```text
atoi=42 strlen=7
scaled=(6,12) sizeOf=16
```

（`atoi("  42abc")` 按 C 语义跳空白、取 `42`、遇 `a` 停；`scale` 把 `(3,4)`→`(6,12)`；`sizeOf<Vec2>=16` 印证两个 `Int64` 的 C 布局。）

## 7. 与其它语言 FFI 对照

| 维度 | 仓颉 | Rust `extern "C"` | Go `cgo` |
|---|---|---|---|
| 声明外部 | `foreign func f(..): T` | `extern "C" { fn f(..)->T }` | `//go:import "C"` + 注释里 C 原型 |
| 导出给 C | `@C func` | `#[no_mangle] pub extern "C"` | `//export Name` |
| C 结构布局 | `@C struct` | `#[repr(C)] struct` | C 生成 Go 结构 |
| 裸指针 | `CPointer<T>` + `unsafe read/write` | `*const/*mut` + `unsafe` | `unsafe.Pointer` |
| 字符串 | `CString`（malloc/free 手动） | `CString::new`（Drop 自动） | `C.CString`（手动 `C.free`） |
| 自动内存 | ❌ C 侧靠手动/包 `Resource` | Drop/RAII | ❌ 手动 |
| 链接外库 | `-L`/`-l` | `build.rs`+`cargo:rustc-link-lib` | cgo `LDFLAGS` |

心智：仓颉最像 **Rust 的显式 unsafe + 手写 `#[repr(C)]`**，但**没有 Drop 自动释放 C 内存**，所以 `malloc/free` 配对要自己保证（或包 `Resource`）。`CString::new` 那种"离开作用域自动 free"在仓颉里要靠 `try-with-resources` 自己造。

## 8. FAQ

### Q1: `@C struct` 和 `struct` 区别？

`@C struct` 按 **C ABI** 排内存（跨语言字节兼容）、成员限 CType；普通 `struct` 是仓颉自己的值类型、布局不保证与 C 一致。跨界一律 `@C struct`。

### Q2: 为什么 `atoi` 返回写 `Int32` 不是 `Int64`？

C 的 `int` 是 32 位；仓颉整数字面量默认 `Int64`，但 FFI 签名必须**按 C 的真实宽度**写。写成 `Int64` 会读多 4 字节、串位。`size_t`→`UIntNative`、`int`→`Int32`（§2）。

### Q3: `LibC.mallocCString` 出来的要自己 free 吗？GC 管不到？

要自己 `free`。那是 **libc 堆**、GC 不认。`mallocCString`↔`free` 成对（§3）。想要自动，就包进一个 `Resource` 对象用 `try-with-resources`（21）。

### Q4: `inout v` 传给 @C 函数，需要 free 吗？

不需要。`inout` 是把**仓颉托管变量 `v` 的地址**临时借给 C 就地改，内存所有权没交给 C、返回即归位。别 free（会崩）。（区别于 `mallocCString`——那是 malloc 出来的 C 内存。）

### Q5: 怎么把仓颉函数当回调传给 C（如 `qsort`）？

**本 1.0.5 环境未能安全验证**该写法：`qsort` 要一个 C 函数指针参数，而 `CFunctionPointer<...>` / `func<...>` 之类的类型在本机 `cjc` 下都解析失败，官方 API 参考此刻不可达——按"不臆造未验证 API"的纪律，本篇**不写具体签名**。方向是对的（`@C` 导出函数 + 以 C 函数指针传参），具体类型请查 1.0.5《C 互操作》原文/库 API 确认后再用。

### Q6: 链了 `libfoo.so`，编译过了、运行报找不到？

动态库运行期搜索问题（§5）。`LD_LIBRARY_PATH` 指到 `.so` 目录，或编译期 `--set-runtime-rpath`/`-Wl,-rpath` 写死进产物。见文章 35/40。

## 9. 总结

1. **ABI**：`@C struct` 保证与 C 逐字节兼容（成员限 CType），`sizeOf` 验布局；标量按 C 真实宽度声明（`Int32`≠`Int64`、`size_t`=`UIntNative`）。
2. **资源**：C 堆（`mallocCString`/`malloc`）不受 GC 管，`malloc`↔`free` 成对、防悬垂；长生命周期就包 `Resource`+`try-with-resources`（21）。`inout` 借用不 free。
3. **导出**：`@C func` 按 C 约定导出、可被 C 回调；模块编成 `dylib` 供 C 链接。
4. **构建**：libc 符号自动链接（本示例/29 零配置）；自定义 C 库走 `-L`/`-l`，动态库运行期 `LD_LIBRARY_PATH`/rpath（35/40）。
5. **纪律**：C 回调所需的函数指针类型本文未实测、不臆造（§8 Q5）——延续全系列"没在 CI 验过就不硬写"。

## 参考资料

1. 仓颉-C 互操作（29 的 API 基础）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/FFI/cangjie-c.html
2. cjc 链接与运行时参数（`-L`/`-l`/`--import-path`/rpath）：https://docs.cangjie-lang.cn/cjnative/user_manual/source_zh_cn/Appendix/compile_options.html
3. 资源管理（`Resource`/`try-with-resources`）：articles/21-resource-management.md ｜ C 互操作 API 教程：articles/29-c-interop.md
4. 运行时环境变量：https://docs.cangjie-lang.cn/cjnative/user_manual/source_zh_cn/Appendix/runtime_env.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写。`foreign`/`@C struct`/`CPointer` 读写/`inout`/`sizeOf`/`mallocCString`↔`free`/libc 符号(`strlen`/`atoi`)自动链接 均本地 `cjc` 实测；示例 053 输出 `atoi=42 strlen=7` / `scaled=(6,12) sizeOf=16` 由 Linux CI 核对。**C 回调函数指针类型（qsort 场景）本环境未能安全验证，故不写入示例**，仅在 FAQ 点明方向与查证路径。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
