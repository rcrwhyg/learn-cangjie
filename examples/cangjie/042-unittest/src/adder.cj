package utdemo

// 被测代码（生产代码）——正常构建（cjpm build）时会编译本文件。
// 对应测试在同目录下的 adder_test.cj（文件名以 _test.cj 结尾），
// cjpm 在测试模式下才会编译它。

public func add(a: Int64, b: Int64): Int64 {
    return a + b
}

public func divide(a: Int64, b: Int64): Int64 {
    if (b == 0) {
        throw Exception("divide by zero")
    }
    return a / b
}
