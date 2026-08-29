# 仓颉函数类型、Lambda 与闭包

> **摘要**: 仓颉把函数视为**一等公民**：函数有类型，可赋值给变量、作参数与返回值传递。本文依据仓颉 1.0.5 LTS 官方文档，讲透函数类型 `(T1, T2) -> R` 的写法与 `->` 右结合、带类型参数名的函数类型、嵌套函数、Lambda 表达式的参数/返回类型推断规则、闭包的变量捕获与"捕获 `var` 的闭包不能作为一等公民"这一关键限制，以及尾随 lambda、管道 `|>`、组合 `~>`、变长参数等调用语法糖。函数重载与操作符重载将另起一篇深入。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已完成《仓颉函数基础》（`func` 声明、命名参数、默认值、返回值推断）
- 已了解 `let` / `var`、`Int64`、`String`、`Unit`、`Array`、元组解构

> 本文承接《仓颉函数基础》：那一篇里留待后续展开的"函数类型、Lambda、闭包"正是本文主角；而"函数重载、操作符重载"因体量大，单独成篇。

## 1. 函数类型：函数是一等公民

在仓颉中，函数可以像普通值一样被传递——作为参数、作为返回值、赋值给变量。既然是值，函数就有类型，称为**函数类型**。

函数类型由**参数类型**和**返回类型**组成，中间用 `->` 连接；参数类型用一对圆括号 `()` 括起来，可以放 0 个或多个参数类型，多个之间用 `,` 分隔。

```cangjie
func hello(): Unit { println("Hello!") }        // 类型：() -> Unit
func display(a: Int64): Unit { println(a) }     // 类型：(Int64) -> Unit
func add(a: Int64, b: Int64): Int64 { a + b }   // 类型：(Int64, Int64) -> Int64

func returnTuple(a: Int64, b: Int64): (Int64, Int64) { (a, b) }
// 类型：(Int64, Int64) -> (Int64, Int64)，返回类型本身是元组类型
```

> **⚠️ 注意：`->` 是右结合的。**
> 返回类型也是函数类型时，`() -> (Int64, Int64) -> Int64` 等价于 `() -> ((Int64, Int64) -> Int64)`，即"无参函数，返回一个 `(Int64, Int64) -> Int64` 函数"，而不需要额外加括号。

### 1.1 函数类型作为变量、参数、返回值

函数名本身就是一个表达式，其类型即对应的函数类型。于是函数可以赋给变量、作参数传入、作返回值传出：

```cangjie
func add(a: Int64, b: Int64): Int64 { a + b }

// 作为变量类型
let f: (Int64, Int64) -> Int64 = add

// 作为参数类型（op 是一个函数）
func printAdd(op: (Int64, Int64) -> Int64, x: Int64, y: Int64): Unit {
    println(op(x, y))
}

// 作为返回类型（返回一个函数）
func makeAdder(): (Int64, Int64) -> Int64 {
    add
}
```

`printAdd` 的类型是 `((Int64, Int64) -> Int64, Int64, Int64) -> Unit`——第一个形参自己就是函数类型，注意用括号把它和其余参数区分开。

### 1.2 给函数类型标注参数名

函数类型的每个参数可以带名字，提升可读性：

```cangjie
func showFruitPrice(name: String, price: Int64): Unit {
    println("fruit: ${name} price: ${price} yuan")
}

main() {
    let handler: (name: String, price: Int64) -> Unit = showFruitPrice
    handler("banana", 10)
}
```

> **⚠️ 注意：类型参数名要么全写，要么全不写。**
> `(name: String, Int64) -> Int64` 这种"一个写名一个不写"的混排在 1.0.5 会直接编译报错（`either all parameters must be named, or none of them`），这是我在 SDK 上实测确认的约束。

### 1.3 重载函数名作为表达式的歧义

如果某个函数名在当前作用域被重载，直接把函数名当值用可能产生歧义，编译器会报错，需要显式写出函数类型来消除歧义：

```cangjie
func add(i: Int64, j: Int64): Int64 { i + j }
func add(i: Float64, j: Float64): Float64 { i + j }

var f = add                               // 报错：add 有歧义
var plus: (Int64, Int64) -> Int64 = add   // 正确：用目标类型指明是哪一个
```

## 2. 嵌套函数

