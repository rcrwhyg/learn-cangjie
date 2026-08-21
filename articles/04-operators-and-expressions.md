# 仓颉运算符与表达式

> **摘要**: 仓颉把所有可求值的语言元素都视为表达式，表达式不仅有计算结果，还有确定的静态类型。本文从表达式的基本模型出发，系统介绍算术、比较、逻辑、位、区间、赋值和复合赋值运算符，并结合官方优先级表解释复杂表达式的求值顺序。文章还会说明短路求值、类型限制、显式转换，以及暂不展开的高级运算符。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已了解变量、基础数据类型和字符串插值
- 已完成《仓颉变量与数据类型》

## 1. 仓颉中的表达式

### 1.1 表达式一定有类型

在传统语言中，表达式通常指由操作数和运算符组成的计算式。仓颉对表达式的定义更广：凡是可以求值的语言元素都是表达式，包括条件表达式、循环表达式和 `try` 表达式。

每个表达式都有两个重要属性：

- **值**：表达式求值后得到的结果。
- **类型**：编译器为表达式确定的静态类型。

例如，`1 + 2` 的值是 `3`，类型是 `Int64`；`true && false` 的值是 `false`，类型是 `Bool`。表达式的结果可以作为变量初始化值或函数实参。

### 1.2 表达式之间的分隔

仓颉使用分号 `;` 分隔语句或表达式。同一行存在多条表达式时，必须使用分号；一条表达式独占一行时，分号通常可以省略：

```cangjie
let first = 1
let second = 2; let third = 3
```

本文重点讨论由运算符构成的表达式。`if`、循环、`match` 和 `try` 的完整语义会在后续文章中分别展开。

## 2. 算术运算符

### 2.1 基本算术

仓颉支持加法 `+`、减法 `-`、乘法 `*`、除法 `/` 和取模 `%`：

```cangjie
let a: Int64 = 10
let b: Int64 = 3
let sum = a + b       // 13
let difference = a - b // 7
let product = a * b   // 30
let quotient = a / b  // 3
let remainder = a % b // 1
```

整数除法的结果仍然是整数。整数和浮点数的运算规则不同，不能把不同数值类型的混合运算当作自动转换。

### 2.2 一元负号与幂运算

一元 `-` 用于得到数值的相反数。`**` 用于幂运算：

```cangjie
let negative = -5
let square = 2 ** 3
let decimalPower = 2.0 ** 3.0
```

官方规则对幂运算的操作数类型有额外限制，整数和浮点数的组合不能任意混用。遇到不同数值类型时，应先根据官方类型转换规则显式转换，再进行运算。

### 2.3 浮点数运算

浮点类型支持算术和关系运算，但不支持自增和自减运算符。浮点计算还可能产生表示误差，因此不要直接用 `==` 判断两个经过计算的浮点数是否完全相等，除非业务场景明确允许这样做。

## 3. 比较运算符

比较运算符的结果是 `Bool`：

```cangjie
let a: Int64 = 10
let b: Int64 = 3
let less = a < b
let lessOrEqual = a <= b
let greater = a > b
let greaterOrEqual = a >= b
let equal = a == b
let notEqual = a != b
```

比较运算符两侧的操作数必须满足对应类型的比较规则。仓颉是静态强类型语言，不能像 C 语言那样把整数或浮点数直接当作条件使用：

```cangjie
let count: Int64 = 1
// if (count) { }  // 错误：if 条件必须是 Bool
```

字符 `Rune` 的比较依据是 Unicode 值，字符串支持关系比较。不同类型之间的比较不能依赖隐式转换。

## 4. 逻辑运算符

### 4.1 非、与、或

逻辑非 `!`、逻辑与 `&&` 和逻辑或 `||` 只能用于布尔逻辑：

```cangjie
let ready = true
let valid = false
let notReady = !ready
let both = ready && valid
let either = ready || valid
```

`&&` 和 `||` 具有短路行为：

