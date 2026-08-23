// 类类型基础示例
// 演示：class 定义、构造函数与 super 调用、This 类型、引用类型语义、
// 继承（open）、抽象类、覆盖 override、终结器 ~init

// 1) 基本 class：成员变量、构造函数、实例/静态成员函数
open class Shape {
    public var name: String
    public init(name: String) {
        this.name = name
    }
    public open func describe(): String {
        "Shape: ${name}"
    }
    public static func category(): String {
        "Geometry"
    }
}

// 2) 抽象类 + 抽象函数（无函数体的 public/protected 函数）
abstract class Animal {
    public var name: String
    public init(name: String) {
        this.name = name
    }
    public func describe(): String {
        "Animal: ${name}"
    }
    public func sound(): String
}

// 3) 子类继承父类，使用 init 与 super
open class Circle <: Shape {
    public var radius: Int64
    public init(radius: Int64) {
        super("Circle")
        this.radius = radius
    }
    public override func describe(): String {
        "${super.describe()}, r=${radius}"
    }
    public func area(): Float64 {
        3.14159 * Float64(radius) * Float64(radius)
    }
}

// 4) 子类实现抽象函数
class Dog <: Animal {
    public init() {
        super("Dog")
    }
    public override func sound(): String {
        "Woof"
    }
}

// 5) This 类型：父类函数返回 This，子类对象调用时类型为子类
open class Node {
    public var value: Int64
    public init(value: Int64) {
        this.value = value
    }
    public func self(): This {
        this
    }
}

// 6) 引用类型语义：多个变量指向同一对象，修改可见
class Counter {
    public var count: Int64 = 0
    public init() {}
    public func increment() {
        count += 1
    }
}

// 7) 终结器 ~init（演示语法，行为依赖 GC）
class Resource {
    public let tag: String
    public init(tag: String) {
        this.tag = tag
        println("Resource ${tag} acquired")
    }
    ~init() {
        println("Resource ${tag} finalized")
    }
}

main() {
    // 1) 实例化、实例方法、静态方法
    let s = Shape("Generic")
    println(s.describe())
    println(Shape.category())

    // 2) 抽象类不能直接实例化，通过子类实例化
    let d = Dog()
    println(d.describe())
    println("Dog says: ${d.sound()}")

    // 3) 子类构造函数 + super
    let c = Circle(5)
    println(c.describe())
    println("Circle area = ${c.area()}")

    // 4) 引用类型语义：c1 与 c2 指向同一对象
    let c1 = Counter()
    c1.increment()
    c1.increment()
    let c2 = c1   // c2 指向 c1 同一对象
    c2.increment()
    println("c1.count = ${c1.count}")   // 3
    println("c2.count = ${c2.count}")   // 3

    // 5) This 类型：父类 self() 返回 This
    let n = Node(1)
    let s2 = n.self()  // 类型为 Node
    println("s2.value = ${s2.value}")

    // 6) 终结器
    let r = Resource("A")
    // r 超出作用域后由 GC 回收时打印 finalized
}
