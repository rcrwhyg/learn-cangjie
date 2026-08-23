// 接口、属性与子类型示例
// 演示：interface 定义、继承与实现、默认实现、Any、属性 prop、mut 属性、抽象属性、子类型

// 1) 接口定义：抽象成员函数
interface Flyable {
    func fly(): Unit
}

// 接口可以继承多个接口（&）
interface Swimmable {
    func swim(): Unit
}

interface Amphibious <: Flyable & Swimmable {}

// 2) 接口的默认实现
interface Greeter {
    func greet(): String { "Hello" }
}

// 3) sealed interface
sealed interface LocalService {
    func run(): Unit
}

// 4) 抽象属性
interface Boxed {
    prop value: Int64
    mut prop label: String
}

// 5) 实现接口的类（同时实现接口继承）
class Duck <: Amphibious {
    public func fly(): Unit {
        println("Duck flying")
    }
    public func swim(): Unit {
        println("Duck swimming")
    }
}

class Airplane <: Flyable {
    public func fly(): Unit {
        println("Airplane flying")
    }
}

// 6) 实现有默认实现的接口
class EnglishGreeter <: Greeter {}
class ChineseGreeter <: Greeter {
    public override func greet(): String {
        "你好"
    }
}

// 7) 在包内实现 sealed 接口
class LocalRunner <: LocalService {
    public func run(): Unit {
        println("LocalRunner running")
    }
}

// 8) 实现带属性的接口
class Counter <: Boxed {
    public var _value: Int64 = 0
    public var _label: String = "default"

    public prop value: Int64 {
        get() { _value }
    }
    public mut prop label: String {
        get() { _label }
        set(v) { _label = v }
    }
}

// 9) 子类型关系：函数形参接受接口类型
func letItFly(f: Flyable): Unit {
    f.fly()
}

main() {
    // 接口实现与子类型
    let duck = Duck()
    letItFly(duck)
    duck.swim()

    let plane = Airplane()
    letItFly(plane)

    // 默认实现：使用接口的默认 greet
    let eg = EnglishGreeter()
    println(eg.greet())   // Hello

    // 重写默认实现
    let cg = ChineseGreeter()
    println(cg.greet())   // 你好

    // sealed 接口实现
    let runner = LocalRunner()
    runner.run()

    // 抽象属性
    let c = Counter()
    println("c.value = ${c.value}")   // 0
    c.label = "updated"
    println("c.label = ${c.label}")   // updated

    // Any 类型：所有类型都是 Any 的子类型
    var any: Any = 1
    any = 3.14
    any = "hello"
    // println 直接打印 Any 会要求 ToString，此处不输出内容

    // 子类型关系：子类型实例可赋给父类型变量
    let duckAsFlyable: Flyable = duck
    duckAsFlyable.fly()

    // 函数类型子类型
    func takesAny(_: Any) { }
    takesAny(1)
    takesAny("text")
}
