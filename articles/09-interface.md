# 仓颉接口、属性与子类型

> **摘要**: 接口、属性与子类型多态是仓颉面向对象体系的三大支柱。本文依据仓颉 1.0.5 LTS 官方文档，系统介绍 `interface` 的声明、成员（抽象与默认实现）、继承与实现、密封接口（`sealed`）、`Any` 类型；属性的定义（`prop`/`mut prop`）、抽象属性、覆盖与重定义；以及子类型关系的多种来源（class 继承、接口实现、元组、函数、内置规则与传递性），帮助读者理解仓颉的接口抽象、属性封装与多态分派机制。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已了解变量、函数、`class` 与 `struct` 的基础
- 已了解引用类型与值类型语义
- 已完成《仓颉类类型 class》《仓颉结构类型 struct》

## 1. 接口

### 1.1 接口定义

接口（`interface`）用来定义一个抽象类型，它不包含数据，但可以定义类型的行为。一个类型声明实现某接口并实现其所有成员，就称为实现了该接口。

```cangjie
interface I {
    func f(): Unit
}
```

接口的成员可包含：成员函数、操作符重载函数、成员属性。这些成员默认是抽象的，实现类型必须提供对应实现。接口成员可被 `open` 修饰（可选，因为接口本身默认具有 `open` 语义）。

### 1.2 接口成员

#### 1.2.1 抽象成员函数

```cangjie
interface Flyable {
    func fly(): Unit
}

class Bird <: Flyable {
    public func fly(): Unit {
        println("Bird flying")
    }
}
```

类实现接口时必须实现所有声明的成员，否则编译报错。

#### 1.2.2 静态成员函数

接口也可以声明静态成员函数，实现类型必须为类并提供同名静态实现：

```cangjie
interface NamedType {
    static func typename(): String
}

class A <: NamedType {
    public static func typename(): String { "A" }
}

main() {
    println("the type is ${A.typename()}")
}
```

如果接口中的静态成员函数没有默认实现，则不能通过接口类型名直接调用（接口类型名上没有实现）。

#### 1.2.3 操作符重载函数

接口中可以声明操作符重载函数，要求实现类型提供对应的操作符重载：

```cangjie
interface Calculable <: Addable & Subtractable {
    func mul(other: Int64): Int64
    func div(other: Int64): Int64
}
```

实现类型必须实现所有继承链上的操作符重载。

### 1.3 接口的默认实现

接口成员可以拥有默认实现。当某类型实现带默认实现的接口时，可以继承默认实现，也可以选择重写：

```cangjie
interface Greeter {
    func greet(): String { "Hello" }
}

class A <: Greeter {}                          // 继承默认实现
class B <: Greeter {
    public override func greet(): String {
        "hi, B"
    }
}
```

> **⚠️ 注意**：当一个类型实现多个接口，且多个接口中包含同名成员的默认实现时，会发生默认实现冲突，编译时会要求实现类型提供自己的实现。

子接口继承父接口的成员时，若父接口中的成员有默认实现，子接口不允许仅声明该成员（即没有默认实现），必须给出新的默认实现；若父接口中的成员无默认实现，子接口可以仅声明也可以给出默认实现。上述两种情形中，函数声明或定义前的 `override` 或 `redef` 修饰符都是可选的——实例成员使用 `override`，`redef` 用于同名静态成员的重定义。

### 1.4 sealed interface

接口可以使用 `sealed` 修饰，表示只能在接口定义所在的包内被继承、实现或扩展。`sealed` 已蕴含 `public`/`open` 语义，提供这些修饰符编译器会告警。

```cangjie
package A
sealed interface I2 {}

package B
import A.*
class S2 <: I2 {}    // 错误：I2 是 sealed interface，不能在包外被继承
```

## 2. 接口继承与实现

### 2.1 接口继承

接口可以单继承或多继承（使用 `&`）：

```cangjie
interface A {}
interface B {}
interface C <: A & B {}    // 多继承
```

继承父接口时，子接口会继承父接口的所有成员约束。

### 2.2 类实现接口

类使用 `<:` 既可以继承父类，也可以实现接口；多接口实现使用 `&`：

```cangjie
open class Animal {}
interface Flyable { func fly(): Unit }
class Duck <: Animal & Flyable {
    public func fly(): Unit { println("Duck flying") }
}
```

