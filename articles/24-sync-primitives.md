# 仓颉同步与并发原语

> **摘要**: 上一篇能起线程、能取结果，但只要多个线程碰同一份可变数据，就会有**数据竞争**。仓颉 1.0.5 的 `std.sync` 提供四件套解决它：**原子操作**（`AtomicInt64`/`AtomicBool`/`AtomicReference`）、**可重入互斥锁**（`Mutex` 的 `lock/unlock/tryLock`）、**条件变量**（`Condition` 的 `wait/notify/notifyAll`）、以及配套的 **`synchronized` 关键字**（自动加解锁）；再加 core 的 **`ThreadLocal`** 做线程局部存储。本文依据官方 `concurrency/sync.html`，讲清每种原语的语义、`Mutex` 可重入的 lock/unlock 配对规则、`wait` 必须包在循环里的原因，以及几条经典错误用法，配一个**全部输出确定**的示例。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已完成《线程与协程使用》（`spawn`/`Future`/`Thread`）
- 已了解数据竞争、临界区、死锁等并发常识

## 1. 为什么需要同步

多个线程读写同一份可变数据、且至少有一个是写，又没有同步保护，就是**数据竞争**——结果不确定、可能损坏状态。仓颉给三种主流机制保证线程安全：**原子操作**、**互斥锁**、**条件变量**，再配 `synchronized` 与 `ThreadLocal`。

> **⚠️ 一个仓颉特有的写法前提**：官方所有计数器示例里，被 `Mutex`/`Atomic` 保护的共享变量都是**全局变量**（顶层 `var`/`let`）。因为把**局部 `var` 直接闭包进 `spawn` 会触发"捕获可变变量的闭包不能作一等公民"**（见《函数类型、Lambda 与闭包》）。访问全局变量不算捕获，所以跨线程共享可变状态请用全局 + 同步原语。

## 2. 原子操作 Atomic

仓颉对**整数、`Bool`、引用类型**提供原子操作。整数原子类有 `AtomicInt8/16/32/64` 与 `AtomicUInt8/16/32/64`；`Bool` 用 `AtomicBool`，引用用 `AtomicReference`。

整数原子支持的操作（`import std.sync.AtomicInt64` 等）：

| 操作 | 功能 |
|---|---|
| `load()` | 读取 |
| `store(val)` | 写入 |
| `swap(val)` | 交换，返回**旧值** |
| `compareAndSwap(old, new)` | 当前值 == old 才换成 new，成功返 `true` |
| `fetchAdd/fetchSub/fetchAnd/fetchOr/fetchXor` | 读改算，返回**运算前的值** |

两个记忆点：① 交换/算术类**返回的是修改前的值**；② `compareAndSwap` 是"等于 old 才替换"。

```cangjie
var obj = AtomicInt32(1)
obj.load()               // 1
obj.swap(2)              // 返回 1，之后值为 2
obj.compareAndSwap(2, 3) // 值确为 2 → 换成 3，返回 true
obj.compareAndSwap(2, 3) // 值已是 3 ≠ 2 → 不换，返回 false
obj.fetchAdd(1)          // 返回旧值 3，之后值为 4
```

`Bool` / 引用类型的原子只给 `load/store/swap/compareAndSwap`（引用类型 CAS 比较的是**引用是否同一对象**）。

典型用途——无锁计数（4 个任务各 `fetchAdd` 若干次，结果精确可加）：

```cangjie
import std.sync.AtomicInt64
let count = AtomicInt64(0)
// 每个 spawn 里：count.fetchAdd(1)
// 全部结束后：count.load() 得到总数
```

> **💡 提示**：每种原子方法还有接收**内存排序参数**的重载，但仓颉 1.0.5 **目前只支持顺序一致性**（`seq_cst`）。

## 3. 可重入互斥锁 Mutex

`Mutex` 保护临界区，保证任意时刻最多一个线程进入。取不到锁就阻塞，直到锁释放被唤醒。**可重入**指：同一线程已持有该锁后可再次立即获得。

主要成员：

```cangjie
public class Mutex <: UniqueLock {
    public init()
    public func lock(): Unit       // 加锁，取不到则阻塞
    public func unlock(): Unit     // 解锁，唤醒一个等待者
    public func tryLock(): Bool    // 尝试加锁，取不到返回 false（不阻塞）
    public func condition(): Condition
}
```

