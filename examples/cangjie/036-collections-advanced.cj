// 标准库数据结构示例：迭代器协议 + ArrayDeque + 集合算法（管道写法）
// 覆盖文章 18 之外的部分：自定义 Iterable/Iterator、for-in 脱糖、while-let 手动驱动、
// ArrayDeque 双端队列、以及 filter/map/reduce/any/all 组合。
//
// 全部为 1.0.5 base SDK 自带（std.collection），本地可 staticlib 编译。

import std.collection.*

// ===== 自定义可迭代类型：实现 Iterable<T>，提供 iterator() =====
class Countdown <: Iterable<Int64> {
    let n: Int64
    init(n: Int64) { this.n = n }
    public func iterator(): Iterator<Int64> { CountdownIter(n) }
}

// 配套的迭代器：实现 Iterator<T> 的 next()，耗尽返回 None
class CountdownIter <: Iterator<Int64> {
    var cur: Int64
    init(n: Int64) { cur = n }
    public func next(): Option<Int64> {
        if (cur <= 0) {
            return None
        }
        let v = cur
        cur -= 1
        Some(v)
    }
}

main(): Int64 {
    // 1) 自定义 Iterable 直接被 for-in 遍历
    var total = 0
    for (x in Countdown(5)) {
        total += x                 // 5+4+3+2+1 = 15
    }
    println("countdown sum = ${total}")   // countdown sum = 15

    // 2) 手动驱动迭代器：while + let Some 模式（等价于 for-in 的脱糖形式）
    let it = Countdown(3).iterator()
    var seq = ""
    while (let Some(v) <- it.next()) {
        seq += "${v}"              // "321"
    }
    println("manual iterator = ${seq}")   // manual iterator = 321

    // 3) ArrayDeque：双端队列（文章 18 未覆盖的容器）
    let dq = ArrayDeque<Int64>()
    dq.addLast(2)
    dq.addLast(3)
    dq.addFirst(1)                 // 队列为 [1, 2, 3]
    let head = dq.removeFirst()    // 取出 1，剩 [2, 3]
    println("deque size=${dq.size} head=${head} first=${dq.first.getOrThrow()} last=${dq.last.getOrThrow()}")
    // deque size=2 head=1 first=2 last=3

    // 4) 集合算法（管道 `|>` 写法）：filter 与 map 返回 Iterator，用 for-in 落地
    let nums = ArrayList<Int64>([1, 2, 3, 4, 5, 6])
    var evenSum = 0
    for (x in (nums |> filter { v => v % 2 == 0 } |> map { v => v * 10 })) {
        evenSum += x               // 偶数 [2,4,6] → *10 → 20+40+60 = 120
    }
    println("even*10 sum = ${evenSum}")   // even*10 sum = 120

    // reduce / any / all 直接产生结果值
    println("reduce = ${nums |> reduce { x, y => x + y }}")   // reduce = 21
    println("any>5 = ${nums |> any { v => v > 5 }}")          // any>5 = true
    println("all>0 = ${nums |> all { v => v > 0 }}")          // all>0 = true

    return 0
}
