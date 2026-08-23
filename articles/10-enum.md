# 仓颉枚举类型

> **摘要**: 枚举（enum）是仓颉中的一种代数数据类型（Algebraic Data Type），它通过列举一个类型的所有可能取值来定义该类型。本文依据仓颉 1.0.5 LTS 官方文档，系统介绍 enum 的定义、构造器（无参、有参、匿名 `...`）、递归 enum、成员函数与属性、enum 值的构造以及与同名标识符的解析规则，帮助读者掌握 enum 类型的使用方式。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已了解变量、函数、`class` 与 `struct` 的基础
- 已了解 `interface` 与 `match` 表达式基础
- 已完成《仓颉类类型 class》《仓颉接口、属性与子类型》

## 1. enum 的定义

enum 类型以关键字 `enum` 开头，后跟类型名和花括号定义体。enum 只能定义在源文件的顶层作用域。enum 体中通过若干**构造器**列举该类型所有可能的取值，多个构造器之间使用 `|` 分隔（第一个构造器前的 `|` 是可选的）：

```cangjie
enum RGBColor {
    | Red(UInt8)
    | Green(UInt8)
    | Blue(UInt8)
}
```

构造器可以分成三类：

| 形态 | 语法 | 含义 |
|------|------|------|
| 无参构造器 | `Red` | 不携带数据 |
| 有参构造器 | `Red(UInt8)` | 携带若干参数 |
| 匿名构造器 | `...` | 表示"其他可能"，仅 non-exhaustive enum 允许 |

每个 enum 中**至少存在一个有名字的构造器**。

## 2. 构造器详解

### 2.1 有参与无参构造器

构造器可以是有名字的，可以没有参数（无参构造器），也可以携带若干参数（有参构造器）：

```cangjie
enum RGBColor {
    | Red(UInt8)    // 有参
    | Green         // 无参
    | Blue(UInt8)   // 有参
}
```

### 2.2 同名构造器

仓颉支持同一个 enum 中定义多个同名构造器，但要求参数个数不同：

```cangjie
enum RGBColor {
    | Red
    | Green
    | Blue
    | Red(UInt8)
    | Green(UInt8)
    | Blue(UInt8)
}
```

无参构造器与零参数构造器视为相同数量，**不能**同时存在。

### 2.3 匿名构造器 `...`

每个 enum 中最多只能有一个 `...` 构造器，且 `...` 只能是最后一个构造器。拥有 `...` 构造器的 enum 称为 **non-exhaustive enum**：

```cangjie
enum Status {
    | Pending
    | Running
    | Done
    | ...
}
```

由于 `...` 构造器没有名字，不能被直接匹配，解构时需要使用通配符模式 `_` 或绑定模式。

### 2.4 递归 enum

enum 支持递归定义，构造器的参数类型可以引用 enum 自身：

```cangjie
enum Expr {
    | Num(Int64)
    | Add(Expr, Expr)
    | Sub(Expr, Expr)
}
```

上例定义了一种表达式类型：数字 `Num`、加法 `Add`、减法 `Sub`，其中 `Add` 与 `Sub` 的参数递归使用 `Expr`。这种表达方式在函数式编程中称为**代数数据类型**。

## 3. enum 内的成员

enum 体中可以定义成员函数、操作符函数和成员属性。**构造器、成员函数、成员属性之间不能重名**：

```cangjie
enum RGBColor {
    | Red
    | Green
    | Blue

    public static func printType() {
        print("RGBColor")
    }
}
```

成员可以是实例的或静态的，访问规则与 `class` 相同：实例成员通过 enum 值访问，静态成员通过类型名访问。

## 4. enum 的使用

### 4.1 构造 enum 值

enum 没有构造函数，构造 enum 值有两种方式：

- 通过类型名加点号加构造器：`RGBColor.Red`
- 直接使用构造器名：`Red`

```cangjie
enum RGBColor {
    | Red(UInt8)
    | Green(UInt8)
    | Blue(UInt8)
}

main() {
    let r = RGBColor.Red(255)   // 类型名.构造器(实参)
    let g = Green(128)          // 直接使用构造器
    let b = Blue(64)            // 直接使用构造器
}
```

