# 仓颉标准库：编码、转换、正则与内存流（文本处理工具箱）

> **摘要**: 文章 25 讲了 I/O 的**核心模型**（Stream 抽象、节点流/处理流、`File` + try-with-resources）。本篇按"标准库补全"的目标，深入 25 **没展开**的文本处理四件套：**编码**（`String` ↔ UTF-8 字节 `Array<Byte>` ↔ `Rune`）、**转换**（`std.convert` 的 `Parsable`/`RadixConvertible`/`Formattable`：`parse`/`tryParse`/`toString(radix:)`/`StringBuilder`）、**正则**（`std.regex` 的 `find`/`findAll`，raw string 写模式）、以及 **`std.io` 内存流**（`ByteBuffer` + `readToEnd`）。本文所有 API 均经 1.0.5 SDK 本地 `cjc` 实测确认，配一个跨 `convert`/`io`/`regex` 的完整示例。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已完成《基础 I/O》（Stream 模型）、《字符串与字符处理》（`String`/`Rune`/UTF-8）、《错误处理与 Option》（`Option`）

> 定位：这是文章 25 的**阶段三补全篇**——25 讲"流怎么用"，本篇讲"文本处理工具箱的全量 API"。凡 25 讲过的（`InputStream`/`OutputStream`/`BufferedXxx`/`File`）一句话带过，重心在编码/转换/正则/内存流。

## 1. 编码：`String` ↔ 字节 ↔ 码点

仓颉 `String` 是**一段 UTF-8 编码的字节序列**。文本处理第一步常是在三种表示间转换：

| 表示 | 类型 | 用途 |
|---|---|---|
| 字符 | `String` | 日常文本 |
| 字节 | `Array<Byte>` | I/O、网络、编码转换 |
| 码点 | `Rune` / `Array<Rune>` | 按"字符"遍历/判断 |

```cangjie
let s = "hi"
let bytes: Array<Byte> = s.toArray()      // String → UTF-8 字节
let back: String = String.fromUtf8(bytes) // UTF-8 字节 → String

let runes: Array<Rune> = s.toRuneArray()  // String → 码点数组（承接文章 13）
```

- **`toArray()` / `String.fromUtf8`** 是文本与字节流互转的桥：`OutputStream.write` 要的是 `Array<Byte>`，所以写字符串得先 `.toArray()`；读回来用 `String.fromUtf8`。
- `Rune` 相关（`toRuneArray`、`'\u{...}'` 通用字符）在文章 13 已详述，此处只作编码链路的一环。

> **⚠️ 注意**：中文等非 ASCII 在 UTF-8 里占多字节——`"仓颉".toArray().size` 是 **6**（每字 3 字节），而 `"仓颉".toRuneArray().size` 是 **2**。字节数 ≠ 字符数（这正是文章 13 强调过的 `size` 语义）。

## 2. `std.convert`：解析、格式化与字符串构造

`std.convert` 负责"类型 ↔ 字符串"的显式转换。核心是几个接口（均实测）：

### 2.1 `Parsable`：字符串 → 数值

`parse`（失败抛异常）与 `tryParse`（失败返回 `None`）挂在**目标类型**上（不是 `String` 的方法）：

```cangjie
import std.convert.*

let n: Int64 = Int64.parse("42")          // 42
let ok: Option<Int64> = Int64.tryParse("not-a-number")   // None（不抛）

// 用 tryParse + ?? 做安全解析
let v: Int64 = Int64.tryParse("42") ?? 0
```

- **注意方向**：是 `Int64.parse(s)`，不是 `"s".parse()`（后者编译报 `'parse' is not a member of String`）。
- 浮点用 `Float64.parse("3.14")` 同理。

### 2.2 `RadixConvertible`：任意进制字符串

整数可 `toString(radix:)` 输出到指定进制，也能按进制解析回来：

```cangjie
let hex = Int64(255).toString(radix: 16)   // 十六进制
let bin = Int64(255).toString(radix: 2)    // "11111111"
```

> 字母大小写、前缀等**格式细节依实现而定**，本文示例刻意用 `radix: 2`（纯数字，无字母歧义）保证输出确定。需要十六进制时按 SDK 实测值为准，别臆断大小写。

### 2.3 `Formattable` 与 `StringBuilder`

- **`Formattable.format(...)`**：类型自定义格式化（实现该接口即可被格式化）；具体占位符语法以库 API 为准。
- **`StringBuilder`**：高效逐段拼接（比 `+=` 少产生中间串）：

  ```cangjie
  let sb = StringBuilder()
  sb.append("a=")                 // append 返回自身？实测为“链式不可用”，逐条调用即可
  sb.append(Int64(1).toString())
  println(sb.toString())          // a=1
  ```

