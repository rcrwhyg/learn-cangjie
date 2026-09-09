# 仓颉类型系统：静态强类型、类型格、名义子类型与类型安全保证

> **摘要**: 前面 03/08/10/11/18/20 篇讲了"怎么写类型"——本篇讲"**编译器为什么这样管你**"。视角从"用法"切到"**类型系统作为一个模型**"：静态 & 强类型（**无隐式转换**，实测 `Int64→Int32` 与 `Int64+Float64` 都直接编译错）、类型格里的**顶类型 `Any` 与底类型 `Nothing`**、**名义子类型**（只有 `class`/`interface` 进格子，`struct` 不进）、`as` 返回 `Option<T>`（**1.0.5 里没有 `as?`**——纠正常见直觉）、**泛型不变性**（`Box<Int64>` 不是 `Box<Any>`，无 `out`/`covariant` 关键字）、以及**三条编译期安全保证**（穷尽性 / Option 不自动解包 / 编译期溢出检测）。所有原理都在 1.0.5 本地 `cjc` 实测；示例 `044-type-system.cj` 把 9 条原理拧成一段可跑代码，Linux CI 核对运行输出。

## 前置知识

- 已看完基础篇：03 变量与类型、08 类、10 枚举、11 模式匹配、18 泛型、20 异常与 Option
- 已完成《字符串与字符》《集合》《模式匹配原理预备》——本篇不再教语法，只讲**规则**
- 已完成《cjc 编译器》（文章 35）——本篇讲到的诊断格式（`mismatched types ... expected/found`）与整型溢出策略直接承接

> **本篇与基础篇的分工**：基础篇说"`let x: Int64 = 5` 这样写"；本篇说"**为什么不能 `let y: Int32 = x` 这样写**"——从编译器实证的规则反推类型系统的模型。

## 1. 静态 & 强类型：两条断言，全部实测

**"静态"**：类型决策全部在编译期完成，运行时不再改变。证据——**编译期就报算术溢出**（不是运行时才报）：

```cangjie
main(): Int64 { return 9223372036854775807 + 1 }
```

`cjc` 直接：

```text
error: arithmetic operation '+' overflow
```

（`Int64.max + 1` 常量表达式在编译期就折叠、并按文章 35 的默认 `--int-overflow=throwing` 策略判溢出错。运行时才管的语言不可能给出这个错。）

**"强类型 = 无隐式转换"**：`cjc` **不接受**任何"数字自动变宽/变窄/转符号"。实测两条：

```cangjie
// (a) 把 Int64 赋给 Int32
let a: Int64 = 1
let b: Int32 = a           // error: mismatched types, expected 'Int32', found 'Int64'
```

```cangjie
// (b) 不同类型混算
let x: Int64 = 1
x + 1.0                    // error: invalid binary operator '+' on type 'Int64' and 'Float64'
```

**唯一通路是显式 `T(e)` 构造**：`Int32(x)` / `Int64(f)` / `Float64(n)`（官方《类型转换》页一致）。`Int64(3.9)` 按截断得 `3`（同页示例：`Int64(1024.1024) = 1024`）。**没有** `x.toInt32()` / `x.convert<T>()` 这类方法（实测 `undeclared identifier`）。

> **💡 为什么这么"轴"**：C 的隐式数值提升、Java 的 `int→long` 隐式拓宽、JS 的 `1 + "2"`，代价是"读代码看不出实际类型"。仓颉把"每一次跨界"都写成 `Int32(x)`，读代码就一定能看出**这里发生了一次可能损失精度的转换**——这是它拿"打字多"换"阅读零歧义"的显式取舍。

## 2. 类型格：顶类型 `Any` 与底类型 `Nothing`

把"是子类型"看成偏序，仓颉的类型集合有顶和底两端。

- **顶类型 `Any`**：所有类型的父。任何值都能装进 `Any`：`let x: Any = 1` 编译通过（实测）；`Any` 参数像"入口漏斗"。
- **底类型 `Nothing`**：**没有值**（唯一 inhabited 方式是永不正常返回），是**所有类型的子**。任何"期望 T"的位置都能塞 `Nothing` 表达式：

