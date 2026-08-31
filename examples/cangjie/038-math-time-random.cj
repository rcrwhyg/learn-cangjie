// 标准库数学、时间与随机数示例（1.0.5 base SDK：std.math / std.time / std.random）
// 覆盖：数学函数 pow/sqrt/cbrt/atan2；Duration 时间算术与单位换算；带种子的可复现随机。
//
// 说明：JSON/序列化在 1.0.5 属 stdx 扩展（base SDK 无 std.json），本篇不覆盖；
// 时间线刻意不用"当前时刻"、随机数用固定种子，保证输出完全确定。

import std.math.*
import std.time.*
import std.random.*

main(): Int64 {
    // 1) 数学：常用函数（Float64 打印为 6 位小数，另用真值判定避免格式歧义）
    println("math: pow=${pow(2.0, 10.0)}, sqrt=${sqrt(9.0)}, atan2(0,1)=${atan2(0.0, 1.0)}")
    // math: pow=1024.000000, sqrt=3.000000, atan2(0,1)=0.000000
    println("math: cmp=${pow(2.0, 10.0) == 1024.0 && sqrt(9.0) == 3.0}")
    // math: cmp=true

    // 2) 时间：Duration 算术与单位换算 + 从 UnixEpoch 得到确定日期
    let d = 3 * Duration.second + 500 * Duration.millisecond
    println("time: d_ms=${d.toMilliseconds()}, d_s=${d.toSeconds()}")
    // time: d_ms=3500, d_s=3
    let epochPlusOneDay = DateTime.UnixEpoch.addDays(1)
    println("date: ${epochPlusOneDay.year}-${epochPlusOneDay.month}-${epochPlusOneDay.dayOfMonth}")
    // date: 1970-1-2

    // 3) 随机：同种子 → 同序列（可复现）
    var r1 = Random(42)
    var r2 = Random(42)
    println("random: same_seed_eq=${r1.nextInt64() == r2.nextInt64()}")
    // random: same_seed_eq=true

    return 0
}