定义在源文件顶层的函数是**全局函数**；定义在某个函数体内部的函数是**嵌套函数**。

- 嵌套函数的作用域仅限于其所在的外部函数：它可以访问外部函数的变量和参数，但外部函数不能访问嵌套函数内部的变量。
- 嵌套函数既可以被外部函数直接调用，也可以作为返回值被返回出去。

```cangjie
func foo(): (Int64, Int64) -> Int64 {
    func nestAdd(a: Int64, b: Int64): Int64 {
        a + b + 3
    }
    println(nestAdd(1, 2))   // 外部函数内部直接调用：6
    nestAdd                   // 作为返回值返回出去，供外部调用
}
```

官方提醒了三条实践要点：只在确实需要时用嵌套函数；**避免过度嵌套**（层级太深会显著增加理解与维护成本）；如果嵌套函数被返回并作为闭包使用，要注意它可能捕获外部函数的变量，影响这些变量的生命周期与内存管理——这正好引出下一节的闭包。

## 3. Lambda 表达式

Lambda 是**匿名函数**——没有名字的函数，用来就地写一小段可传递的逻辑。语法：

```
{ p1: T1, p2: T2, ..., pn: Tn => 表达式或声明序列 }
```

`=>` 之前是参数列表（可以一个参数都没有），`=>` 之后是函数体。

```cangjie
let f1 = { a: Int64, b: Int64 => a + b }
let f2 = { =>                 // 无参 lambda
    println("Hello")
    println("World")
}
```

> **⚠️ 注意：`=>` 一般不能省略。** 不管有没有参数，`=>` 都要写（`{ => ... }` 里的 `=>` 也要）。唯一例外是把它作为**尾随 lambda** 用在调用尾部时（见第 5.1 节），才可以省略 `=>`。

### 3.1 参数类型什么时候能省

Lambda 里参数的类型标注可以省略，但**前提是编译器能推断出来**，只有两种情形能推断：

1. **赋值给变量**时，按变量的类型推断；
2. **作为实参**传给某个函数时，按该函数形参的类型推断。

```cangjie
// 靠变量类型推断：sum1 是 (Int64, Int64) -> Int64，于是 a、b 都推断为 Int64
var sum1: (Int64, Int64) -> Int64 = { a, b => a + b }

func f(a1: (Int64) -> Int64): Int64 { a1(1) }
// 靠形参类型推断：a2 推断为 Int64
f({ a2 => a2 + 10 })
```

### 3.2 Lambda 不能声明返回类型

Lambda **不支持显式写返回类型**，返回类型一律由上下文推断或按函数体规则推导：

- 上下文（变量类型 / 形参类型 / 所在函数返回类型）已指明返回类型，就用上下文的；
- 上下文没指明时，和普通函数体一样，根据 lambda 体内所有 `return` 表达式的类型与函数体最后一项的类型共同推导。

```cangjie
let g: () -> Unit = { => println(10) }   // 返回类型由变量类型给出
let h = { => }                            // 体为空 → 返回类型 Unit
```

### 3.3 立即调用与变量调用

Lambda 可以定义后立即调用，也可以赋给变量再用变量名调用：

```cangjie
let r1 = { a: Int64, b: Int64 => a + b }(1, 2)   // 立即调用：3
let r2 = { => 123 }()                             // 立即调用（无参）：123

var g = { x: Int64 => println("x = ${x}") }
g(2)                                              // 通过变量调用
```

## 4. 闭包：捕获环境里的变量

当一个函数或 lambda 从它的静态作用域里"带走"了外部变量，函数/lambda 连同被捕获的变量就构成一个**闭包**；即使离开了定义它的作用域，闭包依然能正常访问这些变量。

### 4.1 什么算捕获、什么不算

**是**变量捕获的情形：

- 函数的**参数缺省值**里访问了本函数之外定义的局部变量；
- 函数 / lambda 内访问了**本函数（本 lambda）之外定义的局部变量**；
- `class` / `struct` 内定义的**非成员函数**访问了实例成员变量或 `this`。

**不是**变量捕获的情形：

- 访问定义在本函数 / 本 lambda 内的局部变量；
- 访问本函数 / 本 lambda 自己的形参；
- 访问**全局变量、静态成员变量**；
- 在**实例成员函数或属性**里访问实例成员变量（因为这类函数本来就带 `this` 参数）。

