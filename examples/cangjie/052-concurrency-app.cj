package conc

// 并发应用实战（配合文章 50）：把 45 的并发/内存模型原理落到一个真程序——
// 任务拆分（分块 map-reduce）、任务通信（生产者 fan-in 队列）、同步（原子归约）、
// 屏障（Future.get 收口）。所有结果确定、与调度顺序无关，Linux CI 逐行核对。

import std.collection.ArrayList
import std.collection.concurrent.ConcurrentLinkedQueue
import std.sync.AtomicInt64

// —— 任务体：分块求和（纯函数、无共享，天然线程安全）——
func partialSum(lo: Int64, hi: Int64): Int64 {
    var s = 0
    for (i in lo..=hi) {
        s += i
    }
    return s
}

// —— 生产者：把 1..=k 的局部和塞进共享队列（fan-in）——
func producerTask(k: Int64, q: ConcurrentLinkedQueue<Int64>): Unit {
    var s = 0
    for (i in 1..=k) {
        s += i
    }
    q.add(s)   // CLQ.add 内部线程安全（承 45）
}

main(): Int64 {
    // 1) 任务拆分 + 结果归约：把 1..=100 切 4 块并行，各自 Future.get() 收口（屏障）后相加
    let los = [1, 26, 51, 76]
    let his = [25, 50, 75, 100]
    let futs = ArrayList<Future<Int64>>()
    for (i in 0..4) {
        let lo = los[i]              // 用不可变 let 捕获进闭包，避免"捕获可变局部"限制（承 45）
        let hi = his[i]
        futs.add(spawn { partialSum(lo, hi) })
    }
    var total = 0
    for (f in futs) {
        total += f.get()             // get() 既是取值、也是"等它完成"的同步点
    }
    println("sum1_100=${total}")     // 5050

    // 2) 任务通信：4 个生产者 fan-in 到无锁队列，主线程抽干求和（顺序无关 -> 确定）
    let q = ConcurrentLinkedQueue<Int64>()
    let ps = ArrayList<Future<Unit>>()
    for (_ in 0..4) {
        ps.add(spawn { producerTask(10, q) })
    }
    for (p in ps) {
        p.get()                       // 等所有生产者入队完毕（屏障）
    }
    var fanIn = 0
    var go = true
    while (go) {
        match (q.remove()) {          // remove 返回 Option：有则累加、空则停（承 45 的"isEmpty+remove 是 race"）
            case Some(v) => fanIn += v
            case None => go = false
        }
    }
    println("fanin=${fanIn}")         // 4 * (1+..+10) = 220

    // 3) 同步：原子累加，8 个任务各 fetchAdd(1..=8)，无需锁
    let acc = AtomicInt64(0)
    let ts = ArrayList<Future<Unit>>()
    for (i in 1..=8) {
        let v = i
        ts.add(spawn { acc.fetchAdd(v) })
    }
    for (t in ts) {
        t.get()
    }
    println("atomic=${acc.load()}")   // 1+2+..+8 = 36
    return 0
}
