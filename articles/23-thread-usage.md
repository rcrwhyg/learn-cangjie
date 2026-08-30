# 仓颉线程与协程使用

> **摘要**: 上一篇讲了仓颉并发的**模型**（M:N 抢占式、面向仓颉线程编程），这一篇讲**怎么用**。核心就三件套：`spawn { ... }` 发起任务并拿回 `Future<T>`；用 `get()` / `get(timeout)` / `tryGet()` 三种方式收敛结果；用 `Thread` 访问线程信息、用 `cancel()` + `hasPendingCancellation` 做**协作式终止**。外加 `sleep(Duration)` 控制时序。本文依据仓颉 1.0.5 LTS 官方 `concurrency` 的创建/访问/终止/睡眠四页，配一个**输出完全确定**的示例（用 `SyncCounter` 门控取消、用超时窗保证时序）。锁、通道等**同步原语**在下一篇《同步与并发原语》展开。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已完成《函数类型、Lambda 与闭包》（`spawn` 参数是闭包）《并发模型概述》
- 已了解 `Option<T>`、`Future<T>`、`Duration`

## 1. 用 spawn 创建任务

创建一个新的仓颉线程只需 `spawn` + 一个**无形参的 lambda**，lambda 体就是新线程里跑的代码：

```cangjie
main(): Int64 {
    spawn { =>
        println("New thread before sleeping")
        sleep(100 * Duration.millisecond)
        println("New thread after sleeping")
    }
    println("Main thread")
    return 0
}
```

> **⚠️ 注意（最容易踩的坑）**：**主线程一结束，所有还没跑完的子线程会被一起终止**，无论它是否执行完。上例里新线程可能"还没来得及打印就退出了"。要让子线程跑完，必须显式等待——这就用到 `Future`。

## 2. `Future<T>`：等待与取结果

`spawn` 表达式的返回类型是 `Future<T>`，`T` 与该 lambda 的返回类型一致。它的三个取值方法（官方原型）：

| 方法 | 行为 | 返回 |
|---|---|---|
| `get(): T` | **阻塞**当前线程直到任务结束并返回结果（若已结束则直接返回）；任务里抛异常会在此重抛 | `T` |
| `get(timeout: Duration): T` | 阻塞等待，但**超过 timeout 还没完成就抛 `TimeoutException`**；`timeout <= Duration.Zero` 时等同 `get()` | `T` |
| `tryGet(): Option<T>` | **非阻塞**：没算完返回 `None`，算完返回值 | `Option<T>` |

```cangjie
main(): Int64 {
    let fut: Future<Int64> = spawn {
        sleep(Duration.second)
        return 1
    }
    try {
        let res: Int64 = fut.get()   // 阻塞等到结果
        println("result = ${res}")   // result = 1
    } catch (_) {
        println("oops")
    }
    return 0
}
```

`get(timeout)` 的超时用法：

```cangjie
let fut = spawn {
    sleep(Duration.second)
    return 1
}
try {
    let res = fut.get(Duration.millisecond)  // 只等 1ms
    println("result: ${res}")
} catch (_: TimeoutException) {
    println("oops")   // 睡 1s、只等 1ms → 必定走这里
}
```

> **💡 提示：`get()` 放哪会影响并行度。** 把 `fut.get()` 放在主线程其它工作**之前**，等于让主线程停下来干等，两个任务就"串行"了；放在之后才谈得上并行。

## 3. 访问线程：`Thread`

每个 `Future<T>` 对应一个仓颉线程，用 `Thread` 对象表示。`Thread` **不能直接构造**，只能：

- 从 `Future<T>` 的 `thread` 属性拿到它代表的线程；
- 用静态属性 `Thread.currentThread` 拿到"当前正在执行"的线程。

```cangjie
class Thread {
    static prop currentThread: Thread   // 当前线程
    prop id: Int64                      // 线程唯一标识（整数）
    prop hasPendingCancellation: Bool   // 是否有待处理的取消请求
}
```

