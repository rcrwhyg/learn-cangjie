// 资源管理示例
// 演示：三种资源释放路径（手动 close / try-with-resources 自动 close / 终结器 ~init）、
// Resource 接口契约、try-with-resources 与手动释放的取舍、显式触发 GC（std.runtime.gc）
//
// 注意：终结器 ~init 的触发时机、执行线程、相对顺序都不确定（官方规则 5/6/7），
// 因此本示例把“可观察的输出”放在 try-with-resources 上；终结器只做内部计数，
// 不依赖其执行时机来判定正确性。

import std.collection.ArrayList
import std.runtime.gc

// ========== 1) 实现 Resource：交给 try-with-resources 自动关闭 ==========

class Conn <: Resource {
    let name: String
    private var closed: Bool = false

    public init(name: String) {
        this.name = name
        println("open ${name}")
    }

    public func query(): Unit {
        println("query on ${name}")
    }

    public func isClosed(): Bool {
        closed
    }

    public func close(): Unit {
        closed = true
        println("close ${name}")
    }
}

// ========== 2) 带终结器的普通类（非 open，最多一个 ~init，不能显式调用）==========

class TempBuffer {
    public let id: Int64
    public init(id: Int64) {
        this.id = id
    }
    // 终结器：无参数、无返回、无修饰符，实例被 GC 回收时触发（时机不确定）
    ~init() {
        // 这里只做“假设性”的资源清理示意；不 println，避免依赖不确定的执行时机
        TempBuffer.destroyedCount += 1
    }
    public static var destroyedCount: Int64 = 0
}

main(): Int64 {
    // ---- 1) try-with-resources：作用域结束自动 close ----
    println("--- try-with-resources ---")
    try (c = Conn("db-1")) {
        c.query()
    }   // 离开作用域自动调用 c.close()

    // ---- 2) 多个资源：一行声明多个，作用域结束都会自动 close ----
    println("--- multiple resources ---")
    try (r1 = Conn("a"), r2 = Conn("b")) {
        r1.query()
        r2.query()
    }

    // ---- 3) 手动释放（对照）：不用 try-with-resources 时要自己 close ----
    println("--- manual close ---")
    let manual = Conn("manual")
    manual.query()
    manual.close()   // 开发者负责调用；漏掉就是资源泄漏

    // ---- 4) 终结器演示：造对象、丢弃引用、触发 GC ----
    println("--- finalizer + gc ---")
    let holder = ArrayList<TempBuffer>()
    holder.add(TempBuffer(1))
    holder.add(TempBuffer(2))
    holder.remove(at: 0)
    holder.remove(at: 0)
    // 请求一次阻塞式 GC；是否已运行终结器不确定，故只打印“请求过 GC”，不打印计数
    gc(heavy: true)
    println("gc requested")

    // 正确性说明：优先用 try-with-resources 管理有明确作用域的资源；
    // 终结器仅作为“兜底”，其时机不确定，不能承载必须按时执行的逻辑。
    return 0
}