两条铁律：**访问共享数据前先 `lock`；处理完必须 `unlock`**。

```cangjie
import std.sync.Mutex
var count: Int64 = 0
let mtx = Mutex()
// 每个 spawn 里：
mtx.lock()
count += 1
mtx.unlock()
```

### 3.1 可重入与 lock/unlock 配对

可重入意味着同一线程重复 `lock` 同一把 `Mutex` 不会自锁死。但——

> **⚠️ 注意**：可重入锁的 `unlock()` 次数**必须等于** `lock()` 次数才能真正释放。`foo()` 里 `lock` 后调用同样 `lock` 的 `bar()`，退出时各自 `unlock`，最终净释放正确。

### 3.2 三种典型错误（官方点名，务必避开）

1. **加了锁不解锁**：其他线程永远拿不到锁、被阻塞。
2. **没持锁就 `unlock`**：抛 `IllegalSynchronizationStateException`。
3. **把 `tryLock()` 当成一定成功**：它只是"尝试"，没拿到锁还去改临界区、或随后 `unlock`，会出未定义/异常。`tryLock()` 返回 `false` 时**不要**进入临界区、也**不要** `unlock`。

## 4. synchronized 自动加解锁

`Mutex` 手动 lock/unlock 容易忘解锁、或持锁时抛异常导致不释放。`synchronized(lock) { ... }` 在进入时自动加锁、退出时（含 `break`/`continue`/`return`/`throw` 跳出）自动解锁：

```cangjie
import std.sync.Mutex
var count: Int64 = 0
let mtx = Mutex()
// 每个 spawn 里，替代 lock/unlock：
synchronized(mtx) {
    count += 1
}
```

`synchronized` 也能作**表达式**取值，例如用它安全地创建条件变量：

```cangjie
let cond = synchronized(mtx) { mtx.condition() }
```

## 5. 条件变量 Condition

`Condition` 是与某把锁绑定的等待队列，由 `mutex.condition()` 创建（一把锁可建多个）。它让线程阻塞、等待别的线程的信号再恢复。

```cangjie
public interface Condition {
    func wait(): Unit
    func wait(timeout!: Duration): Bool
    func waitUntil(predicate: () -> Bool): Unit
    func waitUntil(predicate: () -> Bool, timeout!: Duration): Bool
    func notify(): Unit     // 唤醒一个等待者
    func notifyAll(): Unit  // 唤醒全部等待者
}
```

规则：调用 `wait`/`notify`/`notifyAll` 前，**当前线程必须已持有绑定的那把锁**。`wait` 会：把自己加入等待队列 → **完全释放该锁**（记录重入次数）→ 阻塞 → 被 `notify` 唤醒后重新抢回锁并恢复重入状态。

> **⚠️ 为什么 `wait` 必须写在循环里**：系统不保证调度实时性、语言规范**允许虚假唤醒**（`wait(timeout)` 返回值由实现决定）。所以永远用"谓词循环"包住：

```cangjie
mtx.lock()
while (!ready) {   // 条件不满足就继续等，防虚假唤醒
    cond.wait()
}
// 用共享状态...
mtx.unlock()
```

两条经典错误（官方示例）：**wait 用的锁和 condition 绑定的锁不是同一把**、或 **wait 时根本没持锁**——都会在 `wait` 内部释放锁时抛异常。

进阶：一把锁建 `notFull`/`notEmpty` 两个 `Condition`，可实现**有界阻塞队列**（满了 `put` 等、空了 `get` 等），这是生产者-消费者的标准骨架。

## 6. 线程局部变量 ThreadLocal

`ThreadLocal<T>`（core，无需 import）给每个线程一份独立存储，线程各读写各的，互不影响：

```cangjie
public class ThreadLocal<T> {
    public init()
    public func get(): Option<T>          // 没有值时返回 None
    public func set(value: Option<T>): Unit  // 传 None 等于删除
}
```

```cangjie
let tl = ThreadLocal<Int64>()
spawn { tl.set(123); /* ... */ }   // 这条线程看到的是 123
spawn { tl.set(456); /* ... */ }   // 那条线程看到的是 456，互不干扰
```

注意 `get()` 返回 `Option<T>`——从没 `set` 过就是 `None`。

## 7. 完整可运行示例（输出确定）

