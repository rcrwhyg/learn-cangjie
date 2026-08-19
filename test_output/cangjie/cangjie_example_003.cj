// 协程示例
import std.sync.*

main() {
    // 创建协程
    let future = spawn {
        println("在协程中执行")
        return 42
    }
    
    // 等待协程结果
    let result = future.get()
    println("协程返回: ${result}")
}