# 仓颉变量与数据类型

> **摘要**: 变量和数据类型是编程语言的基础。本文从仓颉变量声明的统一形式开始，区分 `let`、`var` 和 `const` 的语义，再介绍类型注解、类型推断以及整数、浮点、布尔、字符和字符串类型。文中还会说明整数默认类型、常量求值和显式类型转换，并对比仓颉、Go 和 Java 的相关写法。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 了解程序、变量和类型的基本概念
- 已完成《仓颉开发环境搭建与 Hello World》

## 1. 变量声明：let、var 与 const

### 1.1 使用 let 声明不可变变量

仓颉变量声明的基本形式是：

```text
修饰符 变量名: 变量类型 = 初始值
```

定义变量时，可变性修饰符是必要的。`let` 和 `var` 都是变量修饰符：`let` 变量只能被赋值一次，`var` 变量可以被多次赋值。`const` 是用于编译时常量求值的特殊修饰符，虽然同样具有不可变特性，但在使用上比 `let` 更严格。

```text
let language: String = "Cangjie"
```

`let` 适合表示只需要一次赋值的数据。需要强调的是，“不可变”描述的是变量绑定不能再次赋值；对于引用类型，仍需结合类型本身的可变性分析对象成员是否可以修改。

如果 `let` 变量已经完成初始化，再次赋值会导致编译错误：

```text
let count = 1
// count = 2  // 错误：let 声明的变量不能重新赋值
```

### 1.2 使用 var 声明可变变量

需要在运行过程中多次赋值时，使用 `var`：

```text
var count = 1
count = 2
```

`var` 变量重新赋值时，新的值必须符合原变量的类型。`var` 允许改变变量绑定的值，但不意味着可以把任意类型的值写入同一个变量。

> **建议**: 如果变量不需要变化，使用 `let`；只有确实需要重新赋值时才使用 `var`。

### 1.3 使用 const 声明常量

`const` 变量在编译时完成求值，必须在声明时提供初始化表达式，并且运行时不可改变：

```text
const maxRetries: Int64 = 3
const gravity = 6.674e-11
```

`const` 可以出现在全局、局部和静态成员变量中，但不能在扩展中定义。它的初始化表达式必须是 `const` 表达式，例如字面量、其他 `const` 值、符合要求的 `const` 函数调用以及满足限制的算术或关系表达式。`const` 变量具有深度不可变语义，所引用实例的成员也不能再作为左值使用。后续文章会专门介绍常量求值和 `const` 函数。

## 2. 初始化与类型注解

### 2.1 类型注解的写法

类型注解写在变量名之后，使用冒号分隔：

```text
let age: Int64 = 25
let height: Float64 = 1.68
let enabled: Bool = true
let title: String = "仓颉"
```

类型注解表达了两个信息：

1. 变量名是什么。
2. 变量允许保存哪一种类型的值。

当初始化值的类型与注解不一致时，编译器会报告类型错误，而不是等到运行时才发现问题。

### 2.2 为什么要初始化

全局变量和静态成员变量必须在声明时初始化。局部变量和实例成员变量可以先声明、后初始化，但必须在被引用前完成初始化：

```text
let retryCount: Int64 = 0
var message: String = "等待中"
```

局部 `let` 变量也可以先声明、后完成一次初始化：

```text
let message: String
message = "等待中"
```

编译器会保守地检查所有控制流路径，无法确定变量在使用前一定完成初始化，或无法确定不可变变量是否会被重复初始化时，会报告编译错误。

## 3. 类型推断

仓颉可以根据初始化表达式推断变量类型，因此很多时候不需要重复写类型注解：

```text
let count = 25       // 推断为 Int64
let ratio = 1.68     // 推断为 Float64
let ready = true     // 推断为 Bool
let name = "Alice"  // 推断为 String
```

类型推断不会削弱静态类型检查。编译器只是替你补充了类型信息，变量仍然具有明确的静态类型。

### 3.1 什么时候使用类型注解

以下情况适合显式写类型：

- 类型不容易从表达式中看出来。
- 变量是公开接口、类成员或函数参数的一部分。
- 需要让编译器检查某个值是否符合预期类型。
- 代码需要强调一个重要的类型选择。

以下情况可以优先使用类型推断：

- 初始化表达式已经清楚表达了类型。
- 局部变量的类型不会影响读者理解。
- 重复写类型反而让代码变得冗长。

类型推断和类型注解不是二选一的编程风格，而是根据可读性和接口清晰度灵活选择。

## 4. 常用基础数据类型

### 4.1 整数类型

仓颉没有不带位宽的通用 `Int` 类型。整数类型包括有符号的 `Int8`、`Int16`、`Int32`、`Int64`、`IntNative`，以及无符号的 `UInt8`、`UInt16`、`UInt32`、`UInt64`、`UIntNative`。

在没有类型上下文时，整数字面量默认推断为 `Int64`：

```text
let year: Int64 = 2026
var attempts: Int64 = 0
attempts = attempts + 1
```

整数字面量也可以通过后缀指定类型，例如 `100i8`、`0x10u64`。整数常用于计数、索引和状态标记，不同数值类型之间不能依赖隐式转换。

