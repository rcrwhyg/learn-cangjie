# 仓颉-C 互操作

> **摘要**: 为了复用庞大的 C 生态，仓颉支持**双向互操作**：仓颉用 `foreign` + `@C` 声明并调用 C 函数，C 也能通过 `CFunc`（函数指针）回调仓颉函数。所有跨语言调用都必须包在 `unsafe` 块里，参数/返回值要满足 C↔仓颉的**类型映射**（`CString`、`CPointer<T>`、`@C struct`、`VArray`、`CFunc` 等），`inout` 用于把变量地址按引用传给 C，`@CallingConv` 指定调用约定。本文依据仓颉 1.0.5 LTS 官方 FFI 章节，讲清 `foreign`/`@C`/`CFunc`/`inout`/`unsafe`/调用约定/类型映射/`sizeOf`，以及"调用 C 的副作用注意事项"与链接方式，并配一个只用系统 libc、本地与 CI 均可验证的示例。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已完成《指针与内存管理相关基础》（了解裸指针的不安全性）、《class/struct》《函数基础》（变长参数）
- 了解 C 的指针、`struct`、函数指针、调用约定概念

## 1. 双向互操作总览

- **仓颉调用 C**：用 `foreign` 声明 C 函数（可省 `@C`），在 `unsafe` 块里调用。
- **C 调用仓颉**：把仓颉函数（`@C` 修饰）或 `CFunc` 闭包作为函数指针传给 C。

因为 C 侧可能做不安全操作，**所有 FFI 调用点都必须在 `unsafe` 上下文中**。

## 2. 仓颉调用 C 函数

```cangjie
// C 侧:  int rand();  int printf(const char*, ...);
foreign func rand(): Int32
foreign func printf(fmt: CString, ...): Int32

main() {
    let r = unsafe { rand() }
    unsafe {
        var fmt = LibC.mallocCString("Hello, No.%d\n")
        printf(fmt, 1)
        LibC.free(fmt)
    }
}
```

`foreign` 的硬性规则（官方，均影响合法性）：

1. `foreign` 修饰的函数**只能有声明、不能有实现**。
2. 参数/返回类型必须符合 **C↔仓颉类型映射**。
3. 调用 `foreign` 函数必须在 **`unsafe`** 块内，否则编译错误。
4. `@C` 只能修饰 `foreign` 函数、**顶层作用域的非泛型函数**、`struct`——不能修饰 `var`/`class`/`interface`。
5. `foreign` 函数**不支持命名参数与默认值**；**支持变长参数**（`...`，放最后，各实参须满足 `CType`）。
6. 即便仓颉有栈扩容，C 侧实际栈用量仓颉不可感知，进 C 后**仍可能栈溢出**，需按情况调 `cjStackSize`。

```cangjie
foreign func rand(): Int32 { return 0 }   // 错误：foreign 不能有实现
@C foreign var a: Int32 = 0               // 错误：@C 不能修饰变量
@C foreign class A {}                      // 错误：@C 不能修饰 class
```

## 3. `CFunc`：对应 C 函数指针

`CFunc` 是"可被 C 调用的函数"，类型是泛型 `CFunc<(参数) -> 返回>`，对应 C 的函数指针。三种形式：

1. `@C` 修饰的 `foreign` 函数；
2. `@C` 修饰的仓颉函数；
3. 标注为 `CFunc` 类型的 **lambda**（与普通 lambda 不同，**不能捕获变量**）。

```cangjie
foreign func free(ptr: CPointer<Int8>): Unit                 // 形式1
@C func callableInC(ptr: CPointer<Int8>) { ... }             // 形式2
let f1: CFunc<(CPointer<Int8>) -> Unit> = { ptr => ... }     // 形式3（不捕获）

foreign func atexit(cb: CFunc<() -> Unit>): Int32            // CFunc 作参数
```

