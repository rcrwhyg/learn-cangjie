package ct

// const 函数与常量求值示例（配合文章 43）。
// const func 关键：在 const 上下文里编译期算；在其他上下文里运行时算（同一个函数、两种时机）。

const func sq(x: Int64): Int64 { x * x }                        // 纯、无 var、无副作用
const func hyp(a: Int64, b: Int64): Int64 { sq(a) + sq(b) }     // 调另一个 const func

// const func 允许递归（实测通过）：只要能被编译期收敛。
const func fact(n: Int64): Int64 {
    if (n <= 1) { 1 } else { n * fact(n - 1) }
}

// —— const 上下文：这些初始化表达式全部在编译期求值 ——
const TRIPLE: Int64 = 3 * 14                    // 42（编译期折叠）
const HYP: Int64 = hyp(3, 4)                    // 25（编译期调用 const func）

class Magic {
    public static const SEVEN: Int64 = 7        // 类级 const（struct/class 单写 const 会报"expected static"）
}

// 运行时函数：从外部拿参数（模拟非 const 输入），
// 然后调用同一个 const func sq——这一次它在运行期算，不是编译期算。
func runtimeSquares(n: Int64): Int64 {
    var acc = 0
    for (i in 1..n) { acc += sq(i) }
    return acc
}

main(): Int64 {
    const local: Int64 = fact(5)                // 编译期算 120
    println("TRIPLE=${TRIPLE}")                 // 42
    println("HYP=${HYP}")                       // 25
    println("fact5=${local}")                   // 120
    println("MAGIC=${Magic.SEVEN}")             // 7
    println("runtime_sq_1_to_4=${runtimeSquares(4)}")   // 14（1..4 上界不含 → i=1,2,3 → 1+4+9）
    return 0
}
