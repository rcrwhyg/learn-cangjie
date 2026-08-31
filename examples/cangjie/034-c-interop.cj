// 仓颉-C 互操作示例（基于 1.0.5 std 的 foreign / LibC / CPointer / CString / inout）
// 演示：foreign 声明并 unsafe 调用系统 libc 函数(strlen)、CString 与 String 互转与释放、
// @C struct + CPointer 的 read/write、inout 引用传参、sizeOf 计算结构体大小。
//
// 只用系统 libc 符号（strlen 由 libc 自动链接）与内置 LibC，无需自定义 .c 或 -l 链接。

// 声明外部 C 函数：foreign 只有声明无实现；调用须在 unsafe 块里。返回 UIntNative（对应 C 的 size_t）
foreign func strlen(s: CString): UIntNative

// @C 修饰的 struct：与 C 结构体同内存布局，成员须满足 CType
@C
struct Point {
    var x: Int64 = 0
    var y: Int64 = 0
    init(x: Int64, y: Int64) {
        this.x = x
        this.y = y
    }
}

// 被 @C 修饰的仓颉函数：形参是 C 指针；通过 CPointer 读写结构体（模拟被 C 侧回调修改）
@C
func bump(p: CPointer<Point>): Unit {
    let v = unsafe { p.read() }
    unsafe { p.write(Point(v.x + 1, v.y + 1)) }
}

// 把 Int64 就地置为 42，用于演示 inout 引用传参
@C
func setFortyTwo(ptr: CPointer<Int64>): Unit {
    unsafe { ptr.write(42) }
}

main(): Int64 {
    // ---- 1) CString：mallocCString 造串、strlen 取长、toString 转回仓颉 String、free 释放 ----
    let cs = unsafe { LibC.mallocCString("hello cangjie") }
    let n: UIntNative = unsafe { strlen(cs) }
    println("cstr = ${cs.toString()}, len = ${n}")   // cstr = hello cangjie, len = 13
    unsafe { LibC.free(cs) }

    // ---- 2) @C struct + CPointer + inout：把本地结构体地址传给 @C 函数并读回 ----
    println("sizeOf<Point> = ${sizeOf<Point>()}")     // sizeOf<Point> = 16
    var pt = Point(10, 20)
    unsafe { bump(inout pt) }                         // x、y 各 +1
    println("point = (${pt.x}, ${pt.y})")             // point = (11, 21)

    // ---- 3) inout：把仓颉变量的地址按引用传给 @C 函数 ----
    var value: Int64 = 0
    unsafe { setFortyTwo(inout value) }
    println("value after inout = ${value}")           // value after inout = 42

    return 0
}
