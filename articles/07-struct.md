# 仓颉结构类型

> **摘要**: 结构体（struct）是仓颉中的值类型抽象，把一组相关的数据与操作封装为一个整体。本文依据仓颉 1.0.5 LTS 官方文档，系统介绍 `struct` 的声明、成员变量、构造函数（普通 init 与主构造函数）、成员函数（实例与静态）、访问修饰符以及值类型拷贝语义，帮助读者掌握 struct 的定义与使用方式。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已了解变量、`let`/`var`、`Int64`、`String`、`Bool`、`Unit`
- 已了解函数定义与调用
- 已完成《仓颉变量与数据类型》《仓颉控制流语句》《仓颉函数基础》

## 1. struct 的基本形态

仓颉使用关键字 `struct` 定义结构体类型，依次是 `struct` 关键字、类型名和定义在一对花括号中的定义体。`struct` 只能定义在源文件的顶层作用域，不能嵌套在函数或代码块内。

```cangjie
struct Rectangle {
    let width: Int64
    let height: Int64
}
```

上例定义了名为 `Rectangle` 的结构体，它拥有两个 `Int64` 类型的成员变量 `width` 和 `height`。结构体定义体（`struct` 定义体）中可以声明的内容包括：

- 成员变量（实例成员变量与静态成员变量）
- 成员属性（定义方式与 class 一致，详见官方《属性》章节，将在《接口、属性与子类型》一文中展开）
- 静态初始化器
- 构造函数（普通构造函数与主构造函数）
- 成员函数（实例成员函数与静态成员函数）
- 操作符函数（详见官方《操作符重载》，将在后续函数专题展开）

> 说明：本文聚焦成员变量、构造函数、成员函数与值类型语义。成员属性与操作符函数都属于 `struct` 的合法成员（官方《定义 struct 类型》已确认），其详细用法将在对应专题文章中系统讲解，避免此处重复或遗漏。

## 2. 成员变量

### 2.1 实例成员变量

实例成员变量是 struct 实例自身拥有的数据，通过实例访问。实例成员变量定义时可以省略初值（但必须标注类型），也可以设置初值：

```cangjie
struct Rectangle {
    let width = 10
    let height: Int64   // 不设初值，构造函数中必须完成初始化
}
```

实例成员变量可以是不可变的（`let`）或可变的（`var`）。`let` 成员变量在初始化后不能再被赋值；`var` 成员变量则可以通过实例修改：

```cangjie
struct Rectangle {
    public var width: Int64
    public var height: Int64
}

main() {
    var r = Rectangle(10, 20)
    r.width = 8   // OK：变量 r 是 var，width 是 var
    r.height = 24
}
```

修改实例成员变量需要同时满足两个条件：变量本身用 `var` 声明，成员变量也用 `var` 声明。

### 2.2 静态成员变量与静态初始化器

静态成员变量使用 `static` 修饰，所有实例共享同一份数据，必须通过类型名访问。静态成员变量定义时必须给出初值，或在静态初始化器中赋值。

```cangjie
struct Counter {
    public static var instances: Int64 = 0
}
```

静态初始化器以 `static init` 开头，无参数，函数体中必须完成对所有未初始化静态成员变量的赋值：

```cangjie
struct Counter {
    public static var degree: Int64
    static init() {
        degree = 180
    }
}
```

一个 struct 中最多允许定义一个静态初始化器，否则报重定义错误。

## 3. 构造函数

### 3.1 普通构造函数

普通构造函数以 `init` 开头，后跟参数列表和函数体，函数体中必须完成对所有未初始化实例成员变量的赋值，否则编译报错。当参数名与成员变量名同名时，使用 `this` 区分：

```cangjie
struct Rectangle {
    public var width: Int64
    public var height: Int64

    public init(width: Int64, height: Int64) {
        this.width = width
        this.height = height
    }
}
```

一个 struct 中可以定义多个普通构造函数，但它们必须构成重载（参数列表不同），否则报重定义错误。

