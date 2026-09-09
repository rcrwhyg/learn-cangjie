# 值类型、引用类型与内存管理：赋值语义、浅拷贝穿透与 GC

> **摘要**: 前面 07/08 教过"怎么定义 `struct`/`class`"——本篇讲**赋值时到底发生了什么**：值类型全量拷贝、引用类型共享对象；两条实测铁证之外，还有一个高频踩坑点——**`Array` 名义上是 `struct`（值类型），实际只共享"元素引用"，赋值不拷 backing store**（官方原文），真正"连数据一起拷"的是 `VArray<T, $N>`。再往下：GC 怎么管生命周期、`~init` 终结器的**触发时机非确定**、`open class` 里**禁止** `~init`（实测）、`std.runtime.gc` 手动触发接口、以及"GC ≠ 资源释放"这条设计边界。所有规则都在 1.0.5 `cjc` 本地实测；示例 `047-value-ref-memory.cj` 一次跑通五条语义，Linux CI 输出逐行核对。

## 前置知识

- 已完成《struct》（07）、《class》（08）、《类型系统》（41，讲名义子类型时已提"struct 不进子类型格"——本篇讲"为什么"）
- 已完成《资源管理》（21，try-with-resources + `Resource` 接口）——本篇第 9 节会回来强调"GC 不管资源释放"
- 接触过 Rust/C++/Java 任一"内存管理"心智更好，本篇会点名对照

> **本篇与基础篇的分界**：基础篇说"`struct` 长这样、`class` 长那样"；本篇说"**把一个 `struct` 赋给另一个变量之后，改一个另一个会不会变**"——从**行为**反推语言设计。

## 1. 两分法：赋值到底拷了什么

Cangjie 的类型分两大家族：

| 家族 | 有哪些 | 赋值/传参时 | 通常所在 |
|---|---|---|---|
| **值类型** | `struct`、`enum`、`Bool`、整数/浮点、`Rune`、元组、`VArray<T,$N>` | **全量拷贝** | 栈 / 寄存器 / 内联在别的对象里 |
| **引用类型** | `class`、`interface`、`Array<T>`（见 §4）、lambda/闭包 | **只拷引用（指针）**，两边共享同一对象 | 堆（GC 管） |

一句话：**值类型"是它的值"，引用类型"是指向它的指针"**。这条差异不是性能上的、而是**语义上的**——同一份数据是不是"共享"决定了改一边另一边会不会变。

## 2. struct 赋值 = 全量拷贝（实测）

```cangjie
struct Point { public var x: Int64; public init(x: Int64) { this.x = x } }
let p1 = Point(1)
var p2 = p1        // 拷贝：p2 是独立的一份
p2.x = 99
// p1.x 仍然是 1
```

CI 输出（示例 A 行）：`struct-copy: p1.x=1 p2.x=99`——两边彻底独立。

这是"struct 是值类型"的直接体现；也是它**不进子类型格**（41 篇实测：`class C <: struct` 被拒）的原因：**值语义 + 多态分派**在实现上很难自洽（子类多出的字段会破坏父类型的固定拷贝大小），Cangjie 干脆让 struct 不参与继承。

## 3. class 赋值 = 共享对象（实测）

```cangjie
class Cfg { public var v: Int64 = 0; public init() {} }
let c1 = Cfg()
let c2 = c1        // 只拷"指向同一对象"这个动作
c2.v = 42
// c1.v 也变 42
```

CI 输出（示例 B 行）：`class-alias: c1.v=42 c2.v=42`。

`class` 是引用类型 → **对象只有一份**、两个变量都是它的名字。**"想复制一个对象"要显式**（自己写 `.clone()` 或复制构造），不能靠赋值。

> **💡 心智**：`let x = ...` 里的 `x` 是**变量**，不是"盒子"。值类型的变量**就是**它的值；引用类型的变量**是**一个指向堆对象的指针。赋值拷的是"变量本身"——所以值类型拷整个值、引用类型拷指针。

