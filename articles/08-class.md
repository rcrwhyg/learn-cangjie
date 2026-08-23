# 仓颉类类型

> **摘要**: 类（class）是仓颉中的引用类型抽象，是面向对象编程的核心载体。本文依据仓颉 1.0.5 LTS 官方文档，系统介绍 `class` 的声明、成员变量与构造函数、抽象类与抽象函数、This 类型、终结器 `~init`、访问修饰符、引用类型语义以及继承与覆盖机制，帮助读者掌握 class 的定义与使用方式。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已了解变量、`let`/`var`、`Int64`、`String`、`Bool`、`Unit`
- 已了解函数定义与调用
- 已了解 `struct` 的定义与值类型语义
- 已完成《仓颉函数基础》《仓颉结构类型 struct》

## 1. class 与 struct 的对比

class 是引用类型，struct 是值类型。两者的核心差异在赋值或传参时的行为：

| 特性 | class | struct |
|------|-------|--------|
| 类型分类 | 引用类型 | 值类型 |
| 赋值 / 传参 | 复制引用，多个变量共享同一对象 | 复制整个实例 |
| 修改可见性 | 通过任一引用修改，所有引用都可见 | 各副本独立 |
| 继承 | 支持单继承 | 不能继承 |
| 抽象 / 终结器 | 支持 | 抽象函数不适用；不支持 `~init` |

```cangjie
class Counter {
    public var count: Int64 = 0
    public init() {}
}

main() {
    let a = Counter()
    let b = a   // b 与 a 指向同一对象
    a.count = 5
    println(b.count)  // 5
}
```

## 2. class 定义

class 类型以关键字 `class` 开头，后跟类名和花括号定义体。class 只能定义在源文件顶层作用域。

```cangjie
class Rectangle {
    let width: Int64
    let height: Int64
    public init(width: Int64, height: Int64) {
        this.width = width
        this.height = height
    }
    public func area() {
        width * height
    }
}
```

class 定义体中可以声明成员变量、成员属性、静态初始化器、构造函数、成员函数和操作符函数。

### 2.1 抽象类与抽象函数

使用 `abstract` 修饰的类称为抽象类。抽象类除了能定义普通成员函数外，还可以声明抽象函数——没有函数体、必须由非抽象子类实现的成员函数。抽象类定义时的 `open` 修饰符是可选的，也可以使用 `sealed` 修饰。

```cangjie
abstract class Animal {
    public var name: String
    public init(name: String) {
        this.name = name
    }
    public func describe(): String {
        "Animal: ${name}"
    }
    public func sound(): String   // 抽象函数：无函数体
}
```

抽象函数必须使用 `public` 或 `protected` 修饰，没有函数体；非抽象子类必须实现父类中的所有抽象函数。抽象类不可直接实例化。

## 3. 成员变量

### 3.1 实例成员变量

实例成员变量通过对象访问，定义时可以省略初值（但必须标注类型），也可以设置初值：

```cangjie
class Rectangle {
    let width = 10
    let height: Int64   // 不设初值，构造函数中必须赋值
}
```

实例成员变量可以是 `let` 或 `var`。`var` 成员变量可以通过对象修改：

```cangjie
class Rectangle {
    public var width: Int64
    public var height: Int64
}

main() {
    let r = Rectangle(10, 20)
    r.width = 8
    println(r.area())  // 192
}
```

> **⚠️ 注意**：官方文档建议通过成员函数修改对象状态，而不是直接修改 `var` 成员变量。直接修改只用于示意，实际项目应封装到成员函数中。

### 3.2 静态成员变量与静态初始化器

静态成员变量使用 `static` 修饰，必须通过类名访问。定义时若无静态初始化器则必须有初值：

```cangjie
class Rectangle {
    let width = 10
    static let height = 20
}

let l = Rectangle.height   // 20
```

静态初始化器以 `static init` 开头，无参数，函数体中必须完成对所有未初始化静态成员变量的赋值，且最多允许一个：

```cangjie
class Rectangle {
    static let degree: Int64
    static init() {
        degree = 180
    }
}
```

## 4. 构造函数

class 支持普通构造函数和主构造函数，规则与 struct 类似，区别在于子类的构造函数可以通过 `super(args)` 调用父类构造函数。

### 4.1 普通构造函数与主构造函数

普通构造函数以 `init` 开头；主构造函数以类名命名，参数列表中的 `let`/`var` 形参同时声明成员变量和形参。

```cangjie
class Rectangle {
    public Rectangle(let width: Int64, let height: Int64) {}
}
```

### 4.2 子类构造函数与 super

子类的 `init` 可以使用 `super(args)` 调用父类构造函数，或使用 `this(args)` 调用本类其他构造函数。两者只能调用一个，且必须作为构造函数体的第一个表达式。

```cangjie
open class A {
    public A(let a: Int64) {}
    public func getA(): Int64 { a }
}

class B <: A {
    public var b: Int64
    public init(a: Int64, b: Int64) {
        super(a)        // 必须放在第一行
        this.b = b
    }
}
```

