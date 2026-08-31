// 标准库总览示例：跨多个 std.* 包协同完成一个小任务
// 目的：演示"标准库分层"的实际使用——按需 import、只依赖 base SDK 自带包
// 覆盖：std.collection（容器）、std.math（数学函数）、std.sync（并发原语）
//
// 说明：这些都是 1.0.5 base SDK 自带的包，无需下载 stdx；本示例本地上
// 也能 `cjc --output-type staticlib` 编过。

import std.collection.{ArrayList, HashMap}   // 精确导入两个类型
import std.math.sqrt                         // 只导一个函数
import std.sync.AtomicInt64                  // 原子计数

main(): Int64 {
    // 1) std.collection：容器（数组式 + 键值）
    let list = ArrayList<Int64>([3, 1, 4, 1, 5])
    var sum: Int64 = 0
    for (x in list) {
        sum += x
    }
    let map = HashMap<String, Int64>([("a", 1), ("b", 2)])
    println("collection: sum=${sum}, map.size=${map.size}")   // collection: sum=14, map.size=2

    // 2) std.math：数学函数。Float64 插值以六位小数打印（本文实测格式）
    println("math: sqrt(16)=${sqrt(16.0)}")                   // math: sqrt(16)=4.000000

    // 3) std.sync：并发原语（此处顺序调用，输出确定）
    let cnt = AtomicInt64(0)
    for (_ in 0..10) {
        cnt.fetchAdd(1)
    }
    println("sync: count=${cnt.load()}")                      // sync: count=10

    return 0
}
