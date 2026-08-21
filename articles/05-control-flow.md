# 仓颉控制流语句

> **摘要**: 控制流决定程序执行哪些分支、重复哪些操作以及何时提前结束。本文依据仓颉 1.0.5 LTS 官方文档，系统介绍 `if`、`match`、`for-in`、`while`、`do-while`、`where`、`break` 和 `continue`，重点解释它们作为表达式时的类型、穷尽性、区间遍历和控制转移语义。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已了解变量、Bool、Int64、Range 和表达式
- 已完成《仓颉运算符与表达式》

## 1. 控制流也是表达式

仓颉把所有可求值的语言元素都视为表达式，因此控制流不只是改变执行顺序，也可能产生值和类型：

- `if` 可以根据条件选择一个值。
- `match` 可以根据模式选择一个值。
- `for-in`、`while` 和 `do-while` 的类型是 `Unit`，值为 `()`。
- `break` 和 `continue` 的类型是 `Nothing`，因为它们不会继续执行当前循环后面的代码。

代码块由一组按顺序执行的表达式构成。代码块最后一个表达式的值和类型就是代码块的值和类型；空代码块的类型和值分别是 `Unit` 和 `()`。

## 2. if 表达式

### 2.1 基本分支

`if` 的基本形式如下：

```cangjie
if (条件) {
    分支一
} else {
    分支二
}
```

条件必须是 `Bool` 表达式，不能把整数或浮点数当成 C 语言中的真假值：

```cangjie
let count: Int64 = 1
// if (count) { }  // 错误：if 条件必须是 Bool
```

`else` 可以省略。当只关心条件成立时执行的副作用，不关心 `if` 的值时，省略 `else` 的 `if` 表达式类型为 `Unit`。

### 2.2 多分支条件

多个条件可以通过 `else if` 连接：

```cangjie
func readScore(): Int64 {
    82
}

let score = readScore()
let level = if (score >= 90) {
    "A"
} else if (score >= 60) {
    "B"
} else {
    "C"
}
```

当 `if` 作为变量初值使用时，它的类型必须能够由各分支代码块确定。如果上下文没有明确类型，所有分支需要有兼容的最小公共父类型；如果分支类型互不兼容，编译器会报告错误。

### 2.3 if 的条件和结果类型

下面的 `if` 表达式各分支都是 `String`，因此结果可以推断为 `String`：

```cangjie
let message = if (ready) {
    "可以开始"
} else {
    "请等待"
}
```

如果明确标注了结果类型，各分支需要符合该类型要求：

```cangjie
let message: String = if (ready) {
    "可以开始"
} else {
    "请等待"
}
```

不要让不同分支返回没有公共类型关系的值，例如一个分支返回 `String`、另一个分支返回 `Int64`。

## 3. match 表达式

### 3.1 按值匹配

带匹配值的 `match` 由一个待匹配表达式和多个 `case` 分支组成：

```cangjie
let level = "B"
match (level) {
    case "A" => println("优秀")
    case "B" => println("合格")
    case _ => println("需要继续练习")
}
```

`case` 后面是模式，`=>` 后面是匹配成功后执行的代码。匹配成功后，后续 `case` 不再执行。

### 3.2 穷尽性

`match` 必须穷尽，即覆盖待匹配值的所有可能情况。最简单的方式是在最后使用 `_`：

```cangjie
let value: Int64 = 3
let description = match (value) {
    case 0 => "零"
    case 1 => "一"
    case _ => "其他值"
}
```

缺少 `_` 或其他能够覆盖剩余情况的模式时，编译器可能报告 `match` 非穷尽。穷尽性是编译期约束，不应通过运行时的默认分支来弥补。

### 3.3 match 作为值

和 `if` 一样，`match` 可以作为变量初始化值或函数返回值。各 `case` 分支的结果需要满足上下文类型要求：

```cangjie
let label: String = match (value) {
    case 0 => "零"
    case _ => "非零"
}
```

没有使用 `match` 的值时，它的类型为 `Unit`，分支的最后表达式不需要形成统一结果类型。

### 3.4 无匹配值的 match

`match` 也可以不写待匹配值，此时每个 `case` 后面是一个 `Bool` 表达式：

```cangjie
let temperature: Int64 = 25
match {
    case temperature < 0 => println("冰点以下")
    case temperature > 30 => println("炎热")
    case _ => println("舒适")
}
```

分支按顺序判断，遇到第一个值为 `true` 的 `case` 后执行并退出。最后的 `_` 表示 `true`，通常用于兜底。

### 3.5 模式守卫

模式后可以使用 `where` 增加布尔条件。模式先匹配，守卫条件再判断：

```cangjie
enum Result {
    | Success(Int64)
    | Failure(String)
}

let result = Result.Success(100)
let message = match (result) {
    case Success(value) where value >= 60 => "通过"
    case Success(_) => "未通过"
    case Failure(reason) => reason
}
```

枚举模式和模式守卫将在后续模式匹配专题中继续深入。本文只使用它们说明控制流的穷尽匹配和分支选择。

## 4. while 表达式

`while` 先判断条件，再决定是否执行循环体：

```cangjie
var countdown: Int64 = 3
while (countdown > 0) {
    println(countdown)
    countdown -= 1
}
```

如果第一次判断条件就是 `false`，循环体一次也不会执行。`while` 表达式的类型是 `Unit`。

条件必须是 `Bool`，并且每次循环都要有机会改变相关状态，否则程序可能无法结束：

