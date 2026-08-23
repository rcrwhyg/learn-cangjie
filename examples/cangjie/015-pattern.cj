// 模式匹配示例
// 演示：常量模式、通配符模式、绑定模式、Tuple 模式、类型模式、enum 模式、
// 嵌套组合、模式守卫、变量定义中的模式、for-in 中的模式、无匹配值 match

// 1) 表达式 enum（用于 eval）
enum Expr {
    | Num(Int64)
    | Add(Expr, Expr)
    | Sub(Expr, Expr)
}

// 2) 命令 enum（用于嵌套模式）
enum TimeUnit {
    | Year(UInt64)
    | Month(UInt64)
}

enum Command {
    | SetTimeUnit(TimeUnit)
    | GetTimeUnit
    | Quit
}

// 3) 颜色 enum（用于模式守卫）
enum RGBColor {
    | Red(Int16)
    | Green(Int16)
    | Blue(Int16)
}

// 4) 类型模式所依赖的类层级
open class Animal {
    public var name: String
    public init(name: String) {
        this.name = name
    }
}

class Dog <: Animal {
    public init() { super("Dog") }
}

class Cat <: Animal {
    public init() { super("Cat") }
}

// 计算表达式
func eval(e: Expr): Int64 {
    match (e) {
        case Num(n) => n
        case Add(a, b) => eval(a) + eval(b)
        case Sub(a, b) => eval(a) - eval(b)
    }
}

// 描述颜色（含模式守卫）
func describeColor(c: RGBColor): String {
    match (c) {
        case Red(r) where r < 0 => "Red = 0"
        case Red(r) => "Red = ${r}"
        case Green(g) where g < 0 => "Green = 0"
        case Green(g) => "Green = ${g}"
        case Blue(b) where b < 0 => "Blue = 0"
        case Blue(b) => "Blue = ${b}"
    }
}

// 等级评定：使用函数避免常量传播导致误报
func gradeOf(score: Int64): String {
    match (score) {
        case 0 | 10 | 20 | 30 | 40 | 50 => "D"
        case 60 => "C"
        case 70 | 80 => "B"
        case 90 | 100 => "A"
        case _ => "Not a valid score"
    }
}

func isZero(x: Int64): String {
    match (x) {
        case 0 => "zero"
        case n => "x is not zero and x = ${n}"
    }
}

func greet(person: (String, Int64)): String {
    match (person) {
        case ("Bob", age) => "Bob is ${age}"
        case ("Alice", age) => "Alice is ${age}"
        case (name, 100) => "${name} is 100"
        case _ => "unknown"
    }
}

func classify(a: Animal): String {
    match (a) {
        case d: Dog => "Dog named ${d.name}"
        case c: Cat => "Cat named ${c.name}"
        case _: Animal => "Other animal"
    }
}

func handleCommand(cmd: Command): String {
    match (cmd) {
        case SetTimeUnit(Year(y)) => "Set year ${y}"
        case SetTimeUnit(Month(m)) => "Set month ${m}"
        case GetTimeUnit => "Get unit"
        case Quit => "Quit"
    }
}

main() {
    // 1) 常量模式 + | 组合 + 通配符兜底
    let level = gradeOf(85)
    println("level = ${level}")

    // 2) 绑定模式
    let desc = isZero(-10)
    println(desc)

    // 3) Tuple 模式
    let person = ("Alice", 30)
    println(greet(person))

    // 4) enum 模式 + 模式守卫
    println("color = ${describeColor(RGBColor.Red(200))}")
    println("color = ${describeColor(RGBColor.Blue(-50))}")

    // 5) 类型模式
    let animals: Array<Animal> = [Dog(), Cat(), Dog()]
    for (a in animals) {
        println(classify(a))
    }

    // 6) 模式的嵌套组合
    println(handleCommand(Command.SetTimeUnit(Year(2024))))
    println(handleCommand(Command.Quit))

    // 7) 无匹配值的 match
    let n: Int64 = -3
    match {
        case n > 0 => println("positive")
        case n < 0 => println("negative")
        case _ => println("zero")
    }

    // 8) 变量定义中的 Tuple 模式
    let (a, b) = (100, 200)
    println("a = ${a}, b = ${b}")

    // 9) for-in 中的 Tuple 模式
    let pairs = [(1, 2), (3, 4), (5, 6)]
    for ((i, j) in pairs) {
        println("Sum = ${i + j}")
    }

    // 10) 表达式求值演示
    let expr = Sub(Add(Num(3), Num(5)), Num(2))
    println("eval((3+5)-2) = ${eval(expr)}")
}
