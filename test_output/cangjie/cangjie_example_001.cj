// 类型推断示例
let name = "Alice"          // 编译器推断为 String 类型
let age = 25                // 编译器推断为 Int 类型
let pi: Float = 3.14        // 显式类型注解

// 类型安全示例
// let result = name + age  // 编译错误：类型不匹配
let greeting = "Hello, ${name}!"  // 正确：字符串模板