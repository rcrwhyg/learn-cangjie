# 仓颉错误处理与 Option

> **摘要**: 仓颉的错误处理有两条互补的路：**异常**（`throw` + `try-catch-finally`）适合"打破当前控制流、向上传播"的意外情况；**Option**（`Some`/`None`）适合"预期内可能没有值"的返回值。本文依据仓颉 1.0.5 LTS 官方 error_handle 与 Option 章节，讲清 `Error` 与 `Exception` 的区别、自定义异常、`try-catch-finally` 的完整规则、`try` 作为表达式的类型推导、`CatchPattern` 的类型/联合/通配符三形态、`try-with-resources` 自动释放资源、常见内置异常，以及 Option 的四种解构方式（`match` / `??` / `?.` / `getOrThrow`）和用它做错误传播。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已完成《enum 枚举类型》（Option 是泛型 enum）与《泛型编程》
- 已了解 class 继承、`open`/`override`、`Resource` 概念

> 说明：仓颉 1.0.5 **没有** Rust 式的 `Result<T, E>` 类型（我在 SDK 上确认 `Result`/`Ok` 未定义）。错误处理由"异常 + Option"两条路组成，本文即讲这两条。

## 1. `Error` 与 `Exception`

仓颉的异常类分两支：

| 类别 | 含义 | 你的应对 |
|---|---|---|
| `Error` | 运行时系统内部错误、资源耗尽 | **不应主动抛出**，只能尽量安全终止 |
| `Exception` | 程序逻辑错误或 IO 错误（数组越界、文件不存在等） | 需要在程序里 `catch` 处理 |

**关键限制**：

- 你**不能继承 `Error` 或其子类**自定义异常；**可以继承 `Exception` 或其子类**。
- `throw` 只能抛 `Exception` 子类型，**不能手动 `throw` 一个 `Error`**。

自定义异常：

```cangjie
open class FatherException <: Exception {
    public init() { super("This is FatherException.") }
    public init(message: String) { super(message) }
    public open override func getClassName(): String { "FatherException" }
}

class ChildException <: FatherException {
    public init() { super("This is ChildException.") }
    public open override func getClassName(): String { "ChildException" }
}
```

> **⚠️ 注意**：`Exception` 默认 `getClassName()` 不会自动返回子类名——**子类必须重写 `getClassName()`** 才能拿到正确的类名。

`Exception` 的主要成员：`init()`、`init(message)`、属性 `message`、`toString()`（类名 + message）、`getClassName()`、`printStackTrace()`（打印到标准错误流）。

## 2. throw 与 try-catch-finally

`throw` 抛出异常（表达式必须是 `Exception` 子类型）；抛出的异常若不被捕获，交给系统默认处理函数（可通过 `Thread.handleUncaughtExceptionBy` 注册自定义处理）。

一个 `try` 表达式由 `try` 块、若干 `catch` 块、可选 `finally` 块组成：

```cangjie
try {
    throw NegativeArraySizeException("I am an Exception!")
} catch (e: NegativeArraySizeException) {
    println(e)
    println("NegativeArraySizeException is caught!")
}
println("This will also be printed!")
```

结构规则（官方 + 实测）：

- **0 或多个 catch**；没有 catch 时**必须**有 finally。
- 有 catch 时 finally 可省。
- `catchPattern` 引入的变量与 catch 块内变量**同作用域级别**，块内再定义同名变量会**重定义报错**。
- 若某个 catch 能捕获的异常都能被**更前面**的 catch 捕获，编译器给"**catch 块不可达**"warning。

### 2.1 finally 一定执行

无论是否发生异常、异常是否被处理，`finally` 块都会执行（异常未被处理时，执行完 finally 再继续向外抛）。

### 2.2 try 是表达式，有类型

`try` 表达式的类型 = **finally 之外所有分支类型的最小公共父类型**；`finally` 分支不参与类型计算。若 `try` 表达式的值未被使用，其类型为 `Unit`，不要求分支有公共父类型。

```cangjie
open class C {}
open class D <: C {}
class E <: D {}

let x = try { E() } catch (e: Exception) { D() } finally { C() }
// x 的类型是 E、D 的最小公共父类型 D（finally 里的 C() 不参与）
```

