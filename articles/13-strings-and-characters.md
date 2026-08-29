# 仓颉字符串与字符处理

> **摘要**: 字符串与字符是几乎所有程序都要处理的基础数据。仓颉使用 `String` 表示 Unicode 文本，使用 `Rune` 表示单个 Unicode 字符。本文依据仓颉 1.0.5 LTS 官方文档，系统介绍字符串的三种字面量、字符串插值、关系运算与拼接、常用方法，以及 `Rune` 字符字面量、Unicode 通用字符、关系运算和与 `UInt32` 的相互转换。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已了解变量、函数、字符串插值基础
- 已了解 `Array<T>`、区间 `Range`
- 已完成《仓颉变量与数据类型》《仓颉数组、元组与区间》

## 1. 字符串字面量

仓颉的字符串字面量分为三类：**单行字符串字面量**、**多行字符串字面量**、**多行原始字符串字面量**。所有字面量在编译期被求值为 `String` 类型的值。

### 1.1 单行字符串字面量

单行字符串的内容被一对单引号或一对双引号包围，**只能写在同一行**。在引号内，除了用于包围的引号和单独出现的反斜杠 `\` 之外，其他字符都可以直接使用；反斜杠和引号需要用 `\` 转义。

```cangjie
let s1: String = ""                            // 空字符串
let s2: String = "Hello, Cangjie"              // 双引号
let s3: String = 'Hello, Cangjie'              // 单引号（与双引号等价）
let s4: String = "包含 \"双引号\" 的字符串"     // 用 \" 转义
let s5: String = "Hello, Cangjie\n"            // \n 表示换行
let s6: String = "反斜杠 \\ 用 \\\\ 表示"      // \\ 表示单个反斜杠
```

仓颉 1.0.5 中 `String` 是结构体类型（值类型），但内部持有的是堆上分配的 UTF-8 字节序列。把它赋值给另一个 `let` 变量时不会复制底层字节，但两个变量都可以正常读取。

### 1.2 多行字符串字面量

多行字符串以 **三个双引号 `"""`** 或 **三个单引号 `'''`** 开头与结尾，**开头的三个引号必须单独占一行**。字面量内容从开头的三个引号所在行的下一行开始，到第一个非转义的三个引号为止。字面量内可以包含换行、制表符、单双引号等任意字符，只有反斜杠 `\` 仍需要转义。

```cangjie
let multi: String = """
    第一行
    第二行：x = ${10 + 20}
    第三行：包含 "双引号" 与 '单引号' 都不需要转义
