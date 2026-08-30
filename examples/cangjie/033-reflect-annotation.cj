// 反射、注解与动态特性示例（基于 1.0.5 标准库 std.reflect）
// 演示：TypeInfo 获取（of/泛型 of/get）、反射读写实例成员、
// 自定义注解 @Annotation + const init + findAnnotation 读取、
// 编译期整数溢出注解 @OverflowWrapping。
//
// 注意：本文件 import std.reflect，本地 macOS(1.0.5) SDK 缺该包会被
// tools/test-local.sh 跳过；真正的编译与运行以 Linux CI 为准。

import std.reflect.*

// ---- 自定义注解：@Annotation 修饰的 class，必须提供至少一个 const init ----
@Annotation
public class Version {
    let code: String
    const init(code: String) {
        this.code = code
    }
}

@Version["1.0"] class A {}

@Version["1.1"] class B {}

// ---- 反射读写成员用的普通类（成员需 public 才可见）----
public class Account {
    public var balance: Int64 = 100
}

// ---- 编译期整数溢出策略注解（编译器内置，不依赖 std.reflect）----
// Wrapping：溢出后高位截断。Int8 下 105 + 105 = 210 -> 截断为 -46。
@OverflowWrapping
func addWrap(a: Int8, b: Int8): Int8 {
    a + b
}

main(): Int64 {
    // 1) 运行时类型信息：of 实例 / of<静态类型> 打印的都是类型全名
    let infoA: TypeInfo = TypeInfo.of(A())
    println("type of A = ${infoA}")           // type of A = default.A

    // 2) 反射读取自定义注解（顺序无关，A、B 各一条）
    for (o in [A(), B()]) {
        if (let Some(v) <- TypeInfo.of(o).findAnnotation<Version>()) {
            println("version = ${v.code}")     // version = 1.0 / version = 1.1
        }
    }

    // 3) 反射访问并修改实例成员变量
    let acc = Account()
    let field = TypeInfo.of(acc).getInstanceVariable("balance")
    println("balance = ${(field.getValue(acc) as Int64).getOrThrow()}")   // balance = 100
    field.setValue(acc, 250)
    println("balance after = ${(field.getValue(acc) as Int64).getOrThrow()}")  // balance after = 250

    // 4) 整数溢出：Wrapping 高位截断
    println("wrap 105+105(Int8) = ${addWrap(105, 105)}")   // wrap 105+105(Int8) = -46

    return 0
}