实现要求：

- 成员函数、操作符重载：函数名、参数列表、返回类型必须与接口一致
- 成员属性：`mut` 修饰与类型必须一致
- 例外：若接口成员函数的返回类型是 class 类型，实现函数的返回类型可以是其子类型

### 2.3 struct、enum 实现接口

struct、enum 同样可以实现接口，函数或属性定义前的 `override`/`redef` 修饰符都是可选的。

### 2.4 通过扩展实现接口

除了在定义类型时声明实现接口，还可以通过 `extend` 为已有类型补实现接口。仓颉除 `Tuple`、`VArray` 和函数外，其他类型都可以实现接口。

## 3. Any 类型

`Any` 是仓颉内置的空接口（仅含 `interface Any {}`）。所有接口默认继承 `Any`，所有非接口类型默认实现 `Any`，因此所有类型都是 `Any` 的子类型：

```cangjie
main() {
    var any: Any = 1
    any = 3.14
    any = "hello"
}
```

这意味着可以编写形参为 `Any` 的通用函数来接受任何类型的实参。`Any` 自身不能直接调用任何具体方法，需要通过类型转换恢复具体类型。

## 4. 属性（prop）

属性通过 getter 和可选的 setter 间接提供对数据的访问与修改能力。属性在使用上与普通变量无异，但能更好地支持访问控制、监控与数据绑定等机制。

### 4.1 属性定义

属性可在 `interface`、`class`、`struct`、`enum`、`extend` 中定义：

```cangjie
class Foo {
    public prop a: Int64 {
        get() { 0 }
    }
    public mut prop b: Int64 {
        get() { 0 }
        set(v) { }
    }
}
```

- 无 `mut` 修饰的属性：仅提供 getter，类似 `let` 变量，**不可**赋值
- 带 `mut` 修饰的属性：同时提供 getter 和 setter，类似 `var` 变量，**可以**取值与赋值

getter 函数类型为 `() -> T`，setter 函数类型为 `(T) -> Unit`，形参名需要显式指定。

> **⚠️ 注意**：对于数值、元组、函数、`Bool`、`Unit`、`Nothing`、`String`、`Range` 和 `enum` 类型，在它们的扩展和声明中不能声明 `mut` 修饰的属性，也不能实现带 `mut` 属性的接口。

### 4.2 属性的使用

属性的使用方式与成员变量一致。实例属性通过对象访问，静态属性通过类型名访问：

```cangjie
class A {
    public prop x: Int64 { get() { 123 } }
    public static prop y: Int64 { get() { 321 } }
}

main() {
    let a = A()
    println(a.x)   // 123
    println(A.y)   // 321
}
```

### 4.3 抽象属性

与抽象函数类似，接口与抽象类中可以声明抽象属性（无 getter/setter 实现）。实现类型或非抽象子类必须实现这些抽象属性。

```cangjie
interface Boxed {
    prop value: Int64
    mut prop label: String
}

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
```

实现时需保持 `mut` 修饰与类型一致。

### 4.4 属性的覆盖与重定义

与成员函数一样，成员属性支持 `open`、`override`、`redef` 修饰。子类型覆盖父类型属性时：

- 实例属性使用 `override` 覆盖
- 静态属性使用 `redef` 重定义
- 父类型带 `mut` 修饰时，子类型也必须带 `mut` 修饰
- 属性类型必须与父类型一致

```cangjie
open class A {
    public open prop x: Int64 { get() { 0 } }
}

class B <: A {
    public override prop x: Int64 { get() { 100 } }
}
```

## 5. 子类型关系

子类型是仓颉多态分派的依据。两个类型 `S` 和 `T`，若 `S <: T`（`S` 是 `T` 的子类型），则所有需要 `T` 的位置都可以使用 `S`。

### 5.1 继承 class 带来的子类型

子类继承父类后即为父类的子类型：

```cangjie
open class Super {}
class Sub <: Super {}
let s: Super = Sub()    // OK：Sub 是 Super 的子类型
```

### 5.2 实现接口带来的子类型

实现接口的类型即为接口的子类型，多接口实现时同时是所有接口的子类型：

