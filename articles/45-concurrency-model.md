# 仓颉并发模型与内存模型：SeqCst 原语、happens-before 与死锁原理

> **摘要**: 文章 22 讲了 M:N 调度、23 讲了 `spawn`/`Future`、24 讲了 `Mutex`/`Atomic`/`Condition` 的**用法**——本篇讲它们**背后承诺了什么**（内存模型），以及在 1.0.5 上做并发设计的**取舍**。三个核心实测结论：① **`MemoryOrder` 只有 `SeqCst` 一支**——`Acquire`/`Release`/`Relaxed` 在 1.0.5 SDK 里都取不到（实测），意味着仓颉原子操作**没有 C++/Rust 那种细粒度内存序**；② **`Channel` / `actor` 关键字都不存在**（实测：`std.concurrent` 无、`actor` 语法解析失败），跨线程消息传递靠 `std.collection.concurrent.ConcurrentLinkedQueue`；③ **happens-before 只由同步动作建立**（`spawn`+`Task.get()` / `Mutex.lock()`-`unlock()` / SeqCst 原子），**不加同步就没有任何可见性/顺序保证**。所有断言 1.0.5 本地实测；示例 `048-memory-model.cj` 演示三种同步各建立一条 HB，Linux CI 核对。

## 前置知识

- 已完成文章 22/23/24（并发概述 / `spawn`+`Future` / 同步原语）——**本篇假定你会用它们**
- 已完成文章 41/44（类型系统 / 值引用与内存管理）——GC 与"堆共享"的背景
- 会一点 C++ `std::memory_order` / Java JMM / Rust `Ordering` 更好；本篇会**具体对照**

> **本篇与 22/23/24 的分界**：那三篇是"工具怎么用"（`Mutex.lock()`、`AtomicInt64.fetchAdd`）；本篇是"用它们买到了什么保证、不买会怎样"——即**内存模型**。

## 1. 数据竞争：先讲清"错"再讲"对"

**定义**（官方 sync.html 直引）："多个线程读写同一份可变数据、且至少有一个是写，又没有同步保护，就是**数据竞争**。"

拆细看，"两个访问、同一内存、至少一写、**无 happens-before 关系**"——**四条同时成立**才算 race。前两条容易查，**"无 HB"这一条才是并发 bug 的根**。§3 讲怎么建立 HB；§6 讲怎么"看起来没事但其实是 race"。

> **⚠️ 抢占式调度的现实**：官方 overview 明写"仓颉提供**抢占式**的线程模型"。这意味着**任何一行代码之间**都可能被切走——你绝不能靠"我这段循环不长、不会被打断"来保不变性。**同步不是"防并发"，是"给硬件与编译器立字据"**：我保证这段的可见性顺序。

## 2. 1.0.5 的内存模型：**只有 SeqCst**

C++11/Rust/Java VarHandle 都给你**四五种内存序**（`Relaxed`/`Acquire`/`Release`/`AcqRel`/`SeqCst`），换不同性能/表达力。**Cangjie 1.0.5 里 `MemoryOrder` 枚举只有 `SeqCst` 一支**：

```cangjie
import std.sync.{AtomicInt64, MemoryOrder}
a.store(7, memoryOrder: MemoryOrder.SeqCst)      // ✅ 实测通过
a.load(memoryOrder: MemoryOrder.Acquire)          // ❌ 'Acquire' is not a member of enum 'MemoryOrder'
```

（实测：`Acquire`/`Release`/`AcqRel`/`Relaxed` **全部**报"不是 MemoryOrder 成员"。SDK 二进制里能搜到 `SeqCst` 一个枚举 case。）

**含义**：所有原子操作都是**顺序一致**（sequentially consistent）——最强、最保守、最"符合直觉"，代价是**编译器/CPU 不能对它们做最激进的重排优化**。

> **💡 为什么"够用"**：绝大多数正确程序不需要 Relaxed/Acquire/Release——它们是为**锁-free 数据结构实现者**（写一个 `Arc`、写一个无锁队列）准备的微优化。业务代码走 SeqCst，等价于 Rust 的 `Ordering::SeqCst` 或 Java 里"把 atomic 当 volatile 变量看 + 原子自增"，**心智负担最小**。想要细粒度内存序的人，1.0.5 给不了。

