// 变量与数据类型示例
main() {
    let name: String = "Alice"
    let age: Int64 = 25
    let height: Float64 = 1.68
    let isStudent: Bool = true
    let initial: Rune = r'A'
    let inferredCount = 10
    let greeting = "${name} is ${age} years old"
    let unitValue: Unit = ()
    var score: Int64 = 90
    const maxScore: Int64 = 100

    score = score + 5

    println("姓名: ${name}")
    println("年龄: ${age}")
    println("身高: ${height}")
    println("是否为学生: ${isStudent}")
    println("姓名首字母: ${initial}")
    println("推断的数量: ${inferredCount}")
    println(greeting)
    println("Unit值: ${unitValue}")
    println("成绩: ${score}/${maxScore}")
}