### 3.2 主构造函数

除普通构造函数外，struct 内最多可以定义一个主构造函数。主构造函数的名字与 struct 类型名相同，参数列表中可以包含两种形参：

- **普通形参**：仅作为构造函数参数；
- **成员变量形参**：在参数名前加 `let` 或 `var`，同时声明成员变量和构造函数参数。

```cangjie
struct Rectangle {
    public Rectangle(let width: Int64, let height: Int64) {}
}
```

上例的主构造函数 `public Rectangle(let width: Int64, let height: Int64) {}` 在语义上等价于：先声明两个 `let` 成员变量 `width`、`height`，再编写一个把参数分别赋给成员变量的普通构造函数。主构造函数只是把"声明成员变量"和"参数赋值"两步合并到参数列表中，由编译器自动完成，因此函数体可以为空：

```cangjie
struct Rectangle {
    let width: Int64
    let height: Int64

    public init(width: Int64, height: Int64) {
        this.width = width
        this.height = height
    }
}
```

两种写法在"成员构成"和"初始化行为"上完全一致，区别仅在于主构造函数更简洁。

主构造函数的参数列表也可以混合两种形参：

```cangjie
struct Rectangle {
    public Rectangle(name: String, let width: Int64, let height: Int64) {}
}
```

### 3.3 自动生成的无参构造函数

当 struct 定义中不存在任何自定义构造函数（包括主构造函数），并且所有实例成员变量都有初值时，编译器会自动生成一个无参构造函数：

```cangjie
struct Rectangle {
    let width: Int64 = 10
    let height: Int64 = 10
    // 自动生成：public init() { }
}
```

只要存在任何自定义构造函数，或存在未设初值的实例成员变量，就不会再自动生成无参构造函数。

## 4. 成员函数

### 4.1 实例成员函数

实例成员函数是 struct 实例可以执行的操作，通过实例访问。函数体内可以使用 `this` 引用当前实例：

```cangjie
struct Rectangle {
    let width: Int64 = 1
    let height: Int64 = 1

    public func area() {
        this.width * this.height
    }
}
```

实例成员函数可以直接访问实例成员变量，仓颉会优先把名字解析为成员变量；只有当出现同名局部名（如参数名）需要区分时，才显式使用 `this`：

```cangjie
struct Counter {
    var count: Int64 = 0

    // 直接访问成员变量 count，无需 this
    public func incr(): Int64 {
        count = count + 1
        count
    }

    // 参数名与成员变量同名，用 this 区分
    public func set(count: Int64) {
        this.count = count
    }
}
```

### 4.2 静态成员函数

静态成员函数使用 `static` 修饰，通过类型名调用。静态成员函数中不能访问实例成员变量，也不能调用实例成员函数；但实例成员函数中既可以访问实例成员也可以访问静态成员。

```cangjie
struct Rectangle {
    let width: Int64 = 10
    let height: Int64 = 20

    public func area() {
        this.width * this.height
    }

    public static func typeName(): String {
        "Rectangle"
    }
}
```

调用方式：`Rectangle.typeName()` 调用静态函数，`r.area()` 调用实例函数。

## 5. 访问修饰符

struct 的成员（成员变量、构造函数、成员函数、操作符函数等）可使用四种访问修饰符：

| 修饰符 | 可见范围 |
|--------|----------|
| `private` | 仅 struct 定义内可见 |
| `internal`（缺省） | 当前包及子包内可见 |
| `protected` | 当前模块内可见 |
| `public` | 模块内外均可见 |

缺省修饰符是 `internal`，即只对当前包及子包可见。

```cangjie
package a

public struct Rectangle {
    public var width: Int64        // 任意位置可访问
    var height: Int64              // 同包及子包可访问（internal）
    private var area: Int64        // 仅 struct 内可访问
}
```

访问修饰符控制外部代码能访问到的成员，也控制 `struct` 类型本身对外的可见性。`struct` 类型与成员缺省都是 `internal`（仅当前包及子包可见），但"让其他包也能引用"要分清范围：