## 3. happens-before：三条建立路径（实测在 048 里）

Cangjie 没有形式化 JMM 那种"HB 完整定义"，但从**实际行为**上，以下**三类动作**建立 HB（承 24 篇的用法、本篇给"为什么"）：

### 3.1 `spawn` + `Task.get()`

```cangjie
let t = spawn { a.store(7, memoryOrder: MemoryOrder.SeqCst) }
t.get()                                       // HB：t 里所有写 → 对 t.get() 之后的读可见
println(a.load(memoryOrder: MemoryOrder.SeqCst))   // 一定看得到 7
```

`spawn { ... }` 起任务时——**主线程在 spawn 之前的写** 对**子任务** 可见；反过来 `t.get()` 返回时——**子任务的所有写** 对**主线程** 可见。这是**任务边界**天然给的（023 篇讲过 `Future`，本篇给它一个"内存"名字）。

### 3.2 `Mutex.lock()` / `unlock()` 配对

**同一把锁**：`unlock()` **happens-before** 后续对同一把锁的 `lock()`。所以：

```cangjie
// 线程 A
mutex.lock(); sharedSum += 1; mutex.unlock()
// 线程 B（在 A 之后拿到锁）
mutex.lock(); let v = sharedSum; mutex.unlock()   // 一定看到 A 的写
```

`synchronized(mtx) { ... }` 是 lock/unlock 的语法糖（24 篇），建立**同一种** HB。**关键**：`sharedSum` 本身**不是**原子——它的可见性**全靠**外部那把锁。锁内怎么读写都行、锁外都不安全。

### 3.3 SeqCst 原子**之间**

`a.store(1, memoryOrder: MemoryOrder.SeqCst)` 和后面 `a.load(memoryOrder: MemoryOrder.SeqCst)` **在同一个原子对象**上构成 HB 关系。**不同**原子对象之间，SeqCst 只保证"所有线程看到的**全局顺序**一致"（不保证"我以为先写的能被你先读到"）。

## 4. 消息传递 ≠ 共享：1.0.5 的现实

Go/Kotlin/Rust 有内建 `chan` / Channel。Cangjie 1.0.5 **没有**：

- **`std.concurrent` 不存在**（实测报 `can not find package 'std.concurrent'`）。
- **`actor` 关键字**：`actor class Counter { ... }` 报 `expected declaration, found 'actor'`（实测）——**没有内建 Actor 模型**。
- **`std.collection.concurrent`** 提供的是 **`ConcurrentLinkedQueue<T>`**——一个线程安全队列，`.add(v)` 无锁塞、`.remove()` 弹一个（返 `Option<T>`）。

所以"消息传递风格"要手写：

```cangjie
let q = ConcurrentLinkedQueue<Int64>()
q.add(10); q.add(20); q.add(30)
var sum: Int64 = 0
while (true) {
    match (q.remove()) {          // remove 返 Option
        case Some(v) => sum += v
        case None => break
    }
}
```

（048 里 §3 就是这个模式。）CLQ 是"能塞能弹的 FIFO + 内部无锁"，够用；但它**不是** CSP——没有 `!` / 无缓冲同步语义、没有 `select` 多路复用。

> **⚠️ 别把"能用队列"当成"有了 Channel"**：CLQ 是"有缓冲 + 非阻塞"；Channel 通常承诺"没缓冲、发送即等对方接收"（rendezvous）。1.0.5 里做真正的 CSP 得在 CLQ 上再加 `Mutex + Condition`（24 篇）自己攒。

## 5. 死锁：4 条件与 Cangjie 的解法

经典 Coffman 4 条件（并发通用、非 Cangjie 独有）：**互斥 + 持有并等待 + 不可剥夺 + 循环等待**。打破任一即可。Cangjie 1.0.5 里能用的招：

| 招 | 用法 | 说明 |
|---|---|---|
| **锁顺序**（Lock Ordering） | 全局给锁排个号、总按号加锁 | 打破"循环等待"——最常用 |
| **`tryLock()`** | `if (mtx.tryLock()) { ... } else { 走备用路径 }` | 拿不到就退让（打破"持有并等待"） |
| **`synchronized` 块** | 只包最小临界区、块内**别**再调用户代码 | 缩短持锁时间、少嵌套 |
| **`Mutex` 可重入** | 同线程重入不死锁（24 篇讲过） | 只解决"自己等自己"，跨线程环**没用** |
| **不用锁** | 只用 Atomic / CLQ | 从根上不打死锁 |