> **⚠️ 注意**：子类主构造函数**不能**重声明从父类继承的成员变量，否则会报"the variable 'x' must not shadow a member variable of the supertype"。

如果子类的构造函数没有显式调用 `super` 也没有调用本类其他构造函数，编译器会在构造函数体开头自动插入对父类无参构造函数的调用。如果父类没有无参构造函数，则编译报错。

### 4.3 自动生成的无参构造函数

与 struct 一样，当 class 中不存在任何自定义构造函数且所有实例成员变量都有初值时，编译器会自动生成一个无参构造函数。

## 5. 终结器

终结器是实例被垃圾回收时触发的清理函数，函数名固定为 `~init`，通常用于释放系统资源：

```cangjie
class Resource {
    public let tag: String
    public init(tag: String) {
        this.tag = tag
    }
    ~init() {
        println("Resource ${tag} finalized")
    }
}
```

终结器有以下限制：

- 没有参数、没有返回类型、不能有修饰符，也不能被显式调用
- 带有终结器的类不可被 `open` 修饰
- 一个类最多只能定义一个终结器
- 终结器不可以定义在扩展中
- 终结器触发时机、执行线程和执行顺序都不确定
- 终结器抛异常或创建线程属于未定义行为

## 6. 成员函数

class 成员函数同样分为实例成员函数和静态成员函数。实例成员函数只能通过对象访问，静态成员函数只能通过类名访问。静态成员函数中不能访问实例成员。

```cangjie
class Rectangle {
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

根据是否有函数体，实例成员函数又分为抽象成员函数（无函数体，只能定义在抽象类或接口中）和非抽象成员函数。

## 7. This 类型

`This` 是类内部的一个占位符类型，代指当前类的类型。它只能作为实例成员函数的返回类型使用。当子类对象调用定义在父类中、返回 `This` 的函数时，编译器会按实际运行时类型（子类类型）解析：

```cangjie
open class C1 {
    public func f(): This { this }
}

class C2 <: C1 {}

main() {
    var obj1: C2 = C2()
    var obj2: C1 = C2()
    var x = obj1.f()   // x 的类型为 C2
    var y = obj2.f()   // y 的类型为 C1
}
```

如果实例成员函数没有声明返回类型，且函数体中只存在返回 `This` 类型的表达式，返回类型会被推断为 `This`。

## 8. 访问修饰符

class 的成员可使用四种访问修饰符：

| 修饰符 | 可见范围 |
|--------|----------|
| `private` | 仅 class 定义内可见 |
| `internal`（缺省） | 当前包及子包可见 |
| `protected` | 当前模块及当前类的子类可见 |
| `public` | 模块内外均可见 |

> **⚠️ 注意**：与 struct 不同，class 的 `protected` 还包含"当前类的子类可见"，可以跨包被子类访问。

## 9. 创建对象与引用类型语义

通过类名调用构造函数即可创建对象：

```cangjie
class Rectangle {
    public var width: Int64
    public var height: Int64
    public init(width: Int64, height: Int64) {
        this.width = width
        this.height = height
    }
}

main() {
    let r = Rectangle(10, 20)
    let w = r.width
    let h = r.height
}
```

class 是引用类型，赋值或传参时**不会**复制对象本身，多个变量指向同一个对象：

```cangjie
main() {
    var r1 = Rectangle(10, 20)
    let r2 = r1   // r2 与 r1 指向同一对象
    r1.width = 1
    r1.height = 1
    // r1.area() == 1
    // r2.area() == 1
}
```

这是 class 与 struct 的核心语义差异，也是引用类型适合表示对象身份而不是纯数据的原因。

## 10. 继承

### 10.1 open 与 sealed

非抽象的类默认不能被继承。要让类可被继承，必须使用 `open` 修饰：

```cangjie
open class A { let a: Int64 = 10 }
class B <: A { let b: Int64 = 20 }   // OK：A 是 open
class C <: B {}                       // 错误：B 不是 open，不可继承
```

抽象类总是可被继承的，`open` 是可选的；抽象类也可以使用 `sealed` 修饰，表示只能在本包内被继承：

```cangjie
sealed abstract class Base {}
class Sub <: Base {}   // OK：本包内
// package B; class Sub2 <: Base {}  // 错误：sealed 只能在本包继承
```

class 仅支持**单继承**，不能同时继承多个类（多接口实现使用 `&` 语法，详见后续接口专题）。

未显式指定父类的 class，其直接父类是 `Object`。`Object` 是所有类的父类，不包含任何成员。

### 10.2 父类构造函数调用

子类的构造函数必须显式或隐式调用父类构造函数（详见 4.2 节）。

### 10.3 覆盖（override）与重定义（redef）

子类可以覆盖父类的非抽象实例成员函数。父类函数需要 `open`，子类函数使用 `override`（可选）：

```cangjie
open class A {
    public open func f(): Unit {
        println("I am superclass")
    }
}