```cangjie
func die(msg: String): Nothing { throw Exception(msg) }
main(): Int64 {
    let x: Int64 = die("boom")   // OK：Nothing 出现在期望 Int64 的位置
    return x
}
```

编译器知道 `die(...)` **不会回来**，所以不会抱怨"函数缺 return"——这就是底类型的用处。

> **⚠️ `Nothing` 与 `Unit` 别混**：`Unit`（承基础篇）是"有且仅有一个值 `()`"的类型；`Nothing` 是"没有任何值"的类型。前者是"什么都不返回"，后者是"根本不会返回"。

## 3. 名义子类型（nominal）：只有 class / interface 进格子

**名义 = 由"声明说 A 是 B 的子"决定**，跟"A、B 有哪些字段方法"无关。这一点比结构类型（TypeScript、Go 隐式接口）严格。

### 3.1 谁能当"基"

`class` 之间用 `class D <: Base { }`，`class` 实现 `interface` 用 `class C <: Iface { }`。**`struct` 不在子类型关系里**——实测：

```cangjie
struct S { public var x: Int64; public init(x: Int64) { this.x = x } }
class C <: S { }
// error: class 'C' can only inherit a class or implement interfaces
```

含义：`struct` 是纯值类型（复制语义，见文章 44 深挖），没有多态方法分派，也就没有"子类型"可言。

### 3.2 override 需要 `open`

基类想让方法被覆盖，**必须写成 `public open func`**——只写 `public func` 子类 `override` 编译失败：

```cangjie
open class A { public func s(): String { "a" } }
class B <: A { public override func s(): String { "b" } }
// error: cannot override function 's'
```

改成 `public open func s()` 就通过。**"开"的语义要显式**——这避免"作者本不想让你覆盖、你偷偷覆盖了"的脆弱继承。

### 3.3 上转免费、下转要证明

- **上转**（子 → 父）是子类型的定义本身，赋值即完成：`let a: Animal = Dog()`（不写 cast）。
- **下转**（父 → 子）编译器不保证成立，走 `is` / `as`：

  - `e is T` → `Bool`：运行时 `e` 的动态类型是 `T` 或其子 → `true`。
  - `e as T` → **`Option<T>`**：成功 `Some(e)`，失败 `None`。

> **⚠️ 1.0.5 只有 `as`、没有 `as?`**——`as` 本身就返回 `Option`。Kotlin/Rust/其他"两个下转操作符（抛 / 返 Option）"的语言习惯在这里不适用。要**失败即抛**的写法，用 `.get()`（或 `unwrap()`）取 Option；要**成功继续、失败另一支**，直接 `match (x as T) { case Some(v) => ...; case None => ... }`。这个反直觉点官方《类型转换》页明确写了：`let b = 1 as String   // b = Option<String>.None`。

### 3.4 interface 也是名义

`class C <: Iface { }` 显式声明实现，**不会因为 C 恰好有 iface 要求的成员就自动算实现**。这让"接口实现"是一等可查的声明，不是巧合。

## 4. 泛型不变性：`Box<Int64>` 与 `Box<Any>` 是两个不搭的类

直觉常以为"`Int64` 是 `Any` 的子，那 `Box<Int64>` 也是 `Box<Any>` 的子"——**仓颉不是这样**。实测：

```cangjie
class Box<T> { public var content: T; public init(v: T) { this.content = v } }
main(): Int64 {
    let b = Box<Int64>(7)
    let a: Box<Any> = b        // error: mismatched types
    return 0
}
```

同参数才通融：`let a: Box<Int64> = b` 编译通过。

**为什么默认不变**：`Box<T>` 既能读也能写。假设它协变，那 `a.content = "str"` 会通过——但 `b.content` 依然是 `Int64` 视图，内存里却躺了 String 的位模式——类型系统崩了。这是所有"带可变状态 + 泛型"语言的共同底线（Java `ArrayList<Object>` 也不是 `ArrayList<Object>` 的子）。