## 4. 反直觉重点：`Array` 名义是 struct，实际是共享引用

`Array<T>` **官方明确说是 struct**（值类型家族），但——引官方《数组类型》原文：

> "Array 虽然是 `struct` 类型，但其内部持有的只是元素的引用，因此在作为表达式使用时**不会拷贝副本**，同一个 `Array` 实例的所有引用都会**共享同样的元素数据**。"

也就是说：

```cangjie
let a = [1, 2, 3]
var b = a         // Array 变量拷贝了——但两个变量都指向同一份 backing store
b[0] = 99
// a[0] 也变 99
```

CI 输出（示例 D 行）：`array: a[0]=99 b[0]=99`。

**"Array 是 struct" 与 "Array 赋值共享数据" 并不矛盾**——它像 `class Cfg { var backing: Ref; }` 一样，**外壳**是 struct（拷贝时拷的是外壳里那几个字：ptr/len/cap），**外壳里指向的堆内存**是共享的。

要**真正拷贝数据**，两种路：

```cangjie
let c = a.clone()        // Array.clone()：新 backing store + 元素逐个复制
let v: VArray<Int64, $3> = [1, 2, 3]   // VArray：见下节
```

## 5. `VArray<T, $N>` 才是真正的"值数组"

Cangjie 另有一族 **`VArray<T, $N>`**——`$` 后跟一个 `Int64` 字面量表示**固定长度**、编译期就定死，**整个 backing store 内联在结构里**：

```cangjie
let va: VArray<Int64, $3> = [1, 2, 3]
var vb = va          // 连数据一起拷！
vb[0] = 99
// va[0] 仍然是 1
```

CI 输出（示例 E 行）：`VArray: va[0]=1 vb[0]=99`——与 §4 的 `Array` 表现**正好相反**。

**代价与限制**（官方明说）：
- 拷贝 = 复制整段数据 → 大长度用在性能敏感处不合适。
- `$N` 必须是**字面量**（编译期常量），不能是运行时值。
- 元素类型 `T` **不能含**：引用类型、enum、lambda（`CFunc` 除外）、未实例化泛型——因为"值数组要能被完整拷贝到栈/内联"这个前提不允许这些"带堆指针的东西"。

选哪个：**要长度动态、要常见 API（`.push`/`.size`/迭代）** 用 `Array`；**要小尺寸、固定长度、零堆分配、纯值语义** 用 `VArray`（比如 SIMD/寄存器向量、常量查找表）。

## 6. 浅拷贝穿透：struct 里的 class 字段

这是最容易忽略的一种"看似拷贝、其实共享"。`struct` 拷贝是"**逐字段全量拷**"，可**字段本身若是引用类型，拷的也只是那个指针**：

```cangjie
class Cfg { public var v: Int64 = 0; public init() {} }
struct Wrap { public let cfg: Cfg; public init(ic: Cfg) { this.cfg = ic } }

let c1 = Cfg()
let w1 = Wrap(c1)
var w2 = w1        // w2 是独立 struct；但 w2.cfg 和 w1.cfg 指向**同一个** Cfg
w2.cfg.v = 7
// w1.cfg.v 也是 7、c1.v 也是 7
```

CI 输出（示例 C 行）：`nested: w1.cfg.v=7 w2.cfg.v=7 c1.v=7`——**三个名字、一个对象**。

C++ 术语叫"浅拷贝"，Rust 术语叫 `Clone` 只对 `Copy` 字段真复制、别的靠各自实现。Cangjie 的 struct 拷贝 = "浅拷贝（按字段逐个拷值）"；字段是引用时，指针值被拷、**目标不拷**。要**深拷贝** 得手写。

## 7. 生命周期：值 vs 引用的"活多久"

- **值类型**：跟着它所在的**变量作用域**走——`main()` 里 `let p = Point(1)`，出了 `main` 就没了（栈）。
- **引用类型**：`Cfg()` 出来的对象在**堆上**，**由 GC 决定什么时候回收**——不是"函数返回即销毁"。

