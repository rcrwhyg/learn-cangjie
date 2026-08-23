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
    println("size: ${text.size}")                    // 20
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
    println("runes.size = ${runes.size}")  // 10
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
