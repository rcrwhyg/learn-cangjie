# 仓颉资源管理

> **摘要**: 内存可以交给垃圾回收（GC），但文件、socket、C 指针这类**非内存资源**必须显式释放，否则泄漏。仓颉 1.0.5 提供三条资源释放路径：**手动 `close`**、**`try-with-resources` 自动关闭**（实现 `Resource` 接口）、以及**终结器 `~init`**（对象被 GC 回收时触发，但时机不确定）。本文依据仓颉 1.0.5 LTS 官方文档（class 终结器小节、error_handle 的 try-with-resources、`std.runtime.gc`），讲清 `Resource` 契约、终结器的 12 条硬性限制、GC 的显式触发，以及三者如何取舍——核心结论是：**有明确作用域的资源优先用 `try-with-resources`，终结器只作兜底**。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已完成《class 类类型》《错误处理与 Option》（`try-with-resources` 在异常篇已引入，本篇从"资源管理"视角系统化）
- 已了解引用类型、GC 基本概念

> 内存模型、值/引用类型语义、GC 算法原理将在《值类型、引用类型与内存管理》专题（后续）深入；本篇聚焦**非内存资源的正确释放**。

## 1. 为什么需要"资源管理"

GC 负责回收**内存**，但它**管不了非内存资源**：打开的文件句柄、数据库连接、socket、`malloc` 来的 C 指针……这些资源数量有上限，不主动释放就会泄漏，最终耗尽系统资源。

仓颉给三种释放路径：

| 方式 | 何时释放 | 确定性 | 适用 |
|---|---|---|---|
| 手动 `close` | 你写 `x.close()` 的那一刻 | 确定，但要自己保证不漏 | 生命周期不规则 |
| `try-with-resources` | 离开 `try` 作用域时自动 `close` | 确定 | **有明确作用域**的资源（首选） |
| 终结器 `~init` | 对象被 GC 回收时 | **不确定** | 兜底，不能承载"必须按时"的逻辑 |

## 2. `Resource` 接口与 try-with-resources

`try-with-resources` 的资源类型必须实现 `Resource` 接口：

```cangjie
interface Resource {
    func isClosed(): Bool   // 是否已关闭
    func close(): Unit      // isClosed 返回 false 时，用于释放资源
}
```

用法（异常篇《错误处理与 Option》已引入，这里回到资源视角）：

```cangjie
class Conn <: Resource {
    let name: String
    private var closed: Bool = false
    public init(name: String) { this.name = name }
    public func query(): Unit { println("query on ${name}") }
    public func isClosed(): Bool { closed }
    public func close(): Unit { closed = true; println("close ${name}") }
}

main() {
    try (c = Conn("db-1")) {
        c.query()
    }   // 离开作用域自动调用 c.close()
}
```

要点（官方 + 实测）：

- `try` 与 `{}` 之间可写**一个或多个** `ResourceSpecification`（`,` 分隔），离开作用域都会自动 `close`。
- `try (...)` 引入的名字与块内变量**同作用域级别**，块内再同名会重定义报错。
- `catch`、`finally` 在 try-with-resources 里都**可选**；整个表达式类型为 `Unit`。
- 一般**没必要**再配 `catch`/`finally`，也不建议再手动 `close`（逻辑冗余）；需要处理资源使用/释放过程中的异常时才可加。
- **资源释放顺序**官方未对"多资源"明确承诺，因此**不要依赖关闭顺序**写关键逻辑。

> **✅ 推荐**：只要资源有清晰的作用域边界（函数内打开、用完就关），一律用 `try-with-resources`——它把"忘记 close"从高频 bug 变成不可能。

## 3. 手动 close（对照）

不用 `try-with-resources` 时，你得对每条退出路径都记得 `close`，异常时尤其容易漏：

```cangjie
let c = Conn("db-2")
try {
    c.query()
} finally {
    if (!c.isClosed()) { c.close() }   // 手动兜底
}
```

这正是 `try-with-resources` 帮你省掉的样板。

## 4. 终结器 `~init`

`class` 支持定义**终结器**，函数名固定为 `~init`，当类的实例被垃圾回收时触发，通常用于释放系统资源：

```cangjie
class C {
    var p: CString
    init(s: String) {
        p = unsafe { LibC.mallocCString(s) }
    }
    ~init() {
        unsafe { LibC.free(p) }   // 回收时释放 C 内存
    }
}
```

### 4.1 十二条限制（官方规则，逐条实测）

1. 终结器**没有参数、没有返回类型、没有泛型类型参数、没有任何修饰符，也不可以被显式调用**。
2. 带终结器的类**不可被 `open` 修饰**，只有非 `open` 的类可以拥有终结器。
3. 一个类**最多只能定义一个**终结器。
4. 终结器**不可以定义在扩展（`extend`）中**。
5. 终结器被触发的**时机是不确定的**。
6. 终结器可能**在任意一个线程上执行**。
7. 多个终结器的**执行顺序是不确定的**。
8. 终结器向外抛出未捕获异常属于**未定义行为**。
9. 终结器中创建线程或使用线程同步功能属于**未定义行为**。
10. 终结器执行结束后若该对象还能被继续访问，属于**未定义行为**。
11. 对象初始化过程中抛异常时，**未完整初始化的对象的终结器不会执行**。
12. **依赖终结器的同步行为**属于未定义行为（例如主线程 `while` 等某个终结器改的标志位）。