```cangjie
func make(): Cfg { return Cfg() }         // 局部变量"消失了"、堆上的 Cfg 依然活着
main(): Int64 { let c = make(); c.v = 1; println(c.v); return 0 }   // 1，正常
```

这就是"引用类型总在堆上"的含义。**别用 C++ 那种"离开作用域就析构"的心智**——Cangjie 类对象的生命周期跟作用域**解耦**、由 GC 判。

## 8. 终结器 `~init`：GC 时触发，**时机不可依赖**

`class` 可以定义 `~init() { ... }`——**当实例被 GC 回收时调用**（08 篇语法）。要点：

- **触发时机不确定**——取决于堆压力/GC 策略；不要靠 `~init` 关文件/释放 socket（下一节 §9）。
- **`open class` 里禁止 `~init`**——本篇实测：

  ```cangjie
  open class Cfg { public init() {}; ~init() { ... } }
  // error: finalizer is forbidden in class 'Cfg' that is open
  ```
  原因：`open` 允许被继承，子类可能延长对象生命周期、和终结器的"最后一次回收"心智冲突。
- 若**确实**要"析构语义"，用 `Resource` + `try-with-resources`（文章 21），那是**确定作用域边界**的。

> 官方 `class.html` 的 `~init` 示例里就用了 `import std.runtime.*` + `gc(heavy: true)` **强制**触发一次 GC 才能观察到——反过来说明**你不该指望它自己按点触发**。

## 9. 手动 GC：`std.runtime.gc`（承 8）

```cangjie
import std.runtime.*
gc()                 // 提示做一次轻量 GC
gc(heavy: true)      // 阻塞式重 GC（官方 class 篇同款）
```

（实测 `cjc --output-type staticlib` 通过。）用途：调试/演示时"我要看现在能不能回收"——**不是**性能调优开关。生产代码里频繁手动 `gc()` 反而伤吞吐。

## 10. 资源 ≠ 内存：GC 只保证内存

**Cangjie 有 GC，但 GC 只回收"仓颉堆上的对象"**——文件句柄、socket、锁、外部 C 库资源**不受 GC 保证按时释放**。想"作用域结束就释放"，走文章 21 的 `Resource` 接口 + `try-with-resources`：

```cangjie
try (f <- File.open("x.txt")) {     // 离开作用域一定 close，不看 GC 脸色
    ...
}
```

`~init` 只在**对象被 GC** 时才跑，可能推迟很久、也可能**进程退出都不跑**（官方 class 页原话："fail: obj is freed before gc!" 演示了这点）。**资源用 try、内存用 GC**，两条路不能混。

## 11. 所有权 / 借用？Cangjie 是"值 + 引用 + GC"

有 Rust 背景的人常问"仓颉有借用检查吗"。**1.0.5 里没有 Rust 那种生命周期 + 借用系统**——`cjc --help` 里有个 `--enable-borrows` 是**实验性**选项，不是默认。日常代码的心智模型是：

- **值类型（struct/enum/基础类型）**：赋值=拷贝，两边完全独立。
- **引用类型（class/Array/lambda）**：赋值=共享，两边看同一对象；生命周期由 GC 管。
- **没有 move、没有 `&mut`、没有 borrow-checker**——是**Java 风格 GC 语言**的心智，不是 Rust 风格。

（`--enable-borrows` 属于**未验证行为**，本篇不使用；细节看 1.0.5 手册的实验特性章节。）

## 12. 完整示例（一次跑通五条语义）

`047-value-ref-memory.cj`：