```cangjie
interface I1 {}
interface I2 {}
interface I3 <: I1 & I2 {}
class C <: I1 {}
extend Int64 <: I2 {}
// C 是 I1 的子类型，Int64 是 I2 的子类型，I3 是 I1 和 I2 的子类型
```

### 5.3 元组类型的子类型

若元组 `t1` 的每个元素类型都是 `t2` 对应位置元素类型的子类型，则 `t1` 的类型是 `t2` 的子类型（协变）：

```cangjie
open class C1 {}
class C2 <: C1 {}
open class C3 {}
class C4 <: C3 {}
let t: (C1, C3) = (C2(), C4())    // OK
```

### 5.4 函数类型的子类型

给定两个函数类型 `(U1) -> S2` 和 `(U2) -> S1`，前者是后者的子类型，当且仅当 `U2 <: U1`（参数类型**逆变**）且 `S2 <: S1`（返回类型**协变**）。

```cangjie
open class U1 {}
class U2 <: U1 {}
open class S1 {}
class S2 <: S1 {}

func f(a: U1): S2 { S2() }
func g(a: U2): S1 { S1() }

let h: (U2) -> S1 = g
let h2: (U2) -> S1 = f   // OK：f 的类型是 g 的类型的子类型
```

直观理解：实参类型要求更严格时（`U2` 比 `U1` 更窄）依然可被调用；返回结果类型更具体（`S2` 比 `S1` 更窄）时满足原结果的类型需求。

### 5.5 永远成立的子类型

- `T <: T`（每个类型都是自身的子类型）
- `Nothing <: T`（`Nothing` 是所有类型的子类型）
- `T <: Any`（任何类型都是 `Any` 的子类型）
- `class C` 定义的类型都是 `Object` 的子类型

### 5.6 传递性

子类型关系具有传递性。`A <: B` 且 `B <: C` 可推出 `A <: C`。

### 5.7 泛型类型的子类型

泛型类型间也有子类型关系，详细规则涉及型变（协变、逆变、不变）与约束，将在后续泛型专题展开。

## 6. 一个完整示例

本示例组合了接口定义、继承与实现、默认实现、密封接口、抽象属性、`Any` 类型与子类型多态：

<!-- example: cangjie/013-interface.cj -->
```cangjie
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
```

预期输出：

```text
Duck flying
Duck swimming
Airplane flying
Hello
你好
LocalRunner running
c.value = 0
c.label = updated
Duck flying
```

> **⚠️ 说明**：`Any` 类型的变量由于未实现 `ToString` 接口，直接 `println` 会编译报错，因此示例中仅演示对其赋不同类型的值。

## 7. 常见问题

### Q1: 接口和抽象类有什么区别？

接口只能声明抽象成员与提供默认实现，不包含数据；抽象类可以包含数据成员、部分实现和抽象成员。struct 与 enum 只能实现接口，不能继承抽象类。

### Q2: 一个类能实现多个接口吗？

可以，使用 `&` 分隔：

```cangjie
class C <: I1 & I2 & I3 {}
```

### Q3: 接口的默认实现能被子接口保留吗？

若父接口中的成员有默认实现，子接口不允许仅声明该成员，必须给出新的默认实现；函数定义前的 `override` 或 `redef` 修饰符是可选的（实例成员用 `override`，同名静态成员的重定义用 `redef`）。

### Q4: 多接口默认实现冲突怎么办？

当一个类型实现多个接口，且多个接口中包含同名成员的默认实现时，编译会要求实现类型提供自己的实现，默认实现不会被自动采用。

### Q5: 抽象属性和抽象函数有什么不同？

抽象属性通过 `prop` 关键字声明，不提供 getter/setter 实现；抽象函数通过 `func` 声明，不提供函数体。两者都必须在实现类型或非抽象子类中给出实现。

### Q6: `Any` 类型有什么用？

`Any` 是所有类型的父类型，可作为通用容器或函数形参类型。但 `Any` 不含任何成员方法，要调用具体方法需要通过类型转换（如 `as` 或模式匹配）恢复具体类型。

### Q7: 子类型关系有什么用？

子类型是仓颉多态分派的依据：函数形参、变量类型、返回值类型都可以接收子类型实例。这让一段代码可以处理一族类型，是面向对象的核心机制。

### Q8: 函数类型的子类型方向是反直觉的吗？