class B <: A {
    public override func f(): Unit {
        println("I am subclass")
    }
}

main() {
    let a: A = A()
    let b: A = B()
    a.f()   // I am superclass
    b.f()   // I am subclass（动态派发）
}
```

被覆盖的函数通过动态派发决定调用版本：编译时类型决定函数签名，运行时类型决定实际调用版本。

静态函数的重定义使用 `redef` 修饰符（可选），调用时按类名决定版本，无动态派发：

```cangjie
open class C {
    public static func foo(): Unit { println("I am class C") }
}
class D <: C {
    public redef static func foo(): Unit { println("I am class D") }
}

main() {
    C.foo()   // I am class C
    D.foo()   // I am class D
}
```

> **⚠️ 注意**：如果父类的 `open` 函数有命名形参（`p!: T`），子类的同名函数必须保持完全一致的命名形参，否则编译报错。

## 11. 一个完整示例

本示例组合了基本 class、抽象类、This 类型、引用类型语义、继承与覆盖、终结器：

<!-- example: cangjie/012-class.cj -->
```cangjie
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
```

预期输出：

```text
Shape: Generic
Geometry
Animal: Dog
Dog says: Woof
Shape: Circle, r=5
Circle area = 78.53975
c1.count = 3
c2.count = 3
s2.value = 1
Resource A acquired
Resource A finalized
```

> **⚠️ 关于终结器输出**：`~init` 由垃圾回收器触发，调用时机与平台、内存压力、运行时实现都相关。在 macOS 静态库检查场景下可能看不到 finalizer 输出，正式运行或 Linux 环境下通常能观察到。

## 12. 常见问题

### Q1: class 与 struct 的根本区别是什么？

class 是引用类型，赋值或传参时只复制引用，多个变量共享同一对象；struct 是值类型，赋值或传参会复制整个实例。class 支持单继承，struct 不能继承。

### Q2: 非抽象类能被继承吗？

不能。除非显式加上 `open` 修饰。抽象类默认可被继承（`open` 可省略）。

### Q3: 抽象类可以直接实例化吗？

不能。必须通过实现其所有抽象函数的非抽象子类来实例化。

### Q4: 子类主构造函数可以重声明父类成员吗？

不可以。在主构造函数中重声明从父类继承的成员变量会报"the variable 'x' must not shadow a member variable of the supertype"。

### Q5: super() 必须显式调用吗？

子类的 `init` 构造函数可以选择显式 `super(args)` 或 `this(args)`，或省略——省略时编译器会插入对父类无参构造函数的调用。父类没有无参构造函数时，必须显式调用。

### Q6: This 类型有什么用？

当父类函数返回 `This` 时，子类对象调用该函数会得到子类类型的结果，从而支持流畅的链式 API 与子类型特定操作。

### Q7: 终结器什么时候会执行？

由垃圾回收器在对象被回收时触发，时机、线程、顺序均不确定。资源管理应优先考虑 RAII（确定性释放）模式，不要依赖终结器做关键同步。

### Q8: override 和 redef 分别是做什么的？

`override` 用于覆盖父类的实例成员函数（实例方法动态派发）；`redef` 用于重定义父类的静态成员函数（静态方法按类名派发）。两者都是可选修饰符。

## 13. 总结

1. `class` 是引用类型，赋值或传参只复制引用；`struct` 是值类型，会复制整个实例。
2. `class` 以 `class` 关键字声明，只能在顶层作用域定义，可包含成员变量、构造函数、成员函数、终结器等。
3. 抽象类（`abstract class`）可包含抽象函数（无函数体），抽象函数必须由非抽象子类实现。
4. 成员变量分实例成员（`let`/`var`）和静态成员（`static`），与 struct 规则相同。
5. 构造函数分普通 `init` 与主构造函数，子类可通过 `super(args)` 调用父类构造函数；终结器 `~init` 在 GC 回收时执行，时机不确定。
6. `This` 类型仅作为实例成员函数返回类型使用，支持动态子类型推断。
7. 访问修饰符 `private` / `internal`（缺省） / `protected` / `public`，class 的 `protected` 包含子类可见语义。
8. class 支持单继承，未指定父类时默认继承 `Object`；非抽象类必须加 `open` 才能被继承。
9. 实例方法使用 `override` 覆盖，遵循动态派发；静态方法使用 `redef` 重定义，按类名派发。
10. 接口实现、属性、继承层级、子类型多态与类型转换等高级机制将在后续专题展开。

## 参考资料

1. 仓颉 1.0.5 LTS class 定义：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/class_and_interface/class.html
2. 仓颉 1.0.5 LTS interface 接口：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/class_and_interface/interface.html
3. 仓颉 1.0.5 LTS 属性：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/class_and_interface/prop.html
4. 仓颉 1.0.5 LTS 子类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/class_and_interface/subtype.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