```cangjie
var index: Int64 = 0
while (index < 3) {
    index += 1
}
```

## 5. do-while 表达式

`do-while` 先执行循环体，再判断条件，因此循环体至少执行一次：

```cangjie
var attempts: Int64 = 0
    attempts += 1
} while (attempts < 2)
```

`do-while` 适合“先执行一次，再决定是否继续”的场景，例如首次读取输入或首次尝试操作。

## 6. for-in 表达式

`for-in` 遍历实现 `Iterable<T>` 的序列。仓颉内置的数组和区间都可以被遍历：

```cangjie
for (number in 1..=5) {
    println(number)
}
```

序列表达式只求值一次，然后初始化迭代器。每轮循环将当前元素绑定到迭代变量。

### 6.1 遍历区间

区间 `1..5` 是左闭右开，遍历 `1、2、3、4`；`1..=5` 是左闭右闭，遍历 `1、2、3、4、5`。区间也可以指定步长：

```cangjie
for (number in 10..0 : -2) {
    println(number)
}
```

步长不能为 0。起点、终点和步长方向不匹配时，区间可能为空。

### 6.2 where 条件

`for-in` 的序列后面可以使用 `where` 过滤迭代值：

```cangjie
for (number in 0..8 where number % 2 == 1) {
    println(number)
}
```

只有 `where` 条件为 `true` 时，当前元素才进入循环体。它比在循环体开头写 `if` 更直接地表达“只遍历满足条件的元素”。

### 6.3 元组迭代变量

当序列中的元素是元组时，迭代变量也可以使用元组形式进行解构：

```cangjie
let pairs = [(1, 2), (3, 4)]
for ((left, right) in pairs) {
    println("${left}, ${right}")
}
```

迭代变量不能在循环体中重新赋值。如果不需要使用当前元素，可以使用 `_`，避免产生未使用变量告警：

```cangjie
for (_ in 0..5) {
    println("执行一次")
}
```

## 7. break 与 continue

### 7.1 break

`break` 终止当前循环，转而执行循环表达式之后的代码：

```cangjie
var firstMultiple: Int64 = 0
for (number in 1..=20) {
    if (number % 4 == 0) {
        firstMultiple = number
        break
    }
}
```

`break` 只能直接出现在循环体中，不能放在嵌套函数中借此跳出外层循环。

### 7.2 continue

`continue` 提前结束当前轮循环，进入下一轮：

```cangjie
for (number in 1..=5) {
    if (number == 3) {
        continue
    }
    println(number)
}
```

`break` 和 `continue` 的类型都是 `Nothing`，因为执行它们后不会继续执行当前循环体中后面的表达式。

## 8. 一个完整示例

下面的示例组合了条件分支、`match`、区间遍历、`continue`、`while`、`do-while` 和 `break`。

<!-- example: cangjie/009-control-flow.cj -->
```cangjie
// 控制流示例
func readScore(): Int64 {
    82
}

main() {
    let score = readScore()
    let level = if (score >= 90) {
        "A"
    } else if (score >= 60) {
        "B"
    } else {
        "C"
    }

    println("等级: ${level}")

    match (level) {
        case "A" => println("优秀")
        case "B" => println("合格")
        case _ => println("需要继续练习")
    }

    var sum: Int64 = 0
    for (number in 1..=5) {
        if (number == 3) {
            continue
        }
        sum += number
    }
    println("跳过 3 后的总和: ${sum}")

    var countdown: Int64 = 3
    while (countdown > 0) {
        countdown -= 1
    }

    var attempts: Int64 = 0
    do {
        attempts += 1
    } while (attempts < 2)
    println("do-while 执行次数: ${attempts}")

    var firstMultiple: Int64 = 0
    for (number in 1..=20) {
        if (number % 4 == 0) {
            firstMultiple = number
            break
        }
    }
    println("第一个 4 的倍数: ${firstMultiple}")
}
```

预期输出：

```text
等级: B
合格
跳过 3 后的总和: 12
do-while 执行次数: 2
第一个 4 的倍数: 4
```

## 9. 常见问题

### Q1: `if` 和 `match` 有什么区别？

`if` 主要根据布尔条件分支；`match` 根据模式匹配值或条件，并且要求分支覆盖所有可能情况。

### Q2: 为什么 `match` 最后经常写 `_`？

因为 `match` 必须穷尽，`_` 可以匹配剩余所有情况，帮助编译器确认不存在遗漏分支。

### Q3: `while` 和 `do-while` 怎么选择？

需要先判断条件时使用 `while`；需要保证循环体至少执行一次时使用 `do-while`。

### Q4: `break` 和 `continue` 能用于任意代码块吗？

不能。它们必须位于对应的循环体中，不能通过嵌套函数间接控制外层循环。

## 10. 总结

1. `if`、`match`、循环和代码块都是具有类型和值的表达式。
2. `if` 条件必须是 `Bool`，有值的分支需要满足类型兼容规则。
3. `match` 必须穷尽，`_` 是常见的兜底模式。
4. `while` 先判断，`do-while` 先执行，`for-in` 遍历可迭代序列。
5. `where` 可以过滤 `for-in` 的迭代值。
6. `break` 终止循环，`continue` 跳过当前轮，二者类型都是 `Nothing`。

## 参考资料

1. 仓颉 1.0.5 LTS 表达式：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_programming_concepts/expression.html
2. 仓颉 1.0.5 LTS match 表达式：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/match.html
3. 仓颉 1.0.5 LTS 区间类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/range.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