对照官方示例：主线程用 `fut.thread.id`、新线程用 `Thread.currentThread.id`，取的是**同一个** `Thread` 对象，因此打印出相同的 id：

```cangjie
main(): Unit {
    let fut = spawn {
        println("Current thread id: ${Thread.currentThread.id}")
    }
    println("New thread id: ${fut.thread.id}")
    fut.get()
}
```

> **⚠️ 注意**：`id` 的具体数值每次运行可能不同（且可能是其它值），**别把 id 数值写进断言/预期输出**；要判断"是不是同一个线程"，比较 `id` 是否相等即可。

## 4. 协作式终止：`cancel()` + `hasPendingCancellation`

`Future<T>.cancel()` 只是向对应线程**发送一个终止请求**，它**不会真的停止线程**。线程要么主动检查、要么忽略：

- 任务里用 `Thread.currentThread.hasPendingCancellation` 查看是否被请求取消；
- 有请求就自己走收尾逻辑并返回；**没有/忽略**，则任务照常跑到自然结束。

也就是说"如何终止"完全交给开发者处理。官方示例用 `SyncCounter` 做时序门控，保证"发取消请求"发生在"任务醒来检查"**之前**，从而让输出确定：

```cangjie
import std.sync.SyncCounter

main(): Unit {
    let syncCounter = SyncCounter(1)
    let fut = spawn {
        syncCounter.waitUntilZero()                          // 先阻塞，等放行
        if (Thread.currentThread.hasPendingCancellation) {   // 醒来后检查取消请求
            println("cancelled")
            return
        }
        println("hello")
    }
    fut.cancel()       // 发送取消请求
    syncCounter.dec()  // 放行：任务醒来时取消请求已在
    fut.get()          // join
}
```

输出：`cancelled`。

> **⚠️ 注意**：这是**协作式**取消——`cancel()` 不强杀线程。若任务从不调用 `hasPendingCancellation` 检查，取消请求会被忽略、任务一路跑到底。别指望 `cancel()` 能让任意卡死的线程停下来。

## 5. 线程睡眠：`sleep(Duration)`

```cangjie
func sleep(dur: Duration): Unit   // 至少睡 dur
```

- 阻塞**当前线程**一段时间后再恢复；参数是 `Duration`。
- **`dur <= Duration.Zero` 时不会睡**，只是让出一次执行资源。

```cangjie
main(): Int64 {
    println("Hello")
    sleep(Duration.second)   // 睡 1 秒
    println("World")
    return 0
}
```

`Duration` 常用量：`Duration.second`、`Duration.millisecond`，也可 `100 * Duration.millisecond` 这样乘系数。

## 6. 完整可运行示例（输出确定）

下例覆盖 `get/tryGet/get(timeout)`、线程 `id` 比较、`cancel + hasPendingCancellation`、`sleep`。为让 CI 输出逐行可比，做了两处确定性设计：① 不打印易变的线程 id 数值，只打印"是否不同"的布尔；② 取消示例用 `SyncCounter` 门控时序。

<!-- example: cangjie/028-thread-usage.cj -->
```cangjie
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
```

预期输出：

```text
get=10 tryGet=10
distinct_threads=true
timeout as expected
cancel=cancelled
main slept ok
```

> 关于残留任务：示例里 `f3` 睡 1 秒但主线程只等了 1 毫秒就继续；按第 1 节规则，主线程 `return` 时它会被一并终止，不影响程序正常退出与输出。

## 7. 语言对比

