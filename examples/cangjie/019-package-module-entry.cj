// 包、模块与程序入口示例
// 演示：package 声明、import 单个 / 多个 / 通配符 / 重命名、
// 顶层变量与函数的可见性修饰符（public / internal / private / protected）、
// main 入口函数的合法签名（无参数 / Array<String> 参数、Unit / 整数类型返回值）

package demo

// 单个 import：导入 std.collection.ArrayList
import std.collection.ArrayList
// 多个 import：同一包下批量导入
import std.collection.{HashSet, HashMap}
// 通配符 import：导入 std.io 下所有可见声明
// import std.io.*    // 通配符 import：导入 std.io 下所有可见声明（按需启用）
// import as 重命名：解决不同包同名类型冲突
import std.collection.ArrayList as AL

// ========== 1) 顶层声明的可见性 ==========

// public 修饰：模块内外均可见
public let GREETING: String = "Hello, 仓颉"

// 默认（internal）：仅当前包及子包内可见
let packageOnly: String = "仅包内可见"

// private 修饰：仅当前文件内可见（本文件内任意位置可访问）
private let fileOnly: String = "仅当前文件可见"

public func greet(name: String): String {
    "${GREETING}, ${name}"
}

internal func packageFn(): Int64 {
    42
}

protected func moduleFn(): Int64 {
    100
}

// ========== 2) 自定义类型声明 ==========

public struct User {
    public User(public var name: String, public var age: Int64) {}
}

public class Counter {
    public var count: Int64 = 0
    public func inc(): Unit {
        count += 1
    }
}

public enum Color {
    Red | Green | Blue
}

// ========== 3) 隐式 import core 包 ==========

// 下列类型 String / Int64 / Array / Range 无需显式 import 即可使用，
// 因为编译器会自动为源码隐式导入 core 包中所有 public 修饰的声明
func showBuiltin(): Unit {
    let s: String = "隐式导入"
    let n: Int64 = 100
    let arr: Array<Int64> = [1, 2, 3]
    let r: Range<Int64> = 0..5
    println("${s}, ${n}, arr.size=${arr.size}, r=${r.start}..${r.end}")
}

// ========== 4) main 函数（程序入口） ==========

// main 没有参数，返回 Int64
main(): Int64 {
    println("=== main(): Int64 ===")
    println(greet("World"))              // 顶层 public 函数

    let user: User = User("Alice", 30)
    println("${user.name}, ${user.age}")  // 顶层 struct

    let counter: Counter = Counter()
    counter.inc()
    counter.inc()
    println("count = ${counter.count}")

    let c: Color = Color.Red
    let colorName: String = match (c) {
        case Red => "red"
        case Green => "green"
        case Blue => "blue"
    }
    println("color = ${colorName}")     // enum 通过 match 转换

    // 使用 import 导入的集合类型
    let list: ArrayList<Int64> = ArrayList<Int64>([1, 2, 3])
    let set: HashSet<String> = HashSet<String>(["a", "b", "c"])
    let map: HashMap<String, Int64> = HashMap<String, Int64>([("x", 1), ("y", 2)])
    println("list.size = ${list.size}")
    println("set.size  = ${set.size}")
    println("map.size  = ${map.size}")

    // 使用 import as 重命名后的别名
    let list2: AL<Int64> = AL<Int64>([10, 20, 30])
    println("list2.size = ${list2.size}")

    // 调用隐式导入的 builtin
    showBuiltin()
    println("fileOnly = ${fileOnly}")  // private 变量仅当前文件可见

    return 0
}

// 也可写一个无返回值的 main 入口
// main() {
//     println("无返回值的 main")
// }
// 也可写一个接收命令行参数的 main
// main(args: Array<String>): Unit {
//     for (arg in args) {
//         println(arg)
//     }
// }