## 3. CatchPattern 三种形态

`catch ( <CatchPattern> )` 通过模式匹配决定捕获什么。

1. **类型模式** `e: SomeException`：捕获 `SomeException` 及其子类的异常，绑定到 `e`。
2. **联合类型模式** `e: A | B | ...`：用 `|` 连接多个异常类（"或"）。因为无法静态确定实际类型，**被捕获异常会被转换成这些类的最小公共父类型**，所以 catch 块里只能访问公共父类的成员：

```cangjie
open class Father <: Exception { var father: Int32 = 0 }
class ChildOne <: Father { var childOne: Int32 = 1 }
class ChildTwo <: Father { var childTwo: Int32 = 2 }

try {
    throw ChildOne()
} catch (e: ChildTwo | ChildOne) {
    println("${e is Father}")   // true：e 已被当作 Father
}
```

3. **通配符模式** `_`：捕获任意 `Exception`（等价于 `e: Exception`），但不绑定变量：

```cangjie
try {
    throw OverflowException()
} catch (_) {
    println("catch an exception!")
}
```

## 4. try-with-resources（自动释放资源）

用于**自动释放非内存资源**。与普通 try 的区别：`try` 与 `{}` 之间可以写一个或多个 `ResourceSpecification`（实例化实现 `Resource` 接口的对象），离开作用域时自动调用其 `close()`。`catch` 和 `finally` 在这里都是可选的；整个表达式类型为 `Unit`。

`Resource` 接口：

```cangjie
interface Resource {
    func isClosed(): Bool   // 判断是否已关闭；未关闭则调用 close
    func close(): Unit      // isClosed 返回 false 时释放资源
}
```

```cangjie
class Worker <: Resource {
    let name: String
    private var opened: Bool = false
    public init(name: String) { this.name = name }
    public func start(): Unit { opened = true; println("${name} started") }
    public func isClosed(): Bool { !opened }
    public func close(): Unit { println("${name} closed"); opened = false }
}

main() {
    try (w = Worker("Tom")) {
        w.start()
        println("working")
    }   // 离开作用域自动调用 w.close()
}
```

规则：`ResourceSpecification` 的类型**必须实现 `Resource`**；`try (...)` 里引入的名字与块内变量同作用域，块内再同名会重定义报错；一般没必要再配 catch/finally（逻辑冗余），但需要处理资源使用/释放过程中的异常时可以加。

## 5. 常见内置运行时异常

`core` 直接提供、开箱即用：

| 异常 | 触发 |
|---|---|
| `ConcurrentModificationException` | 并发修改 |
| `IllegalArgumentException` | 传入不合法/不正确参数 |
| `NegativeArraySizeException` | 创建大小为负的数组 |
| `NoneValueException` | 值不存在（如 `Option.getOrThrow()` 遇到 `None`、Map 找不到 key） |
| `OverflowException` | 算术运算溢出 |

## 6. Option：另一种"错误"

`Option<T>` 是内置的泛型 enum，两个构造器 `Some(T)`（有值）和 `None`（无值）。因为"无值"在很多场景本身就是一种可预期的失败，Option 是仓颉做**轻量错误处理**的主力。

```cangjie
enum Option<T> {
    | Some(T)
    | None
}
```

### 6.1 便捷写法与自动装箱

- **`?Ty` 是 `Option<Ty>` 的语法糖**：`?Int64` 等价于 `Option<Int64>`。
- 当上下文要求 `Option<T>` 时，可直接给一个 `T` 值，编译器自动用 `Some` 包装（**不是类型转换**）：

```cangjie
let a: Option<Int64> = Some(100)
let b: ?Int64 = Some(100)
let c: Option<Int64> = 100          // 自动 Some(100)
```

- 上下文推不出类型时，用 `None<T>` 显式构造：`let x = None<Int64>`。

### 6.2 四种解构方式

1. **模式匹配**（Option 本质是 enum）：

```cangjie
func getString(p: ?Int64): String {
    match (p) {
        case Some(x) => "${x}"
        case None => "none"
    }
}
```

