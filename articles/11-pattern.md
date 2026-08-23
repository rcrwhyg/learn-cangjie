# 仓颉模式匹配

> **摘要**: 模式匹配是仓颉中处理多分支逻辑与解构复合数据的重要机制。本文依据仓颉 1.0.5 LTS 官方文档，系统介绍仓颉支持的六种模式（常量、通配符、绑定、Tuple、类型、enum），`match` 表达式的语法、模式守卫、穷尽性检查与类型推导，以及模式在变量定义、`for-in` 表达式和无匹配值 `match` 中的应用，帮助读者掌握模式匹配的全部形态。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已了解变量、函数、控制流
- 已了解 `enum` 类型与构造器
- 已完成《仓颉枚举类型 enum》

## 1. 模式概览

模式（Pattern）是 `match` 表达式、`let` 变量定义和 `for-in` 表达式中用来匹配和解构值的语法形式。仓颉支持以下六种模式：

| 模式 | 语法 | 用途 |
|------|------|------|
| 常量模式 | `0` / `"text"` / `r'A'` / `true` | 匹配特定值 |
| 通配符模式 | `_` | 匹配任意值，不绑定 |
| 绑定模式 | `id` | 匹配任意值，并绑定到变量 |
| Tuple 模式 | `(p1, p2, ...)` | 匹配并解构元组 |
| 类型模式 | `id: Type` / `_: Type` | 匹配运行时类型并转换 |
| enum 模式 | `Name(p1, p2, ...)` | 匹配 enum 构造器并解构参数 |

多种模式可以**嵌套组合**，特别是 Tuple 模式和 enum 模式可以内嵌其他模式。

## 2. 常量模式

常量模式可以是整数字面量、浮点字面量、字符字面量、布尔字面量、字符串字面量（**不支持**字符串插值）、`Unit` 字面量。匹配成功的条件是待匹配值与常量值相等。

多个常量模式可用 `|` 连接，表示"或"：

```cangjie
func gradeOf(score: Int64): String {
    match (score) {
        case 0 | 10 | 20 | 30 | 40 | 50 => "D"
        case 60 => "C"
        case 70 | 80 => "B"
        case 90 | 100 => "A"
        case _ => "Not a valid score"
    }
}
```

> **注意**：常量模式的目标类型为 `Rune` 时，`Rune` 字面量（如 `r'A'`）和单字符字符串字面量（如 `"A"`）都可使用。

## 3. 通配符模式

通配符模式用下划线 `_` 表示，匹配任意值但不绑定变量。常用于最后一个 `case` 兜底：

```cangjie
match (x) {
    case 0 => "zero"
    case _ => "other"   // 通配符，匹配其他所有情况
}
```

通配符模式**只**能单独使用，不能嵌套在其他模式内。

## 4. 绑定模式

绑定模式用标识符 `id` 表示，匹配任意值并将其与 `id` 绑定，在 `=>` 之后可通过 `id` 访问：

```cangjie
let y = match (x) {
    case 0 => "zero"
    case n => "x = ${n}"   // n 绑定非 0 的值
}
```

绑定模式等同于引入一个**不可变**变量（作用域从引入处到该 case 结尾），因此 `=>` 之后不能修改 `n`。

> **⚠️ 注意**：
> - 使用 `|` 连接多个模式时**不能**使用绑定模式：`case x | y =>` 报错
> - 绑定模式也不能嵌套出现在其他模式中
> - 当 identifier 与 enum 构造器同名时，按 enum 模式处理（不是绑定模式）

## 5. Tuple 模式

Tuple 模式用于匹配并解构元组值，语法为 `(p_1, p_2, ..., p_n)`，其中 `p_i` 是模式：

```cangjie
let greeting = match (person) {
    case ("Bob", age) => "Bob is ${age}"
    case ("Alice", age) => "Alice is ${age}"
    case (name, 100) => "${name} is 100"
    case _ => "unknown"
}
```

元组长度需要匹配（`n >= 2`），且每个位置上的值都要能匹配对应的子模式。

## 6. 类型模式

类型模式用于判断值的运行时类型是否是某个类型的子类型。语法有两种：

- `_: Type`：匹配并转换类型，不绑定
- `id: Type`：匹配并转换类型，同时绑定到 `id`

```cangjie
open class Base {
    public var a: Int64 = 10
    public init() { a = 10 }
}
class Derived <: Base {
    public init() { a = 20 }
}

func test(d: Base): Int64 {
    match (d) {
        case b: Base => b.a          // 总是匹配，返回 10 或 20
        case _: Derived => 999       // 永远不会匹配，d 已经是 Base
        case _ => 0
    }
}
```