两条硬规则：**被捕获的变量必须在闭包定义时可见**，且**必须已完成初始化**，否则编译报错。

```cangjie
func returnAddNum(): (Int64) -> Int64 {
    let num: Int64 = 10
    func addNum(a: Int64): Int64 { a + num }   // 捕获 let 局部变量 num
    addNum
}

main() {
    let f = returnAddNum()
    println(f(10))   // 20：num 所在作用域已结束，闭包仍能访问 num
}
```

### 4.2 捕获 `let` 与捕获 `var` 的关键区别

这是仓颉闭包最容易踩的坑，务必记牢：**捕获了 `var`（可变）局部变量的闭包，只能被直接调用，不能作为一等公民使用**——不能赋值给变量、不能作实参、不能作返回值、不能把函数名当表达式用。这样设计是为了防止"捕获了可变变量的闭包逃逸出去"带来的数据竞争与生命周期问题。

```cangjie
func f() {
    var x = 1
    func g() { println(x) }   // g 捕获了可变变量 x
    let b = g                 // 报错：捕获 var 的闭包不能赋给变量
    // g                       // 报错：不能把 g 当表达式
    g()                        // 正确：只能直接调用
}
```

官方在 1.0.5 上给出的报错信息是 `function capturing mutable variables needs to be called directly`（我实测确认）。

而且这个限制**具有传递性**：若 `f` 调用了捕获 `var` 的 `g`，且 `g` 捕获的那个 `var` **不在** `f` 内定义，那么 `f` 同样被视为捕获了 `var`，`f` 也不能作一等公民。反之，如果 `g` 捕获的 `var` 恰好定义在 `f` 内部，`f` 就没有向外捕获，`f` 仍可作一等公民返回出去。

### 4.3 捕获引用类型、访问全局/静态变量

- 如果被捕获的是**引用类型**（`class` 实例），闭包里可以修改该实例的 `var` 成员（改的是对象内部状态，而不是重新绑定变量本身）。
- **访问全局变量、静态成员变量不属于捕获**，因此即便它们是可变的 `var`，访问它们的函数/lambda 依然可以作为一等公民使用。

```cangjie
var globalV = 0
func countGlobal(): Unit {
    globalV += 1        // 访问全局 var：不是捕获
}
let g = countGlobal     // OK：可作一等公民赋值
```

## 5. 函数调用语法糖

仓颉提供了几种让调用更顺手的语法糖：尾随 lambda、管道 `|>`、组合 `~>`、变长参数。

### 5.1 尾随 lambda

当函数的**最后一个形参是函数类型**，且**对应实参是一个 lambda** 时，可以把这个 lambda 挪到圆括号**外面**，写成"尾随"形式；如果函数**有且只有一个** lambda 实参，连圆括号都可以省略：

```cangjie
func myIf(cond: Bool, fn: () -> Int64): Int64 {
    if (cond) { fn() } else { 0 }
}

myIf(true, { => 100 })   // 普通调用
myIf(true) {             // 尾随 lambda：lambda 放到括号外，且可省略 =>
    100
}

func apply(fn: (Int64) -> Int64): Unit { fn(1) }
apply { i => i * i }     // 唯一 lambda 实参，省略圆括号
```

### 5.2 管道表达式 `|>`（pipeline）

`e1 |> e2` 是 `let v = e1; e2(v)` 的语法糖——把左侧的值喂给右侧函数，多个处理步骤串起来更像"数据流动"。`e2` 必须是函数类型，`e1` 的类型是其参数类型的子类型。

```cangjie
func inc(x: Int64): Int64 { x + 1 }
func double(x: Int64): Int64 { x * 2 }

let r = 5 |> inc |> double    // double(inc(5)) = 12
```

### 5.3 组合表达式 `~>`（composition）

`f ~> g` 表示两个**单参**函数的组合，等价于 `{ x => g(f(x)) }`。要求 `f(x)` 的返回类型是 `g` 参数类型的子类型。求值顺序是：先对 `f` 求值、再对 `g` 求值，最后组合。

```cangjie
let composed = inc ~> double   // 等价于 { x: Int64 => double(inc(x)) }
let v = composed(5)            // 12
```