### 4.2 名称冲突时的解析

当省略类型名时，构造器的名字可能与类型名、变量名、函数名发生冲突。此时**必须**加上 enum 类型名来使用构造器：

```cangjie
let Red = 1
func Green(g: UInt8) { return g }
enum RGBColor {
    | Red
    | Green(UInt8)
    | Blue(UInt8)
}

main() {
    let r1 = Red               // 选择 let Red
    let r2 = RGBColor.Red      // OK：显式标注
    let g1 = Green(100)        // 选择 func Green
    let g2 = RGBColor.Green(100)
    let b = Blue(100)          // OK：Blue 无冲突，可直接使用
}
```

当存在同名的 `class` 或 `struct` 类型时，也会发生冲突：

```cangjie
class Blue {}
enum RGBColor {
    | Red
    | Green(UInt8)
    | Blue(UInt8)
}

let r = Red           // OK：枚举构造器
let b = Blue(100)     // 错误：会选择 class Blue，无法直接构造 enum
let b2 = RGBColor.Blue(100)  // OK
```

> **建议**：在大型项目中，建议**总是**使用 `TypeName.Constructor` 的完整形式构造 enum 值，可读性最佳且无歧义。

## 5. 一个完整示例

本示例组合了无参/有参构造器、递归 enum、non-exhaustive enum、成员函数、静态成员、enum 实现接口：

<!-- example: cangjie/014-enum.cj -->
```cangjie
// 枚举类型示例
// 演示：enum 定义、构造器（无参、有参、... ）、递归 enum、成员函数、属性、enum 值构造

// 1) 简单 enum：三个无参构造器
enum Color {
    | Red
    | Green
    | Blue

    public func name(): String {
        match (this) {
            case Red => "Red"
            case Green => "Green"
            case Blue => "Blue"
        }
    }
}

// 2) 带参数的 enum 构造器
enum RGBColor {
    | Red(UInt8)
    | Green(UInt8)
    | Blue(UInt8)

    public func channel(): UInt8 {
        match (this) {
            case Red(v) => v
            case Green(v) => v
            case Blue(v) => v
        }
    }
}

// 3) non-exhaustive enum（含 ... 构造器）
enum Status {
    | Pending
    | Running
    | Done
    | ...

    public func label(): String {
        match (this) {
            case Pending => "pending"
            case Running => "running"
            case Done => "done"
            case _ => "other"
        }
    }
}

// 4) 递归 enum：表达式树
enum Expr {
    | Num(Int64)
    | Add(Expr, Expr)
    | Sub(Expr, Expr)
}

// 5) enum 成员函数 + 静态成员
enum Direction {
    | North
    | South
    | East
    | West

    public func label(): String {
        match (this) {
            case North => "N"
            case South => "S"
            case East => "E"
            case West => "W"
        }
    }

    public static func all(): Array<Direction> {
        [North, South, East, West]
    }
}

// 6) enum 实现接口
interface Printable {
    func describe(): String
}

enum LogLevel <: Printable {
    | Info
    | Warn
    | Error

    public func describe(): String {
        match (this) {
            case Info => "INFO"
            case Warn => "WARN"
            case Error => "ERROR"
        }
    }
}

// 求值递归 enum 表达式
func eval(e: Expr): Int64 {
    match (e) {
        case Num(n) => n
        case Add(a, b) => eval(a) + eval(b)
        case Sub(a, b) => eval(a) - eval(b)
    }
}

main() {
    // 1) enum 值构造（类型名.构造器 或 裸构造器）
    let c1 = Color.Red
    let c2 = Green
    println("c1 = ${c1.name()}")
    println("c2 = ${c2.name()}")

    // 2) 有参构造器
    let red = RGBColor.Red(255)
    let green = RGBColor.Green(128)
    let blue = Blue(64)
    println("red channel = ${red.channel()}")
    println("green channel = ${green.channel()}")
    println("blue channel = ${blue.channel()}")

    // 3) non-exhaustive enum：必须用 case _ 兜底
    let s = Status.Running
    println("status = ${s.label()}")

    // 4) 递归 enum 表达式求值
    // (3 + 5) - 2 = 6
    let expr = Sub(Add(Num(3), Num(5)), Num(2))
    println("eval((3+5)-2) = ${eval(expr)}")

    // 5) enum 成员函数 + 静态成员
    let n = Direction.North
    println("North.label() = ${n.label()}")
    let dirs = Direction.all()
    println("dirs.size = ${dirs.size}")

    // 6) enum 实现接口
    let lvl: LogLevel = LogLevel.Warn
    let printable: Printable = lvl
    println("lvl.describe() = ${printable.describe()}")
}
```

