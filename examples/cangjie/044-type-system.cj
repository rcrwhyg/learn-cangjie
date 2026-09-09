// 仓颉类型系统原理示例（配合文章 41）。演示的都是"编译器背后强制的规则"，
// 与基础篇"怎么声明类型"不重叠：静态类型/推断、Any 顶类型、Nothing 底类型、
// 名义子类型与安全下转(is + as 返回 Option)、泛型不变、Option 不自动解包、
// 穷尽性检查、编译期溢出检测。
package typesys

// —— 名义子类型：只有 class / interface 进子类型格；base 方法要 open 才可 override ——
open class Animal {
    public open func sound(): String { "..." }
}
class Dog <: Animal {
    public override func sound(): String { "woof" }
}
class Cat <: Animal {
    public override func sound(): String { "meow" }
}

// Any 是顶类型：任何值都能进来。1.0.5 里没有 as?——`as T` 本身就返回 Option<T>。
// is T 判类型；as T 安全下转（成功 Some、失败 None）。
func describe(x: Any): String {
    if (x is Dog) { return "dog" }
    if (x is Cat) {
        match (x as Cat) {                 // as Cat 直接是 Option<Cat>
            case Some(c) => return "cat says ${c.sound()}"
            case None => return "impossible"
        }
    }
    return "not-an-animal"
}

// Nothing 是底类型：永不正常返回的函数——可出现在任何"期望某类型"的位置。
func impossible(msg: String): Nothing {
    throw Exception(msg)
}
func mustBePositive(v: Int64): Int64 {
    // else 分支是 Nothing，自动补到期望 Int64 的位置
    return if (v > 0) { v } else { impossible("non-positive") }
}

// 泛型不变：Box<Int64> 不是 Box<Any>（正文用编译错坐实；这里只做正确用法）
class Box<T> {
    public var content: T
    public init(v: T) { this.content = v }
}

// Option 不自动解包：只有 match 才把里面值掏出来
func firstEven(xs: Array<Int64>): Option<Int64> {
    for (x in xs) {
        if (x % 2 == 0) { return Some(x) }
    }
    return None
}

// 穷尽性：enum 少写一支就编译失败（这里写全，能过）
enum Status {
    | Ok
    | Warn
    | Error
}
func statusText(s: Status): String {
    return match (s) {
        case Ok => "ok"
        case Warn => "warn"
        case Error => "error"
    }
}

main(): Int64 {
    // 静态类型 + 推断 + 显式转换（无隐式收窄；数值转换走 T(e)）
    let n = 42                             // 推断 Int64
    let f = 3.9                            // 推断 Float64
    println("n=${n}, trunc=${Int64(f)}")   // Int64(3.9) 显式转 → 3
    // 名义子类型：父类型引用可指向子对象，方法分派看实际类型
    let a: Animal = Dog()
    println("animal: ${a.sound()}")        // woof
    // Any 顶类型 + is / as(→Option)
    println("desc Dog=${describe(Dog())}")
    println("desc Cat=${describe(Cat())}")
    println("desc Int=${describe(42)}")
    // Nothing 底类型
    println("positive=${mustBePositive(5)}")
    // 泛型（同参数才能赋值——因为 Box<Int64> 与 Box<Any> 之间没有子类型）
    let b = Box<Int64>(7)
    println("box=${b.content}")
    // Option 必须 match
    match (firstEven([1, 3, 8, 9])) {
        case Some(v) => println("even=${v}")
        case None => println("even=none")
    }
    // 穷尽 match
    println("status=${statusText(Status.Warn)}")
    return 0
}
