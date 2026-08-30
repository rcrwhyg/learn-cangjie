// 错误处理与 Option 示例
// 演示：自定义 Exception、throw、try-catch-finally、try 作表达式（最小公共父类型）、
// CatchPattern 的联合类型(|)与通配符(_)、try-with-resources、
// Option 解构四件套（match / ?? / ?. / getOrThrow）与用 Option 做错误传播

// ========== 1) 自定义异常 ==========

open class AppException <: Exception {
    public init(message: String) {
        super(message)
    }
    public open override func getClassName(): String {
        "AppException"
    }
}

// ========== 2) try-with-resources 用到的资源类型 ==========

class Worker <: Resource {
    let name: String
    private var opened: Bool = false

    public init(name: String) {
        this.name = name
    }
    public func start(): Unit {
        opened = true
        println("${name} started")
    }
    public func isClosed(): Bool {
        !opened
    }
    public func close(): Unit {
        println("${name} closed")
        opened = false
    }
}

// ========== 3) 用 Option 做错误传播：安全除法 ==========

func safeDiv(a: Int64, b: Int64): ?Int64 {
    if (b == 0) {
        None
    } else {
        Some(a / b)
    }
}

// ========== 4) Option 解构用的类型 ==========

struct Box {
    public var v: Int64
    public init(v: Int64) {
        this.v = v
    }
}

main(): Int64 {
    // ---- 1) throw + try-catch-finally ----
    try {
        throw AppException("boom")
    } catch (e: AppException) {
        println("caught: ${e.message}")
    } finally {
        println("finally executed")
    }

    // ---- 2) CatchPattern 联合类型(|)：多异常共用一个 catch ----
    try {
        throw IllegalArgumentException("bad arg")
    } catch (e: IllegalArgumentException | OverflowException) {
        // 被捕获异常类型转换为两者的最小公共父类型，故只能访问公共成员（如 message）
        println("union caught: ${e.message}")
    }

    // ---- 3) CatchPattern 通配符(_)：捕获任意 Exception ----
    try {
        throw OverflowException()
    } catch (_) {
        println("wildcard caught any exception")
    }

    // ---- 4) try 作为表达式：类型取各分支的最小公共父类型（finally 不参与）----
    let v: Int64 = try {
        10
    } catch (e: Exception) {
        -1
    } finally {
        println("in finally")
    }
    println("try-expr v = ${v}")

    // ---- 5) try-with-resources：离开作用域自动 close ----
    try (w = Worker("Tom")) {
        w.start()
        println("working")
    }

    // ---- 6) Option 定义与自动装箱 ----
    let a: Option<Int64> = Some(100)
    let b: ?Int64 = Some(200)
    let c: Option<Int64> = 300 // 需要 Option 处直接给 T，编译器自动 Some 包装
    println("a=${a.getOrThrow()} b=${b.getOrThrow()} c=${c.getOrThrow()}")

    // ---- 7) Option 解构：match ----
    println("match = ${describeOption(Some(7))}")
    println("match = ${describeOption(None)}")

    // ---- 8) Option 解构：?? (coalescing) ----
    // 用运行期结果演示，避免 Some/None 字面量被编译期折叠
    let someFromDiv = safeDiv(14, 2)     // Some(7)
    let noneFromDiv = safeDiv(14, 0)     // None
    println("some ?? 0 = ${someFromDiv ?? 0}")
    println("none ?? 0 = ${noneFromDiv ?? 0}")

    // ---- 9) Option 解构：?. 问号操作符 ----
    let boxOpt = boxOptFor(99)           // Some(Box(99))
    let boxed: ?Int64 = boxOpt?.v        // Some(99)
    println("boxOpt?.v = ${boxed ?? -1}")
    let noneOpt = boxOptFor(-1)          // None（约定 v<0 返回 None）
    let empty: ?Int64 = noneOpt?.v       // None
    println("noneOpt?.v = ${empty ?? -1}")

    // ---- 10) getOrThrow：None 时抛 NoneValueException ----
    try {
        let _ = noneFromDiv.getOrThrow()
    } catch (e: NoneValueException) {
        println("NoneValueException caught")
    }

    // ---- 11) 用 Option 做错误传播 ----
    let ok = safeDiv(10, 2)
    let bad = safeDiv(10, 0)
    println("safeDiv(10,2) = ${ok ?? 0}")
    println("safeDiv(10,0) default = ${bad ?? -1}")

    return 0
}

func describeOption(p: ?Int64): String {
    match (p) {
        case Some(x) => "value:${x}"
        case None => "none"
    }
}

// 约定：v < 0 返回 None，否则返回 Some(Box(v))；用运行期分支避免常量折叠
func boxOptFor(v: Int64): ?Box {
    if (v < 0) {
        None
    } else {
        Some(Box(v))
    }
}