Cangjie 的 `Mutex` 是**可重入**的（同线程 `lock()` 两次不阻塞），能防一种自锁、防不了两线程 A/B 环——**可重入 ≠ 免疫死锁**，别混。

## 6. 常见"看起来对、其实 race"的模式

### 6.1 Check-Then-Act（无锁版）

```cangjie
// 错例（本篇实测思路；048 里给正确版）
if (!q.isEmpty()) {            // ①  别的线程可能在 ① 和 ② 之间把最后元素掏空
    let v = q.remove()         // ②
    ...
}
```

CLQ 的 `isEmpty()` 与 `remove()` 是**两次独立调用**、彼此无原子性。正确写法：**直接** `remove()`、拿 `Option` 判空——**这就是 048 §3 的循环**。

### 6.2 双检锁里的可见性

DCLP 在 C++/Java 老代码里因为"编译器可能重排 `new` + `ptr = ...`"而 bug。Cangjie 因为**默认 SeqCst**、`Mutex` 建 HB，**这类"半初始化对象被别的线程看到"的坑反而不容易触发**——但依然**必须**用 `Mutex`/`Atomic` 保护"检查是否已初始化"这一步。

### 6.3 "共享状态靠原子指针发布"

一个 class 对象的构造是引用类型、堆上；把它赋给一个 `AtomicReference` 后**必须** `store(..., memoryOrder: MemoryOrder.SeqCst)` 才让别的线程 `load()` 拿到"完整构造好的对象"——SeqCst 帮你保这一点。**普通 `var ref: AtomicReference<T>` 的字段写不算**。

## 7. 与其它语言内存模型对照

| 维度 | Cangjie 1.0.5 | Rust | C++11 | Java |
|---|---|---|---|---|
| 内存序 API | **只有 SeqCst** | `Ordering::{Relaxed..SeqCst}` 5 种 | `memory_order_*` 6 种 | VarHandle 4 种（Acquire/Release/Plain/Opaque） |
| 形式化 JMM | 无专门文档、行为跟 SeqCst | 部分形式化 | 有 | 有（JSR-133） |
| Actor / Channel 内建 | ❌（CLQ 手工搭） | crossbeam / tokio mpsc | 无 | 无（Reactor/LMAX） |
| Mutex 可重入 | ✅ | ❌（原生） | ❌（std） | ❌ |
| 默认调度 | M:N 抢占式（22 篇） | 依运行时 | OS | 依 JVM |

**心智**：把 Cangjie 当作"**只给你 Java 里 `synchronized` 与 `volatile` 那一层强度**"——**没有** `unsafe` 内存序、**没有** Actor runtime。写代码时"能加锁就加锁、拿不准就 SeqCst"最省事。

## 8. 完整示例（三种 HB 建立路径 + CLQ 消息传递）

`048-memory-model.cj`：

<!-- example: cangjie/048-memory-model.cj -->
```cangjie
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
```

编译并运行（Linux）：

```shell
cjc 048-memory-model.cj -o conc && ./conc
```

预期输出（**每一行都是确定值**，因为每处跨线程可见性都有 HB 支撑）：

```text
seqcst=7
mutex_hb=2
clq_sum=60
```

## 9. FAQ

### Q1: 1.0.5 原子为什么不给 Relaxed/Acquire/Release？

**没给 ≠ 错**，是**取舍**。绝大多数程序不需要细粒度内存序；给了用户会**误用**（Relaxed 用错就是 UB）。Cangjie 团队选择"默认最强、不给降级"——性能损失在真实业务里几乎测不出来、心智负担直接砍半。

### Q2: 那我这内存敏感的 hot loop 上 SeqCst 太慢怎么办？

（1）先量——Cangjie 的 `cjprof`（文章 40）跑一遍看是不是真热点；（2）99% 情况"少锁一点 / 换无锁队列"比"降级内存序"更有效；（3）真要极致，走 FFI（29 篇）到 C 里做，回来。1.0.5 语言内**没有**再往下调的余地。