`CFunc` 同样要求参数/返回满足 `CType`、不支持命名参数/默认值，且在仓颉侧调用也要 `unsafe`。可以把 `CPointer<T>` 强转成 `CFunc` 再调用——但**极危险**（指针若为空/非法会 core dump）。

## 4. `inout`：按引用把变量地址传给 C

对 `CFunc` 调用时，实参加 `inout` 即按引用传递，表达式类型是 `CPointer<T>`（`T` 是被修饰表达式类型）。约束：

- 只能用在 `CFunc` 调用处；
- 被修饰对象类型须满足 `CType`，**但不能是 `CString`**；
- **不能**是 `let` 变量、字面量、入参、临时值；
- 可以来自顶层/局部变量、`struct` 成员，但**不能直接或间接来自 `class` 实例成员**；
- 传过去的指针只在**本次调用期间**有效，C 侧不应保存。

```cangjie
var n: Int64 = 0
unsafe { foo1(inout n) }   // OK：把 n 的地址交给 C 侧
```

## 5. `unsafe`

`unsafe` 可修饰函数、表达式、作用域。需要 `unsafe` 上下文的情形：调用 `@C` 函数、调用 `CFunc`、调用 `foreign` 函数、调用被 `unsafe` 修饰的函数、以及指针读写/偏移等。

> **⚠️ 陷阱**：普通 lambda **无法传递 `unsafe` 属性**——`unsafe` 的 lambda 逃逸后，可能被当普通函数在非 `unsafe` 上下文直接调用而**不报错**。因此要在 lambda 里调 `unsafe` 函数时，把调用整个写进 `unsafe` 块。

## 6. 调用约定 `@CallingConv`

调用方与被调方必须用相同调用约定。仓颉支持：

- `CDECL`：clang 在各平台的默认约定（**不写时即 CDECL**）。
- `STDCALL`：Win32 API 约定。

`@CallingConv` 只能修饰 `foreign` 块、单个 `foreign` 函数、顶层 `CFunc` 函数；修饰 `foreign` 块时对块内每个函数生效。

```cangjie
@CallingConv[CDECL]        // 可省略
foreign func rand(): Int32
```

## 7. 类型映射

### 7.1 基础类型

原则：仓颉侧不含指向托管内存的引用类型；两侧内存布局一致。

| 仓颉 | C | 字节 |
|---|---|---|
| `Unit` | `void` | 0 |
| `Bool` | `bool` | 1 |
| `Int8` | `int8_t` | 1 |
| `UInt8` | `char` / `uint8_t` | 1 |
| `Int16`/`UInt16` | `int16_t`/`uint16_t` | 2 |
| `Int32`/`UInt32` | `int32_t`/`uint32_t` | 4 |
| `Int64`/`UInt64` | `int64_t`/`uint64_t` | 8 |
| `IntNative` | `ssize_t` | 随平台 |
| `UIntNative` | `size_t` | 随平台 |
| `Float32`/`Float64` | `float`/`double` | 4/8 |

> C 的 `int`/`long` 因平台而异，需**你显式指定**对应仓颉类型。`Unit` 在互操作里只能作 `CFunc` 返回类型或 `CPointer` 泛型参数。

### 7.2 结构体：`@C struct`

```cangjie
// C: struct { long long x, y, z; } Point3D;
@C
struct Point3D {
    var x: Int64 = 0
    var y: Int64 = 0
    var z: Int64 = 0
}
foreign func addPoint(p1: Point3D, p2: Point3D): Point3D
```

`@C struct` 限制：成员须满足 `CType`；不能实现/扩展接口；不能作 `enum` 关联值；**不能被闭包捕获**；不能有泛型参数。它自动满足 `CType`。

### 7.3 指针：`CPointer<T>`

对应 C 指针，`T <: CType`。可 `read`/`write`（读写不安全，须 `unsafe`）、偏移、判空 `isNull`、转整型。支持 `CPointer` 之间强转（两侧 `T` 都须 `CType`）、`CFunc`→`CPointer` 强转（但别对转换后的指针 read/write）。

