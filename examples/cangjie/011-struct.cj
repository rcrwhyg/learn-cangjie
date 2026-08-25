// 结构体基础示例
// 演示：struct 定义、成员变量、普通 init、主构造函数、实例/静态成员函数、
// this、值类型拷贝语义、可变成员变量修改、引用类型成员共享

// 普通构造函数 + 实例成员变量 + 实例/静态成员函数
struct Rectangle {
    public var width: Int64
    public var height: Int64

    public init(width: Int64, height: Int64) {
        this.width = width
        this.height = height
    }

    public func area() {
        width * height
    }

    public func perimeter() {
        2 * (width + height)
    }

    public static func typeName(): String {
        "Rectangle"
    }
}

// 主构造函数 + 成员变量形参（let/var 在参数前同时定义成员变量和形参）
struct Point {
    public Point(var x: Int64, var y: Int64) {}
    public init(x: Int64) {
        this.x = x
        this.y = 0
    }

    public func translate(dx: Int64, dy: Int64): Point {
        Point(x + dx, y + dy)
    }
}

// 静态成员变量
struct Counter {
    public static var instances: Int64 = 0
    public let id: Int64

    public init() {
        instances += 1
        id = instances
    }

    public static func currentCount(): Int64 {
        instances
    }
}

// 引用类型成员：值类型成员独立拷贝，引用类型成员只拷贝引用（共享同一对象）
struct Pair {
    public var data: Array<Int64>   // Array 是引用类型
    public var n: Int64             // Int64 是值类型

    public init(data: Array<Int64>, n: Int64) {
        this.data = data
        this.n = n
    }
}

main() {
    // 1) 普通构造函数创建实例并访问实例成员
    let r = Rectangle(10, 20)
    println("Rectangle 类型: ${Rectangle.typeName()}")
    println("r.area() = ${r.area()}")
    println("r.perimeter() = ${r.perimeter()}")

    // 2) 可变实例成员变量：变量和字段都需 var
    var r2 = Rectangle(3, 4)
    r2.width = 8
    r2.height = 24
    println("r2.area() = ${r2.area()}")

    // 3) 值类型拷贝语义：修改 r1 不影响 r2
    var r1 = Rectangle(10, 20)
    let rCopy = r1
    r1.width = 1
    r1.height = 1
    println("r1.area() = ${r1.area()}")   // 1
    println("rCopy.area() = ${rCopy.area()}") // 200

    // 4) 主构造函数
    let p = Point(3, 4)
    println("p = (${p.x}, ${p.y})")
    let p2 = p.translate(10, 20)
    println("p2 = (${p2.x}, ${p2.y})")
    let p3 = Point(7)
    println("p3 = (${p3.x}, ${p3.y})")

    // 5) 静态成员变量在实例间共享
    let c1 = Counter()
    let c2 = Counter()
    let c3 = Counter()
    println("c1.id = ${c1.id}")
    println("c2.id = ${c2.id}")
    println("c3.id = ${c3.id}")
    println("Counter.instances = ${Counter.instances}")
    println("Counter.currentCount() = ${Counter.currentCount()}")

    // 6) 引用类型成员：值类型成员独立、引用类型成员共享同一对象
    var a = Pair([1, 2, 3], 10)
    let b = a                       // 值拷贝：n 被完整复制；data 仅复制引用（指向同一数组）
    a.n = 99                        // 不影响 b.n：值类型成员各自独立
    a.data[0] = 999                 // 影响 b.data！a 与 b 共享同一个 Array 对象
    println("a.n = ${a.n}")          // 99
    println("b.n = ${b.n}")          // 10（值类型成员独立拷贝）
    println("b.data[0] = ${b.data[0]}")  // 999（引用类型成员共享同一数组）
}