2. **coalescing 操作符 `??`**：`e1 ?? e2`，`e1` 是 `Some(v)` 则返回 `v`，否则返回 `e2`。

```cangjie
let a = Some(1)
let b: ?Int64 = None
let r1: Int64 = a ?? 0    // 1
let r2: Int64 = b ?? 0    // 0
```

3. **问号操作符 `?.` / `?()` / `?[]` / `?{}`**：对 `Option` 做链式安全访问。`e?.b`：`e` 是 `Some(v)` 则结果是 `Some(v.b)`，否则 `None`。支持多层 `a?.b.c?.d`，任一环节为 `None` 则整体 `None` 且**后续不再求值**。赋值 `a?.b.c?.d = 200` 也只在路径完整时生效。

4. **`getOrThrow()`**：`Some(v)` 返回 `v`，`None` **抛 `NoneValueException`**。

> **💡 提示**：`?.` 只处理"值可能缺失"，不会吞异常；`??` 给缺失值一个兜底；`getOrThrow()` 把"缺失"升级成异常。三者按场景选。

## 7. 用 Option 做错误传播

对"可预期、可恢复"的失败，用 Option 返回值比抛异常更干净——调用方被类型系统逼着处理 `None`。例如安全除法：

```cangjie
func safeDiv(a: Int64, b: Int64): ?Int64 {
    if (b == 0) { None } else { Some(a / b) }
}

let ok = safeDiv(10, 2)          // Some(5)
let bad = safeDiv(10, 0)         // None
println(ok ?? 0)                 // 5
println(bad ?? -1)               // -1（缺失时用默认值兜底）
```

经验法则：**意外**（数组越界、IO 失败）→ 异常；**预期内的空**（查不到、可选字段）→ Option。

## 8. 完整可运行示例

