package perf

// 性能分析与优化示例（配合文章 46）。演示"少分配、少 GC"的几个正确写法。
// 注意：本程序证明**写法正确**（结果确定、可编译），**不证明速度**——
// 真实性能必须用 cjprof（文章 40）在 Linux 上测量，别凭感觉。
// （StringBuilder 在 std.core、无需 import）

// 1) Array 预分配：一次到位，避免 add 触发多次"扩容 + 拷贝"
func sumPreallocated(n: Int64): Int64 {
    let a = Array<Int64>(n, { i => i })      // 给定长度 + 初始化函数，一次分配
    var s: Int64 = 0
    for (x in a) { s += x }
    return s
}

// 2) VArray<T,$N>：定长小数组、零堆分配（承文章 44），适合热点里的小缓冲区
func sumVArray(): Int64 {
    let v: VArray<Int64, $4> = [1, 2, 3, 4]
    var s: Int64 = 0
    for (i in 0..v.size) { s += v[i] }        // VArray 不实现 for-in，用索引遍历
    return s
}

// 3) 字符串累积：走 StringBuilder，避免 s = s + x 每次造中间串
func buildLabel(): String {
    let sb = StringBuilder()
    for (_ in 0..3) { sb.append("x") }
    return sb.toString()
}

main(): Int64 {
    println("prealloc_sum=${sumPreallocated(5)}")   // 0+1+2+3+4 = 10
    println("varray_sum=${sumVArray()}")            // 1+2+3+4 = 10
    println("label=${buildLabel()}")                // xxx
    return 0
}