下例把四件原语一次跑通，且**每项结果都是确定值**：原子计数 100、Mutex 计数 100、`synchronized` 计数 100、可重入锁 220、条件变量 99、`ThreadLocal` 42。

<!-- example: cangjie/029-sync-primitives.cj -->
```cangjie
// 同步与并发原语示例
// 演示：原子操作 AtomicInt64、可重入互斥锁 Mutex(lock/unlock/tryLock)、
// synchronized 自动加解锁、Condition 条件变量(wait/notifyAll + 谓词循环)、
// ThreadLocal 线程局部变量。所有输出均做成了确定值。
//
// 关键：跨 spawn 共享的可变计数用“全局变量 + 同步原语”保护（全局变量访问不算闭包捕获，
// 官方示例也是这么写的）；把局部 var 直接塞进 spawn 闭包会触发“捕获可变变量不能作一等公民”。

import std.sync.{AtomicInt64, Mutex, Condition}
import std.collection.ArrayList

// ---- 共享可变状态：全局，配合同步原语保护 ----
let atomicCount = AtomicInt64(0)
var mutexCount: Int64 = 0
let mutex = Mutex()
var syncCount: Int64 = 0

// ---- 可重入锁演示用 ----
var reCount: Int64 = 0
let reMutex = Mutex()

func bar() {
    reMutex.lock()      // 已被 foo 持有，可重入：立即再次获得
    reCount += 100
    reMutex.unlock()
}

func foo() {
    reMutex.lock()
    reCount += 10
    bar()
    reMutex.unlock()    // unlock 次数需与 lock 次数一致
}

// ---- Condition 演示用 ----
var ready: Bool = false
var result: Int64 = 0

main(): Int64 {
    // 1) AtomicInt64：4 个任务各 fetchAdd 25 次 -> 100（原子，无需锁）
    let fa = ArrayList<Future<Unit>>()
    for (_ in 0..4) {
        fa.add(spawn {
            for (_ in 0..25) { atomicCount.fetchAdd(1) }
        })
    }
    for (f in fa) { f.get() }

    // 2) Mutex：4 个任务各在锁内自增 25 次 -> 100
    let fb = ArrayList<Future<Unit>>()
    for (_ in 0..4) {
        fb.add(spawn {
            for (_ in 0..25) {
                mutex.lock()
                mutexCount += 1
                mutex.unlock()
            }
        })
    }
    for (f in fb) { f.get() }

    // 3) synchronized：等价于自动 lock/unlock，4×25 -> 100
    let fc = ArrayList<Future<Unit>>()
    for (_ in 0..4) {
        fc.add(spawn {
            for (_ in 0..25) {
                synchronized(mutex) { syncCount += 1 }
            }
        })
    }
    for (f in fc) { f.get() }

    // 4) 可重入锁：foo -> bar 对同一 Mutex 二次加锁不死锁；主线程与子线程各跑一次 -> 220
    let rd = spawn { foo() }
    foo()
    rd.get()

    // 5) Condition：消费者在谓词循环里 wait，生产者置位后 notifyAll（顺序无关）
    let mtx2 = Mutex()
    let cond: Condition = synchronized(mtx2) { mtx2.condition() }
    let consumer = spawn {
        mtx2.lock()
        while (!ready) {         // 官方建议：把 wait 包在循环里，防虚假唤醒
            cond.wait()
        }
        let v = result
        mtx2.unlock()
        v
    }
    mtx2.lock()
    result = 99
    ready = true
    cond.notifyAll()
    mtx2.unlock()

    // 6) ThreadLocal：各线程独立存储，子线程读回自己 set 的值
    let tl = ThreadLocal<Int64>()
    let ftl = spawn {
        tl.set(42)
        tl.get().getOrThrow()
    }

    println("atomic=${atomicCount.load()}")          // atomic=100
    println("mutex=${mutexCount}")                    // mutex=100
    println("synchronized=${syncCount}")              // synchronized=100
    println("reentrant=${reCount}")                   // reentrant=220
    println("condition=${consumer.get()}")            // condition=99
    println("threadlocal=${ftl.get()}")               // threadlocal=42
    return 0
}
```

预期输出（每行都用 `get()` 收敛，跨线程完成顺序不影响结果）：

