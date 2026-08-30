package macro_dprint

import macro_dprint.define.*

// 使用宏：`@dprint(表达式)` 会打印"表达式原文 = 表达式值"。
main(): Int64 {
    let x = 3
    let y = 2
    @dprint(x)
    @dprint(x + y)
    return 0
}
