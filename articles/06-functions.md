# 仓颉函数基础

> **摘要**: 函数把一段可复用的计算封装为带名称、可传参与可返回值的执行单元。本文依据仓颉 1.0.5 LTS 官方文档，系统介绍 `func` 声明、参数列表（非命名参数、命名参数、默认值）、返回值类型与推断、函数体类型与 `return`、作用域与遮盖以及函数调用规则，帮助读者从零掌握仓颉函数的定义与调用。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已了解变量、`let`/`var`、`Int64`、`String`、`Bool`、`Unit`、`Nothing` 和表达式求值
- 已完成《仓颉运算符与表达式》《仓颉控制流语句》

## 1. 函数的声明形态

仓颉使用关键字 `func` 开始一个函数定义，依次是函数名、参数列表、可选的返回值类型和函数体。参数列表在一对圆括号内，多个参数以逗号分隔；参数列表与返回值类型之间用 `:` 分隔；函数体在一对花括号内。

```cangjie
func add(a: Int64, b: Int64): Int64 {
    return a + b
}
```

上例定义了函数 `add`，拥有两个 `Int64` 类型参数 `a`、`b`，返回值类型为 `Int64`，函数体将 `a + b` 的值作为 `return` 的结果返回。

函数名可以是任意合法标识符。函数声明的位置决定其可见性：顶层函数在包内可见，嵌套函数在外层函数体结束前可见。

## 2. 参数列表

一个函数可以拥有 0 个或多个参数。根据调用时是否需要写出参数名，参数分为两类：非命名参数和命名参数。

### 2.1 非命名参数

非命名参数的定义方式为 `p: T`，其中 `p` 是参数名，`T` 是参数类型，中间用 `:` 连接：

```cangjie
func add(a: Int64, b: Int64): Int64 {
    return a + b
}
```

调用非命名参数时，实参是一个表达式，实参与形参按位置一一对应，且实参类型必须是形参类型的子类型。

### 2.2 命名参数

命名参数的定义方式为 `p!: T`，在参数名后多一个 `!`：

```cangjie
func add(a!: Int64, b!: Int64): Int64 {
    return a + b
}
```

调用命名参数时，实参必须写成 `p: e` 的形式，其中 `p` 是命名参数的名字，`e` 是传给该参数的表达式。多个命名参数的调用顺序可以与定义顺序不同：

```cangjie
func add(a!: Int64, b!: Int64): Int64 {
    return a + b
}

let r = add(b: 2, a: 1) // 命名参数允许调换顺序
```

非命名参数和命名参数可以共存，但必须保证所有非命名参数都位于命名参数之前。一旦出现命名参数，后面不能再出现非命名参数：

```cangjie
// func add(a!: Int64, b: Int64): Int64 { } // 错误：命名参数 a 之后不能再出现非命名参数 b
```

### 2.3 默认值

只能为命名参数设置默认值，语法为 `p!: T = e`，其中 `e` 是默认值的表达式：

```cangjie
func greet(name!: String = "仓颉"): String {
    "你好, ${name}"
}

let m1 = greet()              // 使用默认值 "仓颉"
let m2 = greet(name: "Alice") // 使用传入值 "Alice"
```

对于拥有默认值的命名参数，调用时可以省略该实参，此时参数取定义时的默认值；也可以传入新的实参覆盖默认值：

```cangjie
func add(a: Int64, b!: Int64 = 2): Int64 {
    return a + b
}

let r1 = add(1)          // b 取默认值 2，结果为 3
let r2 = add(1, b: 20)   // b 取传入值 20，结果为 21
```

### 2.4 参数是不可变变量

函数参数均为不可变变量，在函数体内不能对其赋值：

```cangjie
func add(a: Int64, b: Int64): Int64 {
    // a = a + b // 错误：不能对参数赋值
    return a + b
}
```

如果需要基于参数做修改，应将参数值复制到局部变量再操作：

```cangjie
func increment(value: Int64): Int64 {
    var result = value
    result += 1
    return result
}
```

### 2.5 参数与作用域

参数的作用域从定义处起至函数体结束。在函数体内不能再定义与参数同名的变量，否则会构成重定义错误；但允许在外层作用域定义同名变量，函数体内将使用局部参数遮盖外层变量：

```cangjie
func add(a: Int64, b: Int64): Int64 {
    var a_ = a // 正确：新名称避免冲突
    // var b = b // 错误：重定义 b
    return a
}

let r = 0
func useR(a: Int64): Int64 {
    var r = a // 函数体内 r 遮盖全局 r
    return r
}
```

> **⚠️ 注意**
> 命名参数的 `!` 属于参数定义语法的一部分，调用时实参形式是 `p: e` 而非 `p!: e`，不要混淆。

## 3. 函数返回值类型