<!-- example: cangjie/047-value-ref-memory.cj -->
```cangjie
package mem

// 值类型 / 引用类型与内存管理原理示例（配合文章 44）。
// 演示的都是"赋值/传参时到底拷贝什么"——基础篇只讲"怎么写 struct/class"，
// 本篇讲"值/引用语义"的实测边界。所有输出稳定、Linux CI 逐行核对。

class Cfg {                        // 引用类型：class
    public var v: Int64 = 0
    public init() {}
    // ~init() { ... }              // 终结器：GC 触发、时机不确定，故示例不打印、只在正文讲
}

struct Point {                     // 值类型：struct
    public var x: Int64
    public init(x: Int64) { this.x = x }
}

struct Wrap {                      // 值类型外壳、里面装一个引用
    public let cfg: Cfg
    public init(ic: Cfg) { this.cfg = ic }
}

main(): Int64 {
    // A) struct 值类型：赋值即"字段全量拷贝"、两边独立
    let p1 = Point(1)
    var p2 = p1
    p2.x = 99
    println("struct-copy: p1.x=${p1.x} p2.x=${p2.x}")

    // B) class 引用类型：赋值即"共享同一对象"
    let c1 = Cfg()
    let c2 = c1                    // 同一个对象、两个引用
    c2.v = 42
    println("class-alias: c1.v=${c1.v} c2.v=${c2.v}")

    // C) struct 里的 class 字段：struct 拷贝是"浅拷贝"——字段仍是同一引用
    let w1 = Wrap(c1)
    var w2 = w1                    // 结构拷了、cfg 指针没换
    w2.cfg.v = 7
    println("nested: w1.cfg.v=${w1.cfg.v} w2.cfg.v=${w2.cfg.v} c1.v=${c1.v}")

    // D) Array：官方"内部只持元素引用"，赋值不拷 backing store
    let a = [1, 2, 3]
    var b = a
    b[0] = 99
    println("array: a[0]=${a[0]} b[0]=${b[0]}")

    // E) VArray<T,$N>：真正的值类型数组，赋值连 backing store 一起拷
    let va: VArray<Int64, $3> = [1, 2, 3]
    var vb = va
    vb[0] = 99
    println("VArray: va[0]=${va[0]} vb[0]=${vb[0]}")

    return 0
}
```

编译并运行（Linux）：

```shell
cjc 047-value-ref-memory.cj -o mem && ./mem
```

预期输出：

```text
struct-copy: p1.x=1 p2.x=99
class-alias: c1.v=42 c2.v=42
nested: w1.cfg.v=7 w2.cfg.v=7 c1.v=7
array: a[0]=99 b[0]=99
VArray: va[0]=1 vb[0]=99
```

## 13. 与其它语言心智对照

| 场景 | Cangjie | Rust | Java | C++ |
|---|---|---|---|---|
| `let y = x`（x 是 struct） | 全量拷贝 | `Copy` 才拷、否则 move | 值类型拷贝、引用共享 | 拷贝构造 |
| `let y = x`（x 是 class） | 共享引用 | 需 `.clone()` | 共享引用 | 默认拷构造、`std::shared_ptr` 才共享 |
| `let y = x`（x 是 `Array<T>`） | **共享 backing**（本文点） | `Vec` move 或 clone | `int[]` 共享 | `std::vector` 深拷 |
| 真值数组 | `VArray<T,$N>` | `[T; N]` | 无 | `std::array` |
| 释放 | GC + `~init`(时机不可靠) | RAII/`Drop` | GC + `finalize`(不推荐) | RAII |
| 借用作普通模式 | ❌（实验性） | ✅ 核心 | ❌ | 部分 |

**心智**：Java 背景基本无缝；Rust 背景要把"move/borrow"清空——Cangjie 是"GC + 双类型"，不是"零成本所有权"；C++ 背景**别指望 RAII 关资源**（`~init` 不可靠），走 try-with-resources。

## 14. FAQ

### Q1: `let y = x` 到底何时拷贝？

看 `x` 的**类型**：值类型（struct/enum/基础/VArray/元组）拷整个；引用类型（class/`Array`/接口/lambda）只拷指针。**没有"move"**——都是"按类型决定拷贝粒度"。

### Q2: Array 到底是值类型还是引用类型？