> **⚠️ 实测**：`StringBuilder.append` **不能链式** `sb.append("x").append("y")`（`append` 不返回 `StringBuilder`），要**逐条 `sb.append(...)`**。且 `append` 接收 `String`，数值要先 `.toString()`。

## 3. `std.regex`：正则匹配

模式用 **raw string**（`#"..."#`）写，避免反斜杠转义地狱（Cangjie 的 `r'...'` 是 Rune 字面量、`r"..."` **不是**原始串——写正则别用 Python 的 `r""` 习惯）。

```cangjie
import std.regex.*

let digits = Regex(#"\d+"#)

// find：返回 Option<MatchResult>（第一处匹配）
let m = digits.find("abc123")
if (let Some(mr) <- m) {
    println("首个数字串命中")
}

// findAll：返回可迭代，能数也能逐个取
var count = 0
for (_ in digits.findAll("a1b22c333")) { count += 1 }   // 3
```

- **`Regex(pattern)`**：编译模式（pattern 是 `#"..."#`）。
- **`find(str)`**：首个匹配，返回 `Option`（配合 `let Some(..)`）。
- **`findAll(str)`**：全部匹配，可 `for-in` 迭代。
- 取捕获组、替换等更细的 `MatchResult`/`replace` API 属库 API 层，本文用到 `find`/`findAll` 已足够覆盖常见"提取+计数"，替换等按需在库 API 查（见《标准库总览》第 4 节查法）。

> **⚠️ 命名坑**：`match` 是关键字，正则"找第一处"的方法是 **`find`** 不是 `match`（`r.match(...)` 会因关键字报错；`` r.`match`(...) `` 也报"not a member"——1.0.5 `Regex` 上叫 `find`/`findAll`）。

## 4. `std.io` 内存流：`ByteBuffer`

处理流里最常用的是"在内存里攒字节"——`ByteBuffer` 既是 `OutputStream`（可 `write`）又可当 `InputStream`（可被 `readToEnd` 读尽），适合先缓冲再一次性取出：

```cangjie
import std.io.*

let buf = ByteBuffer()
buf.write("buf".toArray())                 // 像输出流一样写
let all: Array<Byte> = readToEnd(buf)      // 一次性读到尾
println(String.fromUtf8(all))              // buf
```

承接 25：`BufferedInputStream`/`BufferedOutputStream`（磁盘缓冲）、`StringReader`/`StringWriter`（按字符串读写）用法一致；`readToEnd` 是"读尽一个 `InputStream` 到 `Array<Byte>`"的便捷函数。

## 5. 完整可运行示例

一条 `main` 串起四件套：编码往返、`parse`+进制、正则 `find`/`findAll`、`ByteBuffer`+`readToEnd`、`StringBuilder`。全部 base SDK、本地编译通过、输出确定。

<!-- example: cangjie/037-io-text.cj -->
```cangjie
// 标准库基础 I/O 与文本处理示例（承接文章 25 的流模型，聚焦未展开的：编码/转换/正则/内存流/字符串构造）
// 全部使用 1.0.5 base SDK 自带包：std.convert / std.io / std.regex；本地可 staticlib 编译。
//
// 覆盖：
//   1) 编码：String ↔ UTF-8 字节（toArray / String.fromUtf8）
//   2) convert：字符串→整数（Int64.parse）、整数→任意进制（toString(radix:)）
//   3) std.regex：find（Option）与 findAll（可迭代）
//   4) std.io：ByteBuffer 内存流写入 + readToEnd 读回
//   5) std.convert：StringBuilder 逐段拼串

import std.convert.*
import std.io.*
import std.regex.*

// findAll 返回可迭代结果，用 for-in 计数
func countMatches(r: Regex, s: String): Int64 {
    var c = 0
    for (_ in r.findAll(s)) {
        c += 1
    }
    c
}

main(): Int64 {
    // 1) 编码：String ↔ UTF-8 字节数组
    let greeting = "hi"
    let bytes = greeting.toArray()
    let back = String.fromUtf8(bytes)
    println("encode: ${bytes.size} bytes, round-trip=${back}")   // encode: 2 bytes, round-trip=hi

    // 2) convert：解析与进制转换
    let n: Int64 = Int64.parse("42")                 // 字符串 → Int64
    let bin = Int64(255).toString(radix: 2)         // Int64 → 二进制字符串
    println("convert: parse=${n}, 255_binary=${bin}")   // convert: parse=42, 255_binary=11111111

    // 3) std.regex：find（返回 Option）+ findAll（可迭代）
    let digits = Regex(#"\d+"#)
    let found = digits.find("abc123").isSome()
    let total = countMatches(digits, "a1b22c333")
    println("regex: find=${found}, count=${total}")   // regex: find=true, count=3

    // 4) std.io：内存流 ByteBuffer
    let buf = ByteBuffer()
    buf.write("buf".toArray())
    println("io: readToEnd=${String.fromUtf8(readToEnd(buf))}")   // io: readToEnd=buf

    // 5) std.convert：StringBuilder 逐段拼串
    let sb = StringBuilder()
    sb.append("a=")
    sb.append(Int64(1).toString())
    println("builder: ${sb.toString()}")              // builder: a=1

    return 0
}
```