### Q3: 没有 actor 关键字，我能不能自己攒？

可以，但要写不少。基本骨架：`ConcurrentLinkedQueue<Message>` + 一个 `spawn` 循环从队列里 `remove` 并 dispatch。缺的是"编译器帮你保证消息只被那一个任务处理"——1.0.5 得**你手动保证**。

### Q4: `ConcurrentLinkedQueue` 能保证"生产者写完、消费者立刻看得到"吗？

能——它的 `.add()`/`.remove()` **内部已经有序**（无锁 CAS + SeqCst 语义级别）。你不需要额外 `Mutex` 包一下。**这就是"消息传递"的默认好处**：数据是"传"过去的、不是"共享"的，同步点在队列 API 里。

### Q5: `spawn { }` 里读到"主线程之前 var 出来的变量"，为什么不是 race？

`spawn` 边界建 HB（§3.1）——主线程在 `spawn` **之前** 的写，对**新任务** 都可见。反过来，新任务在 `get()` 之前的写、`get()` 之后主线程一定能看到。**跨边界之前发生的写、都不算 race**。

### Q6: 我看到别人代码里用 `if (!q.isEmpty()) q.remove()`——为什么错？

`isEmpty()` 与 `remove()` 是**两次独立**调用，中间别的线程可能掏空——`remove()` 返回 `None` 时你已经在 `if` 外面了。**统一改成 `match (q.remove()) { case Some(v) => ...; case None => ... }`**：把"有没有"和"取出来"合成一个原子动作。

### Q7: 死锁能靠"超时 tryLock"完全避免吗？

能**大幅降低**概率、但**不消除**。超时路径本身要设计好（走备用还是重试、重试多久）；锁顺序 + 单锁 + 不用锁 三件套才是根治。

### Q8: 1.0.5 里 GC 与并发怎么配合？多线程写 atomic 会不会被 GC 影响？

`AtomicReference<T>` 与 `Mutex` 保护的对象都在**GC 堆**上、GC 会正确识别"多任务同时持有"的强引用。**atomic 是"内存位置原子"、不是"生命周期原子"**——写一个引用进 AtomicReference 之后，只要还有别的引用指向那个对象，GC 就不会收它。这条与 Java 一致。

## 10. 总结

1. **数据竞争 4 条件**：多线访问同一内存、至少一写、无 HB——**四条全中**才是 race。抢占式调度让你**不能靠"这段很快"避同步**。
2. **1.0.5 只有 SeqCst**——`MemoryOrder` 枚举里 **`Acquire`/`Release`/`Relaxed` 都不存在**（实测），意味着原子**默认最强**、也**没有降级选项**。
3. **三条 HB 建立路径**：`spawn` 起点 / `Task.get()` 终点、`Mutex.lock/unlock` 配对、SeqCst 原子**之间**——048 里三种各一次。
4. **无 Channel、无 actor 关键字**：消息传递靠 `std.collection.concurrent.ConcurrentLinkedQueue`（`add`/`remove`→`Option`）；CSP 风格要自己攒。
5. **死锁**：Coffman 4 条件；Cangjie 招 = 锁顺序 / `tryLock` / 缩短临界区 / `Mutex` 可重入（只治自锁）/ 无锁结构。
6. **CLQ 的 `isEmpty` + `remove` 是 race**——统一走 `match (q.remove())`；这是 1.0.5 里最常见的并发写法错误。

## 参考资料

1. 并发概述（M:N 抢占式模型）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/concurrency/concurrency_overview.html
2. 同步机制（Mutex / Atomic / Condition / `synchronized`）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/concurrency/sync.html
3. 创建线程：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/concurrency/create_thread.html
4. 值/引用与内存管理（GC、堆共享的心智，承 44 篇）：articles/44-value-ref-memory.md
5. 同步原语用法（本篇假定读者已掌握）：articles/24-sync-primitives.md

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写。所有 1.0.5 现状（`MemoryOrder.SeqCst` 唯一、`std.concurrent` 不存在、`actor` 关键字不存在、CLQ 有 `add`/`remove`/`peek`/`size`/`isEmpty` 而无 `poll`、`Mutex` 可重入）均本地 `cjc` 实测；"抢占式调度"与数据竞争定义直引官方文档。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