函数返回值类型是函数被调用后得到的值的类型。仓颉的函数返回值类型是可选的：可以显式标注，也可以交由编译器推导。

### 3.1 显式标注

显式返回值类型写在参数列表与函数体之间：

```cangjie
func add(a: Int64, b: Int64): Int64 {
    return a + b
}
```

此时要求函数体类型以及所有 `return e` 中 `e` 的类型都是返回值类型的子类型。若将 `return a + b` 改为 `return (a, b)`，会因 `(Int64, Int64)` 与 `Int64` 不匹配而报错。

### 3.2 类型推断

未显式标注返回值类型时，编译器将根据函数体类型与所有 `return` 表达式共同推导：

```cangjie
func add(a: Int64, b: Int64) {
    return a + b // 推导为 Int64
}
```

> **注意**
> 并非所有情况下返回值类型都能被推导，推导失败时编译器会报错。指定返回类型为 `Unit` 时，编译器会在函数体所有可能返回的地方自动插入 `return ()`，使得返回类型总是 `Unit`。

### 3.3 return 的两种形式

函数体中可以用 `return` 表达式终止执行并返回，共有两种形式：

- `return expr`：要求 `expr` 的类型与函数返回值类型一致：

```cangjie
func foo(): String {
    return "hello" // 正确：String 与 String 一致
    // return 100  // 错误：Int64 与 String 不一致
}
```

- `return`：等价于 `return ()`，要求函数返回值类型为 `Unit`：

```cangjie
func initApp(): Unit {
    println("init")
    return
}
```

作为整体，`return` 表达式本身的类型是 `Nothing`，因为执行它后不会继续执行后续表达式。这与控制流中 `break`/`continue` 的类型一致。

## 4. 函数体

函数体中定义了函数被调用时执行的操作，通常包含变量定义和表达式，也可以包含新的函数定义（即嵌套函数）：

```cangjie
func add(a: Int64, b: Int64) {
    var r = 0
    r = a + b
    return r
}
```

### 4.1 函数体类型

函数体也是有类型的，类型是函数体内最后一“项”的类型：若最后一项是表达式，则函数体类型是该表达式的类型；若最后一项是变量定义、函数声明或函数体为空，则函数体类型为 `Unit`。

```cangjie
func add(a: Int64, b: Int64): Int64 {
    a + b // 最后一项是 Int64 表达式，函数体类型为 Int64
}

func show(): Unit {
    let s = "Hello"
    print(s) // 最后一项是 print 调用，函数体类型为 Unit
}
```

这是仓颉中常见的返回值简写形式：当函数体最后一项是表达式且能满足返回值类型时，可以省略 `return`，直接以表达式结尾作为返回结果：

```cangjie
func greet(name!: String = "仓颉"): String {
    "你好, ${name}" // 最后一项即返回值
}
```

### 4.2 局部变量与嵌套函数

函数体内定义的变量属于局部变量，作用域从定义之后开始至函数体结束；函数体内定义的嵌套函数同样仅在该函数体内可见。

对于局部变量，允许在其外层作用域中已存在同名变量，此时局部变量会遮盖外层变量：

```cangjie
let r = 0
func add(a: Int64, b: Int64): Int64 {
    var r = 0   // 遮盖全局 r
    r = a + b
    return r
}
```

嵌套函数在外层函数调用时被定义，其主体逻辑将在后续文章中结合 Lambda、闭包深入展开。

## 5. 函数调用

函数调用的形式为 `f(arg1, arg2, ..., argn)`，其中 `f` 是函数名，`arg1` 到 `argn` 是实参序列，实参可以是 0 个或多个（`f()` 表示无参调用）。

### 5.1 根据参数种类传参

非命名参数的实参是表达式；命名参数的实参必须写成 `p: e`：

```cangjie
func calculate(a: Int64, b!: Int64): Int64 {
    return a + b
}

let x = 1
let y = 2
let r = calculate(x, b: y) // x 对应非命名参数 a，y 对应命名参数 b
```

再次强调，多个命名参数调用时允许与定义顺序不同：

```cangjie
func calculate(a: Int64, b!: Int64, c!: Int64 = 10): Int64 {
    a + b + c
}

let r = calculate(1, c: 20, b: 2) // r = 1 + 2 + 20 = 23
```

对于无参或只有命名参数且都有默认值的情况，可以直接 `f()` 调用，全部参数取默认值。

### 5.2 语言对比

#### 对比维度

| 特性 | 仓颉 | Go | Java |
|------|------|----|------|
| 参数命名区分 | 非命名参数 `p: T` 与命名参数 `p!: T` 并存，非命名在前 | 只有位置参数，不区分命名 | 只有位置参数，不区分命名 |
| 默认值 | 仅命名参数可设默认值 `p!: T = e` | 不支持默认值 | 不支持默认值 |
| 参数可变性 | 均为不可变，体内不可赋值 | 可变值拷贝，体内可修改形参 | 可变值/引用拷贝，体内可修改形参 |
| 返回值类型 | 可显式标注，也可推导；推导失败报错 | 必须显式标注（多返回值除外） | 必须显式标注 |
| 调用时命名参数顺序 | 命名参数可调换顺序 | 不支持命名参数 | 不支持命名参数 |