| 维度 | 仓颉 | Go | Java | Rust |
|---|---|---|---|---|
| 起任务 | `spawn { }` → `Future<T>` | `go f()` | `Executor.submit` → `Future<T>` | `thread::spawn` → `JoinHandle<T>` |
| 拿结果 | `get()`（阻塞）/ `get(timeout)` / `tryGet()` | channel / `WaitGroup` | `Future.get()` / `get(timeout)` | `join()` |
| 非阻塞探测 | `tryGet(): Option<T>` | `select`+`default` | 无直接对应 | 无（需轮询句柄） |
| 取消 | 协作式：`cancel()` + `hasPendingCancellation` 自查 | `context.Context` 取消 | `Future.cancel()`（中断标志，仍需自查） | 无内建，需自行标志/ channel |
| 睡眠 | `sleep(Duration)` | `time.Sleep` | `Thread.sleep(ms)` | `thread::sleep` |
| 主线程退出 | **子线程一并终止** | main 退则全退（除非阻塞） | 非 daemon 线程会阻止 JVM 退出 | main 退则进程终止 |

**从 Go 迁移**：`spawn`+`Future.get()` 像"起了个 goroutine 并用一个 channel 收结果"；仓颉直接把这层封成 `Future`。取消方面，Go 用 `context`，仓颉用 `cancel()` + 任务内 `hasPendingCancellation` 自查，同样是协作式。
**从 Java 迁移**：`Future.get()/get(timeout)` 几乎同名同义；`tryGet()` 类似 Guava 的 `Future.getNow`。注意 Java 线程分 daemon/user，仓颉是"主线程结束子线程一起停"的语义，更像进程级随 main 退出。

## 8. 常见问题（FAQ）

### Q1: 为什么我的 `spawn` 任务"没执行就没了"？

主线程 `return`/结束时，未完成的子线程会被一起终止。要么在主线程里 `fut.get()` 等它，要么想办法延长主线程生命周期。

### Q2: `get()`、`get(timeout)`、`tryGet()` 怎么选？

要结果就 `get()`；能等但有时间上限用 `get(timeout)`（超时抛 `TimeoutException`）；只想"顺便看一眼有没有算好、不想阻塞"用 `tryGet(): Option<T>`。

### Q3: `cancel()` 能把线程杀掉吗？

不能。它只发"取消请求"。线程要不要停、怎么收尾，得自己在任务里查 `Thread.currentThread.hasPendingCancellation` 决定。

### Q4: 怎么拿到当前线程 / 某任务的线程对象？

当前线程用 `Thread.currentThread`；某任务对应线程用 `fut.thread`。两者不能直接 `new`。

### Q5: 线程 id 能当业务标识吗？

`Thread.id` 是运行时给的整数、每次可能不同，别硬编码或跨进程依赖，只适合本机比较"是否同一线程"。

### Q6: `sleep(0)` / 负数会怎样？

`dur <= Duration.Zero` 时不睡眠，只让出一次执行资源。

### Q7: `Duration` 怎么写？

常用 `Duration.second`、`Duration.millisecond`，也支持 `100 * Duration.millisecond` 这种倍乘。

## 9. 总结

1. `spawn { => ... }` 起任务、返回 `Future<T>`（`T` = lambda 返回类型）；**主线程结束会带走未完成的任务**。
2. 三种收敛：`get()` 阻塞取值（可重抛任务异常）、`get(timeout)` 超时抛 `TimeoutException`、`tryGet()` 非阻塞返 `Option<T>`。`get()` 的位置影响并行度。
3. `Thread` 不可直接构造，通过 `fut.thread` 或 `Thread.currentThread` 获取；`id` 易变、别作断言值。
4. 终止是**协作式**：`fut.cancel()` 只发请求，任务用 `hasPendingCancellation` 自查再决定收尾；忽略则跑到底。
5. `sleep(Duration)` 睡当前线程；`<= Duration.Zero` 只让出不睡眠。

## 参考资料

1. 仓颉 1.0.5 LTS 创建线程：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/concurrency/create_thread.html
2. 仓颉 1.0.5 LTS 访问线程：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/concurrency/use_thread.html
3. 仓颉 1.0.5 LTS 终止线程：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/concurrency/terminal_thread.html
4. 仓颉 1.0.5 LTS 线程睡眠指定时长：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/concurrency/sleep.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
