package mpdemo

import mpdemo.greet.*

// cjpm 会先编 greet 包、再编本 main（cjpm check 会打印这个串行编译顺序）。
// cjpm run 一条命令搞定"编译 + 运行可执行产物"。
main(): Int64 {
    println(greeting("cangjie"))            // hello, cangjie
    println("add(2, 3) = ${add(2, 3)}")     // add(2, 3) = 5
    return 0
}
