// 运算符与表达式示例
main() {
    var left: Int64 = 10
    let right: Int64 = 3
    let ready: Bool = true

    let sum = left + right
    let difference = left - right
    let product = left * right
    let quotient = left / right
    let remainder = left % right
    let power = 2 ** 3

    let equal = left == right
    let greater = left > right
    let inRange = left >= 1 && left <= 10
    let notReady = !ready

    let bitAnd = left & right
    let bitOr = left | right
    let bitXor = left ^ right
    let shifted = left << 1

    let openRange = 1..5
    let closedRange = 1..=5
    var openCount = 0
    var closedCount = 0
    for (_ in openRange) {
        openCount += 1
    }
    for (_ in closedRange) {
        closedCount += 1
    }

    left += 2
    var enabled = true
    enabled &&= false

    println("算术: ${sum}, ${difference}, ${product}, ${quotient}, ${remainder}, ${power}")
    println("比较: ${equal}, ${greater}, ${inRange}, ${notReady}")
    println("位运算: ${bitAnd}, ${bitOr}, ${bitXor}, ${shifted}")
    println("区间元素个数: ${openCount}, ${closedCount}")
    println("赋值: ${left}, ${enabled}")
}