**声明点变体也没有**：`interface Producer<out T>`、`interface Producer<T covariant>` 这些写法在 1.0.5 **不能解析**（实测报 `unclosed delimiter` / `expected '{' or '<'`）——想用协变/逆变就得靠"包一层 `interface` 手写方法级变型"，或换用函数类型 `(Nothing) -> T` 之类的表达。**这是 1.0.5 的现实**，别按 Kotlin/Rust 直觉找关键字。

## 5. 类型安全的三条编译期保证

前两条基础篇已经"用"过，这里是**为什么编译器会管**的原理层证据。

### 5.1 穷尽性（exhaustiveness）：`match` 少一支编译失败

```cangjie
enum E { | A | B }
main(): Int64 { let e = E.A; return match (e) { case A => 1 } }
// error: non-exhaustive patterns
```

编译器把 `match` 当"**必须给每个可能的构造器一个答案**"来处理——少一支 = 有输入走到"无定义" = 编译期直接拒。这是模式匹配能替代 `if-else if-else throw` 的根因。

### 5.2 Option 不自动解包：`Option<Int64> + Int64` 是非法运算

```cangjie
main(): Int64 { let x: Option<Int64> = Some(5); return x + 1 }
// error: invalid binary operator '+' on type 'Enum-Option<Int64>' and 'Int64'
```

**没有"Optional 自动 unwrap"**。想拿里面的值只有：`match`、`.get()`（失败抛）、`.getOrElse(v)`、`.map(f)`。这条把"空值可能"编码进类型，让"忘了判空"变成**编译错**而不是运行时 NPE。

### 5.3 溢出可编译期检测：`max + 1` 不是运行时才报

见第 1 节。当操作数是编译期常量、结果超出目标类型范围，`cjc` **直接在编译期报错**（不是运行时抛）；不可静态判定的部分按 `--int-overflow` 策略处理（`throwing` 默认 → 运行时抛；`wrapping`/`saturating` 是显式选择的语义）。

## 6. 类型错误诊断怎么读（与 cjc 诊断合流，承 35 篇）

`cjc` 的类型错误都是同一个骨架：

```text
error: <kind-of-error>
  |
N |  <源代码行>
  |     ^^^^ <expected ... / found ...>
```

**四类高频 kind**（都在本篇实测过）：

| 诊断 | 什么在错 | 修法 |
|---|---|---|
| `mismatched types` + `expected 'X', found 'Y'` | 赋值/传参类型不对 | 显式 `X(expr)` 或改类型 |
| `invalid binary operator '+' on type 'A' and 'B'` | 混类型算术 / Option 上算 | 转同类型 / `match` 解包 |
| `array literal type cannot be inferred` | `let v = []` 空数组 | 写 `let v: Array<Int64> = []` |
| `non-exhaustive patterns` | `match` 少分支 | 补齐或加 `_` |

看到这些**先别去搜"怎么让编译器闭嘴"**——它就是在**告诉你类型系统的规则被触到了**。

## 7. 完整示例（把 6 节拧成一段可跑代码）

`044-type-system.cj`——同时用满：`T(e)` 显式转换、`Any`/`Nothing`、名义子类型与 `open`、`is` + `as`(→Option) 组合、泛型不变性、Option 显式 match、穷尽性：

