// 泛型编程示例
// 演示：泛型函数（无约束 + where 约束）、泛型 class/struct/enum、泛型成员函数与
// 静态泛型函数、泛型接口、类型别名（含泛型别名）与泛型类型构造器的不变性

import std.collection.ArrayList

// ========== 1) 泛型函数 ==========

// 1.1 无约束泛型：只透传，不做任何类型相关操作
func id<T>(a: T): T {
    a
}

// 1.2 接口约束：需要 ToString 才能打印
func showAny<T>(a: T) where T <: ToString {
    println("showAny: ${a}")
}

// 1.3 多类型形参 + 函数类型作为参数（组合）
func compose<T1, T2, T3>(f: (T1) -> T2, g: (T2) -> T3): (T1) -> T3 {
    return { x: T1 => g(f(x)) }
}

func times2(a: Int64): Int64 { a * 2 }
func plus10(a: Int64): Int64 { a + 10 }

// ========== 2) 泛型 struct / class / enum ==========

struct Pair<T, U> {
    let x: T
    let y: U
    public init(a: T, b: U) {
        x = a
        y = b
    }
    public func first(): T { x }
    public func second(): U { y }
}

class Stack<T> {
    private var items: ArrayList<T> = ArrayList<T>()
    public func push(v: T) {
        items.add(v)
    }
    public func pop(): Option<T> {
        if (items.isEmpty()) {
            return None
        }
        let v = items.remove(at: items.size - 1)
        Some(v)
    }
    public func size(): Int64 { items.size }
}

enum MyOption<T> {
    | SomeVal(T)
    | Empty

    public func getOrDefault(default: T): T {
        match (this) {
            case SomeVal(v) => v
            case Empty => default
        }
    }
}

// ========== 3) 泛型接口 + 泛型成员函数 + 静态泛型函数 ==========

interface Describable<T> {
    func describe(x: T): String
}

class IntDescriber <: Describable<Int64> {
    public func describe(x: Int64): String { "int:${x}" }
}

class Box<T> {
    public var content: T
    public init(c: T) { content = c }

    // 成员函数也可以再声明自己独立的类型形参
    public func mapInto<U>(f: (T) -> U): U {
        f(content)
    }

    // 静态泛型函数
    public static func singleton(v: T): Box<T> {
        Box<T>(v)
    }
}

// ========== 4) 泛型不变性演示 ==========

open class Animal {
    public init() {}
    public open func speak(): String { "animal" }
}
class Dog <: Animal {
    public override func speak(): String { "woof" }
}

interface Container<X> {
    func get(): X
}
class Holder<X> <: Container<X> {
    public var v: X
    public init(v: X) { this.v = v }
    public func get(): X { v }
}

// 只要形参一致，就只接受严格相同实参
func takesAnimalContainer(_: Container<Animal>) {
    println("got a Container<Animal>")
}

// ========== 5) 类型别名（含泛型别名） ==========

type Ints = Array<Int64>
type PairSI = Pair<String, Int64>

// 泛型别名：短一点的写法
type MyStack<T> = Stack<T>

main(): Int64 {
    // 泛型函数：显式类型实参 + 通过变量类型推断
    let n: Int64 = id<Int64>(42)
    println("id(42) = ${n}")
    showAny<Int64>(7)
    showAny<String>("hi")

    let composed = compose<Int64, Int64, Int64>(times2, plus10)
    println("composed(9) = ${composed(9)}")   // (9*2)+10 = 28

    // 泛型 struct
    let p: PairSI = PairSI("hello", 0)
    println("Pair.first=${p.first()} second=${p.second()}")

    // 泛型 class：栈
    let s: MyStack<Int64> = MyStack<Int64>()
    s.push(1)
    s.push(2)
    let popped = s.pop()
    match (popped) {
        case Some(v) => println("pop=${v}, size=${s.size()}")
        case None => println("empty stack")
    }

    // 泛型 enum
    let a: MyOption<Int64> = SomeVal(3)
    let b: MyOption<Int64> = Empty
    println("a=${a.getOrDefault(0)} b=${b.getOrDefault(-1)}")

    // 泛型接口 + 实现
    let d: Describable<Int64> = IntDescriber()
    println("describe = ${d.describe(99)}")

    // 泛型成员函数（U 独立于 Box 的 T）
    let box = Box<Int64>(5)
    let toStr = { x: Int64 => "n=${x}" }
    let shown: String = box.mapInto<String>(toStr)
    println("box.mapInto = ${shown}")   // n=5

    // 静态泛型函数（与类同类型形参）
    let sb = Box<Int64>.singleton(100)
    println("singleton content = ${sb.content}")

    // 泛型不变性：把 Holder<Dog> 传给 Container<Animal> 会编译报错，
    // 所以此处只能构造严格 Holder<Animal> 传入。
    let hc: Container<Animal> = Holder<Animal>(Animal())
    takesAnimalContainer(hc)
    println("hc.get().speak() = ${hc.get().speak()}")

    // 类型别名
    let nums: Ints = [1, 2, 3]
    println("nums.size = ${nums.size}")

    return 0
}
