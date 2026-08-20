// 协程示例
main() {
    // 创建协程并返回计算结果
    let future = spawn {
        println("在协程中执行")
        return 42
    }

    // 等待协程完成并获取结果
    let result = future.get()
    println("协程返回: ${result}")
}