> **⚠️ 注意：流操作符与命名参数的配合有限制。**
> 无默认值的命名形参函数不能直接 `x |> f`（因为调用必须写 `f(name: x)`）；有默认值的命名形参直接用于流操作符同样报错。要绕过，用 lambda 显式给命名实参：`1 |> { x: Int64 => f(name: x) }`。

### 5.4 变长参数

当函数**最后一个非命名形参是 `Array` 类型**时，调用处可以在该位置直接传一串实参（0 个或多个）代替 `Array` 字面量：

```cangjie
func sum(arr: Array<Int64>): Int64 {
    var total = 0
    for (x in arr) { total += x }
    total
}

sum()          // 0
sum(1, 2, 3)   // 6，等价于 sum([1, 2, 3])
```

> **⚠️ 注意：变长参数只适用于最后一个非命名参数。** 命名参数（`arr!: Array<Int64>`）用不了这个语法糖，写 `length(1, 2, 3)` 会报 `expected 1 argument, found 3`（实测确认）。此外，变长参数也不能用于操作符重载（除函数调用 `()`、索引 `[]`）、`~>`、`|>` 这些调用方式。

## 6. 完整可运行示例

下面的示例把前五节的用法串成一个可运行程序：函数类型作变量/参数/返回值、带类型参数名、嵌套函数、Lambda 的类型推断与立即调用、捕获 `let` 变量并逃逸的闭包、尾随 lambda、`|>` 管道、`~>` 组合、变长参数。

<!-- example: cangjie/021-functions-lambda-closure.cj -->
```cangjie
// 函数类型、Lambda 与闭包示例
// 演示：函数类型（一等公民）、函数类型作参数/返回值/变量、带类型参数名、
// 嵌套函数、Lambda（参数与返回类型推断、立即调用）、闭包（捕获 let 局部变量并逃逸）、
// 调用语法糖：尾随 lambda、pipeline(|>)、composition(~>)、变长参数

// ========== 1) 函数类型（一等公民） ==========

func add(a: Int64, b: Int64): Int64 {
    a + b
}

func returnTuple(a: Int64, b: Int64): (Int64, Int64) {
    (a, b)
}

// 函数类型作为参数类型
func printAdd(op: (Int64, Int64) -> Int64, x: Int64, y: Int64): Unit {
    println("printAdd = ${op(x, y)}")
}

// 函数类型作为返回类型（-> 右结合，等价于 () -> ((Int64, Int64) -> Int64)）
func makeAdder(): (Int64, Int64) -> Int64 {
    add
}

// 带类型参数名的函数类型
func showFruitPrice(name: String, price: Int64): Unit {
    println("fruit: ${name} price: ${price} yuan")
}

// ========== 2) 嵌套函数 ==========

func foo(): (Int64, Int64) -> Int64 {
    func nestAdd(a: Int64, b: Int64): Int64 {
        a + b + 3
    }
    println("nestAdd(1,2) = ${nestAdd(1, 2)}") // 6
    nestAdd // 把嵌套函数作为返回值返回
}

// ========== 3) 闭包：捕获 let 局部变量并逃逸到作用域之外 ==========

func returnAddNum(): (Int64) -> Int64 {
    let num: Int64 = 10
    func addNum(a: Int64): Int64 {
        a + num // 捕获外部只读局部变量 num
    }
    addNum
}

// ========== 4) 调用语法糖 ==========

// 尾随 lambda：最后一个形参是函数类型
func myIf(cond: Bool, fn: () -> Int64): Int64 {
    if (cond) {
        fn()
    } else {
        0
    }
}

func square(x: Int64): Int64 {
    x * x
}

// pipeline / composition 的普通单参函数
func inc(x: Int64): Int64 {
    x + 1
}

func double(x: Int64): Int64 {
    x * 2
}

// 变长参数：最后一个非命名形参是 Array 类型
func sum(arr: Array<Int64>): Int64 {
    var total = 0
    for (x in arr) {
        total += x
    }
    total
}

main(): Int64 {
    // ---- 1) 函数类型 ----
    let f: (Int64, Int64) -> Int64 = add // 函数名作为表达式，赋给函数类型变量
    println("f(3,4) = ${f(3, 4)}")        // 7
    let (p, q) = returnTuple(1, 2)
    println("tuple = ${p}, ${q}")          // 1, 2
    printAdd(add, 10, 20)                  // 函数类型作实参
    let adder = makeAdder()
    println("adder(5,6) = ${adder(5, 6)}") // 函数类型作返回值 → 11
    let handler: (name: String, price: Int64) -> Unit = showFruitPrice
    handler("banana", 10)                  // 带类型参数名的函数类型

    // ---- 2) 嵌套函数 ----
    let returnedNest = foo()
    println("returnedNest(1,2) = ${returnedNest(1, 2)}") // 6

    // ---- 3) Lambda ----
    // 参数类型由变量类型推断
    var sum1: (Int64, Int64) -> Int64 = { a, b => a + b }
    println("sum1(2,3) = ${sum1(2, 3)}")  // 5
    // 无参数 lambda
    let greet = { => println("Hello, Lambda") }
    greet()
    // 立即调用
    let r1 = { a: Int64, b: Int64 => a + b }(1, 2)
    println("immediate = ${r1}")          // 3
    // 作为实参时参数类型由形参推断（n 推断为 Int64）
    let mapped = applyOnce({ n => n * n }, 9)
    println("applyOnce = ${mapped}")      // 81

    // ---- 4) 闭包 ----
    let add10 = returnAddNum()
    println("add10(32) = ${add10(32)}")   // 42（捕获的 num 在作用域外仍可访问）

    // ---- 5) 调用语法糖 ----
    // 尾随 lambda：普通写法
    println("myIf normal = ${myIf(true, { => 100 })}") // 100
    // 尾随 lambda：把 lambda 放到圆括号外
    println("myIf trailing = ${myIf(true) { 100 }}")   // 100
    // 唯一 lambda 实参可省略圆括号
    println("square via trailing = ${callWithLambda { i => i * i }}") // 1（内部对 1 求平方）
    // pipeline：数值依次流过函数
    let piped = 5 |> inc |> square         // square(inc(5)) = square(6) = 36
    println("piped = ${piped}")
    // composition：f ~> g 等价于 { x => g(f(x)) }
    let composed = inc ~> double
    println("composed(5) = ${composed(5)}") // double(inc(5)) = 12
    // 变长参数：直接传参数序列
    println("sum() = ${sum()}")             // 0
    println("sum(1,2,3) = ${sum(1, 2, 3)}") // 6

    return 0
}

// 供 lambda 作实参类型推断使用
func applyOnce(fn: (Int64) -> Int64, v: Int64): Int64 {
    fn(v)
}

// 供“唯一 lambda 实参省略圆括号”使用：对 1 应用传入的函数
func callWithLambda(fn: (Int64) -> Int64): Int64 {
    fn(1)
}
```