是的，函数类型对参数是**逆变**、对返回值是**协变**。原因：参数越具体（越严格）越能被接收，返回值越具体（越窄）越能替代父类型结果。

### Q9: 已经有成员变量了，为什么还要有属性？

成员变量只能"被动地"存取一个值：读就是读、写就是写，无法在读写时附加任何逻辑。属性提供 getter 和可选 setter 来**间接**获取和设置值，使用时与普通变量无异（调用方只操作数据、对内部实现无感知），但内部因此获得了成员变量不具备的能力：

1. **封装与访问控制**：把成员变量声明为 `private`，再用 `public` 属性暴露读写入口，外部完全不感知内部存储，却能做到同样的访问与修改。
2. **数据校验与约束**：setter 中可以拒绝非法值；成员变量的赋值则无法拦截。
3. **派生值（计算属性）**：无 `mut` 属性的 getter 可以实时计算返回值，它根本不占用存储——这是纯成员变量做不到的。
4. **数据监控、跟踪调试、数据绑定**：官方文档明确列举的属性适用场景，都依赖"每次读写都会经过 getter/setter"这一前提。
5. **接口约定更直观**：抽象属性让接口对数据操作的约定比 `getSize()/setSize()` 这样的函数对更简洁、更符合意图。

<!-- example: cangjie/020-prop-vs-member.cj -->
```cangjie
// 属性 vs 成员变量示例
// 演示：为什么有了成员变量还需要属性
// 属性提供 getter/setter 间接访问：封装、校验、派生值（计算属性）

class Circle {
    private var _radius: Float64 = 0.0    // 私有成员变量：外部不可直接访问

    // 属性：对外像普通变量，内部可以加校验逻辑
    public mut prop radius: Float64 {
        get() { _radius }
        set(v) {
            if (v >= 0.0) {
                _radius = v
            }
        }
    }

    // 派生属性：不存储值，读取时实时计算——这是纯成员变量做不到的
    public prop area: Float64 {
        get() { 3.14159 * _radius * _radius }
    }
}

main() {
    var c = Circle()
    c.radius = -5.0                         // setter 拒绝非法值，_radius 保持 0.0
    println(c.radius == 0.0)                // true：非法赋值被拦截
    c.radius = 2.0                          // 合法赋值
    println(c.radius == 2.0)                // true
    println(c.area > 12.5 && c.area < 12.6) // true：面积随 radius 实时算出
}
```

预期输出：

```text
true
true
true
```

一句话总结：**成员变量回答"数据存在哪"，属性回答"数据如何被访问"。** 需要校验、派生、监控或日后可能改变存取方式的数据，都应该用属性而不是公有成员变量——否则一旦要加约束，所有直接访问成员变量的调用点都得修改。

## 8. 总结

1. `interface` 用关键字 `interface` 声明，可包含抽象成员函数、操作符重载、抽象属性；可使用 `sealed` 限制为包内可见。
2. 接口支持单继承与多继承（`&`），class、struct、enum 都可以实现接口；实现要求成员名、参数列表、返回类型一致（class 返回类型允许子类型）。
3. 接口成员可拥有默认实现，子接口必须重新给出实现；多接口同名默认实现冲突时由实现类型提供。
4. `Any` 是内置空接口，所有非接口类型默认实现 `Any`，可作为通用类型使用。
5. `prop` 声明属性，`mut prop` 才能赋值；属性可在 `interface`、`class`、`struct`、`enum`、`extend` 中定义。
6. 抽象属性在接口和抽象类中声明，实现时需保持 `mut` 与类型一致；属性支持 `override` 覆盖与 `redef` 重定义。
7. 子类型来源包括：class 继承、接口实现、元组（协变）、函数（参数逆变+返回协变）、内置规则（`T`/`Nothing`/`Any`/`Object`）与传递性。
8. 泛型类型的子类型涉及型变与约束，将在后续泛型专题深入。

## 参考资料

1. 仓颉 1.0.5 LTS interface 接口：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/class_and_interface/interface.html
2. 仓颉 1.0.5 LTS 属性：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/class_and_interface/prop.html
3. 仓颉 1.0.5 LTS 子类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/class_and_interface/subtype.html
4. 仓颉 1.0.5 LTS 类型转换：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/class_and_interface/typecast.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
