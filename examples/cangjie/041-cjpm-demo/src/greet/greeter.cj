package mpdemo.greet

// 对外公开的库函数：cjpm 会把 greet 包先编成模块内的依赖，再编 main。
public func greeting(who: String): String {
    return "hello, ${who}"
}

public func add(a: Int64, b: Int64): Int64 {
    return a + b
}
