# 仓颉并发应用实战：任务拆分、队列通信、原子归约与屏障

> **摘要**: 文章 22–24 讲了并发原语怎么用、45 讲了内存模型（SeqCst-only、happens-before、CLQ），本篇**把它们组装成一个真并发程序**：一个"分块 map-reduce + 生产者 fan-in + 原子归约"的作业。核心是四条实战主线——**任务拆分**（把大任务切成互不共享的块并行跑）、**任务通信**（用 `ConcurrentLinkedQueue` 做 fan-in，代替 1.0.5 里没有的 Channel）、**同步**（`AtomicInt64` 无锁归约）、**屏障**（`Future.get()` 收口）。示例 `052-concurrency-app.cj` 的结果**与调度顺序无关、完全确定**，Linux CI 逐行核对。

## 前置知识

- 已完成《并发概述》（22）、`spawn`/`Future`（23）、同步原语（24）、《并发模型与内存模型》（45）
- 读过 45 会顺：本篇直接用它的结论（SeqCst 原子、CLQ 的 `remove` 返 `Option`、闭包捕获限制、无 Channel/actor）
- 承《集合》：`ArrayList` 收集 `Future`

> 定位：阶段五实战第三篇。22–24/45 是"零件说明书"，本篇是"组装作业"。

## 1. 并发作业的三种典型结构

写并发程序，99% 落在三种拓扑里，本篇示例各演一段：

| 结构 | 目的 | 仓颉手段 |
|---|---|---|
| **Map-reduce（分块并行）** | 加速 CPU 密集：切分-并行-归约 | 各块 `spawn` → `Future<T>.get()` 相加 |
| **Fan-in（生产者-消费者）** | 多任务把结果汇给一处 | 共享 `ConcurrentLinkedQueue`，主线程 `remove` 抽干 |
| **无锁累加** | 多任务写同一计数 | `AtomicInt64.fetchAdd`（SeqCst，45） |

共同纪律：**共享可变状态 = 要么别共享（map-reduce 各算各的）、要么用同步原语（atomic/CLQ/Mutex）**。45 的"无 happens-before 即 race"在这里就是设计准则。

## 2. 任务拆分 + `Future` 屏障（map-reduce）

把一个求和任务切成 4 块，各 `spawn` 一个任务，最后用 `Future.get()` **既取结果、又当屏障**（等它完成）：

```cangjie
let futs = ArrayList<Future<Int64>>()
for (i in 0..4) {
    let lo = los[i]            // 关键：先绑成不可变 let，再被闭包捕获
    let hi = his[i]
    futs.add(spawn { partialSum(lo, hi) })
}
var total = 0
for (f in futs) { total += f.get() }   // 每 get() 阻塞到对应任务完成
```

要点：
- **`spawn` 接的是块 `{ ... }`**（不是 `spawn 函数名`，实测报 `expected '{'`）——承 23。
- **返回类型 `Future<T>`**，`T` 是块最后表达式的类型；`get()` 阻塞取值（23）。
- **闭包捕获坑**：仓颉不允许把"可变的局部 `var`"直接捕获进 `spawn`（承 45 / 23）。所以循环里先把 `los[i]` 绑成 **不可变 `let lo`** 再捕获——既合规又避免"所有任务读到同一个被改的 `i`"的经典 bug。
- **`ArrayList<Future<T>>` 收集句柄**：`Array` 不能 `+` 拼接（实测 `invalid binary operator '+'`），要动态收集就用 `ArrayList.add`（24 同款）。

各块互不共享（`partialSum` 是纯函数、只读入参），所以**零同步、天然安全**——这是并发设计的第一原则：**能不共享就不共享**。

## 3. 任务通信：用 `ConcurrentLinkedQueue` 做 fan-in

1.0.5 **没有 Channel**（45 实测），多生产者汇一消费者，最接近的是 `std.collection.concurrent.ConcurrentLinkedQueue`——线程安全无锁队列：

```cangjie
let q = ConcurrentLinkedQueue<Int64>()
let ps = ArrayList<Future<Unit>>()
for (_ in 0..4) { ps.add(spawn { producerTask(10, q) }) }
for (p in ps) { p.get() }             // 先等所有生产者入队完
var fanIn = 0
var go = true
while (go) {
    match (q.remove()) {               // remove 返回 Option：非破坏性地"要么取一个、要么空"
        case Some(v) => fanIn += v
        case None => go = false
    }
}
```