<!-- example: cangjie/025-error-option.cj -->
```cangjie
// 错误处理与 Option 示例
// 演示：自定义 Exception、throw、try-catch-finally、try 作表达式（最小公共父类型）、
// CatchPattern 的联合类型(|)与通配符(_)、try-with-resources、
// Option 解构四件套（match / ?? / ?. / getOrThrow）与用 Option 做错误传播

// ========== 1) 自定义异常 ==========

open class AppException <: Exception {
    public init(message: String) {
        super(message)
    }
    public open override func getClassName(): String {
        "AppException"
    }
}

// ========== 2) try-with-resources 用到的资源类型 ==========

class Worker <: Resource {
    let name: String
    private var opened: Bool = false

    public init(name: String) {
        this.name = name
    }
    public func start(): Unit {
        opened = true
        println("${name} started")
    }
    public func isClosed(): Bool {
        !opened
    }
    public func close(): Unit {
        println("${name} closed")
        opened = false
    }
}

// ========== 3) 用 Option 做错误传播：安全除法 ==========

func safeDiv(a: Int64, b: Int64): ?Int64 {
    if (b == 0) {
        None
    } else {
        Some(a / b)
    }
}

// ========== 4) Option 解构用的类型 ==========

struct Box {
    public var v: Int64
    public init(v: Int64) {
        this.v = v
    }
}

main(): Int64 {
    // ---- 1) throw + try-catch-finally ----
    try {
        throw AppException("boom")
    } catch (e: AppException) {
        println("caught: ${e.message}")
    } finally {
        println("finally executed")
    }

    // ---- 2) CatchPattern 联合类型(|)：多异常共用一个 catch ----
    try {
        throw IllegalArgumentException("bad arg")
    } catch (e: IllegalArgumentException | OverflowException) {
        // 被捕获异常类型转换为两者的最小公共父类型，故只能访问公共成员（如 message）
        println("union caught: ${e.message}")
    }

    // ---- 3) CatchPattern 通配符(_)：捕获任意 Exception ----
    try {
        throw OverflowException()
    } catch (_) {
        println("wildcard caught any exception")
    }

    // ---- 4) try 作为表达式：类型取各分支的最小公共父类型（finally 不参与）----
    let v: Int64 = try {
        10
    } catch (e: Exception) {
        -1
    } finally {
        println("in finally")
    }
    println("try-expr v = ${v}")

    // ---- 5) try-with-resources：离开作用域自动 close ----
    try (w = Worker("Tom")) {
        w.start()
        println("working")
    }

    // ---- 6) Option 定义与自动装箱 ----
    let a: Option<Int64> = Some(100)
    let b: ?Int64 = Some(200)
    let c: Option<Int64> = 300 // 需要 Option 处直接给 T，编译器自动 Some 包装
    println("a=${a.getOrThrow()} b=${b.getOrThrow()} c=${c.getOrThrow()}")

    // ---- 7) Option 解构：match ----
    println("match = ${describeOption(Some(7))}")
    println("match = ${describeOption(None)}")

    // ---- 8) Option 解构：?? (coalescing) ----
    // 用运行期结果演示，避免 Some/None 字面量被编译期折叠
    let someFromDiv = safeDiv(14, 2)     // Some(7)
    let noneFromDiv = safeDiv(14, 0)     // None
    println("some ?? 0 = ${someFromDiv ?? 0}")
    println("none ?? 0 = ${noneFromDiv ?? 0}")

    // ---- 9) Option 解构：?. 问号操作符 ----
    let boxOpt = boxOptFor(99)           // Some(Box(99))
    let boxed: ?Int64 = boxOpt?.v        // Some(99)
    println("boxOpt?.v = ${boxed ?? -1}")
    let noneOpt = boxOptFor(-1)          // None（约定 v<0 返回 None）
    let empty: ?Int64 = noneOpt?.v       // None
    println("noneOpt?.v = ${empty ?? -1}")

    // ---- 10) getOrThrow：None 时抛 NoneValueException ----
    try {
        let _ = noneFromDiv.getOrThrow()
    } catch (e: NoneValueException) {
        println("NoneValueException caught")
    }

    // ---- 11) 用 Option 做错误传播 ----
    let ok = safeDiv(10, 2)
    let bad = safeDiv(10, 0)
    println("safeDiv(10,2) = ${ok ?? 0}")
    println("safeDiv(10,0) default = ${bad ?? -1}")

    return 0
}

func describeOption(p: ?Int64): String {
    match (p) {
        case Some(x) => "value:${x}"
        case None => "none"
    }
}

// 约定：v < 0 返回 None，否则返回 Some(Box(v))；用运行期分支避免常量折叠
func boxOptFor(v: Int64): ?Box {
    if (v < 0) {
        None
    } else {
        Some(Box(v))
    }
}
```

预期输出：

```text
caught: boom
finally executed
union caught: bad arg
wildcard caught any exception
in finally
try-expr v = 10
Tom started
working
Tom closed
a=100 b=200 c=300
match = value:7
match = none
some ?? 0 = 7
none ?? 0 = 0
boxOpt?.v = 99
noneOpt?.v = -1
NoneValueException caught
safeDiv(10,2) = 5
safeDiv(10,0) default = -1
```

## 9. 语言对比

| 维度 | 仓颉 | Java | Go | Rust |
|---|---|---|---|---|
| 异常基类 | `Exception`（可继承）、`Error`（不可继承） | `Throwable`→`Exception`/`Error` | 无异常（用返回值） | `panic`（非常规） |
| 抛出 / 捕获 | `throw` / `try-catch-finally` | 同左 | `panic`/`recover`（罕用） | 不鼓励 |
| 受检异常 | 无"必须声明抛出"机制 | 有 checked exception | — | — |
| 可选值 | `Option<T>` / `?T`，`Some`/`None` | `Optional<T>` | nil + `if err != nil` | `Option<T>` |
| 成功/失败双类型 | 无 `Result`，用异常或 Option | 异常 | `error` 多返回值 | `Result<T,E>` |
| 缺失兜底 | `??`、`?.`、`getOrThrow` | `orElse`/`map` | 手写判断 | `unwrap_or`、`?` 运算符 |
| 资源管理 | `try-with-resources` + `Resource` | `try-with-resources`+`AutoCloseable` | `defer` | 所有权/Drop |

