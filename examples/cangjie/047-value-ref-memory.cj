package mem

// 值类型 / 引用类型与内存管理原理示例（配合文章 44）。
// 演示的都是"赋值/传参时到底拷贝什么"——基础篇只讲"怎么写 struct/class"，
// 本篇讲"值/引用语义"的实测边界。所有输出稳定、Linux CI 逐行核对。

class Cfg {                        // 引用类型：class
    public var v: Int64 = 0
    public init() {}
    // ~init() { ... }              // 终结器：GC 触发、时机不确定，故示例不打印、只在正文讲
}

struct Point {                     // 值类型：struct
    public var x: Int64
    public init(x: Int64) { this.x = x }
}

struct Wrap {                      // 值类型外壳、里面装一个引用
    public let cfg: Cfg
    public init(ic: Cfg) { this.cfg = ic }
}

main(): Int64 {
    // A) struct 值类型：赋值即"字段全量拷贝"、两边独立
    let p1 = Point(1)
    var p2 = p1
    p2.x = 99
    println("struct-copy: p1.x=${p1.x} p2.x=${p2.x}")

    // B) class 引用类型：赋值即"共享同一对象"
    let c1 = Cfg()
    let c2 = c1                    // 同一个对象、两个引用
    c2.v = 42
    println("class-alias: c1.v=${c1.v} c2.v=${c2.v}")

    // C) struct 里的 class 字段：struct 拷贝是"浅拷贝"——字段仍是同一引用
    let w1 = Wrap(c1)
    var w2 = w1                    // 结构拷了、cfg 指针没换
    w2.cfg.v = 7
    println("nested: w1.cfg.v=${w1.cfg.v} w2.cfg.v=${w2.cfg.v} c1.v=${c1.v}")

    // D) Array：官方"内部只持元素引用"，赋值不拷 backing store
    let a = [1, 2, 3]
    var b = a
    b[0] = 99
    println("array: a[0]=${a[0]} b[0]=${b[0]}")

    // E) VArray<T,$N>：真正的值类型数组，赋值连 backing store 一起拷
    let va: VArray<Int64, $3> = [1, 2, 3]
    var vb = va
    vb[0] = 99
    println("VArray: va[0]=${va[0]} vb[0]=${vb[0]}")

    return 0
}