### 4.2 浮点类型

仓颉的浮点类型包括 `Float16`、`Float32` 和 `Float64`。其中 `Float64` 是双精度浮点类型：

```text
let price: Float64 = 19.9
let temperature: Float64 = 26.5
```

浮点数适合表示测量值、比例和近似数值。涉及金额或需要精确比较时，应根据具体业务选择合适的表示方式，不要直接依赖浮点数的二进制精确性。

### 4.3 Bool：布尔类型

`Bool` 只有 `true` 和 `false` 两个值，通常用于表达条件状态：

```text
let loggedIn: Bool = true
let hasPermission: Bool = false
```

布尔值适合直接表达“是否满足某个条件”，不要用整数 `0` 和 `1` 替代布尔语义。

### 4.4 Rune：字符类型

`Rune` 用于表示 Unicode 字符，可以表示 Unicode 字符集中的所有字符。Rune 字面量必须以 `r` 开头，后面跟单引号或双引号包围的字符。

```text
let initial: Rune = r'A'
let quoted: Rune = r"B"
```

Rune 字面量有三种常见形式：普通字符、转义字符和通用字符。转义字符以反斜杠开头，通用字符使用 `\u{}` 表示 Unicode 值：

```text
let slash: Rune = r'\\'
let newLine: Rune = r'\n'
let chinese: Rune = r'\u{4f60}'
```

Rune 支持按 Unicode 值进行 `<`、`>`、`<=`、`>=`、`==` 和 `!=` 比较，也可以通过 `UInt32(rune)` 获取 Unicode scalar value，或通过 `Rune(number)` 从整数构造字符。字符类型与字符串类型不同，单个字符不能直接当作字符串使用。

### 4.5 Unit：只有一个值的类型

当表达式只关心副作用而不关心结果时，其类型是 `Unit`。`Unit` 只有一个值，字面量是 `()`。例如赋值表达式、循环表达式和只执行输出的函数调用都可以产生 `Unit`。

```text
let result: Unit = ()
```

### 4.6 Nothing：不包含值的类型

`Nothing` 不包含任何值，并且是所有类型的子类型。`break`、`continue`、`return` 和 `throw` 表达式的类型是 `Nothing`，因为执行到这些表达式时，当前控制流不会继续执行后续代码。`Nothing` 不是一个可以自行构造值的普通数据类型。

### 4.7 String：字符串

`String` 用于表示由 Unicode 字符组成的文本数据。官方文档将字符串字面量分为三类。

#### 单行字符串

单行字符串使用一对单引号或双引号，不能跨越多行，并支持转义：

```text
let s1: String = "Hello Cangjie Lang"
let s2 = '可以使用单引号'
let s3 = "第一行\n第二行"
```

#### 多行字符串

多行字符串使用三个单引号或三个双引号，可以跨越多行：

```text
let message = """
    Hello,
    Cangjie Lang
    """
```

#### 多行原始字符串

多行原始字符串使用一对带井号的引号。开头和结尾的井号数量必须相同，内容中的转义序列会保持原样，不会被解释：

```text
let raw = ###"
    原样保留 \\n、缩进和其他字符
    "###
```

#### 插值字符串

插值字符串允许在字符串中嵌入表达式。插值表达式使用 `${}` 包围，表达式的最后一项结果会替换对应位置；多行原始字符串不支持插值：

```text
let name = "Alice"
let count = 10
let greeting = "${name} has ${count} apples"
let area = "area=${let pi = 3.14; pi * 2.0}"
```

#### 字符串操作

String 支持关系比较和 `+` 拼接，也可以使用标准库提供的操作进行包含判断和分割：

```text
let left = "abc"
let right = "ABCabc"
let same = left == right
let joined = left + right
let found = right.contains(left)
let parts = right.split(left)
```

字符串字面量、插值表达式和字符串 API 的具体行为必须以对应版本官方文档为准，不能凭其他语言经验推断。

### 4.8 结构化基础类型的后续安排

官方基础数据类型章节还包括 Tuple、Array 和 Range。它们不是本篇遗漏的内容：本篇先建立类型和变量模型，下一阶段将在《数组、元组与区间》中分别深入讲解声明、访问、解构、边界和遍历规则。

## 5. 一个完整示例

下面的示例把变量声明、类型注解、类型推断和可变变量放在一起。

<!-- example: cangjie/007-variables-and-types.cj -->
```cangjie
// 变量与数据类型示例
main() {
    let name: String = "Alice"
    let age: Int64 = 25
    let height: Float64 = 1.68
    let isStudent: Bool = true
    let initial: Rune = r'A'
    let inferredCount = 10
    let greeting = "${name} is ${age} years old"
    let unitValue: Unit = ()
    var score: Int64 = 90
    const maxScore: Int64 = 100

    score = score + 5

    println("姓名: ${name}")
    println("年龄: ${age}")
    println("身高: ${height}")
    println("是否为学生: ${isStudent}")
    println("姓名首字母: ${initial}")
    println("推断的数量: ${inferredCount}")
    println(greeting)
    println("Unit值: ${unitValue}")
    println("成绩: ${score}/${maxScore}")
}
```