#### 详细分析

**仓颉实现:**

```cangjie
func greet(name!: String = "仓颉"): String {
    "你好, ${name}"
}
let r1 = greet()
let r2 = greet(name: "Alice")
```

**Go实现:**

```go
func greet(name string) string {
    if name == "" {
        name = "Gopher"
    }
    return "Hello, " + name
}
// Go 不支持默认值，需在函数体内模拟
```

**Java实现:**

```java
String greet(String name) {
    if (name == null) name = "Java";
    return "Hello, " + name;
}
String greet() { // Java 通过重载模拟默认值
    return greet("Java");
}
```

#### 迁移建议

- **从Go迁移**: 注意仓颉参数不可修改，习惯在函数内 `a = ...` 的 Go 写法需改用局部变量；默认值不再通过重载或可变参数模拟。
- **从Java迁移**: 仓颉命名参数的 `p: e` 调用方式与 Java 不同，默认值直接写在参数定义处，无需重载。

## 6. 一个完整示例

本示例组合了非命名参数、命名参数默认值、返回值推断、函数体类型简写、命名参数乱序调用和条件表达式：

<!-- example: cangjie/010-functions.cj -->
```cangjie
// 函数基础示例
func add(a: Int64, b: Int64): Int64 {
    return a + b
}

func greet(name!: String = "仓颉"): String {
    "你好, ${name}"
}

func calculate(a: Int64, b!: Int64, c!: Int64 = 10): Int64 {
    a + b + c
}

func showScore(score: Int64): String {
    if (score >= 60) {
        "及格"
    } else {
        "不及格"
    }
}

func describe(value: Int64): String {
    let label = if (value > 0) {
        "正数"
    } else {
        "非正数"
    }
    label
}

main() {
    let sum = add(3, 5)
    println("3 + 5 = ${sum}")

    let m1 = greet()
    let m2 = greet(name: "Alice")
    println(m1)
    println(m2)

    let r1 = calculate(1, b: 2)
    let r2 = calculate(1, b: 2, c: 20)
    let r3 = calculate(1, c: 20, b: 2)
    println("r1=${r1}, r2=${r2}, r3=${r3}")

    let s = showScore(85)
    println(s)

    let d = describe(10)
    println(d)
}
```

预期输出：

```text
3 + 5 = 8
你好, 仓颉
你好, Alice
r1=13, r2=23, r3=23
及格
正数
```

## 7. 常见问题

### Q1: 非命名参数和命名参数可以随意混排吗？

不可以。所有非命名参数必须位于命名参数之前，命名参数之后不能再出现非命名参数。

### Q2: 可以为非命名参数设置默认值吗？

不可以。只有命名参数 `p!: T = e` 允许设置默认值。

### Q3: 函数参数可以在函数体内赋值吗？

不可以。参数是不可变变量，如需修改应复制到局部 `var` 变量再操作。

### Q4: 返回值类型必须显式标注吗？

不需要。可以省略，由编译器根据函数体类型和所有 `return` 表达式推导；推导失败时会报错。

### Q5: 什么时候可以省略 `return`？

当函数体最后一项是表达式，且其类型满足返回值类型要求时，可以省略 `return`，直接以该表达式作为返回值。

### Q6: 命名参数调用时顺序有要求吗？

命名参数的实参可以与定义顺序不同，编译器按参数名匹配。

## 8. 总结

1. `func` 定义函数，非命名参数 `p: T` 在前，命名参数 `p!: T` 在后，仅命名参数可设默认值 `p!: T = e`。
2. 参数是不可变变量，作用域至函数体结束，局部同名定义会重定义报错，外层同名则被遮盖。
3. 返回值类型可选，显式标注需要与函数体类型和所有 `return e` 类型一致；省略时由编译器推导，`Unit` 会自动补 `return ()`。
4. `return` 与 `return expr` 类型为 `Nothing`，函数体类型由最后一项决定，表达式结尾可简写返回值。
5. 调用时非命名参数按位置、命名参数用 `p: e` 且允许乱序，默认值在不传参时生效。
6. 函数类型、`Lambda`、闭包、重载、操作符重载、变长参数与 `const` 函数将在后续专题深入。

## 参考资料

1. 仓颉 1.0.5 LTS 基本概念：函数：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_programming_concepts/function.html
2. 仓颉 1.0.5 LTS 定义函数：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/function/define_functions.html
3. 仓颉 1.0.5 LTS 调用函数：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/function/call_functions.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
