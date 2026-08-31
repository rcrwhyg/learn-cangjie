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