类型模式会触发**运行时类型检查**和**类型转换**。当类型不匹配时，模式失败，匹配继续往下。

## 7. enum 模式

enum 模式用于匹配 enum 类型的实例，语法与 enum 构造器类似：

```cangjie
enum RGBColor {
    | Red(UInt8)
    | Green(UInt8)
    | Blue(UInt8)
}

let s = match (c) {
    case Red(v) => "red = ${v}"
    case Green(v) => "green = ${v}"
    case Blue(v) => "blue = ${v}"
}
```

无参构造器用 `case Red` 匹配，有参构造器用 `case Red(v)` 匹配并解构参数。enum 类型的前缀可以省略（`RGBColor.Red` 简写为 `Red`）。

> **⚠️ 注意**：使用 `|` 连接多个 enum 模式时，每个模式**不能**引入新变量，且必须独立。

## 8. 模式守卫（pattern guard）

模式守卫在 `case` 模式的后面用 `where` 子句指定额外条件，要求一个 `Bool` 类型的表达式：

```cangjie
enum RGBColor {
    | Red(Int16)
    | Green(Int16)
    | Blue(Int16)
}

let cs = match (c) {
    case Red(r) where r < 0 => "Red = 0"
    case Red(r) => "Red = ${r}"
    case Green(g) where g < 0 => "Green = 0"
    case Green(g) => "Green = ${g}"
    case Blue(b) where b < 0 => "Blue = 0"
    case Blue(b) => "Blue = ${b}"
}
```

模式守卫仅在模式**已经匹配**后再判断条件，条件为 `true` 才执行该 case。

## 9. match 表达式

### 9.1 定义

`match` 表达式对值进行模式匹配。语法：

```cangjie
let result = match (value) {
    case pattern1 => expr1
    case pattern2 where cond => expr2
    case _ => exprDefault
}
```

`match` 执行时依次将 `value` 与每个 `case` 模式匹配：

- 模式匹配成功且 `where` 条件满足（若有）时，执行 `=>` 之后的表达式并**退出** match
- 模式匹配失败时，继续下一个 case
- match 保证一定存在匹配的 case（编译器会做穷尽性检查）

### 9.2 穷尽性检查

`match` 必须穷尽所有可能的值，否则编译报错。确保穷尽的方式是：

1. 覆盖 enum 的所有构造器
2. 或在最后使用通配符模式 `_` 兜底

```cangjie
enum T { | Red | Green | Blue }

// 错误：未覆盖 Blue
match (a) {
    case Red => 0
    case Green => 1
}

// 正确：覆盖所有
match (a) {
    case Red => 0
    case Green => 1
    case Blue => 2
}

// 正确：用 _ 兜底
match (a) {
    case Red => 0
    case _ => 1
}
```

> **注意**：non-exhaustive enum（带 `...` 构造器）必须用 `case _` 或绑定模式兜底。

### 9.3 无匹配值的 match

不带值的 `match` 等价于 `if-else if-else` 链，case 后的表达式为 `Bool` 类型：

```cangjie
let n: Int64 = -3
match {
    case n > 0 => println("positive")
    case n < 0 => println("negative")
    case _ => println("zero")
}
```

无匹配值的 match 不再使用模式，也没有 pattern guard，case 后的表达式求值为 `true` 时执行对应分支。

### 9.4 match 表达式的类型

- **上下文有明确类型**时：要求每个 case 的 `=>` 之后类型是上下文类型的子类型
- **无上下文类型**时：match 的类型是所有 case `=>` 类型的最小公共父类型
- match 表达式的值未被使用时：类型为 `Unit`，各分支类型无最小公共父类型要求

```cangjie
// 上下文类型明确：要求 String
let s: String = match (x) {
    case 0 => "zero"
    case _ => "other"
}

// 上下文无类型：推导为各分支的公共父类型
let v = match (x) {
    case 0 => 0      // Int64
    case _ => "x"    // String
}  // 类型为 Any
```

## 10. 模式在其他位置的使用

模式除了在 `match` 中使用外，还可用在变量定义、`for-in` 表达式、`if`/`while` 条件中。**只有 irrefutable（不可失败）的模式**才能用在 `let` 和 `for-in` 中，包括：通配符模式、绑定模式、irrefutable Tuple 模式、irrefutable enum 模式。