我在 SDK 上实测到的报错，对应前四条：

| 违规 | cjc 实测报错 |
|---|---|
| `open class C { ~init() {} }` | `finalizer is forbidden in class 'C' that is open` |
| 显式调用 `c.~init()` | `expected a member name after '.'`（语法层面就不允许） |
| 在 `extend` 里写 `~init` | `unexpected finalizer in extend body` |
| `private ~init()` / 带返回类型 | `unexpected modifier 'private' on finalizer in class body` |

### 4.2 终结器是"兜底"，不是"生命周期钩子"

第 5–12 条本质上在说同一件事：**你不能指望终结器何时、在哪个线程、按什么顺序运行**。因此：

- 有明确作用域的资源 → 用 `try-with-resources`（第 2 节），别交给终结器。
- 需要"确定时刻释放"的逻辑（如写回、按序关闭）→ 不能放终结器。
- 官方示例明确点名：用 `while (Test.t0 != 0)` 轮询等待终结器修改标志位，是**未定义行为**。

## 5. 显式触发 GC：`std.runtime.gc`

需要请求一次垃圾回收时，可用 `std.runtime.gc`（`heavy: true` 为阻塞式）：

```cangjie
import std.runtime.gc

main() {
    gc()             // 请求一次 GC
    gc(heavy: true)  // 阻塞式 GC（等待回收进行）
}
```

> **⚠️ 注意**：即便强制 GC，某个对象的终结器"是否、何时"运行依然不由你掌控（第 4 节）。**不要为了触发终结器而调 `gc()`** 来做业务同步——这正是规则 12 禁止的。`gc()` 只适合在测量内存、压测等场景使用。

## 6. 完整可运行示例

下例把三条路径放进一个程序：`try-with-resources` 自动关闭（含多资源）、手动 `close` 对照、以及一个"非 open + 带终结器"的类和 `std.runtime.gc` 的调用。因终结器时机不确定，**可观察输出只依赖 `try-with-resources`/手动 `close`**，终结器仅做内部计数、不影响输出。

<!-- example: cangjie/026-resource-management.cj -->
```cangjie
// 资源管理示例
// 演示：三种资源释放路径（手动 close / try-with-resources 自动 close / 终结器 ~init）、
// Resource 接口契约、try-with-resources 与手动释放的取舍、显式触发 GC（std.runtime.gc）
//
// 注意：终结器 ~init 的触发时机、执行线程、相对顺序都不确定（官方规则 5/6/7），
// 因此本示例把“可观察的输出”放在 try-with-resources 上；终结器只做内部计数，
// 不依赖其执行时机来判定正确性。

import std.collection.ArrayList
import std.runtime.gc

// ========== 1) 实现 Resource：交给 try-with-resources 自动关闭 ==========

class Conn <: Resource {
    let name: String
    private var closed: Bool = false

    public init(name: String) {
        this.name = name
        println("open ${name}")
    }

    public func query(): Unit {
        println("query on ${name}")
    }

    public func isClosed(): Bool {
        closed
    }

    public func close(): Unit {
        closed = true
        println("close ${name}")
    }
}

// ========== 2) 带终结器的普通类（非 open，最多一个 ~init，不能显式调用）==========

class TempBuffer {
    public let id: Int64
    public init(id: Int64) {
        this.id = id
    }
    // 终结器：无参数、无返回、无修饰符，实例被 GC 回收时触发（时机不确定）
    ~init() {
        // 这里只做“假设性”的资源清理示意；不 println，避免依赖不确定的执行时机
        TempBuffer.destroyedCount += 1
    }
    public static var destroyedCount: Int64 = 0
}

main(): Int64 {
    // ---- 1) try-with-resources：作用域结束自动 close ----
    println("--- try-with-resources ---")
    try (c = Conn("db-1")) {
        c.query()
    }   // 离开作用域自动调用 c.close()

    // ---- 2) 多个资源：一行声明多个，作用域结束都会自动 close ----
    println("--- multiple resources ---")
    try (r1 = Conn("a"), r2 = Conn("b")) {
        r1.query()
        r2.query()
    }

    // ---- 3) 手动释放（对照）：不用 try-with-resources 时要自己 close ----
    println("--- manual close ---")
    let manual = Conn("manual")
    manual.query()
    manual.close()   // 开发者负责调用；漏掉就是资源泄漏

    // ---- 4) 终结器演示：造对象、丢弃引用、触发 GC ----
    println("--- finalizer + gc ---")
    let holder = ArrayList<TempBuffer>()
    holder.add(TempBuffer(1))
    holder.add(TempBuffer(2))
    holder.remove(at: 0)
    holder.remove(at: 0)
    // 请求一次阻塞式 GC；是否已运行终结器不确定，故只打印“请求过 GC”，不打印计数
    gc(heavy: true)
    println("gc requested")

    // 正确性说明：优先用 try-with-resources 管理有明确作用域的资源；
    // 终结器仅作为“兜底”，其时机不确定，不能承载必须按时执行的逻辑。
    return 0
}
```

