package adt

// 代数数据类型与模式匹配原理示例（配合文章 42）。
// 基础篇（10 枚举 / 11 模式匹配 / 20 Option）教"怎么写"；本篇用**同一个 enum**
// 拆出"为什么 match 是穷尽 + 反演积 + 编译器能识别死分支"。

// —— 和类型(sum type)：Shape 是 3 个"积"的和 ——
enum Shape {
    | Square(Int64)          // 积：1 个字段
    | Rect(Int64, Int64)     // 积：2 个字段
    | Empty                  // 积：0 个字段（单元/元积）
}

// 每个"和的分支"给一个答案——这就是穷尽性；每个"积"用 case 反演回字段。
func area(s: Shape): Int64 {
    return match (s) {
        case Square(k) => k * k         // 反演带 1 字段的积
        case Rect(w, h) => w * h        // 反演带 2 字段的积
        case Empty => 0                 // 反演 0 字段的积；漏这一支 non-exhaustive
    }
}

// —— Option 就是一个和类型，不是"语言级特殊"——
// 官方 std 的 `Option<T> = enum { Some(T) | None }`。这里自定义 Opt 演示同构。
enum Opt {
    | V(Int64)
    | N
}
func orElse(o: Opt, d: Int64): Int64 {
    return match (o) { case V(v) => v; case N => d }
}

// —— 泛型 enum = "带类型参数的和之积"，Option<T> 的通用形式 ——
enum Opt2<T> {
    | Some2(T)
    | None2
}
func count<T>(o: Opt2<T>): Int64 {
    return match (o) { case Some2(_) => 1; case None2 => 0 }   // `_` 只判存在、不绑值
}

main(): Int64 {
    println("area Square3=${area(Shape.Square(3))}")     // 9
    println("area Rect2x5=${area(Shape.Rect(2, 5))}")    // 10
    println("area Empty=${area(Shape.Empty)}")           // 0
    println("orElse(N,7)=${orElse(Opt.N, 7)}")           // 7
    println("orElse(V3,7)=${orElse(Opt.V(3), 7)}")       // 3
    let a: Opt2<String> = Opt2.Some2("hi")
    println("count=${count(a)}")                          // 1
    return 0
}