<!-- example: cangjie/044-type-system.cj -->
```cangjie
// 仓颉类型系统原理示例（配合文章 41）。演示的都是"编译器背后强制的规则"，
// 与基础篇"怎么声明类型"不重叠：静态类型/推断、Any 顶类型、Nothing 底类型、
// 名义子类型与安全下转(is + as 返回 Option)、泛型不变、Option 不自动解包、
// 穷尽性检查、编译期溢出检测。
package typesys

// —— 名义子类型：只有 class / interface 进子类型格；base 方法要 open 才可 override ——
open class Animal {
    public open func sound(): String { "..." }
}
class Dog <: Animal {
    public override func sound(): String { "woof" }
}
class Cat <: Animal {
    public override func sound(): String { "meow" }
}

// Any 是顶类型：任何值都能进来。1.0.5 里没有 as?——`as T` 本身就返回 Option<T>。
// is T 判类型；as T 安全下转（成功 Some、失败 None）。
func describe(x: Any): String {
    if (x is Dog) { return "dog" }
    if (x is Cat) {
        match (x as Cat) {                 // as Cat 直接是 Option<Cat>
            case Some(c) => return "cat says ${c.sound()}"
            case None => return "impossible"
        }
    }
    return "not-an-animal"
}

// Nothing 是底类型：永不正常返回的函数——可出现在任何"期望某类型"的位置。
func impossible(msg: String): Nothing {
    throw Exception(msg)
}
func mustBePositive(v: Int64): Int64 {
    // else 分支是 Nothing，自动补到期望 Int64 的位置
    return if (v > 0) { v } else { impossible("non-positive") }
}

// 泛型不变：Box<Int64> 不是 Box<Any>（正文用编译错坐实；这里只做正确用法）
class Box<T> {
    public var content: T
    public init(v: T) { this.content = v }
}

// Option 不自动解包：只有 match 才把里面值掏出来
func firstEven(xs: Array<Int64>): Option<Int64> {
    for (x in xs) {
        if (x % 2 == 0) { return Some(x) }
    }
    return None
}

// 穷尽性：enum 少写一支就编译失败（这里写全，能过）
enum Status {
    | Ok
    | Warn
    | Error
}
func statusText(s: Status): String {
    return match (s) {
        case Ok => "ok"
        case Warn => "warn"
        case Error => "error"
    }
}

main(): Int64 {
    // 静态类型 + 推断 + 显式转换（无隐式收窄；数值转换走 T(e)）
    let n = 42                             // 推断 Int64
    let f = 3.9                            // 推断 Float64
    println("n=${n}, trunc=${Int64(f)}")   // Int64(3.9) 显式转 → 3
    // 名义子类型：父类型引用可指向子对象，方法分派看实际类型
    let a: Animal = Dog()
    println("animal: ${a.sound()}")        // woof
    // Any 顶类型 + is / as(→Option)
    println("desc Dog=${describe(Dog())}")
    println("desc Cat=${describe(Cat())}")
    println("desc Int=${describe(42)}")
    // Nothing 底类型
    println("positive=${mustBePositive(5)}")
    // 泛型（同参数才能赋值——因为 Box<Int64> 与 Box<Any> 之间没有子类型）
    let b = Box<Int64>(7)
    println("box=${b.content}")
    // Option 必须 match
    match (firstEven([1, 3, 8, 9])) {
        case Some(v) => println("even=${v}")
        case None => println("even=none")
    }
    // 穷尽 match
    println("status=${statusText(Status.Warn)}")
    return 0
}
```

编译并运行（Linux）：

```shell
cjc 044-type-system.cj -o ts && ./ts
```

预期输出：

```text
n=42, trunc=3
animal: woof
desc Dog=dog
desc Cat=cat says meow
desc Int=not-an-animal
positive=5
box=7
even=8
status=warn
```

## 8. 与其它语言类型系统对照

| 维度 | 仓颉 | Rust | Java | TypeScript |
|---|---|---|---|---|
| 静/动 | 静态 | 静态 | 静态 | 静态+结构类型 |
| 隐式数值转换 | ❌ 全无 | ❌ 全无（as 显式） | 拓宽 int→long 允许 | 允许 |
| 顶类型 | `Any` | `dyn Any`/trait object | `Object` | `unknown` |
| 底类型 | `Nothing` | `!` (never) | 无 | `never` |
| 子类型 | **名义**（class/interface） | 无子类型（trait 实现） | 名义 | **结构** |
| 泛型变型 | **默认不变、无声明点关键字** | 无子类型 | `<T extends X>`、`? extends` | 结构化推导 |
| 穷尽性 match | ✅ 编译错 | ✅ 编译错 | ❌ 仅告警 | 依赖 `switch(true)` |
| Option/Nullable | Option 显式解包 | Option 显式 | null 引用类型不设防 | `strictNullChecks` |