```cangjie
foreign func malloc(size: UIntNative): CPointer<Unit>
foreign func free(ptr: CPointer<Unit>): Unit

let p1 = CPointer<Point3D>()          // 空指针
if (p1.isNull()) { print("null") }
var raw = unsafe { malloc(24) }
var p3 = unsafe { CPointer<Point3D>(raw) }
unsafe { p3.write(Point3D(...)) }
let v = unsafe { p3.read() }
unsafe { free(raw) }
```

### 7.4 数组：`VArray<T, $N>`

映射 C 数组，可作 `CFunc` 参数或 `@C struct` 成员（`T <: CType` 时 `VArray<T,$N>` 也满足 `CType`）。作参数时按 `CPointer<T>` 传递、调用处需 `inout`；不能作 `CFunc` 返回值。

> 不支持含**柔性数组**（C 里结构体末尾未定长数组）的结构体映射。

### 7.5 字符串：`CString`

对应 C 字符串。成员：`init(CPointer<UInt8>)`、`getChars`、`size`、`isEmpty`/`isNotEmpty`/`isNull`、`startsWith`/`endsWith`、`equals`/`equalsLower`、`subCString`、`compare`（等同 `strcmp`）、`toString()`（转仓颉 `String`）、`asResource`。`String`→`CString` 用 `LibC.mallocCString(...)`，**用完必须 `LibC.free`**。

### 7.6 `sizeOf` / `alignOf`

```cangjie
public func sizeOf<T>(): UIntNative where T <: CType
public func alignOf<T>(): UIntNative where T <: CType
```

64 位上：`@C struct Data { var a: Int64; var b: Float32 }` → `sizeOf<Data>()=16`、`alignOf<Data>()=8`（对齐/填充）。

### 7.7 `CType` 接口

`CType` 是所有 C 互操作类型的父接口（本身无方法），便于泛型约束：`func foo<T>(x: T) where T <: CType {...}`。注意：`CType` 接口自身不满足 `CType`、不可被继承/扩展。

## 8. C 调用仓颉函数

把 C 的函数指针类型映射成 `CFunc` 作 `foreign` 参数，再传仓颉侧函数/闭包：

```cangjie
// C:  typedef void (*callback)(int);  void set_callback(callback);
foreign func set_callback(cb: CFunc<(Int32) -> Unit>): Unit

@C func myCallback(s: Int32): Unit { println("handle ${s}") }
let f: CFunc<(Int32) -> Unit> = { i => println("handle ${i}") }

main() {
    unsafe { set_callback(myCallback) }
    unsafe { set_callback(f) }
}
```

> **⚠️ 命名**：`foreign`/`@C` 的 `CFunc` **不要用 `CJ_`（不分大小写）前缀**，以免与标准库/运行时内部符号冲突导致未定义行为。

## 9. 编译与链接

调 C 库通常要手动链接：

- `-L <dir>` / `--library-path`：库目录（`LIBRARY_PATH` 环境变量也会加入，优先级低于 `-L`）。
- `-l <name>` / `--library`：链接 `lib<name>.<ext>`。

例：链接当前目录的 `libdraw.so` 并运行：

```bash
cjc -L . -l draw ./main.cj
LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH ./main
```

编译 C 侧代码时建议开 `-fstack-protector-all/-strong` 栈保护，仓颉侧默认有溢出检查与栈保护，引入 C 后要自行保证 `unsafe` 块内的溢出安全。

## 10. 使用注意（副作用类）

- **线程局部变量**：仓颉线程会被随机调度到不同 OS 线程，调用 C 的 `thread_local`/`pthread_key_create` 变量**有风险**。
- **线程绑定**（优先级、亲和性）不建议依赖。
- **同步/长阻塞**：当前仓颉线程会等 C 侧执行完，C 里别放长时间阻塞行为。
- **`fork()`**：C 里 fork 出的子进程**不支持再执行仓颉逻辑**。
- **进程退出**：C 里退出进程可能已释放共享资源，导致非法访问。

