// 扩展机制示例
// 演示：直接扩展（成员函数 / 成员属性 / 操作符重载 / mut 函数）、
// 接口扩展（为已有类型实现接口）、泛型扩展与条件能力（带 where 约束）、
// this 可用而 super 不可用、同包多次扩展互相调用

// ========== 1) 直接扩展 ==========

// 给 String 直接扩展一个成员函数
extend String {
    public func shout(): String {
        "${this}!!!"
    }
}

// 给自定义 struct 扩展成员属性 + 操作符 + mut 函数
struct Vec {
    public var x: Int64
    public var y: Int64
    public init(x: Int64, y: Int64) {
        this.x = x
        this.y = y
    }
}

extend Vec {
    // 成员属性：长度平方和（避免浮点格式化，只读）
    public prop lenSq: Int64 {
        get() {
            this.x * this.x + this.y * this.y
        }
    }

    // 操作符重载：Vec + Vec
    public operator func +(rhs: Vec): Vec {
        Vec(this.x + rhs.x, this.y + rhs.y)
    }

    // struct 扩展里定义 mut 函数：缩放自身
    public mut func scaleBy(k: Int64): Unit {
        this.x = this.x * k
        this.y = this.y * k
    }
}

// ========== 2) 接口扩展：给 Array 实现一个自定义接口 ==========

interface PrintSizeable {
    func printSize(): Unit
}

// 泛型接口扩展：Array<T> 实现 PrintSizeable
extend<T> Array<T> <: PrintSizeable {
    public func printSize(): Unit {
        println("size = ${this.size}")
    }
}

// ========== 3) 泛型扩展 + 条件能力：两个元素都可判等时，Pair 才能 equals ==========

class EqInt {
    public var v: Int64
    public init(v: Int64) { this.v = v }
}
interface Eq<T> {
    func equals(other: T): Bool
}
extend EqInt <: Eq<EqInt> {
    public func equals(other: EqInt): Bool {
        this.v == other.v
    }
}

class Pair<T1, T2> {
    public var first: T1
    public var second: T2
    public init(a: T1, b: T2) {
        first = a
        second = b
    }
}

// 只在 T1、T2 都实现 Eq 时，才给 Pair 增加 equals
extend<T1, T2> Pair<T1, T2> where T1 <: Eq<T1>, T2 <: Eq<T2> {
    public func equals(other: Pair<T1, T2>): Bool {
        first.equals(other.first) && second.equals(other.second)
    }
}

// ========== 4) 同包多次扩展互相调用（非 private 可见） ==========

class Counter {
    public var count: Int64 = 0
}

extend Counter {
    public func bump(): Unit {
        this.count += 1
    }
}

extend Counter {
    public func bumpTwice(): Unit {
        this.bump()   // 直接调用同类型其他扩展里的公开成员
        this.bump()
    }
}

main(): Int64 {
    // 直接扩展
    let s: String = "仓颉"
    println("shout = ${s.shout()}")        // 仓颉!!!

    // 成员属性 + 操作符重载 + mut 函数
    let v1 = Vec(3, 4)
    println("lenSq = ${v1.lenSq}")           // 25
    let v2 = Vec(1, 1)
    let v3 = v1 + v2
    println("v3 = (${v3.x}, ${v3.y})")       // (4, 5)
    var mv = Vec(2, 2)
    mv.scaleBy(3)
    println("scaled = (${mv.x}, ${mv.y})")   // (6, 6)

    // 接口扩展：Array 作为 PrintSizeable 使用
    let arr: PrintSizeable = [1, 2, 3]
    arr.printSize()                          // size = 3

    // 泛型扩展 + 条件能力：EqInt 都实现 Eq，Pair 可用 equals
    let pa = Pair<EqInt, EqInt>(EqInt(1), EqInt(2))
    let pb = Pair<EqInt, EqInt>(EqInt(1), EqInt(2))
    println("pair equals = ${pa.equals(pb)}") // true

    // 同包多次扩展互相调用
    let c = Counter()
    c.bumpTwice()
    println("counter = ${c.count}")          // 2

    return 0
}