```text
atomic=100
mutex=100
synchronized=100
reentrant=220
condition=99
threadlocal=42
```

## 8. 语言对比

| 概念 | 仓颉 | Java | Go | Rust |
|---|---|---|---|---|
| 原子 | `AtomicInt64`/`AtomicBool`/`AtomicReference` | `AtomicInteger`/`AtomicReference` | `sync/atomic` | `AtomicI64`/`AtomicBool` |
| 互斥锁 | `Mutex`（可重入） | `ReentrantLock`/`synchronized`（monitor 可重入） | `sync.Mutex`（**不可重入**） | `Mutex<T>`（非重入） |
| 自动加解锁 | `synchronized(m){}` | `synchronized(o){}` | `defer mu.Unlock()` | 作用域守卫 `let _g = m.lock()` |
| 条件变量 | `Condition`（wait/notify/notifyAll/waitUntil） | `Object.wait/notify` | 无原生（用 channel） | `Condvar` |
| 线程局部 | `ThreadLocal<T>` | `ThreadLocal<T>` | 无（用 goroutine 本地变量） | `thread_local!` |

**从 Java 迁移**：`Mutex`≈可重入 `ReentrantLock`、`synchronized(m){}`≈`synchronized(o){}`、`Condition`/`wait`/`notify` 语义几乎一致（同样要"循环里 wait"）。
**从 Go 迁移**：Go 的 `sync.Mutex` **不可重入**，别把可重入当理所当然；Go 用 channel 通信代替条件变量，仓颉两种都给（`Channel` 在下一篇/后续）。

## 9. 常见问题（FAQ）

### Q1: 计数用原子还是锁？

单个整数/引用上的简单"读改写"用原子（`fetchAdd`/`CAS`）最省；一段临界区里多步操作多个变量用 `Mutex`/`synchronized`。

### Q2: `Mutex` 能重入吗？`unlock` 要配几次？

能重入（同线程再次 `lock` 立即成功）。但 `unlock` 次数必须与 `lock` 次数相等才真正释放。

### Q3: `tryLock()` 返回 false 我能直接进临界区吗？

不能。它可能没拿到锁；返回 `false` 时别改临界区、也别 `unlock`。

### Q4: `wait` 为什么要写在 `while` 循环里？

允许虚假唤醒、调度也不保证精确时长；用谓词循环复查条件才安全。

### Q5: `wait`/`notify` 前要不要先 `lock`？

要。调用它们时当前线程必须持有绑定的那把锁，且 `wait` 用的锁必须与 `condition()` 来源同一把，否则释放锁时报错。

### Q6: 共享计数器能写成函数里的局部 `var` 吗？

不能直接放进 `spawn` 闭包（捕获可变局部变量不能作一等公民）。像官方示例那样用**全局变量**配合 `Mutex`/`Atomic`，或把状态收进类实例成员。

### Q7: `ThreadLocal` 的值默认是什么？

`get()` 返回 `Option<T>`，没 `set` 过是 `None`；`set(Option.None)` 会删除该线程的这个值。

## 10. 总结

1. 多线程共享可变数据须同步，否则数据竞争；跨 `spawn` 的共享计数用**全局变量 + 原语**（局部 `var` 会被闭包规则挡下）。
2. **原子**：整/Bool/引用三类，`fetchAdd`/`swap` 返回**旧值**，`compareAndSwap` 是"等 old 才换"；内存排序目前仅顺序一致性。
3. **`Mutex`**：`lock/unlock/tryLock/condition`；可重入但 **lock/unlock 次数要配对**；别在没持锁时 `unlock`、别把 `tryLock` 当必成。
4. **`synchronized(m){}`**：进出自动加解锁（含 `break`/`return`/`throw` 跳出），也可作表达式取值。
5. **`Condition`**：`wait/notify/notifyAll/waitUntil`；`wait` 前必须持锁、必须配同一把锁、且要**包在谓词循环**里防虚假唤醒；两 `Condition` 可搭有界阻塞队列。
6. **`ThreadLocal<T>`**：线程私有存储，`get()` 返 `Option<T>`。

## 参考资料

1. 仓颉 1.0.5 LTS 同步机制：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/concurrency/sync.html
2. 仓颉 1.0.5 LTS 终止线程（`hasPendingCancellation` 与 `std.sync` 上下文）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/concurrency/terminal_thread.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