## 11. 完整可运行示例

只用系统 libc（`strlen` 由 libc 自动链接）与内置 `LibC`，**不需自定义 .c 与 `-l`**，本地与 CI 均可验证；输出确定。

<!-- example: cangjie/034-c-interop.cj -->
```cangjie
// 仓颉-C 互操作示例（基于 1.0.5 std 的 foreign / LibC / CPointer / CString / inout）
// 演示：foreign 声明并 unsafe 调用系统 libc 函数(strlen)、CString 与 String 互转与释放、
// @C struct + CPointer 的 read/write、inout 引用传参、sizeOf 计算结构体大小。
//
// 只用系统 libc 符号（strlen 由 libc 自动链接）与内置 LibC，无需自定义 .c 或 -l 链接。

// 声明外部 C 函数：foreign 只有声明无实现；调用须在 unsafe 块里。返回 UIntNative（对应 C 的 size_t）
foreign func strlen(s: CString): UIntNative

// @C 修饰的 struct：与 C 结构体同内存布局，成员须满足 CType
@C
struct Point {
    var x: Int64 = 0
    var y: Int64 = 0
    init(x: Int64, y: Int64) {
        this.x = x
        this.y = y
    }
}

// 被 @C 修饰的仓颉函数：形参是 C 指针；通过 CPointer 读写结构体（模拟被 C 侧回调修改）
@C
func bump(p: CPointer<Point>): Unit {
    let v = unsafe { p.read() }
    unsafe { p.write(Point(v.x + 1, v.y + 1)) }
}

// 把 Int64 就地置为 42，用于演示 inout 引用传参
@C
func setFortyTwo(ptr: CPointer<Int64>): Unit {
    unsafe { ptr.write(42) }
}

main(): Int64 {
    // ---- 1) CString：mallocCString 造串、strlen 取长、toString 转回仓颉 String、free 释放 ----
    let cs = unsafe { LibC.mallocCString("hello cangjie") }
    let n: UIntNative = unsafe { strlen(cs) }
    println("cstr = ${cs.toString()}, len = ${n}")   // cstr = hello cangjie, len = 11
    unsafe { LibC.free(cs) }

    // ---- 2) @C struct + CPointer + inout：把本地结构体地址传给 @C 函数并读回 ----
    println("sizeOf<Point> = ${sizeOf<Point>()}")     // sizeOf<Point> = 16
    var pt = Point(10, 20)
    unsafe { bump(inout pt) }                         // x、y 各 +1
    println("point = (${pt.x}, ${pt.y})")             // point = (11, 21)

    // ---- 3) inout：把仓颉变量的地址按引用传给 @C 函数 ----
    var value: Int64 = 0
    unsafe { setFortyTwo(inout value) }
    println("value after inout = ${value}")           // value after inout = 42

    return 0
}
```

预期输出：

```text
cstr = hello cangjie, len = 11
sizeOf<Point> = 16
point = (11, 21)
value after inout = 42
```

## 12. 语言对比

| 维度 | 仓颉 | Rust | Go | C# |
|---|---|---|---|---|
| 声明外部函数 | `foreign func f(...)` | `extern "C" fn` | cgo `//extern` | `DllImport` |
| 暴露给 C | `@C func` / `CFunc` | `#[no_mangle] extern fn` | cgo `//export` | `UnmanagedFunctionPointer` |
| 不安全边界 | 调用点必须 `unsafe` | `unsafe` 块 | 无语言级 unsafe | `unsafe` 块 |
| 指针类型 | `CPointer<T>` | `*const/*mut T` | `unsafe.Pointer` | `T*` |
| C 字符串 | `CString` | `CString`/`CStr` | `C.CString` | `Marshal.PtrToString*` |
| 结构体布局 | `@C struct` | `#[repr(C)]` | `C.struct_*` | `[StructLayout]` |
| 引用传参 | `inout` → `CPointer` | `&mut`→裸指针 | `&x`+`unsafe.Pointer` | `ref`/`out` |
| 链接 | `-L`/`-l` | `#[link]`/build.rs | cgo LDFLAGS | 原生互操作 |