预期输出：

```text
f(3,4) = 7
tuple = 1, 2
printAdd = 30
adder(5,6) = 11
fruit: banana price: 10 yuan
nestAdd(1,2) = 6
returnedNest(1,2) = 6
sum1(2,3) = 5
Hello, Lambda
immediate = 3
applyOnce = 81
add10(32) = 42
myIf normal = 100
myIf trailing = 100
square via trailing = 1
piped = 36
composed(5) = 12
sum() = 0
sum(1,2,3) = 6
```

> 输出中的 `square via trailing = 1` 是因为 `callWithLambda` 内部固定对 `1` 应用传入的平方函数（`1 * 1 = 1`）；若把 lambda 换成别的单参函数，这里会随之变化。

## 7. 语言对比

### 7.1 一等公民 / 函数类型

| 特性 | 仓颉 | Go | Java | Kotlin |
|------|------|----|------|--------|
| 函数是值 | 是，函数类型 `(T) -> R` | 是，`func(T) R` | 需函数式接口 / lambda 目标类型 | 是，`(T) -> R` |
| Lambda 语法 | `{ a: T => body }` | `func(a T) R { }` | `(args) -> expr` | `{ a: T -> body }` |
| Lambda 内写返回类型 | 不支持，靠上下文/推导 | 必须写返回类型 | 由目标类型/推导 | 一般靠推导 |
| `=>` 何时省略 | 仅尾随 lambda 时可省 | 无此概念 | 无此概念 | 单表达式可省 `{}` 结构 |

### 7.2 捕获可变变量的限制（核心差异）

仓颉的独特之处：**捕获了 `var` 局部变量的闭包不能作一等公民**（只能被直接调用）。