预期输出：

```text
encode: 2 bytes, round-trip=hi
convert: parse=42, 255_binary=11111111
regex: find=true, count=3
io: readToEnd=buf
builder: a=1
```

## 6. 语言对比

| 主题 | 仓颉 | Rust | Go | Java |
|---|---|---|---|---|
| 字节↔字符串 | `toArray`/`String.fromUtf8` | `.as_bytes()`/`String::from_utf8` | `[]byte`↔`string` | `getBytes()`/`new String(bytes)` |
| 解析数字 | `Int64.parse`/`tryParse`（类型上） | `"42".parse::<i64>()` | `strconv.Atoi` | `Integer.parseInt` |
| 进制 | `toString(radix:)` | `format!("{:b}")` | `strconv.FormatInt` | `Integer.toString(x,16)` |
| 正则 | `std.regex` `Regex`/`find`/`findAll` | `regex` crate | `regexp` | `java.util.regex` |
| 可变字符串 | `StringBuilder` | `String::push_str` | `strings.Builder` | `StringBuilder` |
| 内存流 | `ByteBuffer` + `readToEnd` | `Cursor`/`Vec<u8>` | `bytes.Buffer` | `ByteArrayOutputStream` |

**从 Rust 迁移**：`Int64.parse(s)` 与 Rust `s.parse::<i64>()` 方向相反（仓颉挂在目标类型上，不是字符串上）；正则 `find/findAll` 对应 Rust `find/captures`，同样返回 `Option`/`Iterator`。
**从 Java 迁移**：`StringBuilder` 几乎同名同意，但**不能链式** `append().append()`；`toString(radix:)` 对应 `Integer.toString(x, radix)`。

## 7. 常见问题（FAQ）

### Q1: 想把字符串转成数字，`Int64("123")` 行不行？

不行。数值型转换 `Int64(x)` 只接受数值；字符串解析要用 `std.convert` 的 `Int64.parse("123")`（会抛）或 `Int64.tryParse("123")`（返回 `Option`）。

### Q2: 为什么 `"42".parse()` 报错？

`parse`/`tryParse` 在**目标类型**上，不是 `String` 方法。写 `Int64.parse("42")`。

### Q3: `StringBuilder` 能 `.append(a).append(b)` 链式吗？

不能。`append` 不返回 `StringBuilder`，逐条 `sb.append(...)`，最后 `sb.toString()`。

### Q4: 正则模式里反斜杠总出错？

模式用 **raw string** `#"..."#`（`#"\d+"#`）。别用 `r"..."`（那是 Rune 字面量语法，会报"unrecognized escape"）。

### Q5: `Regex` 有没有 `match` 方法？

没有（`match` 是关键字，也不作为方法名）。用 **`find`**（首个，`Option`）和 **`findAll`**（全部，可迭代）。

### Q6: 写字符串到文件/网络流，怎么转字节？

`s.toArray()` 得 `Array<Byte>` 传给 `write`；读回用 `String.fromUtf8(bytes)`。

### Q7: `readToEnd` 是什么？

`std.io` 的便捷函数：把一个 `InputStream` 读到结尾，返回 `Array<Byte>`；常用于 `ByteBuffer`/`File` 一次性取数据。

## 8. 总结

1. **编码**：`String` 是 UTF-8 字节；`toArray`/`String.fromUtf8` 在文本↔字节间转换，`toRuneArray` 按码点；字节数 ≠ 字符数。
2. **`std.convert`**：`Int64.parse`/`tryParse`（挂在目标类型、返回 `Option` 的 try 版）、`toString(radix:)` 进制、`Formattable`、`StringBuilder`（**逐条 append、不可链式**）。
3. **`std.regex`**：`Regex(#".."#)` + `find`（`Option`）/`findAll`（可迭代）；**方法名是 `find` 不是 `match`**，模式用 raw string。
4. **`std.io`**：`ByteBuffer` 内存流 + `readToEnd`；与 25 的处理流一脉相承。
5. 这些全在 1.0.5 base SDK；本篇 API 全部 cjc 本地实测，示例输出确定。

## 参考资料

1. 仓颉 1.0.5 LTS I/O 处理流（`readToEnd`/`StringWriter` 等）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/Basic_IO/basic_IO_process_stream.html
2. 仓颉 1.0.5 LTS 字符串与字符处理（编码链路）：见 articles/13（对应官方 `basic_data_type/strings.html`、`characters.html`）
3. 仓颉 1.0.5 LTS 标准库总览与查法：见 articles/30

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
