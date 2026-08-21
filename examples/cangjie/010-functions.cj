// 函数基础示例
func add(a: Int64, b: Int64): Int64 {
    return a + b
}

func greet(name!: String = "仓颉"): String {
    "你好, ${name}"
}

func calculate(a: Int64, b!: Int64, c!: Int64 = 10): Int64 {
    a + b + c
}

func showScore(score: Int64): String {
    if (score >= 60) {
        "及格"
    } else {
        "不及格"
    }
}

func describe(value: Int64): String {
    let label = if (value > 0) {
        "正数"
    } else {
        "非正数"
    }
    label
}

main() {
    let sum = add(3, 5)
    println("3 + 5 = ${sum}")

    let m1 = greet()
    let m2 = greet(name: "Alice")
    println(m1)
    println(m2)

    let r1 = calculate(1, b: 2)
    let r2 = calculate(1, b: 2, c: 20)
    let r3 = calculate(1, c: 20, b: 2)
    println("r1=${r1}, r2=${r2}, r3=${r3}")

    let s = showScore(85)
    println(s)

    let d = describe(10)
    println(d)
}
