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
