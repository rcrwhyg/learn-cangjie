// 《cjc 编译器》配套示例：一个"被各种 cjc 选项反复编译"的最小确定性程序。
// 正文用它演示 cjc 的默认产物名、--output-type、-O 优化级别、诊断格式、链接与运行时配置等。
// 关键点：本程序不含任何整数溢出（默认 --int-overflow=throwing 下也安全），
// 且结果与优化级别无关——无论 -O0 / -O2，输出恒定，方便和编译器行为对照。
main(): Int64 {
    // 1) 定点整数求和：1..=10 -> 55（不溢出）
    var sum = 0
    for (i in 1..=10) {
        sum += i
    }
    println("sum(1..=10) = ${sum}")     // sum(1..=10) = 55

    // 2) 简单乘法：优化级别不同结果不变
    let product = 6 * 7
    println("6 * 7 = ${product}")       // 6 * 7 = 42

    // 3) 收尾标记，确认"编译产物能跑起来"
    println("cjc demo ok")              // cjc demo ok
    return 0
}