- **同一模块内的其他包**：把 `struct` 或成员声明为 `protected` 即可，无需设为 `public`（`protected` 表示当前模块可见）。
- **跨模块（外部模块）**：才需要把 `struct` 或成员声明为 `public`。

因此，同模块内跨包访问应优先使用 `protected`，只有面向外部模块时才用 `public`。

## 6. 禁止递归 struct

递归和互递归定义的 struct 均是非法的（官方《定义 struct 类型》明确禁止），例如：

```cangjie
struct R1 {
    let other: R1   // 错误：R1 递归引用自己
}

struct R2 {
    let other: R3   // 错误：R2 与 R3 互递归
}
struct R3 {
    let other: R2
}
```

这是 struct 的硬性约束——值类型在编译期需要确定内存布局，递归定义会导致大小无法求解。

## 7. 创建 struct 实例与值类型语义

定义 struct 后，通过调用构造函数创建实例：

```cangjie
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
}

main() {
    let r = Rectangle(10, 20)
    let w = r.width       // 10
    let h = r.height      // 20
    let a = r.area()      // 200
}
```

struct 是值类型，赋值或传参时会复制实例（成员变量为引用类型时，仅复制引用）。当所有成员变量都是值类型时，修改一个实例不会影响其他实例：

```cangjie
main() {
    var r1 = Rectangle(10, 20)
    let r2 = r1
    r1.width = 1
    r1.height = 1
    // r1.area() == 1
    // r2.area() == 200
}
```

### 7.1 注意：成员变量为引用类型时

上面的"互不影响"只在成员变量都是值类型（如 `Int64`、`Bool`、`Float64`）时成立。当某个成员变量本身是**引用类型**（如 `Array`、`String`、`HashMap` 或 class 实例）时，赋值只复制"引用"而**不会复制被引用的对象**。于是新旧实例的该成员指向同一个对象，通过其中任一实例修改这个共享对象（例如修改数组里的某个元素），另一实例也会看到变化：

```cangjie
struct Pair {
    public var data: Array<Int64>   // Array 是引用类型
    public var n: Int64             // Int64 是值类型

    public init(data: Array<Int64>, n: Int64) {
        this.data = data
        this.n = n
    }
}

main() {
    var a = Pair([1, 2, 3], 10)
    let b = a                       // 值拷贝：n 被完整复制；data 仅复制引用（指向同一数组）

    a.n = 99                        // 不影响 b.n：值类型成员各自独立
    a.data[0] = 999                 // 影响 b.data！a 与 b 共享同一个 Array 对象

    // b.n == 10
    // b.data[0] == 999
}
```

小结：**值类型成员独立拷贝、互不影响；引用类型成员只拷贝引用、共享同一对象，修改会互相影响。** 这正是使用 struct 封装可变引用类型时需要特别小心的点。

这个语义是 struct 与 class 的核心区别，也是 struct 适合表示纯数据结构的根本原因。

## 8. 一个完整示例

本示例组合了实例成员变量、静态成员变量、普通构造函数、主构造函数、实例成员函数、静态成员函数、值类型拷贝语义和可变成员变量修改：

<!-- example: cangjie/011-struct.cj -->
```cangjie
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
```

预期输出：

```text
Rectangle 类型: Rectangle
r.area() = 200
r.perimeter() = 60
r2.area() = 192
r1.area() = 1
rCopy.area() = 200
p = (3, 4)
p2 = (13, 24)
p3 = (7, 0)
c1.id = 1
c2.id = 2
c3.id = 3
Counter.instances = 3
Counter.currentCount() = 3
a.n = 99
b.n = 10
b.data[0] = 999
```

## 9. 常见问题

### Q1: struct 只能定义在顶层吗？

是的。`struct`、`class`、`enum`、`interface` 都只能定义在源文件的顶层作用域，不能嵌套在函数或代码块内。

### Q2: 可以不写构造函数吗？