### 10.1 变量定义中的模式

```cangjie
let _ = 100                       // 通配符：忽略值
let x = 100                       // 绑定模式
let (x, y) = (100, 200)           // Tuple 模式：解构成两个变量
let Red(r) = Red(42)              // enum 模式：解构 enum 值
```

### 10.2 for-in 表达式中的模式

```cangjie
for (i in 1..5) { println(i) }
for ((i, j) in [(1, 2), (3, 4)]) { println("${i + j}") }
for (Red(r) in [Red(10), Red(20)]) { println(r) }
```

`if` 表达式与 `while` 表达式的条件中也可以使用模式（详见 `let pattern` 的"条件"用法）。

## 11. 一个完整示例

本示例组合了六种模式、模式守卫、嵌套组合、变量定义与 for-in 中的模式、无匹配值 match：

<!-- example: cangjie/015-pattern.cj -->
```cangjie
// 模式匹配示例
// 演示：常量模式、通配符模式、绑定模式、Tuple 模式、类型模式、enum 模式、
// 嵌套组合、模式守卫、变量定义中的模式、for-in 中的模式、无匹配值 match

// 1) 表达式 enum（用于 eval）
enum Expr {
    | Num(Int64)
    | Add(Expr, Expr)
    | Sub(Expr, Expr)
}

// 2) 命令 enum（用于嵌套模式）
enum TimeUnit {
    | Year(UInt64)
    | Month(UInt64)
}

enum Command {
    | SetTimeUnit(TimeUnit)
    | GetTimeUnit
    | Quit
}

// 3) 颜色 enum（用于模式守卫）
enum RGBColor {
    | Red(Int16)
    | Green(Int16)
    | Blue(Int16)
}

// 4) 类型模式所依赖的类层级
open class Animal {
    public var name: String
    public init(name: String) {
        this.name = name
    }
}

class Dog <: Animal {
    public init() { super("Dog") }
}

class Cat <: Animal {
    public init() { super("Cat") }
}

// 计算表达式
func eval(e: Expr): Int64 {
    match (e) {
        case Num(n) => n
        case Add(a, b) => eval(a) + eval(b)
        case Sub(a, b) => eval(a) - eval(b)
    }
}

// 描述颜色（含模式守卫）
func describeColor(c: RGBColor): String {
    match (c) {
        case Red(r) where r < 0 => "Red = 0"
        case Red(r) => "Red = ${r}"
        case Green(g) where g < 0 => "Green = 0"
        case Green(g) => "Green = ${g}"
        case Blue(b) where b < 0 => "Blue = 0"
        case Blue(b) => "Blue = ${b}"
    }
}

// 等级评定：使用函数避免常量传播导致误报
func gradeOf(score: Int64): String {
    match (score) {
        case 0 | 10 | 20 | 30 | 40 | 50 => "D"
        case 60 => "C"
        case 70 | 80 => "B"
        case 90 | 100 => "A"
        case _ => "Not a valid score"
    }
}

func isZero(x: Int64): String {
    match (x) {
        case 0 => "zero"
        case n => "x is not zero and x = ${n}"
    }
}

func greet(person: (String, Int64)): String {
    match (person) {
        case ("Bob", age) => "Bob is ${age}"
        case ("Alice", age) => "Alice is ${age}"
        case (name, 100) => "${name} is 100"
        case _ => "unknown"
    }
}

func classify(a: Animal): String {
    match (a) {
        case d: Dog => "Dog named ${d.name}"
        case c: Cat => "Cat named ${c.name}"
        case _: Animal => "Other animal"
    }
}

func handleCommand(cmd: Command): String {
    match (cmd) {
        case SetTimeUnit(Year(y)) => "Set year ${y}"
        case SetTimeUnit(Month(m)) => "Set month ${m}"
        case GetTimeUnit => "Get unit"
        case Quit => "Quit"
    }
}

main() {
    // 1) 常量模式 + | 组合 + 通配符兜底
    let level = gradeOf(85)
    println("level = ${level}")

    // 2) 绑定模式
    let desc = isZero(-10)
    println(desc)

    // 3) Tuple 模式
    let person = ("Alice", 30)
    println(greet(person))

    // 4) enum 模式 + 模式守卫
    println("color = ${describeColor(RGBColor.Red(200))}")
    println("color = ${describeColor(RGBColor.Blue(-50))}")

    // 5) 类型模式
    let animals: Array<Animal> = [Dog(), Cat(), Dog()]
    for (a in animals) {
        println(classify(a))
    }

    // 6) 模式的嵌套组合
    println(handleCommand(Command.SetTimeUnit(Year(2024))))
    println(handleCommand(Command.Quit))

    // 7) 无匹配值的 match
    let n: Int64 = -3
    match {
        case n > 0 => println("positive")
        case n < 0 => println("negative")
        case _ => println("zero")
    }

    // 8) 变量定义中的 Tuple 模式
    let (a, b) = (100, 200)
    println("a = ${a}, b = ${b}")

    // 9) for-in 中的 Tuple 模式
    let pairs = [(1, 2), (3, 4), (5, 6)]
    for ((i, j) in pairs) {
        println("Sum = ${i + j}")
    }

    // 10) 表达式求值演示
    let expr = Sub(Add(Num(3), Num(5)), Num(2))
    println("eval((3+5)-2) = ${eval(expr)}")
}
```

