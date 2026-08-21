// 类型推断示例
main() {
    let name = "Alice"          // 编译器推断为 String 类型
    let age = 25                // 编译器推断为 Int64 类型
    let pi = 3.14               // 编译器推断为 Float64 类型

    // 类型安全示例
    // let result = name + age  // 编译错误：类型不匹配
    let greeting = "Hello, ${name}!"  // 正确：字符串模板
    println(greeting)
}
