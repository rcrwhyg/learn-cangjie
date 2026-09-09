package conc

// 并发模型与内存模型原理示例（配合文章 45）。
// 前置：文章 24 讲了 Mutex / Atomic / Condition 的**用法**；本篇讲**它们承诺了什么**——
// 也就是"内存模型"这一层。所有构造均在 1.0.5 本地实测通过。

import std.sync.{AtomicInt64, Mutex, MemoryOrder}
import std.collection.concurrent.*

// 全局共享状态 + Mutex 保护：官方 029 篇同款姿势
let mutex = Mutex()
var sharedSum: Int64 = 0

main(): Int64 {
    // 1) 显式 SeqCst 内存序——1.0.5 只暴露这一种（无 Acquire/Release/Relaxed）
    let a = AtomicInt64(0)
    let w = spawn { a.store(7, memoryOrder: MemoryOrder.SeqCst) }
    w.get()                                              // 用 Task.get() 建立 happens-before
    println("seqcst=${a.load(memoryOrder: MemoryOrder.SeqCst)}")   // 7

    // 2) Mutex 建立 happens-before：写和读都在同一把锁里，主线程一定能看到 worker 的写
    let t1 = spawn { mutex.lock(); sharedSum += 1; mutex.unlock() }
    let t2 = spawn { mutex.lock(); sharedSum += 1; mutex.unlock() }
    t1.get(); t2.get()                                    // 等两个都完成
    mutex.lock()
    let seen = sharedSum
    mutex.unlock()
    println("mutex_hb=${seen}")                          // 2

    // 3) ConcurrentLinkedQueue：无锁的消息传递（1.0.5 std 无 Channel / 无 actor 关键字，CLQ 是最接近的）
    let q = ConcurrentLinkedQueue<Int64>()
    q.add(10); q.add(20); q.add(30)
    var sum: Int64 = 0
    while (true) {
        match (q.remove()) {                             // remove() 返回 Option<T>
            case Some(v) => sum += v
            case None => break
        }
    }
    println("clq_sum=${sum}")                            // 60

    return 0
}