- `left && right`：如果 `left` 为 `false`，不会求值 `right`。
- `left || right`：如果 `left` 为 `true`，不会求值 `right`。

短路行为适合把前置条件和可能产生问题的操作组合起来：

```cangjie
if (value != 0 && 100 / value > 2) {
    println("满足条件")
}
```

不要把带副作用的操作随意放在逻辑表达式右侧，否则短路可能导致该操作不执行。

### 4.2 逻辑复合赋值

布尔变量支持 `&&=` 和 `||=`：

```cangjie
var enabled = true
enabled ||= true
```

复合赋值的左侧必须是可以被赋值的变量，不能是 `let` 变量或临时表达式。

## 5. 位运算符

整数类型支持按位非 `!`、左移 `<<`、右移 `>>`、按位与 `&`、按位异或 `^` 和按位或 `|`。注意：`!` 根据操作数类型承担不同语义，对 `Bool` 是逻辑非，对整数是按位求反。

```cangjie
let left: Int64 = 0b1010
let right: Int64 = 0b1100
let bitAnd = left & right
let bitOr = left | right
let bitXor = left ^ right
let bitNot = !left
let shiftedLeft = left << 1
let shiftedRight = right >> 1
```

按位与、按位异或和按位或要求两侧是相同的整数类型。位移操作也必须遵守官方定义的操作数类型和范围规则，不要直接套用其他语言的隐式转换经验。

## 6. 区间运算符

仓颉提供两个区间运算符：

- `..`：左闭右开区间，不包含右端点。
- `..=`：左闭右闭区间，包含右端点。

```cangjie
let openRange = 1..5   // 1、2、3、4
let closedRange = 1..=5 // 1、2、3、4、5
```

区间可以被 `for-in` 遍历：

```cangjie
var sum: Int64 = 0
for (number in 1..=5) {
    sum += number
}
```

区间的边界类型、方向和遍历行为必须结合官方 Range 类型章节理解。数组、元组和区间的完整使用会在后续文章中展开。

## 7. 赋值和复合赋值

### 7.1 赋值运算符

`=` 把右侧表达式的值赋给左侧可赋值对象：

```cangjie
var count: Int64 = 1
count = 2
```

左侧必须是可赋值的变量或可变成员。`let` 和 `const` 变量不能在初始化后再次赋值。

### 7.2 复合赋值运算符

仓颉支持以下复合赋值运算符：

```cangjie
var value: Int64 = 10
value += 2
value -= 1
value *= 3
value /= 2
value %= 4
value **= 2
value <<= 1
value >>= 1
value &= 7
value ^= 3
value |= 1
```

布尔变量还可以使用 `&&=` 和 `||=`。复合赋值要求左侧可修改，并且运算结果必须符合左侧变量的类型。

## 8. 显式类型转换

仓颉不支持不同数值类型之间的隐式转换。数值类型之间需要使用目标类型的构造形式显式转换：

```cangjie
let small: Int8 = 10
let large: Int64 = Int64(small)
let decimal: Float64 = Float64(large)
let integer: Int64 = Int64(decimal)
```

类型转换可能发生溢出。编译器能够提前确定的溢出会报告编译错误，运行时才能确定的情况则可能抛出异常。转换前应确认范围和精度是否满足业务要求。

`is` 用于类型检查，`as` 用于可能失败的类型转换。这两个运算符的完整语义属于类型系统和类型转换主题，本文只记录它们位于官方操作符表中，不在此处展开。

## 9. 运算符优先级

官方操作符表的优先级数字越小，优先级越高。常见运算符从高到低大致如下：

| 优先级 | 运算符 | 说明 |
|------|------|------|
| 3 | `!`、一元 `-` | 逻辑/位非、负号 |
| 4 | `**` | 幂运算 |
| 5 | `*`、`/`、`%` | 乘除模 |
| 6 | `+`、`-` | 加减 |
| 7 | `<<`、`>>` | 位移 |
| 8 | `..`、`..=` | 区间 |
| 9 | `<`、`<=`、`>`、`>=`、`is`、`as` | 比较和类型操作 |
| 10 | `==`、`!=` | 判等 |
| 11-13 | `&`、`^`、`|` | 位运算 |
| 14-15 | `&&`、`||` | 逻辑与或 |
| 18 | `=` 及复合赋值 | 赋值 |