- **Go**：闭包可以随意捕获 `var` 并作为值传递，没有这类语言级限制。
- **Java**：lambda 只能捕获 **effectively final** 的局部变量（捕获即视为只读），想改就得绕路（数组/Atomic 等）。
- **Kotlin / Swift**：可捕获可变变量并自由传递，闭包可逃逸。

> **💡 提示**：从 Go/Kotlin 迁移到仓颉，若发现"把捕获了可变局部变量的内层函数赋值给变量/当返回值"编译不过，这不是 bug，而是语言为规避逃逸可变捕获刻意设的规则；改用 `let`（不可变）捕获、或把它放进 `class` 成员、或直接在原地调用即可。从 Java 迁移则相反——仓颉能干净地捕获可变变量并原地使用，只是不能让它作为值"跑出去"。

## 8. 常见问题（FAQ）

### Q1: 函数类型里多个返回类型怎么办？

返回类型只有一个位置；要返回多个值，返回**元组类型**，如 `(Int64, Int64) -> (Int64, Int64)`。

### Q2: `() -> (Int64) -> Int64` 要加括号吗？

不用。`->` 右结合，`() -> (Int64) -> Int64` 就是"无参、返回一个 `(Int64) -> Int64` 函数"。只有你想表达"**参数**是函数类型"时才需要给参数那部分加括号，如 `((Int64) -> Int64, Int64) -> Unit`。

### Q3: Lambda 可以不写 `=>` 吗？

一般不行，`=>` 必须写（哪怕无参也要 `{ => ... }`）。只有把它作为**尾随 lambda** 写在调用括号外时才能省略 `=>`。

### Q4: 为什么我捕获了变量的闭包不能返回/赋值？

因为你捕获的是 `var` 声明的可变局部变量。捕获 `var` 的闭包只能被直接调用，不能作一等公民（赋值、作实参、作返回值都不行），且该限制具传递性。改成捕获 `let` 变量即可正常作为值传递。

### Q5: 捕获全局变量或静态成员变量算捕获吗？会影响一等公民吗？

不算捕获。访问全局变量、静态成员变量不触发第 4.2 节的限制，这类函数仍可作一等公民使用。

### Q6: `|>` 和 `~>` 有什么区别？

`e |> f` 是**求值**：把 `e` 传给 `f` 立即得到结果（`f(e)`）。`f ~> g` 是**组合**：产生一个**新函数** `{ x => g(f(x)) }`，并不立即调用。前者是"跑一遍"，后者是"造一个新函数"。

### Q7: 变长参数能用命名参数吗？

不能。只有**最后一个非命名形参**是 `Array` 类型时才享受变长参数语法；命名参数用它会报"参数数量不符"。

## 9. 总结

1. **函数是一等公民**：函数类型写作 `(参数类型) -> 返回类型`，可作变量、参数、返回值；`->` **右结合**，函数类型参数名要么全写要么全不写。
2. **嵌套函数**：定义在函数体内，作用域限于外部函数，可被调用也可被返回；注意过度嵌套与闭包捕获带来的变量生命周期问题。
3. **Lambda** `{ p: T => body }`：`=>` 通常不可省（尾随 lambda 除外）；参数类型仅在"赋给变量"或"作实参"时可省略由上下文推断；**不支持声明返回类型**。
4. **闭包**：函数/lambda 连同捕获的外部变量。捕获的变量须**定义时可见且已初始化**；捕获 `let` 可正常作一等公民，**捕获 `var` 的闭包只能直接调用**（且限制具传递性）；访问全局/静态变量不算捕获。
5. **调用语法糖**：尾随 lambda（唯一 lambda 实参可省括号）、管道 `e |> f`（`f(e)`）、组合 `f ~> g`（`{x => g(f(x))}`）、变长参数（仅最后一个非命名 `Array` 形参）。
6. 函数重载与操作符重载内容较多，将在下一篇专题展开。

## 参考资料

1. 仓颉 1.0.5 LTS 函数类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/function/first_class_citizen.html
2. 仓颉 1.0.5 LTS 嵌套函数：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/function/nested_functions.html
3. 仓颉 1.0.5 LTS Lambda 表达式：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/function/lambda.html
4. 仓颉 1.0.5 LTS 闭包：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/function/closure.html
5. 仓颉 1.0.5 LTS 函数调用语法糖：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/function/function_call_desugar.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
