package xlang

// 跨语言项目实战（配合文章 51）。文章 29 讲"foreign/@C/CString 的 API 怎么写"；
// 本篇把 C 互操作落到"工程视角"：ABI 布局、内存与资源的所有权配对、构建期如何链自定义 C 库。
// 运行只用 libc 自动链接的符号（strlen/atoi），无需自定义 .c 或 -l，故与其它示例一样可被 CI 直编直跑。
// 诚实说明：把"仓颉函数指针交给 C 回调"（如 qsort）所需的 C 函数指针类型写法，本 1.0.5 环境未能
// 在不臆造前提下确认，故示例不使用它，改在正文 §5 以"已验证的 @C 导出方向 + 构建链接"承担项目主题。

// —— foreign 声明：只有签名、无实现；libc 符号自动链接 ——
foreign func strlen(s: CString): UIntNative     // C: size_t strlen(const char*)
foreign func atoi(s: CString): Int32            // C: int atoi(const char*)

// —— @C struct：与 C 结构体逐字节兼容的内存布局；成员须满足 CType ——
@C
struct Vec2 {
    var x: Int64 = 0
    var y: Int64 = 0
    init(x: Int64, y: Int64) { this.x = x; this.y = y }
}

// —— @C 导出函数：可作为 C 侧回调/入口；形参用 CPointer，读写要 unsafe ——
@C
func scale(p: CPointer<Vec2>): Unit {
    let v = unsafe { p.read() }
    unsafe { p.write(Vec2(v.x * 2, v.y * 3)) }
}

main(): Int64 {
    // 1) 字符串跨界的资源配对：malloc 出来的 CString 必须 free（承 29、资源管理 21）
    let cs = unsafe { LibC.mallocCString("  42abc") }
    let num = unsafe { atoi(cs) }          // C 语义：跳过前导空白、取 42、遇 'a' 停
    let len = unsafe { strlen(cs) }        // "  42abc" 共 7 字节
    unsafe { LibC.free(cs) }               // 谁 malloc 谁 free，成对出现
    println("atoi=${num} strlen=${len}")   // atoi=42 strlen=7

    // 2) 结构体按引用过界：inout 把仓颉变量的地址交给 @C 函数，就地改
    var v = Vec2(3, 4)
    unsafe { scale(inout v) }              // x*2=6, y*3=12
    println("scaled=(${v.x},${v.y}) sizeOf=${sizeOf<Vec2>()}")   // scaled=(6,12) sizeOf=16
    return 0
}
