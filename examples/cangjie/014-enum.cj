// 枚举类型示例
// 演示：enum 定义、构造器（无参、有参、... ）、递归 enum、成员函数、属性、enum 值构造

// 1) 简单 enum：三个无参构造器
enum Color {
    | Red
    | Green
    | Blue

    public func name(): String {
        match (this) {
            case Red => "Red"
            case Green => "Green"
            case Blue => "Blue"
        }
    }
}

// 2) 带参数的 enum 构造器
enum RGBColor {
    | Red(UInt8)
    | Green(UInt8)
    | Blue(UInt8)

    public func channel(): UInt8 {
        match (this) {
            case Red(v) => v
            case Green(v) => v
            case Blue(v) => v
        }
    }
}

// 3) non-exhaustive enum（含 ... 构造器）
enum Status {
    | Pending
    | Running
    | Done
    | ...

    public func label(): String {
        match (this) {
            case Pending => "pending"
            case Running => "running"
            case Done => "done"
            case _ => "other"
        }
    }
}

// 4) 递归 enum：表达式树
enum Expr {
    | Num(Int64)
    | Add(Expr, Expr)
    | Sub(Expr, Expr)
}

// 5) enum 成员函数 + 静态成员
enum Direction {
    | North
    | South
    | East
    | West

    public func label(): String {
        match (this) {
            case North => "N"
            case South => "S"
            case East => "E"
            case West => "W"
        }
    }

    public static func all(): Array<Direction> {
        [North, South, East, West]
    }
}

// 6) enum 实现接口
interface Printable {
    func describe(): String
}

enum LogLevel <: Printable {
    | Info
    | Warn
    | Error

    public func describe(): String {
        match (this) {
            case Info => "INFO"
            case Warn => "WARN"
            case Error => "ERROR"
        }
    }
}

// 求值递归 enum 表达式
func eval(e: Expr): Int64 {
    match (e) {
        case Num(n) => n
        case Add(a, b) => eval(a) + eval(b)
        case Sub(a, b) => eval(a) - eval(b)
    }
}

main() {
    // 1) enum 值构造（类型名.构造器 或 裸构造器）
    let c1 = Color.Red
    let c2 = Green
    println("c1 = ${c1.name()}")
    println("c2 = ${c2.name()}")

    // 2) 有参构造器
    let red = RGBColor.Red(255)
    let green = RGBColor.Green(128)
    let blue = Blue(64)
    println("red channel = ${red.channel()}")
    println("green channel = ${green.channel()}")
    println("blue channel = ${blue.channel()}")

    // 3) non-exhaustive enum：必须用 case _ 兜底
    let s = Status.Running
    println("status = ${s.label()}")

    // 4) 递归 enum 表达式求值
    // (3 + 5) - 2 = 6
    let expr = Sub(Add(Num(3), Num(5)), Num(2))
    println("eval((3+5)-2) = ${eval(expr)}")

    // 5) enum 成员函数 + 静态成员
    let n = Direction.North
    println("North.label() = ${n.label()}")
    let dirs = Direction.all()
    println("dirs.size = ${dirs.size}")

    // 6) enum 实现接口
    let lvl: LogLevel = LogLevel.Warn
    let printable: Printable = lvl
    println("lvl.describe() = ${printable.describe()}")
}