两条从 45 搬来的纪律：
- **先 `p.get()` 全部收口，再抽队列**——否则消费者可能在生产者还没入队时就看到空队列提前退出。`get()` 在这里充当"生产阶段结束"的屏障。
- **抽干用 `match (q.remove())`、绝不用 `if (!q.isEmpty()) q.remove()`**——后者是 check-then-act 竞态（45 §6.1）。`remove()` 自带"没有就给 `None`"的原子语义。

> **CLQ ≠ Channel**：它是"有缓冲、非阻塞"队列，没有 CSP 的"发送即阻塞等对方接收"的会合语义，也没有 `select`。要那种 rendezvous，得在 CLQ 上再叠 `Mutex`+`Condition`（24）自己攒。

## 4. 同步：原子归约（无锁计数器）

多个任务往一个总数上累加，最省事的是 `AtomicInt64.fetchAdd`（SeqCst，45）：

```cangjie
let acc = AtomicInt64(0)
let ts = ArrayList<Future<Unit>>()
for (i in 1..=8) {
    let v = i
    ts.add(spawn { acc.fetchAdd(v) })
}
for (t in ts) { t.get() }
// acc.load() 一定是 1+2+...+8 = 36
```

`fetchAdd` 原子、不丢更新，比给一个 `var` 上 `Mutex`（24）更轻。**归约顺序无所谓**（加法可交换）→ 结果确定，这正是"并发正确性靠可交换/幂等归约"的典型设计。

> 需要更复杂的读-改-写（非单原子指令能表达）时，退到 `Mutex`/`synchronized`（24）——锁建立 happens-before（45 §3.2）。本篇三种手段（不共享 / 原子 / 队列）够用，是因为任务都能拆成"各自算完再合并"。

## 5. 取消与超时（承 23，实战何时用）

长时并发的两个必答题：

- **取消**：`f.cancel()` 协作式取消——任务体内自查 `Thread.hasPendingCancellation` 决定早退（23）。适合"用户取消下载""超预算就停"。取消是**协作**的，不是强杀，所以任务体要留检查点。
- **超时**：`f.getWithTimeout(Duration)` / `f.tryGet()`（23）——拿不到就按超时处理，避免主线程被卡死的子任务无限阻塞。

本篇示例任务都会自然结束、无需这两样；但真实并发应用里，**"能起就要能停、能等就要能超时"**是把 22–24 落到生产的分水岭。

## 6. 完整示例（三种结构各一段，结果确定）

`052-concurrency-app.cj`——CI 里 `cjpm`? 不，单文件 `cjc` 编链后运行：

<!-- example: cangjie/052-concurrency-app.cj -->
```cangjie
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
```

编译并运行（Linux）：

```shell
cjc 052-concurrency-app.cj -o conc && ./conc
```

预期输出（**与线程数、调度顺序、运行次数都无关**）：

```text
sum1_100=5050
fanin=220
atomic=36
```

## 7. 性能维度：何时值得并行（承 46）

并发不是免费加速。判断链：
1. **先 `cjprof`（40/46）测**：是不是 CPU 密集热点？单线程打满才谈并行；I/O 密集是"并发等待"而非"并行计算"（23）。
2. **切分粒度**：块太小 → `spawn`/调度开销 + 归约开销反超收益。示例切 4 块只是演示，真实按核数（`std.env`/`std.core` 的可用 CPU 数）与数据量定。
3. **归约别共享**：map-reduce（§2）优于"所有任务抢一把锁改一个总数"。真要点级共享，用原子（§4）不用锁。
4. **别过度并行**：并发任务数 ≫ 核数时，M:N 调度（22）会排队，不增吞吐反增内存。

## 8. 与其它语言并发范式对照

| 范式 | 仓颉（本篇） | Go | Rust |
|---|---|---|---|
| 起任务 | `spawn { }` → `Future<T>` | `go func()` | `tokio::spawn`/`thread::spawn` |
| 等完成/取值 | `f.get()` | channel 收/`WaitGroup` | `await JoinHandle` |
| 消息传递 | `ConcurrentLinkedQueue`（无 Channel） | `chan`（内建） | `mpsc::channel` |
| 无锁计数 | `AtomicInt64` | `atomic.Int64` | `AtomicU64` |
| 取消 | `f.cancel()`+自查 | `context.Context` | 手动 AbortHandle |
| 并行边界 | 闭包不能捕获可变局部（45） | 数据竞争靠 race detector | 借用检查器在编译期挡 |

