// 数组、元组与区间示例
// 演示：Array（引用类型）创建与访问、VArray（值类型）、Tuple 字面量与访问、Range 字面量

main() {
    // 1) Array 字面量
    let a: Array<Int64> = [1, 2, 3, 4, 5]
    let b = ["a1", "a2", "a3"]                  // 推断为 Array<String>
    println("a.size = ${a.size}")
    println("b.size = ${b.size}")

    // 2) Array 构造
    let empty = Array<Int64>()
    println("empty.size = ${empty.size}")
    let zeros = Array<Int64>(3, repeat: 0)
    let seq = Array<Int64>(4, {i => i * i})      // [0, 1, 4, 9]
    println("zeros = ${zeros.size}, seq[2] = ${seq[2]}")

    // 3) 访问与修改
    println("a[0] = ${a[0]}")
    a[0] = 100
    println("a[0] (after) = ${a[0]}")

    // 4) Range 下标切片
    let s = a[0..3]                              // [100, 2, 3]
    println("slice = ${s.size}")

    // 5) Array 引用语义：共享元素
    let arr1 = [0, 1, 2]
    let arr2 = arr1
    arr2[0] = 99
    println("arr1[0] = ${arr1[0]}, arr2[0] = ${arr2[0]}")  // 都是 99

    // 6) VArray 值类型数组
    var va: VArray<Int64, $3> = [10, 20, 30]
    println("va[1] = ${va[1]}")
    va[2] = 300
    println("va[2] = ${va[2]}")
    println("va.size = ${va.size}")

    // 7) VArray 构造
    let vSeq = VArray<Int64, $5>({i => i * 2})    // [0, 2, 4, 6, 8]
    let vZero = VArray<Int64, $4>(repeat: 0)
    println("vSeq[3] = ${vSeq[3]}, vZero[0] = ${vZero[0]}")

    // 8) Tuple 字面量与访问
    let pi = (3.14, "PI")
    println("pi[0] = ${pi[0]}, pi[1] = ${pi[1]}")

    // 9) 元组多赋值
    var (x, y) = (1, 2)
    println("x = ${x}, y = ${y}")
    (x, y) = (y, x)                              // 交换
    println("after swap: x = ${x}, y = ${y}")

    // 10) 命名元组（带类型参数名）
    func getFruit(): (name: String, price: Int64) {
        return ("banana", 10)
    }
    let f = getFruit()
    println("fruit[0] = ${f[0]}, fruit[1] = ${f[1]}")

    // 11) Range 字面量
    let r1 = 0..10                                 // [0, 1, ..., 9]
    let r2 = 0..=10                                // [0, 1, ..., 10]
    let _ = (r1, r2)                                 // 占位：仅用于演示 Range 类型
    let r3 = 0..10 : 2                             // 步长 2: [0, 2, ..., 8]
    let r4 = 10..0 : -2                           // 倒序: [10, 8, ..., 2]
    println("r4 reversed:")
    for (i in r4) {
        println("  ${i}")
    }
    println("r3 step 2 elements:")
    for (i in r3) {
        println("  ${i}")
    }

    // 12) Range 遍历与 for-in
    var sum = 0
    for (i in 1..=100) {
        sum += i
    }
    println("sum 1..=100 = ${sum}")

    // 13) 空 Range
    let emptyRange = 10..0 : 1                     // 空
    var count = 0
    for (i in emptyRange) {
        count += 1
    }
    println("empty range count = ${count}")
}
