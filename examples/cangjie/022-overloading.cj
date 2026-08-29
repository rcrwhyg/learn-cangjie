// 函数重载与操作符重载示例
// 演示：函数重载（参数个数/类型不同、构造器重载、乱序命名参数不算重载）、
// 重载决议（作用域优先 + 最匹配）、操作符重载（一元/二元、比较、索引 []、函数调用 ()、复合赋值）

open class Base {
    public init() {}
}

class Sub <: Base {}

// ========== 1) 函数重载 ==========

// 参数个数不同
func describe(x: Int64): String { "Int64:${x}" }
func describe(x: Int64, y: Int64): String { "two:${x},${y}" }

// 参数类型不同
func show(v: Int64): String { "int ${v}" }
func show(v: Float64): String { "float" }
func show(v: String): String { "string ${v}" }

// 构造器重载
class Point {
    public var x: Int64 = 0
    public var y: Int64 = 0
    public init() {}
    public init(x: Int64) {
        this.x = x
    }
    public init(x: Int64, y: Int64) {
        this.x = x
        this.y = y
    }
}

// 子类与父类同名不同参：构成重载，按实参类型最匹配决议
open class Shape {
    public func area(scale: Base): Int64 { 10 }
}
class Circle <: Shape {
    public func area(scale: Sub): Int64 { 20 }
}

// ========== 2) 操作符重载 ==========

struct Vector2 {
    public var x: Int64
    public var y: Int64
    public init(x: Int64, y: Int64) {
        this.x = x
        this.y = y
    }

    // 一元 -
    public operator func -(): Vector2 {
        Vector2(-x, -y)
    }
    // 二元 +（返回 Vector2 → 支持复合赋值 +=）
    public operator func +(rhs: Vector2): Vector2 {
        Vector2(x + rhs.x, y + rhs.y)
    }
    // 标量乘法
    public operator func *(k: Int64): Vector2 {
        Vector2(x * k, y * k)
    }
    // 判等
    public operator func ==(rhs: Vector2): Bool {
        x == rhs.x && y == rhs.y
    }
    // 索引取值
    public operator func [](i: Int64): Int64 {
        if (i == 0) { x } else { y }
    }
    // 索引赋值（value! 命名参数；修改 struct 成员需要 mut）
    public mut operator func [](i: Int64, value!: Int64): Unit {
        if (i == 0) { x = value } else { y = value }
    }
}

// 可调用对象：operator func () 让实例可以像函数一样被调用
class Adder {
    public var base: Int64
    public init(base: Int64) { this.base = base }
    public operator func ()(a: Int64, b: Int64): Int64 { base + a + b }
}

main(): Int64 {
    // ---- 函数重载 ----
    println(describe(5))             // Int64:5
    println(describe(5, 6))          // two:5,6
    println(show(1))                 // int 1
    println(show(1.5))               // float
    println(show("hi"))              // string hi

    let p0 = Point()
    let p1 = Point(3)
    let p2 = Point(3, 4)
    println("Point: (${p0.x},${p0.y}) (${p1.x},${p1.y}) (${p2.x},${p2.y})")

    // 重载决议：子类实例命中更匹配的 Sub 版
    let c: Circle = Circle()
    println("area(Sub) = ${c.area(Sub())}")    // 20
    println("area(Base) = ${c.area(Base())}")  // 10

    // ---- 操作符重载 ----
    let a = Vector2(1, 2)
    let b = Vector2(10, 20)
    let neg = -a
    println("neg = (${neg.x},${neg.y})")             // (-1,-2)
    let sum = a + b
    println("a+b = (${sum.x},${sum.y})")             // (11,22)
    let scaled = b * 2
    println("b*2 = (${scaled.x},${scaled.y})")       // (20,40)
    println("eq = ${a == Vector2(1, 2)}")            // true

    // 索引 get / set
    var v = Vector2(7, 8)
    println("v[0]=${v[0]}, v[1]=${v[1]}")            // 7, 8
    v[0] = 100
    println("after set v[0]=${v[0]}")               // 100

    // 复合赋值（+ 返回 Vector2，左操作数同为 Vector2 → 支持 +=）
    var acc = Vector2(1, 1)
    acc += Vector2(2, 3)
    println("acc = (${acc.x},${acc.y})")            // (3,4)

    // 函数调用 () 操作符重载
    let adder = Adder(100)
    println("adder(1,2) = ${adder(1, 2)}")          // 103

    return 0
}