预期输出：

```text
c1 = Red
c2 = Green
red channel = 255
green channel = 128
blue channel = 64
status = running
eval((3+5)-2) = 6
North.label() = N
dirs.size = 4
lvl.describe() = WARN
```

> **⚠️ 关于 match**：本示例用到了 `match` 表达式对 enum 值进行模式匹配。match 的完整语法、模式类型（常量、绑定、类型、通配符、Tuple、enum 等）将在后续《模式匹配》专题中详细介绍。

## 6. 常见问题

### Q1: enum 是不是简单的整数常量？

不是。仓颉的 enum 是代数数据类型（ADT），每个构造器可以携带不同类型和数量的参数，构造器的实例是值而不是整数。enum 不能直接 `println` 输出默认字符串（除非显式实现 `ToString`）。

### Q2: enum 能继承 class 吗？

不能。enum 是独立的类型，但可以实现 `interface`，也可以定义实例/静态成员函数与属性。

### Q3: 同名构造器有数量限制吗？

参数个数不同的同名构造器可以共存，**但**每个 enum 中至多只能有一个 `...` 构造器（必须是最后一个）。

### Q4: `...` 构造器的作用是什么？

`...` 表示 enum 是 non-exhaustive：除了列出的构造器外还可能有"其他"取值。解构 non-exhaustive enum 时必须用 `case _` 兜底。

### Q5: enum 值在 match 中如何解构？

有参构造器用 `case Name(pattern1, pattern2)` 解构；无参构造器用 `case Name` 匹配；`...` 用 `case _` 兜底。详细规则见后续 match 专题。

### Q6: enum 值是否可以使用 `==` 比较？

可以。enum 值的相等性由构造器与参数共同决定：相同构造器且参数相等时为相等。仓颉会自动为 enum 生成合理的相等性实现。

### Q7: enum 在性能上有何特点？

enum 是值类型，构造与匹配都没有堆分配开销；递归 enum 通过栈/堆混合方式存储（深度很大时可能分配到堆上）。`match` 表达式会被编译器优化为跳转表（jump table），性能接近 if-else 链。

### Q8: enum 与 Option<T> 是什么关系？

`Option<T>` 在仓颉中就是用 enum 实现的：`Some(T) | None`。它是处理"可能没有值"场景的常用工具，将在后续专题中详细介绍。

## 7. 总结

1. `enum` 是代数数据类型（ADT），通过枚举所有构造器来定义类型；构造器可携带参数、支持递归。
2. 构造器分无参、有参、匿名 `...` 三类；`...` 表示 non-exhaustive，匹配时需用 `case _` 兜底。
3. enum 体内可定义成员函数、属性、操作符函数；构造器、成员函数、属性之间不能重名。
4. 构造 enum 值可用 `TypeName.Constructor` 或裸构造器；存在名称冲突时必须使用类型名限定。
5. enum 只能定义在顶层作用域，可以实现 `interface`，不能继承 `class`。
6. enum 是后续 match 表达式、Option、Result 等模式匹配机制的基础。

## 参考资料

1. 仓颉 1.0.5 LTS 枚举类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/enum.html
2. 仓颉 1.0.5 LTS 模式概述：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/pattern_overview.html
3. 仓颉 1.0.5 LTS Option 类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/option_type.html
4. 仓颉 1.0.5 LTS match 表达式：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/match.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