**关键差异**：Go/Rust 有内建 channel，仓颉 1.0.5 用 CLQ 代；Go 靠 runtime 抢占、Rust 靠类型系统挡竞争，仓颉靠"约定 + 同步原语 + SeqCst 原子"（45）——纪律在开发者这边。

## 9. FAQ

### Q1: `spawn { partialSum(lo, hi) }` 里的 `lo/hi` 为什么先 `let` 一下？

仓颉**不允许把可变局部 `var` 捕获进 `spawn` 闭包**（45/23 实测限制）。循环里若直接捕获会随 `i` 变化的可变变量，既违规则又有"所有任务读最终值"的 bug。先 `let lo=los[i]` 绑不可变值再捕获，二者都避开。

### Q2: 为什么不直接 `sum += f.get()` 而不收 `Future` 列表？

`f.get()` 立即阻塞等**那一个**任务——串行化，失去并行。必须先 `spawn` 全部、收集句柄，再统一 `get()`，才是"并行跑、最后汇"。这是 map-reduce 的标准两段式。

### Q3: 抽 CLQ 时能不能 `while (!q.isEmpty()) { s += q.remove().get() }`？

不能。`isEmpty()` 与 `remove()` 之间有竞态（45 §6.1）：判空后、取之前可能被别的消费者掏空，`remove()` 返回 `None` 就炸。正确姿势：直接 `match (q.remove()){case Some(v)=>…;case None=>停}`。

### Q4: fan-in 前为什么要先 `p.get()` 所有生产者？

不先等生产者收口，主线程可能趁队列为空就 `go=false` 提前退出，漏掉还没入队的结果。`p.get()` 是"生产阶段完成"的屏障——先屏障、再单线程抽干。

### Q5: 多个任务 `fetchAdd` 顺序乱，结果对吗？

对。加法可交换，`AtomicInt64` 保证无丢失更新 → 最终恒为 `1+…+8`。**只要归约运算是可交换/结合的**，原子累加就与调度无关——这是并发正确性的常见设计前提。

### Q6: 真要高吞吐 web 后端，这套够吗？

本篇是**并发结构**演示。真后端还要连接池、超时、优雅关停、背压（CLQ 无界会吃满内存）。HTTP 层用 `stdx.net.http`（文章 49），并发处理在其内部按连接起任务；你在这之上做的是"业务任务的拆与合"。

## 10. 总结

1. **三结构**：map-reduce（分块 `spawn`+`Future.get` 屏障）、fan-in（`ConcurrentLinkedQueue`）、无锁累加（`AtomicInt64`）——覆盖并发作业主流形态。
2. **拆分纪律**：能不共享就不共享（纯函数各算各的）；必须共享就上同步（原子/锁），**闭包捕获用不可变 `let`**（45）。
3. **通信**：1.0.5 无 Channel，用 CLQ；**先 `get()` 收口再单线程抽干**；抽干用 `match (q.remove())` 不碰 `isEmpty` 竞态。
4. **同步**：可交换归约用原子最省；复杂读-改-写退 `Mutex`（建立 happens-before）。
5. **取消/超时**：`cancel()`+自查、`getWithTimeout`——生产级必备（承 23）。
6. **性能**：先 `cjprof` 再并行、控粒度、别过度并行（承 46）。所有结果确定、CI 核对。

## 参考资料

1. 创建/访问线程、`Future`、取消：articles/23-thread-usage.md（`concurrency/create_thread`/`use_thread`/`terminal_thread`）
2. 同步原语（Mutex/Condition/Atomic）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/concurrency/sync.html
3. 并发内存模型（SeqCst-only / CLQ / 闭包捕获 / 无 Channel）：articles/45-concurrency-model.md
4. 性能剖析 cjprof：articles/46-performance.md、articles/40-debug-perf-build.md

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写。`spawn{}`/`Future.get`/闭包捕获不可变 let/`ArrayList<Future>`/CLQ `remove`→Option/`AtomicInt64` 归约 均本地 `cjc` 实测；示例 052 三种结构的确定输出（5050/220/36）在 Linux CI 核对。1.0.5 无 Channel/actor 承文章 45 的实测结论。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