**心智迁移**：
- **从 Rust**：`Nothing`↔`!`、`Option`↔`Option`、`as` 返回 `Option` 反而**比 Rust `as` 更严**（Rust `as` 是数值截断、这里 `as` 是运行期下转 + Option 包装）。
- **从 Java**：把 `Object`/`instanceof`/`(T)e` 一整套换成 `Any`/`is`/`as T` 返 `Option`——**再也拿不到"抛 ClassCastException"这条路**。
- **从 TS**：TS "structural typing"的心智得整体丢掉——仓颉只看"声明上是不是"。

## 9. FAQ

### Q1: 为什么 `let a: Int32 = someInt64` 不给我自动截断？

它就是不肯"悄悄损失信息"。截断是**语义动作**，必须写成 `Int32(someInt64)`——让 code review 一眼看得见"这里发生了截断"。

### Q2: `as` 是不是就是别的语言的 `as?`？

对，**1.0.5 只有一个 `as`、返回 `Option<T>`**。想"失败抛"就 `.get()`；想"失败另一支"就 `match`。Kotlin 的 `as` / `as?` 二分法在这里是**多余的**。

### Q3: `Nothing` 和 `Unit` 到底差在哪？

`Unit` 是"**有一种值** `()`"（函数什么都不返但正常返回）；`Nothing` 是"**没有值**"（`throw` / 无限循环 / `process.exit`——永不正常返回）。`Nothing` 能顶替任何期望类型的位置，`Unit` 不能。

### Q4: 为什么 `Box<Int64>` 不能塞 `Box<Any>`？

因为 `Box<T>` 允许写（`b.content = something`）。协变会让"写"这条路破坏类型安全。想表达"能产出但不能写"，用 `interface Reader { func read(): Any }` 手写；不要用泛型参数直接顶替。

### Q5: struct 能不能实现 interface？

不能。实测：`class` 才能 `<: Iface`；`struct` 不在子类型格子里。要给"值类型 + 多态"就外层用 `enum` 或 `class` 包一层。

### Q6: 我 override 一个方法一直报 `cannot override function`？

大概率基类那个方法**忘了 `open`**。`public func` 是"关着的"，只有 `public open func` 才能被子类 `override`。设计意图：让"可覆盖"变成需要作者显式许可的能力。

### Q7: 类型报错了，能不能加个 `@Suppress` 之类绕过？

不能——这些错误是**类型系统本身**的一部分，不像 lint 有开关。修的方向只有一个：把类型改成它要的。这是"强类型"的意思。

## 10. 总结

1. **静态 & 强类型**：一切类型决策在编译期；**无隐式数值转换**（`T(e)` 是唯一通路）；编译期就能报溢出。
2. **类型格**：`Any` 顶（万物归它）、`Nothing` 底（Nothing 出现在任何期望类型处都合法）。
3. **名义子类型**：只有 `class`/`interface` 进格子；`struct` **不是**任何类型的子；`open func` 才可 `override`；下转用 `is` + `as`（`as` 返回 `Option`，**1.0.5 没有 `as?`**）。
4. **泛型不变**：`Box<Int64>` 与 `Box<Any>` 之间无子类型；无 `out`/`covariant` 声明点关键字。
5. **编译期安全三条**：穷尽 `match`、`Option` 不自动解包、编译期溢出检测——不是运行时坑、是编译错。
6. **诊断即规则**：`mismatched types` / `invalid binary operator` / `array literal cannot be inferred` / `non-exhaustive patterns` 是类型系统**主动告诉你它被违反了**。

## 参考资料

1. 类型转换（`is` / `as` 与数值 `T(e)`）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/class_and_interface/typecast.html
2. 子类型关系（名义子类型）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/class_and_interface/subtype.html
3. 泛型类型的子类型关系（不变性）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/generic/generic_subtype.html
4. `Nothing` 类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/nothing.html
5. 模式的 Refutability（穷尽性/反驳性）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/pattern_refutability.html
6. Option 类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/option_type.html
7. 整数类型（无隐式转换）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/integer.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写。所有编译错与运行时行为均本地 `cjc` 实测；`as` 返回 Option、无 `as?`、无声明点变体、struct 不进子类型格等反直觉点均以本地实测 + 官方文档双向核对。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