预期输出：

```text
level = B
x is not zero and x = -10
Alice is 30
color = Red = 200
color = Blue = 0
Dog named Dog
Cat named Cat
Dog named Dog
Set year 2024
Quit
negative
a = 100, b = 200
Sum = 3
Sum = 7
Sum = 11
eval((3+5)-2) = 6
```

> **⚠️ 关于 match 中的死代码告警**：当 match 的目标值是编译期常量时，编译器会做常量传播并告警"不可达"分支。文章示例为避免误报，统一将模式匹配封装在函数中，调用时再传实际值。

## 12. 常见问题

### Q1: match 必须穷尽所有可能吗？

是的。编译器会做穷尽性检查：要么覆盖所有构造器，要么用 `case _` 兜底。non-exhaustive enum（带 `...`）必须用 `case _` 或绑定模式兜底。

### Q2: 绑定模式可以修改吗？

不可以。绑定模式 `id` 等同于引入一个不可变变量，在 `=>` 之后不能重新赋值。

### Q3: 为什么 `case x | y` 报错？

`|` 用于"或"关系，多个模式共享结果但不允许引入变量，因为变量需要明确的作用域。

### Q4: 模式守卫 where 在什么时候判断？

模式匹配成功后才判断 where 条件。where 不成立时继续下一个 case。

### Q5: irrefutable 模式是什么？

不可失败的模式，匹配任何值都一定成功。包括：通配符 `_`、绑定模式、长度固定的 Tuple 模式、单一构造器且无参数的 enum 模式等。irrefutable 模式可用在 `let` 和 `for-in` 中。

### Q6: match 的值一定要用吗？

不一定。如果 match 表达式的值未被使用，类型为 `Unit`，各分支类型也无公共父类型要求。

### Q7: 类型模式 vs `is` 类型检查？

类型模式 `id: Type` 同时完成类型判断与转换，可直接使用 `id` 访问转换后的值；`is` 表达式仅做判断并返回 `Bool`。`match` 中的类型模式是更结构化的写法。

### Q8: match 和 if-else 链相比有什么优势？

- 编译器会做穷尽性检查，遗漏分支会报错
- 模式能直接解构元组、enum 等复合数据
- 编译器会优化为跳转表，性能更好

## 13. 总结

1. 仓颉支持六种模式：常量、通配符、绑定、Tuple、类型、enum；前三种最常用，后三种是复合模式。
2. `match` 表达式对值进行模式匹配，依次尝试每个 case，首个匹配后退出；编译器保证一定存在匹配分支。
3. 模式守卫 `where cond` 在模式匹配成功后再加一层条件判断。
4. 穷尽性检查要求覆盖 enum 所有构造器或用 `case _` 兜底；non-exhaustive enum 必须用 `case _`。
5. 绑定模式引入不可变变量；`|` 连接的模式不能引入变量。
6. Tuple 和 enum 模式可嵌套其他模式，组合表达力强。
7. irrefutable 模式可用在 `let` 变量定义和 `for-in` 表达式中。
8. 无匹配值的 `match` 等价于 `if-else if-else` 链，case 表达式求 `Bool`。
9. match 类型由上下文决定或取各分支类型的最小公共父类型。

## 参考资料

1. 仓颉 1.0.5 LTS 模式概述：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/pattern_overview.html
2. 仓颉 1.0.5 LTS match 表达式：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/match.html
3. 仓颉 1.0.5 LTS 枚举类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/enum.html
4. 仓颉 1.0.5 LTS 其他使用模式的地方：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/other.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