**从 Java 迁移**：概念几乎一一对应（`Exception`/`Error`、`try-catch-finally`、`try-with-resources`、`Optional`↔`Option`），但注意仓颉**没有受检异常**，也**不能自定义继承 `Error`**。
**从 Go 迁移**：Go 的 `if err != nil` 在仓颉里可升级为 `try-catch`（意外）或 `Option + ??/?.`（预期空）。
**从 Rust 迁移**：仓颉 1.0.5 **无 `Result`**，也没有 `?` 早返回操作符——"可失败的正常返回"请用 Option + 手动 match，或抛异常。

## 10. 常见问题（FAQ）

### Q1: `Error` 和 `Exception` 我该抛哪个？

都不该随便抛 `Error`。`Error` 是系统级/资源耗尽，程序不主动抛、也不该继承它自定义；业务/逻辑/IO 错误用 `Exception` 或其子类。

### Q2: `catch (e: A | B)` 里为什么访问不了 A 独有字段？

联合类型模式下 `e` 被转成 A、B 的**最小公共父类型**，只能访问公共成员。要访问独有成员，分成两个 catch 块分别捕获 A、B。

### Q3: finally 里 return / 抛异常会怎样？

官方建议**避免在 finally 里再抛异常**。finally 一定执行；try 里没被 catch 的异常，会在执行完 finally 后继续外抛。

### Q4: `try (...)` 里对象要满足什么才能自动关闭？

类型必须实现 `Resource` 接口（`isClosed()` + `close()`），离开作用域时若 `isClosed()` 返回 false 就自动 `close()`。

### Q5: `?Int64` 和 `Option<Int64>` 有区别吗？

没有，`?Ty` 就是 `Option<Ty>` 的语法糖。

### Q6: 什么时候用 Option，什么时候用异常？

预期内、可恢复的"可能没值"用 Option（调用方被迫处理 `None`）；意外、破坏正常流程的错误用异常（`throw` + 上游 `catch`）。

### Q7: `x?.a` 得到的是什么类型？

`Option` 类型（`Some(v.a)` 或 `None`）。所以后面常再接 `?? 默认值` 或 `?.` 继续链式访问。

### Q8: 仓颉有 `Result` / `?` 早返回吗？

1.0.5 **没有** `Result` 类型，也没有 Rust 那种在函数里用 `?` 传播错误的运算符（`?` 在仓颉是 `Option` 的类型糖和 `?.` 安全访问，不是早返回）。

## 11. 总结

1. **两支异常**：`Error`（系统级，不可继承/不可 throw）、`Exception`（可继承、可 `throw`、可 `catch`）；自定义异常要重写 `getClassName()`。
2. **`try-catch-finally`**：0+ 个 catch（无 catch 必须有 finally）；catch 变量与块内同作用域；顺序不当会"catch 不可达"warning。
3. **try 是表达式**：类型 = finally 外各分支的最小公共父类型；值不用时为 `Unit`。
4. **CatchPattern**：类型模式、`A | B` 联合模式（转成公共父类型）、通配符 `_`。
5. **try-with-resources**：`try (r = 资源)` 自动 `close`，资源须实现 `Resource`。
6. **内置运行时异常**：IllegalArgument / NegativeArraySize / NoneValue / Overflow / ConcurrentModification。
7. **Option**：`?T` = `Option<T>`，给 `T` 自动装箱 `Some`，`None<T>` 显式构造；解构四件套 `match` / `??` / `?.` / `getOrThrow`。
8. **选路**：预期空 → Option（+ `??`/`?.`），意外 → 异常；无 `Result`、无 `?` 早返回。

## 参考资料

1. 仓颉 1.0.5 LTS 定义异常：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/error_handle/exception_overview.html
2. 仓颉 1.0.5 LTS throw 和处理异常：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/error_handle/handle.html
3. 仓颉 1.0.5 LTS 常见运行时异常：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/error_handle/common_runtime_exceptions.html
4. 仓颉 1.0.5 LTS Option 类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/option_type.html
5. 仓颉 1.0.5 LTS 使用 Option：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/error_handle/use_option.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