"""
```

完整可运行示例（`examples/cangjie/017-strings-and-characters.cj`）：

<!-- example: cangjie/017-strings-and-characters.cj -->
```cangjie
// 字符串与字符处理示例
// 演示：字符串字面量（单行 / 多行 / 多行原始）、字符串插值、字符串关系运算与拼接、
// 常用方法（size / contains / startsWith / endsWith / indexOf / count / split /
// replace / toAsciiUpper / toAsciiLower / isEmpty / toRuneArray）、Rune 字面量
// （单个字符 / 转义 / 通用 Unicode）、Rune 关系运算、Rune <-> UInt32 转换

main() {
    // ========== 1) 字符串字面量 ==========

    // 1.1 单行字符串：单引号与双引号等价
    let s1: String = "Hello, Cangjie"
    let s2: String = 'Hello, Cangjie'
    println("s1 == s2: ${s1 == s2}")

    // 单行字符串内允许常见转义
    let s3: String = "Hello, Cangjie\n"
    let s4: String = "包含 \"双引号\" 与 \\ 反斜杠"
    println(s3)
    println(s4)

    // 1.2 多行字符串：使用三引号，可跨行
    let multi: String = """
        第一行
        第二行：x = ${10 + 20}
    """
    println("--- 多行字符串 ---")
    println(multi)

    // 1.3 多行原始字符串：井号 + 引号，转义规则不适用
    let raw: String = ##"原文保留 \n 不是换行，\u{4f60} 也不会被解释"##
    println("--- 原始字符串 ---")
    println(raw)

    // ========== 2) 字符串插值 ==========

    let fruit: String = "apples"
    let count: Int64 = 10
    let s5: String = "There are ${count * count} ${fruit}"
    println(s5)

    // 插值内可放多表达式（用 ; 分隔），最终取最后一个表达式的值
    let r: Float64 = 2.4
    let area: String = "r=${r}, area=${let PI: Float64 = 3.141592; PI * r * r}"
    println(area)

    // ========== 3) 字符串关系运算与拼接 ==========

    let a: String = "abc"
    let b: String = "ABC"
    println("a == b: ${a == b}")     // false
    println("a < b: ${a < b}")       // false
    println("a != b: ${a != b}")     // true
    let joined: String = a + b
    println("a + b: ${joined}")      // abcABC

    // ========== 4) 字符串常用方法 ==========

    let text: String = "Hello, Cangjie Lang"
    println("size: ${text.size}")                    // 19
    println("isEmpty: ${text.isEmpty()}")            // false
    println("contains Cangjie: ${text.contains("Cangjie")}")  // true
    println("startsWith Hello: ${text.startsWith("Hello")}")  // true
    println("endsWith Lang: ${text.endsWith("Lang")}")        // true
    println("indexOf Cangjie: ${text.indexOf("Cangjie")}")    // 7
    println("count 'a': ${text.count("a")}")                  // 2
    println("upper: ${text.toAsciiUpper()}")
    println("lower: ${text.toAsciiLower()}")

    // split：按分隔符切分，返回 Array<String>
    let csv: String = "a,b,,c"
    let parts: Array<String> = csv.split(",")
    for (i in 0..parts.size) {
        println("parts[${i}] = ${parts[i]}")
    }

    // replace：替换全部匹配
    let replaced: String = "abcyyabcqqabcbc".replace("abc", "X")
    println("replaced: ${replaced}")

    // ========== 5) Rune 字符类型 ==========

    // 5.1 Rune 字面量：单个字符、转义字符、通用 Unicode
    let r1: Rune = r'A'                 // 单个字符
    let r2: Rune = r'\n'                // 转义字符：换行
    let r3: Rune = r'\t'                // 转义字符：制表符
    let r4: Rune = r'\u{4f60}'          // 你（通用字符，十六进制）
    let r5: Rune = r'\u{597d}'          // 好
    println("${r1}${r4}${r5}")          // A你好

    // 5.2 Rune 关系运算：按 Unicode 值比较
    println("r'a' < r'b': ${r'a' < r'b'}")        // true
    println("r'你' > r'A': ${r4 > r1}")           // true（你 = 0x4f60, A = 0x41）
    println("r'\\n' == r'\\n': ${r2 == r'\n'}")  // true
    println("r'\\t' == r'\\t': ${r3 == r'\t'}")  // true

    // 5.3 Rune 与 UInt32 互转
    let code: UInt32 = UInt32(r1)       // 'A' = 65
    let back: Rune = Rune(UInt32(65))
    println("UInt32('A') = ${code}")
    println("Rune(65) = ${back}")
    println("UInt32('你') = ${UInt32(r4)}")

    // ========== 6) String 与 Rune 互转 ==========

    // toRuneArray：把字符串拆为 Rune 数组（按 Unicode 码点）
    let cn: String = "你好, Cangjie"
    let runes: Array<Rune> = cn.toRuneArray()
    println("runes.size = ${runes.size}")  // 16
    println("runes[0] = ${runes[0]}")      // 你
    println("runes[2] = ${runes[2]}")      // ，

    // 字符串下标返回的是 Byte（UInt8），不是 Rune
    let firstByte: Byte = cn[0]
    println("cn[0] (Byte) = ${firstByte}")  // UTF-8 第一字节

    // ========== 7) 常见字符串处理模式 ==========

    // 7.1 用 for-in 遍历 Rune 数组，统计中文字符
    let sentence: String = "仓颉语言 Hello"
    var chineseCount: Int64 = 0
    var letterCount: Int64 = 0
    for (r in sentence.toRuneArray()) {
        // 中文基本平面：0x4e00 ~ 0x9fff
        let c: UInt32 = UInt32(r)
        if (c >= UInt32(0x4e00) && c <= UInt32(0x9fff)) {
            chineseCount += 1
        } else {
            letterCount += 1
        }
    }
    println("中文字符数: ${chineseCount}")
    println("其他字符数: ${letterCount}")

    // 7.2 用 split 解析简单 CSV 字符串
    let row: String = "Alice,30,Cangjie"
    let fields: Array<String> = row.split(",")
    let name: String = fields[0]
    let ageStr: String = fields[1]
    let lang: String = fields[2]
    println("name=${name}, age=${ageStr}, lang=${lang}")
}

```


### 1.3 多行原始字符串字面量

以 **一个或多个井号 `#`** 加上一个单引号或双引号开头，到相同数量的井号加上相同引号结束。**原始字符串内的转义规则不适用**，`\n`、`\u{4f60}` 等都按字面字符保留。

```cangjie
let raw1: String = #""#                                      // 空原始字符串
let raw2: String = ##"\n 不是换行，\u{4f60} 也不转义"##       // 两个井号
let raw3: String = ###"
    这一段里的换行、缩进会原样保留
    \n 也不会被当成换行符
"###
```

井号数量决定了字面量中可以安全地出现多少个连续的井号。井号数量越多，原始字符串中可以包含越多井号而不会提前结束字面量。

### 1.4 字面量小结

| 字面量类型 | 起始标记 | 结束标记 | 跨行 | 是否支持转义 |
|---|---|---|---|---|
| 单行字符串 | `"` 或 `'` | 与起始相同 | 否 | 是 |
| 多行字符串 | `"""` 或 `'''` | 与起始相同 | 是 | 是（仅 `\`） |
| 多行原始字符串 | `#…"` / `#…'` | `"…#` / `'…#` | 是 | **否** |

## 2. 字符串插值

仓颉支持**插值字符串**：在普通字符串字面量内（不适用于多行原始字符串）通过 `${表达式}` 把表达式的值嵌入字符串。表达式可以是变量、字面量、算术表达式，也可以是用 `;` 分隔的多个声明 / 表达式序列，**整个 `${...}` 最终会被替换为序列中最后一个表达式的值**。

```cangjie
let fruit: String = "apples"
let count: Int64 = 10
let s: String = "There are ${count * count} ${fruit}"
println(s)
// 输出：There are 100 apples
```

插值常用于 `println` 打印非字符串类型：

```cangjie
let r: Float64 = 2.4
let area: String = "半径为 ${r} 的圆面积 = ${let PI = 3.141592; PI * r * r}"
println(area)
// 输出：半径为 2.400000 的圆面积 = 18.095570
```

注意事项：

- 插值表达式必须用 `{}` 包裹，**前面必须加 `$` 前缀**；`{x}` 没有 `$` 不会被识别为插值。
- 插值表达式的结果会调用 `toString()` 转成字符串。
- 多行字符串中也支持插值，例如：

```cangjie
let x: Int64 = 10
let s: String = """
    x = ${x}
    x * 2 = ${x * 2}
"""
```


## 3. 字符串的关系运算与拼接

字符串支持 `==`、`<`、`<=`、`>`、`>=`、`!=` 六种关系运算符，比较的是字符串的字典序（按 Unicode 码点逐位比较）。注意 `==` 是**结构相等**（内容相同即相等），与 `Array`、`class` 的引用相等不同。

字符串支持 `+` 进行拼接，结果是**一个新的字符串**：

```cangjie
let a: String = "abc"
let b: String = "ABC"
println(a == b)   // false
println(a < b)    // false
println(a != b)   // true
let joined: String = a + b
println(joined)   // abcABC
```


## 4. 字符串常用方法

仓颉 `String` 提供了丰富的成员方法。下面是日常开发中最常用的一组（以参数 `String` 类型为例）：

| 方法 | 签名 | 说明 |
|---|---|---|
| `size` | `prop size: Int64` | 字符串的**字节数**（UTF-8 字节数，非字符数） |
| `isEmpty()` | `func isEmpty(): Bool` | 是否为空字符串 |
| `contains(needle)` | `func contains(String): Bool` | 是否包含子串 |
| `startsWith(prefix)` | `func startsWith(String): Bool` | 是否以某前缀开头 |
| `endsWith(suffix)` | `func endsWith(String): Bool` | 是否以某后缀结尾 |
| `indexOf(needle)` | `func indexOf(String): Int64` | 子串首次出现的下标，未找到返回 -1 |
| `count(needle)` | `func count(String): Int64` | 子串出现的次数 |
| `split(sep)` | `func split(String): Array<String>` | 按分隔符切分（不删除空串） |
| `replace(old, new)` | `func replace(String, String): String` | 全量替换 |
| `toAsciiUpper()` | `func toAsciiUpper(): String` | ASCII 字母转大写（非 ASCII 不变） |
| `toAsciiLower()` | `func toAsciiLower(): String` | ASCII 字母转小写 |
| `toRuneArray()` | `func toRuneArray(): Array<Rune>` | 拆为 Unicode 码点数组 |

下标访问 `s[i]` 返回的是 **Byte（`UInt8`）**，不是 `Rune`：

```cangjie
let cn: String = "你好, Cangjie"
let b: Byte = cn[0]               // UTF-8 第一字节（你 = 0xE4）
println("cn[0] (Byte) = ${b}")
```

如果想按 Unicode 字符遍历，应该先 `toRuneArray()` 再迭代（详见 6.2 节）。

完整示例（节选）：

```cangjie
let text: String = "Hello, Cangjie Lang"
println("size: ${text.size}")                          // 20
println("contains Cangjie: ${text.contains("Cangjie")}")
println("startsWith Hello: ${text.startsWith("Hello")}")
println("endsWith Lang: ${text.endsWith("Lang")}")
println("indexOf Cangjie: ${text.indexOf("Cangjie")}")
println("count 'a': ${text.count("a")}")
println("upper: ${text.toAsciiUpper()}")
println("lower: ${text.toAsciiLower()}")
```


## 5. 字符类型 Rune

仓颉的 `Rune` 类型表示 **Unicode 字符集中的一个码点**（注意是码点不是字节）。`Rune` 在内存中固定占用 4 字节，足以表示所有 Unicode 字符（U+0000 ~ U+10FFFF）。

### 5.1 Rune 字面量

`Rune` 字面量以字符 `r` 开头，后跟一对单引号或双引号包围的字符。共有三种形式：

**1. 单个字符**：

```cangjie
let a: Rune = r'a'
let b: Rune = r"b"   // 双引号等价
```

**2. 转义字符**：以 `\` 开头表示特殊字符。常用转义包括 `\\`、`\'`、`\"`、`\n`、`\t`、`\r`、`\0` 等。

```cangjie
let slash: Rune = r'\\'   // 反斜杠
let newLine: Rune = r'\n'  // 换行
let tab: Rune = r'\t'      // 制表符
```

**3. 通用字符**：以 `\u{` 开头，**1~8 个十六进制数** + `}` 结束，表示对应 Unicode 值的字符。

```cangjie
let he: Rune = r'\u{4f60}'   // 你
let llo: Rune = r'\u{597d}'  // 好
println("${he}${llo}")        // 你好
```

通用字符的十六进制位数最少 1 位、最多 8 位，对应 Unicode 码点 0x0 ~ 0x10FFFF。

### 5.2 Rune 关系运算

`Rune` 支持 `<`、`<=`、`>`、`>=`、`==`、`!=` 六种关系运算，**比较的是 Unicode 码点（数值）**：

```cangjie
println(r'a' < r'b')       // true
println(r'你' > r'A')      // true（你 = 0x4f60, A = 0x41）
println(r'\n' == r'\n')    // true
```


### 5.3 Rune 与 UInt32 的转换

`Rune` 可以显式转换为 `UInt32`，**整数类型（含 `UInt32`）也可以显式转换为 `Rune`**：

```cangjie
let r1: Rune = r'A'
let code: UInt32 = UInt32(r1)            // 'A' = 65
let back: Rune = Rune(UInt32(65))         // 'A'
println("UInt32('A') = ${code}")
println("Rune(65) = ${back}")
println("UInt32('你') = ${UInt32(r4)}")    // 20320
```

注意：

- `UInt32` → `Rune` 时，**被截断为低 21 位**（Unicode 范围）；如果值不在 0x0~0x10FFFF 内，结果可能不是合法 Unicode 字符。
- `Rune` → `Byte` 之类的窄类型需要先经 `UInt32` 中转，因为 `Rune` 是 32 位值。

## 6. 字符串与字符的互转

### 6.1 ASCII 字符串与 Byte 互转

对于**单字节 ASCII 字符**，仓颉允许 `Byte` 与 ASCII 字符串字面量互相赋值：

```cangjie
var b: Byte = "0"   // 字符串字面量 → Byte
b = "1"             // 同样合法
println(b)          // 49（"0" 的 ASCII 码）
```

类似地，对于**单字符字符串字面量**，可以赋给 `Rune`：

```cangjie
var r: Rune = "0"   // 字符串字面量 → Rune
r = "1"
```

但这种隐式转换只适用于**字符串字面量**，不适用于任意 `String` 类型的值。

### 6.2 把字符串拆为 Rune 数组

`String.toRuneArray()` 把字符串按 Unicode 码点拆成 `Array<Rune>`：

```cangjie
let cn: String = "你好, Cangjie"
let runes: Array<Rune> = cn.toRuneArray()
println("runes.size = ${runes.size}")  // 16
println("runes[0] = ${runes[0]}")      // 你
println("runes[2] = ${runes[2]}")      // ，
```

这与 `String.size` 得到的**字节数**不同——`cn.size` 应当是 16（"你好, Cangjie" 共 10 个字符，UTF-8 编码占 16 字节）。`toRuneArray()` 的长度才是真正的字符数。

### 6.3 把 Rune 数组重新拼成字符串

仓颉 1.0.5 没有直接的 `Rune.toString()` 字符串方法（`Rune` 未实现 `ToString`），最常用的拼回方式是**字符串插值**或使用 `String` 提供的方法。如果只是把单个 `Rune` 嵌入字符串，写成 `"${r}"` 即可。

### 6.4 典型模式：按字符遍历

```cangjie
let sentence: String = "仓颉语言 Hello"
var chineseCount: Int64 = 0
var letterCount: Int64 = 0
for (r in sentence.toRuneArray()) {
    // 中文基本平面：0x4e00 ~ 0x9fff
    let c: UInt32 = UInt32(r)
    if (c >= UInt32(0x4e00) && c <= UInt32(0x9fff)) {
        chineseCount += 1
    } else {
        letterCount += 1
    }
}
println("中文字符数: ${chineseCount}")
println("其他字符数: ${letterCount}")
```


## 7. 常见问题（FAQ）

### Q1: 单行字符串和多行字符串在内存上有区别吗？

没有。两种字面量在编译后都是 `String` 类型的值，差异仅在源码层是否跨行。性能相同。

### Q2: 字符串插值里能写多行吗？

`${}` 的内容必须写在同一行。要拼接多行结果，应该先在外部用 `let` 计算出最终字符串，再嵌入插值，或者直接使用多行字符串。

### Q3: 字符串可以用 `==` 比较吗？

可以。`String` 是 `struct`，`==` 比较的是**内容相等**（逐字节比较），与 `Array`、`class` 的引用相等不同。

### Q4: `String` 是值类型还是引用类型？

`String` 在仓颉中是 `struct`（值类型），但内部持有一个堆上分配的 UTF-8 字节缓冲。把一个 `String` 变量赋值给另一个变量时，**结构本身被复制，但两者共享同一段底层字节**。修改其中一个变量的内容（通过 `var` + 重新赋值或调用 `replace` 等会返回新 `String` 的方法）不会影响另一个变量。

### Q5: 仓颉字符串下标 `s[i]` 返回的是字符吗？

不是。`s[i]` 返回的是 `Byte`（`UInt8`），即 UTF-8 编码的某一个字节。要按字符访问应使用 `s.toRuneArray()[i]`。

### Q6: `Rune` 字面量必须以 `r` 开头吗？

是的，所有 `Rune` 字面量都必须以 `r` 开头。这是与 `String` 字面量（`"` 或 `'`）的语法区分。

### Q7: 多行原始字符串能嵌套插值吗？

不能。多行原始字符串是按字面保留，不识别 `${}`。如果需要保留字面量同时还要嵌入值，应该用普通多行字符串。

### Q8: 字符串拼接用 `+` 还是 `concat`？

仓颉 1.0.5 没有 `String.concat` 方法，标准做法是使用 `+`。也可以使用 `StringBuilder`（标准库提供）来高效拼接大量字符串。

## 8. 总结

1. 字符串字面量有三种：**单行**（`"..."` / `'...'`）、**多行**（`"""..."""` / `'''...'''`）、**多行原始**（`#"..."#`）。前者不支持跨行，后两者都支持。
2. 字符串插值 `${expr}` 只能用在非原始字符串中；表达式可以是单值或多表达式序列，序列取最后一个表达式的值。
3. `String` 支持 `==`/`<`/`<=`/`>`/`>=`/`!=` 六种关系运算和 `+` 拼接，`==` 是**内容相等**。
4. 常用方法：`size`、`isEmpty`、`contains`、`startsWith`、`endsWith`、`indexOf`、`count`、`split`、`replace`、`toAsciiUpper`、`toAsciiLower`、`toRuneArray`。
5. 字符串下标 `s[i]` 返回 `Byte`；要按 Unicode 字符遍历应使用 `toRuneArray()`。
6. `Rune` 是 Unicode 码点类型，4 字节；字面量以 `r` 开头，支持单字符、转义、通用字符（`\u{xxxx}`）三种形式。
7. `Rune` 与 `UInt32` 可以显式互转；`UInt32` 是 `Rune` 与其他整数类型之间转换的中转。

## 参考资料

1. 仓颉 1.0.5 LTS 字符串类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/strings.html
2. 仓颉 1.0.5 LTS 字符类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/characters.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
