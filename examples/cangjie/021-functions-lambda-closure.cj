// 函数类型、Lambda 与闭包示例
// 演示：函数类型（一等公民）、函数类型作参数/返回值/变量、带类型参数名、
// 嵌套函数、Lambda（参数与返回类型推断、立即调用）、闭包（捕获 let 局部变量并逃逸）、
// 调用语法糖：尾随 lambda、pipeline(|>)、composition(~>)、变长参数

// ========== 1) 函数类型（一等公民） ==========

func add(a: Int64, b: Int64): Int64 {
    a + b
}

func returnTuple(a: Int64, b: Int64): (Int64, Int64) {
    (a, b)
}

// 函数类型作为参数类型
func printAdd(op: (Int64, Int64) -> Int64, x: Int64, y: Int64): Unit {
    println("printAdd = ${op(x, y)}")
}

// 函数类型作为返回类型（-> 右结合，等价于 () -> ((Int64, Int64) -> Int64)）
func makeAdder(): (Int64, Int64) -> Int64 {
    add
}

// 带类型参数名的函数类型
func showFruitPrice(name: String, price: Int64): Unit {
    println("fruit: ${name} price: ${price} yuan")
}

// ========== 2) 嵌套函数 ==========

func foo(): (Int64, Int64) -> Int64 {
    func nestAdd(a: Int64, b: Int64): Int64 {
        a + b + 3
    }
    println("nestAdd(1,2) = ${nestAdd(1, 2)}") // 6
    nestAdd // 把嵌套函数作为返回值返回
}

// ========== 3) 闭包：捕获 let 局部变量并逃逸到作用域之外 ==========

func returnAddNum(): (Int64) -> Int64 {
    let num: Int64 = 10
    func addNum(a: Int64): Int64 {
        a + num // 捕获外部只读局部变量 num
    }
    addNum
}

// ========== 4) 调用语法糖 ==========

// 尾随 lambda：最后一个形参是函数类型
func myIf(cond: Bool, fn: () -> Int64): Int64 {
    if (cond) {
        fn()
    } else {
        0
    }
}

func square(x: Int64): Int64 {
    x * x
}

// pipeline / composition 的普通单参函数
func inc(x: Int64): Int64 {
    x + 1
}

func double(x: Int64): Int64 {
    x * 2
}

// 变长参数：最后一个非命名形参是 Array 类型
func sum(arr: Array<Int64>): Int64 {
    var total = 0
    for (x in arr) {
        total += x
    }
    total
}

main(): Int64 {
    // ---- 1) 函数类型 ----
    let f: (Int64, Int64) -> Int64 = add // 函数名作为表达式，赋给函数类型变量
    println("f(3,4) = ${f(3, 4)}")        // 7
    let (p, q) = returnTuple(1, 2)
    println("tuple = ${p}, ${q}")          // 1, 2
    printAdd(add, 10, 20)                  // 函数类型作实参
    let adder = makeAdder()
    println("adder(5,6) = ${adder(5, 6)}") // 函数类型作返回值 → 11
    let handler: (name: String, price: Int64) -> Unit = showFruitPrice
    handler("banana", 10)                  // 带类型参数名的函数类型

    // ---- 2) 嵌套函数 ----
    let returnedNest = foo()
    println("returnedNest(1,2) = ${returnedNest(1, 2)}") // 6

    // ---- 3) Lambda ----
    // 参数类型由变量类型推断
    var sum1: (Int64, Int64) -> Int64 = { a, b => a + b }
    println("sum1(2,3) = ${sum1(2, 3)}")  // 5
    // 无参数 lambda
    let greet = { => println("Hello, Lambda") }
    greet()
    // 立即调用
    let r1 = { a: Int64, b: Int64 => a + b }(1, 2)
    println("immediate = ${r1}")          // 3
    // 作为实参时参数类型由形参推断（n 推断为 Int64）
    let mapped = applyOnce({ n => n * n }, 9)
    println("applyOnce = ${mapped}")      // 81

    // ---- 4) 闭包 ----
    let add10 = returnAddNum()
    println("add10(32) = ${add10(32)}")   // 42（捕获的 num 在作用域外仍可访问）

    // ---- 5) 调用语法糖 ----
    // 尾随 lambda：普通写法
    println("myIf normal = ${myIf(true, { => 100 })}") // 100
    // 尾随 lambda：把 lambda 放到圆括号外
    println("myIf trailing = ${myIf(true) { 100 }}")   // 100
    // 唯一 lambda 实参可省略圆括号
    println("square via trailing = ${callWithLambda { i => i * i }}") // 1（内部对 1 求平方）
    // pipeline：数值依次流过函数
    let piped = 5 |> inc |> square         // square(inc(5)) = square(6) = 36
    println("piped = ${piped}")
    // composition：f ~> g 等价于 { x => g(f(x)) }
    let composed = inc ~> double
    println("composed(5) = ${composed(5)}") // double(inc(5)) = 12
    // 变长参数：直接传参数序列
    println("sum() = ${sum()}")             // 0
    println("sum(1,2,3) = ${sum(1, 2, 3)}") // 6

    return 0
}

// 供 lambda 作实参类型推断使用
func applyOnce(fn: (Int64) -> Int64, v: Int64): Int64 {
    fn(v)
}

// 供“唯一 lambda 实参省略圆括号”使用：对 1 应用传入的函数
func callWithLambda(fn: (Int64) -> Int64): Int64 {
    fn(1)
}