当表达式同时包含多类运算符时，不要依赖记忆推测。优先使用括号明确意图：

```cangjie
let result = (a + b) * c
let valid = (count > 0) && (total / count > 10)
```

幂运算是右结合，赋值运算符不结合；其他运算符的结合方向应以官方操作符表为准。

## 10. 一个完整示例

下面的示例覆盖本文介绍的算术、比较、逻辑、位、区间和赋值运算。

<!-- example: cangjie/008-operators-and-expressions.cj -->
```cangjie
// 运算符与表达式示例
main() {
    var left: Int64 = 10
    let right: Int64 = 3
    let ready: Bool = true

    let sum = left + right
    let difference = left - right
    let product = left * right
    let quotient = left / right
    let remainder = left % right
    let power = 2 ** 3

    let equal = left == right
    let greater = left > right
    let inRange = left >= 1 && left <= 10
    let notReady = !ready

    let bitAnd = left & right
    let bitOr = left | right
    let bitXor = left ^ right
    let shifted = left << 1

    let openRange = 1..5
    let closedRange = 1..=5
    var openCount = 0
    var closedCount = 0
    for (_ in openRange) {
        openCount += 1
    }
    for (_ in closedRange) {
        closedCount += 1
    }

    left += 2
    var enabled = true
    enabled &&= false

    println("算术: ${sum}, ${difference}, ${product}, ${quotient}, ${remainder}, ${power}")
    println("比较: ${equal}, ${greater}, ${inRange}, ${notReady}")
    println("位运算: ${bitAnd}, ${bitOr}, ${bitXor}, ${shifted}")
    println("区间元素个数: ${openCount}, ${closedCount}")
    println("赋值: ${left}, ${enabled}")
}
```

预期输出：

```text
算术: 13, 7, 30, 3, 1, 8
比较: false, true, true, false
位运算: 2, 11, 6, 20
区间元素个数: 4, 5
赋值: 12, false
```

## 11. 常见问题

### Q1: 为什么 `if (1)` 不合法？

仓颉的条件必须是 `Bool` 表达式，不会把整数的 0 或非 0 自动转换成布尔值。

### Q2: `!` 是逻辑非还是按位非？

两者都可以。对 `Bool` 使用时是逻辑非，对整数使用时是按位求反，具体语义由操作数类型决定。

### Q3: 为什么 `Int64 + Float64` 不能直接计算？

仓颉不支持不同数值类型之间的隐式转换，需要显式转换为兼容类型后再计算。

### Q4: `1..5` 包含 5 吗？

不包含。`..` 是左闭右开，`1..=5` 才包含右端点 5。

## 12. 总结

1. 仓颉表达式不仅是算术计算式，还包括可求值的控制结构，并且每个表达式都有确定类型。
2. 算术、比较、逻辑和位运算必须遵守静态类型规则。
3. `&&` 和 `||` 具有短路求值行为。
4. `..` 和 `..=` 分别表示左闭右开和左闭右闭区间。
5. 赋值和复合赋值要求左侧可修改。
6. 不同数值类型之间必须显式转换。
7. 复杂表达式应使用括号，并以官方优先级表核对求值顺序。

## 参考资料

1. 仓颉 1.0.5 LTS 表达式：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_programming_concepts/expression.html
2. 仓颉 1.0.5 LTS 整数类型与操作：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/integer.html
3. 仓颉 1.0.5 LTS 浮点类型与操作：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/float.html
4. 仓颉 1.0.5 LTS 布尔类型与操作：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/bool.html
5. 仓颉 1.0.5 LTS 操作符优先级：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/Appendix/operator.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
