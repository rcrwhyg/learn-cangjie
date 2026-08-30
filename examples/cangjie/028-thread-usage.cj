// 线程与协程使用示例
// 演示：spawn 创建任务、Future 三种取值（get / get(timeout) / tryGet）、
// Thread 访问（currentThread.id / fut.thread）、cancel + hasPendingCancellation 协作式终止、
// sleep(Duration) 睡眠

import std.sync.SyncCounter

main(): Int64 {
    // ========== 1) 任务结果：get() 与 tryGet() ==========
    let f1: Future<Int64> = spawn { 10 }
    let v1 = f1.get()            // 阻塞直到任务完成，返回 10
    let t1 = f1.tryGet()         // 已完成 -> Some(10)；非阻塞，返回 Option
    println("get=${v1} tryGet=${t1.getOrThrow()}")   // get=10 tryGet=10

    // ========== 2) 访问线程：Thread.currentThread / fut.thread ==========
    let mainId = Thread.currentThread.id     // 主线程 id
    let f2 = spawn { => Thread.currentThread.id }  // 任务把"自己的线程 id"作为结果返回
    let taskId = f2.get()
    // 不同线程 id 不同，输出为确定的布尔值（不打印易变的 id 数值）
    println("distinct_threads=${mainId != taskId}")   // distinct_threads=true

    // ========== 3) 带超时的等待：get(timeout) 抛 TimeoutException ==========
    // 任务里睡 1 秒，主线程只等 1 毫秒 -> 必定超时，输出确定
    let f3 = spawn {
        sleep(Duration.second)
        99
    }
    try {
        let _ = f3.get(Duration.millisecond)
        println("no timeout")
    } catch (_: TimeoutException) {
        println("timeout as expected")
    }

    // ========== 4) 协作式终止：cancel() + hasPendingCancellation ==========
    // cancel() 只是"发请求"，不会强杀线程；任务自行检查并决定如何收尾。
    // 用 SyncCounter 门控，保证"发请求"发生在"任务醒来检查"之前 -> 输出确定。
    let counter = SyncCounter(1)
    let f4 = spawn {
        counter.waitUntilZero()                         // 先阻塞，等待放行
        if (Thread.currentThread.hasPendingCancellation) {
            return "cancelled"                          // 看到取消请求，走取消收尾
        }
        return "ran"                                    // 无取消请求，正常完成
    }
    f4.cancel()          // 发送取消请求
    counter.dec()        // 放行，任务醒来时已带有取消请求
    println("cancel=${f4.get()}")   // cancel=cancelled

    // ========== 5) 睡眠：sleep(Duration) ==========
    sleep(Duration.millisecond)      // 让主线程主动睡一小会儿再结束
    println("main slept ok")

    return 0
}