预期输出（"多个资源"块中 `close a`/`close b` 的先后不固定，见第 2 节说明）：

```text
--- try-with-resources ---
open db-1
query on db-1
close db-1
--- multiple resources ---
open a
open b
query on a
query on b
close a
close b
--- manual close ---
open manual
query on manual
close manual
--- finalizer + gc ---
gc requested
```

## 7. 语言对比

| 维度 | 仓颉 | Java | Go | C# |
|---|---|---|---|---|
| 自动关闭语法 | `try (r = X) {}` | `try (r = X) {}`（try-with-resources） | 无（`defer r.Close()`） | `using (r = X) {}` |
| 资源接口 | `Resource { isClosed; close }` | `AutoCloseable`/`Closeable` | 约定 `Close() error` | `IDisposable` |
| 终结器 | `~init`（GC 时触发，时机不确定） | `finalize()`（已废弃倾向） | 无（`defer`/`runtime.Finalizer`） | `Finalize`（已弃用）/`Dispose` 模式 |
| 显式 GC | `std.runtime.gc()` | `System.gc()`（建议性） | `runtime.GC()` | `GC.Collect()` |
| 推荐路径 | try-with-resources 优先 | try-with-resources 优先 | `defer` 优先 | `using` + `Dispose` 优先 |

**从 Java 迁移**：概念几乎对齐——`Resource`↔`AutoCloseable`、`~init`↔`finalize`；仓颉同样告诫终结器时机不确定，别用 `~init` 做必须按时做的事。
**从 Go 迁移**：Go 靠 `defer`；仓颉靠 `try-with-resources`（块级）+ 手动 `close`。
**从 C# 迁移**：`using`↔`try-with-resources`，但注意仓颉终结器**不能重载/带参、所在类不能 `open`、不能写在扩展里**，比 C# 的 `Finalize` 限制更多。

## 8. 常见问题（FAQ）

### Q1: 我该用哪种方式释放资源？

有清晰作用域 → `try-with-resources`；生命周期不规则、跨函数持有 → 手动 `close`（自己在每条路径调）；终结器只当"忘了关"的兜底，别依赖它。

### Q2: 为什么我的 `open class` 加了 `~init` 报错？

规则 2：带终结器的类不能被 `open` 修饰。去掉 `open`，或去掉终结器。

### Q3: 能在别的文件/扩展里给某类补一个 `~init` 吗？

不能。规则 4：终结器不能定义在 `extend` 中；且规则 3 说一个类最多一个 `~init`，必须写在类体内。

### Q4: 我能不能 `c.~init()` 手动触发清理？

不能。规则 1：终结器不可被显式调用。要手动释放就走 `Resource.close` 或普通成员方法。

### Q5: 用 `gc()` 强制回收，然后读一个被终结器改的标志位，行吗？

不行。这是规则 12 点名的未定义行为——终结器何时/在哪个线程跑不可控，别拿它做同步。

### Q6: `try-with-resources` 里还能写 `catch`/`finally` 吗？

能，但要谨慎。官方说一般没必要（逻辑冗余），只有确实要处理"资源使用/释放过程中的异常"时才加。

### Q7: 多资源会按什么顺序关闭？

官方**未承诺顺序**。别写依赖"先关 A 后关 B"的逻辑；需要有序释放就分开多个 `try-with-resources` 或手动控制。

## 9. 总结

1. GC 管内存，**非内存资源必须显式释放**；仓颉三条路径：手动 `close` / `try-with-resources` / 终结器 `~init`。
2. **`try-with-resources` 首选**：资源实现 `Resource`（`isClosed` + `close`），离开作用域自动关闭；可写多资源（`,` 分隔）；类型是 `Unit`。
3. **终结器 `~init`** 有 12 条硬限制：无参/无返回/无修饰符/不可显式调用、所在类不可 `open`、每类最多一个、不能写在扩展里、**触发时机与顺序不确定**、依赖它的同步是未定义行为。
4. **`std.runtime.gc()`** 可请求 GC（`heavy: true` 阻塞），但别为了触发终结器而调它做业务同步。
5. 多资源关闭**顺序不保证**，不要依赖；必须按时释放的逻辑走 `try-with-resources`/手动，而非终结器。

## 参考资料

1. 仓颉 1.0.5 LTS class 定义（含 class 终结器小节）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/class_and_interface/class.html
2. 仓颉 1.0.5 LTS throw 和处理异常（含 try-with-resources 与 Resource）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/error_handle/handle.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