**从 Rust 迁移**：`foreign`↔`extern`、`@C struct`↔`#[repr(C)]`、`CPointer`↔裸指针、`unsafe` 语义接近；仓颉额外用 `inout` 表达"传地址"，`CFunc` 对应函数指针。
**从 C# 迁移**：`DllImport`↔`foreign`，`[StructLayout]`↔`@C struct`，`ref`↔`inout`。

## 13. 常见问题（FAQ）

### Q1: `foreign` 和 `@C` 什么区别？

`foreign` 表示"这个函数的**实现在 C 侧**"（仓颉只声明）；`@C` 表示"这个仓颉函数/struct 用 C 的 ABI/布局"（可被 C 调用或跨边界传）。`@C` 修饰 `foreign` 时可省略。

### Q2: 为什么调用要包 `unsafe`？

C 侧行为不受仓颉类型/内存安全保证（任意指针、可越界），所以调用 `foreign`/`@C`/`CFunc` 都必须显式 `unsafe`，提醒程序员"此处不安全、我负责"。

### Q3: `foreign func` 能写函数体吗？

不能。`foreign` 只能声明，有实现就编译错误。

### Q4: `inout` 能传 `class` 字段吗？

不能直接或间接来自 `class` 实例成员；可来自顶层/局部变量、`struct` 成员。也不能是 `let`、字面量、入参。

### Q5: `CFunc` lambda 能捕获外部变量吗？

不能。`CFunc` 类型的 lambda 不捕获变量（普通 lambda 才能捕获）。

### Q6: 传给 C 的 `CString` 谁释放？

`LibC.mallocCString` 分配的 `CString` 用完后要 `LibC.free` 释放——它是非内存资源，GC 不管。

### Q7: 调用 C 会不会拖垮并发调度？

`foreign` 调用会阻塞当前**仓颉线程**直到 C 返回（M:N 下让渡系统线程，但仍有吞吐代价）；C 侧长阻塞/fork/线程局部变量都有风险（见第 10 节）。

### Q8: 怎么用 `CPointer` 传定长数组给 C？

用 `VArray<T, $N>`（满足 `CType`）作 `CFunc` 参数，调用处 `inout` 传；`VArray` 不能作 `CFunc` 返回值，也不支持柔性数组。

## 14. 总结

1. 仓颉-C 互操作**双向**：`foreign` 声明并调 C，`@C`/`CFunc` 让 C 回调仓颉；**所有调用点在 `unsafe` 上下文**。
2. `foreign`：只声明不实现、参数/返回须 CType、无命名参数/默认值、支持变长 `...`。
3. `CFunc<...>` 对应 C 函数指针，三种形式（`@C` foreign / `@C` 函数 / `CFunc` 闭包且不捕获）。
4. `inout` 按引用传地址（`CPointer<T>`），有对象来源限制（不能 class 成员/let/字面量）。
5. 类型映射：基础类型表、`@C struct`、`CPointer<T>`、`VArray<T,$N>`、`CString`、`sizeOf/alignOf`、`CType` 父接口。
6. 调用约定 `@CallingConv[CDECL|STDCALL]`（默认 CDECL）；链接用 `-L`/`-l`。
7. 注意线程局部变量、fork、长阻塞、进程退出等跨语言副作用；CString 要 `LibC.free`。

## 参考资料

1. 仓颉 1.0.5 LTS 仓颉-C 互操作：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/FFI/cangjie-c.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