可以。当所有实例成员变量都有初值且没有自定义构造函数时，编译器会自动生成一个无参构造函数；只要存在任何自定义构造函数或未设初值的成员变量，就需要显式提供构造函数。

### Q3: 主构造函数和普通构造函数可以同时存在吗？

可以。struct 中最多允许一个主构造函数，与若干普通 `init` 构造函数共存。它们通过参数列表区分，构成重载。

### Q4: 静态成员函数中能访问实例成员吗？

不能。静态成员函数中不能访问实例成员变量，也不能调用实例成员函数；如果需要访问实例数据，必须通过参数传入。

### Q5: 为什么修改一个实例的"值类型成员"不影响另一个？

struct 是值类型，赋值或传参时会对整个实例做值拷贝：所有值类型成员（如 `Int64`、`Bool`）都会被完整复制，新旧实例各持一份独立数据。因此修改其中一个实例的值类型成员，不会影响另一个实例。这是 struct 与 class 的核心语义区别之一。

### Q6: 那引用类型成员呢？为什么有时又会"互相影响"？

当成员变量本身是引用类型（如 `Array`、`String`、`HashMap` 或 class 实例）时，赋值只复制"引用"而**不复制被引用的对象**。于是新旧实例的该成员指向同一个对象，通过其中任一实例修改这个共享对象（例如修改数组里的某个元素），另一实例也会看到变化。区分点在于：**值类型成员独立拷贝，引用类型成员共享同一对象**。这也是第 7.1 节强调的 struct 使用陷阱。

### Q7: struct 能继承或实现接口吗？

struct 不能继承其他类型，但可以实现 `interface`；被实现的接口方法必须保持一致的 `mut` 修饰。详细规则将在后续《class 类类型》与《接口、属性与子类型》文章中介绍。

### Q8: 修改实例成员变量需要哪些条件？

需要同时满足两点：变量本身用 `var` 声明（不能用 `let`），且要修改的成员变量也是 `var` 声明（不能用 `let`）。如需在 `let` 变量上调用的函数能修改成员变量，可以借助 `mut` 函数，但 `mut` 函数本身也只能修改 `var` 成员变量，无法修改 `let`。`mut` 函数将在后续专题展开。

## 10. 总结

1. `struct` 是值类型，定义在顶层，由 `struct` 关键字、类型名和花括号定义体组成。
2. 成员变量分为实例成员（`let`/`var`）和静态成员（`static`），静态成员通过类型名访问，静态初始化器用于初始化未赋初值的静态成员变量。
3. 构造函数分普通 `init` 与主构造函数（与类型同名），主构造函数的 `let`/`var` 形参同时声明成员变量；所有成员都有初值且无自定义构造函数时会自动生成无参构造函数。
4. 成员函数分实例成员函数与静态成员函数，实例函数可通过 `this` 访问当前实例；静态函数中不能访问实例成员。
5. 访问修饰符 `private` / `internal`（缺省） / `protected` / `public` 控制成员在 struct 内、包、子包、模块和模块外的可见性。
6. struct 禁止递归和互递归定义，编译期需要确定类型大小。
7. struct 是值类型，赋值或传参会复制实例；修改实例成员要求变量和成员变量都使用 `var` 声明。
8. `mut` 函数、泛型结构体与 `class` 的差异将在后续专题深入。

## 参考资料

1. 仓颉 1.0.5 LTS 定义 struct 类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/struct/define_struct.html
2. 仓颉 1.0.5 LTS 创建 struct 实例：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/struct/create_instance.html
3. 仓颉 1.0.5 LTS mut 函数：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/struct/mut.html
4. 仓颉 1.0.5 LTS 泛型结构体：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/generic/generic_struct.html
5. 仓颉 1.0.5 LTS 属性（struct 成员属性定义方式参见此章节）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/class_and_interface/prop.html
6. 仓颉 1.0.5 LTS 操作符重载（struct 操作符函数）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/function/operator_overloading.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
