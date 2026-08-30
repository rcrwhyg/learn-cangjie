macro package macro_dprint.define

import std.ast.*

// dprint：调试用的非属性宏。输入是一段 Tokens（原样程序片段），
// 用 quote + 插值把 `expr` 展开成 `print("expr = "); println(expr)`。
public macro dprint(input: Tokens): Tokens {
    let inputStr = input.toString()
    let result = quote(
        print($(inputStr) + " = ")
        println($(input)))
    return result
}