预期输出：

```text
姓名: Alice
年龄: 25
身高: 1.68
是否为学生: true
姓名首字母: A
推断的数量: 10
Alice is 25 years old
Unit值: ()
成绩: 95/100
```

这个示例中：

- `name`、`age`、`height` 和 `isStudent` 使用 `let`，初始化后不再改变。
- 这些变量使用了显式类型注解，便于读者直接看到类型。
- `initial` 展示了 `Rune` 字符字面量，`unitValue` 展示了 `Unit` 的唯一值 `()`。
- `inferredCount` 和 `greeting` 展示了类型推断与字符串插值。
- `score` 使用 `var` 并显式声明为 `Int64`，展示了可变变量的重新赋值。
- `maxScore` 使用 `const`，其初始化值在编译时求值。
- `score = score + 5` 展示了可变变量的重新赋值。
- `println` 中的 `${...}` 展示了字符串插值。

## 6. 与 Go 和 Java 对比

### 6.1 变量声明对比

| 场景 | 仓颉 | Go | Java |
|------|------|------|------|
| 不可变绑定 | `let name = "Alice"` | Go 没有通用的不可变局部变量 | Java 通常使用 `final` |
| 可变变量 | `var count = 0` | `count := 0` 或 `var count int` | `int count = 0` |
| 编译时常量 | `const limit = 100` | `const limit = 100` | `final int limit = 100` |
| 显式类型 | `let age: Int64 = 25` | `var age int = 25` | `int age = 25` |
| 字符串类型 | `String` | `string` | `String` |

### 6.2 类型推断的差异

- **仓颉**: 可以使用 `let`、`var` 或 `const`；整数字面量在无类型上下文时默认推断为 `Int64`。
- **Go**: 使用 `:=` 进行短变量声明，也可以使用 `var` 配合类型声明。
- **Java**: 局部变量可以使用 `var` 进行类型推断，但 `var` 仍然表示静态类型，不能脱离初始化表达式使用。

不要只根据关键字名称判断语义。例如，仓颉的 `var` 表示可变变量，而 Java 的 `var` 主要表示局部变量类型推断，两者不是同一个概念。

## 7. 常见问题

### Q1: `let` 和 `var` 应该怎么选？

先使用 `let`。如果后续确实需要重新赋值，再改用 `var`。这能缩小变量的可变范围，降低维护成本。

### Q2: `const` 和 `let` 有什么区别？

`let` 是只允许一次赋值的变量修饰符，可以先声明、后初始化；`const` 是编译时常量，必须在声明时提供可在编译时求值的初始化表达式，并且具有更严格的限制。

### Q3: 类型推断是不是动态类型？

不是。类型推断发生在编译阶段，编译器仍然会为变量确定静态类型，并在编译时检查类型错误。

### Q4: 为什么整数和浮点数不能直接混用？

整数和浮点数的表示方式和计算语义不同。仓颉的静态类型检查会阻止不明确的混合运算，避免程序在没有明确意图的情况下发生数值转换。

### Q5: 所有变量都应该写类型注解吗？

不需要。局部变量的初始化表达式已经足够清晰时，可以使用类型推断；公共接口或容易产生歧义的地方，建议显式写出类型。

## 8. 总结

### 核心要点

1. 使用 `let` 声明不可变变量，使用 `var` 声明可变变量。
2. 类型注解写在变量名之后，格式为 `变量名: 类型`。
3. 类型推断发生在编译阶段，不会把仓颉变成动态类型语言。
4. 整数类型使用明确位宽的 `Int8`、`Int16`、`Int32`、`Int64` 等名称；无上下文整数字面量默认是 `Int64`。
5. 常用基础类型包括 `Float16`、`Float32`、`Float64`、`Bool`、`Rune`、`String`、`Unit` 和 `Nothing`。
6. 字符串插值使用 `${表达式}`，可以把值嵌入字符串。

### 练习题

1. 将示例中的 `name`、`age` 和 `height` 替换为自己的信息。
2. 增加一个 `var` 变量，模拟商品数量从 1 增加到 2。
3. 尝试给变量写一个不匹配的类型注解，观察编译器的错误信息。

### 下一步学习

下一篇将介绍运算符与表达式，包括算术、比较和逻辑运算。

## 参考资料

1. 仓颉 1.0.5 LTS 程序结构与变量：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_programming_concepts/program_structure.html
2. 仓颉 1.0.5 LTS 整数类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/integer.html
3. 仓颉 1.0.5 LTS 浮点类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/float.html
4. 仓颉 1.0.5 LTS 布尔类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/bool.html
5. 仓颉 1.0.5 LTS 字符类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/characters.html
6. 仓颉 1.0.5 LTS 字符串类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/strings.html
7. 仓颉 1.0.5 LTS Unit 类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/unit.html
8. 仓颉 1.0.5 LTS Nothing 类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/nothing.html
9. 仓颉 1.0.5 LTS 常量求值：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/function/const_func_and_eval.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