**名义是 struct（值类型），行为像引用**。官方说"内部持有的只是元素的引用"——`Array` 变量本身是 struct、赋值拷结构；但它内部那几个指针指向堆上的 backing store，所以**元素共享**。要真值数组走 `VArray<T, $N>`。

### Q3: 我改了一个变量，另一个跟着变，是不是 bug？

看类型。class/Array 就是这语义、**不是 bug**。想让两边独立：class 用 `.clone()` / 自定义复制构造、Array 用 `.clone()`、或者改用 `VArray`。

### Q4: `~init` 什么时候被调？能用来关文件吗？

**不能**。`~init` 在**GC 决定回收时**触发，可能很晚、也可能到进程退出都不跑。**资源释放**走 `Resource` + `try-with-resources`（文章 21），时机**由作用域决定**。

### Q5: 那 `open class` 里为啥 `~init` 被禁？

`open` = 允许被继承 = 子类可能持有额外状态、生命周期不好界定。终结器语义要求"最后一次回收时触发"，和继承链的"父/子析构顺序"纠缠——干脆在 `open` 上禁掉，避免歧义。

### Q6: struct 拷贝很深还是浅？

**浅**：按字段逐个拷值。**字段是引用类型时，指针值被拷、目标不拷**（本文 §6 nested 例子）。想深拷自己写 `clone`，递归拷每个引用字段。

### Q7: GC 能不能关？想手动 malloc/free 呢？

**没有 malloc/free**——Cangjie 1.0.5 是纯 GC 语言。`std.runtime.gc` 只能**触发** GC、不能关。真要走"C 层手动管理"，用 FFI（承 29 篇）在 C 侧做，仓颉这侧不管。

### Q8: `VArray` 长度能传参吗？

不能。`$N` 语法位置要求**Int64 字面量**——`VArray<Int64, $someVar>` 通不过编译；长度是**类型系统**的一部分（承 41 篇泛型不变），编译期就锁死。要动态长度数组 → `Array`。

## 15. 总结

1. **两分法**：值类型（struct/enum/基础/VArray/元组）**赋值全量拷**；引用类型（class/接口/`Array`/lambda）**只拷指针**。
2. **`Array` 是"名值实引用"**——官方明说内部只持元素引用；赋值**不拷 backing**；要真值数组用 `VArray<T,$N>`（长度是编译期字面量、元素不能含引用/枚举/lambda）。
3. **struct 拷贝是浅拷**：字段是引用时，两边**共享那个目标**（本文 §6）。深拷自己写。
4. **生命周期解耦于作用域**：class 对象在堆、由 GC 判；`make()` 返回后堆对象仍活着。
5. **`~init` 终结器时机非确定**（不应用于资源释放）；**`open class` 禁 `~init`**（实测）。
6. **`std.runtime.gc`**：`gc()` / `gc(heavy: true)`，是调试工具不是性能开关。
7. **GC 只管内存、不管资源**：文件/socket 走 `Resource` + `try-with-resources`（21 篇）。
8. 默认**没有 Rust 式借用**（`--enable-borrows` 实验性）；Cangjie 是"值 + 引用 + GC"。

## 参考资料

1. 类（引用类型 + `~init` 终结器 + GC 手动触发示例）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/class_and_interface/class.html
2. 结构体（值类型语义）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/struct/create_instance.html
3. 数组类型（`Array` 内部只持元素引用；`VArray<T, $N>` 真值数组）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/array.html
4. 类型系统（`struct` 不进子类型格，本篇解释根因）：articles/41-type-system.md
5. 资源管理（`Resource` + `try-with-resources`，本篇 §10 强调）：articles/21-resource-management.md
6. 泛型类型子类型（`VArray<T,$N>` 与 `Array<T>` 的类型关系）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/generic/generic_subtype.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写。所有值/引用语义（struct 全量拷、class 共享、Array 别名、VArray 深拷、open class 禁终结器）均本地 `cjc` 实测；`~init` 与 GC 关系、`std.runtime.gc` 与"Array 内部只持元素引用"官方原文直引。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
