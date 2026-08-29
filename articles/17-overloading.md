# 仓颉函数重载与操作符重载

> **摘要**: 同一个函数名在不同场景下承载多种含义，是几乎所有主流语言都会面对的问题。仓颉 1.0.5 用两条机制回应：**函数重载**让同名函数按参数个数或类型区分，并给出一套**作用域优先 + 最匹配**的重载决议规则；**操作符重载**用 `operator func` 让你在自己类型上支持 `-`、`+`、`==`、`[]`、`()` 等内建操作符。本文依据仓颉 1.0.5 LTS 官方 function 章节，逐条讲清两者的定义形态、限制清单与决议规则，并用 cjc 实测确认了每个负例的报错。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已完成《仓颉函数基础》（`func`、命名参数、默认值）与《仓颉函数类型、Lambda 与闭包》
- 已了解 struct / class / enum / interface 的成员函数与构造器
- 已了解子类型（`<:`）与 `open` / `override`

> 上一篇《函数类型、Lambda 与闭包》聚焦"函数作为值"，本篇补齐官方 `function` 章节剩余两页：`function_overloading.html` 与 `operator_overloading.html`。操作符重载若通过 `extend` 给"第三方类型"实现，还会牵出《扩展机制》专题，此处只讲类型体内定义。

## 1. 函数重载（Function Overloading）

### 1.1 什么构成重载

在同一个作用域中，同一个函数名对应多个函数定义，称为**函数重载**。判断"是不是重载"的关键是：**参数不同**——参数个数不同，或个数相同但类型不同。

```cangjie
func f(a: Int64): Unit {}
func f(a: Float64): Unit {}
func f(a: Int64, b: Float64): Unit {}   // 三个 f 相互重载
```

同名泛型函数在**"把泛型形参改名后其非泛型部分参数不同"**时也构成重载；泛型形参的**约束**不参与判断：

```cangjie
func f1<X, Y>(a: X, b: Y) {}
func f1<Y, X>(a: X, b: Y) {}             // OK：改名后参数顺序不同 → 重载

interface I1 {}
interface I2 {}
func f2<T>(a: T) where T <: I1 {}
func f2<T>(a: T) where T <: I2 {}        // Error：约束不同不算差异，重定义
```

### 1.2 构造器也参与重载

类内的两个 `init`、或主构造函数与 `init`，只要**参数不同**就构成重载（主构造函数与 `init` 视为同名）：

```cangjie
class C {
    var a: Int64
    var b: Float64

    C(var a!: Int64, var b!: Float64) {   // 主构造函数
        this.a = a
        this.b = b
    }
    public init(a: Int64) {               // 另一个 init，参数不同 → 与主构造重载
        b = 0.0
        this.a = a
    }
}
```

### 1.3 跨作用域、跨继承的重载

两个同名不同参的函数**只要在同一可见作用域里**，就构成重载——哪怕它们写在不同的源文件、不同的嵌套层级、或父子类里：

```cangjie
func f(a: Int64): Unit {}
func g() {
    func f(a: Float64): Unit {}    // 与外层 f 都可见时构成重载
}

open class Base { public func f(a: Int64): Unit {} }
class Sub <: Base { public func f(a: Float64): Unit {} }   // 与父类同名不同参 → 重载
```

### 1.4 不构成重载的情况（负例清单）

**只有 `func` 声明**能引入重载。以下四类都不能：

| 情形 | 报错（cjc 实测） |
|---|---|
| 同一作用域声明两个同名**函数类型变量** | `redefinition of declaration 'f'` |
| 变量与函数同名（即使变量是函数类型） | `functions and variables cannot have the same name` |
| 类内**静态成员函数**与**实例成员函数**同名不同参 | `overloaded functions 'f' cannot mix static and non-static` |
| `enum` 的构造器 / 静态成员函数 / 实例成员函数**互相同名不同参** | 同上，不能相互重载 |

> **⚠️ 注意**：函数重载的判定只看**参数**，不看返回值。返回值不同、参数相同的两个函数不是重载而是**重定义**，编译器报错。

## 2. 函数重载决议

调用发生歧义时，编译器按下列**两条规则**在候选集里选一个：

**规则 A：优先作用域级别更高的。** 越内层的作用域级别越高。

```cangjie
open class Base {}
class Sub <: Base {}

func outer() {
    func g(a: Sub) { print("1") }
    func inner() {
        func g(a: Base) { print("2") }
        g(Sub())   // Output: 2  —— 内层的 g 优先
    }
}
```

**规则 B：作用域同级时，选最匹配的。** 对给定实参，若"能用 f 就一定能用 g"但反过来不成立，则 f 比 g 更匹配。**若无唯一最匹配者，报错。**

```cangjie
open class Base {}
class Sub <: Base {}

func outer() {
    func g(a: Sub) { print("1") }
    func g(a: Base) { print("2") }
    g(Sub())   // Output: 1 —— Sub() 更匹配 Sub 参数
}
```

**父类和子类视为同一作用域**：`s.g(Sub())` 会走"最匹配"而不是"子类优先"。

```cangjie
open class Base {}
class Sub <: Base {}
open class Base2 {
    public func g(a: Sub) { print("1") }   // 父类方法参数更具体
}
class Sub2 <: Base2 {
    public func g(a: Base) { print("2") }
}

let s: Sub2 = Sub2()
s.g(Sub())   // Output: 1 —— 同一作用域内按最匹配选父类的 g
```

> **💡 提示**：如果两个候选函数对同一实参"同等匹配"（比如泛型能覆盖、非泛型也能覆盖，两者不分上下），编译器会报 `ambiguous match for function call`。我在 SDK 上验证过这条歧义报错。

## 3. 操作符重载（Operator Overloading）

想让某个类型支持它**默认不支持的操作符**，可以给类型定义一个"操作符函数"。语法在 `func` 前面加 `operator` 修饰符，函数名就是那个操作符：

```cangjie
open class Point {
    var x: Int64 = 0
    var y: Int64 = 0
    public init(a: Int64, b: Int64) {
        x = a
        y = b
    }
    public operator func -(): Point {
        Point(-x, -y)
    }
    public operator func +(right: Point): Point {
        Point(this.x + right.x, this.y + right.y)
    }
}

main() {
    let p1 = Point(8, 24)
    let p2 = -p1       // Point(-8, -24)
    let p3 = p1 + p2   // Point(0, 0)
}
```

### 3.1 五条硬性限制

- `operator` 必须写在 `func` 前面。
- 参数个数必须**匹配对应操作符要求**：一元无参、二元一个参数。
- 只能定义在 `class` / `struct` / `enum` / `interface` / `extend` 内。
- **不能用 `static` 修饰**（操作符函数按实例成员语义工作）。
- **不能是泛型函数**。

cjc 实测：

```
'operator' and 'static' modifiers conflict on function declaration
generic is not allowed in operator overload function
```

> **💡 提示**：如果给类型 `T` **加**的是它**本来就已支持**的**同签名**操作符函数，编译器直接报**重定义错**。例如 `extend Int64 { operator func +(rhs: Int64): Int64 {...} }` 会报：`operator func +(Int64) of type Int64 is a built-in function and cannot be overridden`。

### 3.2 可被重载的操作符一览

下表来自官方附录（优先级从高到低）：

| 优先级 | 操作符 |
|---|---|
| 最高 | `()` `[]` |
| 一元 | `!` `-`（负号） |
| 幂 | `**` |
| 乘除 | `*` `/` `%` |
| 加减 | `+` `-` |
| 移位 | `<<` `>>` |
| 比较 | `<` `<=` `>` `>=` |
| 判等 | `==` `!=` |
| 位运算 | `&` `^` `\|` |

**仓颉不支持自定义操作符**——只能重载上表这些。且**重载后的操作符不改变其固有的优先级和结合性**，你重载出来的 `+` 依然是原来 `+` 的位置。

### 3.3 二元操作符与复合赋值

一旦你**为除关系操作符（`<` `<=` `>` `>=` `==` `!=`）之外的**二元操作符做了重载，**并且返回类型与左操作数类型一致或是其子类型**，那么该类型自动获得对应的复合赋值（`+=`、`*=` 等）。返回类型不符则使用复合赋值时报错：

```cangjie
class My {
    var x: Int64 = 0
    public init(a: Int64) { x = a }
    public operator func +(rhs: My): Int64 { this.x + rhs.x }   // 返回 Int64，不是 My
}

main() {
    var a = My(5); var b = My(3)
    a += b   // 报错：type incompatible in this compound assignment expression
}
```

**只要把返回类型改成 `My`，`a += b` 就能用了**——这是我在示例里演示 `Vector2` 支持 `+=` 的关键。

### 3.4 索引操作符 `[]`

`[]` 有两种形式：**取值**与**赋值**。它们的区分方式是**赋值形式带一个特殊命名参数 `value!`**（不是调用语法，只是标记，`v[0] = 100` 依然写成下标赋值）。两种形式**分别重载**，可以只重载一种：

```cangjie
struct Vec2 {
    var x: Int64
    var y: Int64
    public init(x: Int64, y: Int64) { this.x = x; this.y = y }

    // 取值：[] 里是非命名参数（0 个或多个都行），返回类型任意
    public operator func [](i: Int64): Int64 {
        if (i == 0) { x } else { y }
    }
    // 赋值：非命名参数 + 一个 value! 命名参数，返回必须是 Unit
    public mut operator func [](i: Int64, value!: Int64): Unit {
        if (i == 0) { x = value } else { y = value }
    }
}
```

**注意事项**：

- 在 struct 里修改成员必须写 `mut`（示例中 `mut operator func []`）。
- 除 `enum` 外的**不可变类型**（`const` 修饰的类型）不支持重载索引赋值形式。
- `value` 只能是这一个名字、必须没有默认值、必须只出现一次。

### 3.5 函数调用操作符 `()`

给类型加 `operator func ()`，实例就能像函数一样被"调用"：

```cangjie
class Adder {
    public var base: Int64
    public init(base: Int64) { this.base = base }
    public operator func ()(a: Int64, b: Int64): Int64 { base + a + b }
}

main() {
    let adder = Adder(100)
    println(adder(1, 2))    // 103
}
```

**三条限制**：

- **不能**用 `this()` 或 `super()` 去调 `()` 操作符重载函数——官方明确 `this()` 表示"调构造器"，不是调 `()`。
- 对 **enum**：构造器形式与 `()` 操作符重载**同时能匹配时，优先匹配构造器**。
- `()` 操作符的参数和返回值类型任意。

### 3.6 定义操作符函数的两种方式

- **直接**写在 `struct` / `class` / `enum` / `interface` 体内（本文示例走的都是这条路）。
- **通过 `extend`** 给类型附加。对**非上述四类**的类型（比如给 `Int64`、`String` 这类内建或第三方类型加操作符），**只能**走 `extend`。示例：

```cangjie
extend Complex {
    public operator func +(rhs: Complex): Complex { ... }
}
```

（`extend` 机制细节在《扩展机制》专题展开。）

## 4. 完整可运行示例

下面这个例子把函数重载（不同参数个数、不同参数类型、构造器重载、父子类同名不同参、按最匹配决议）和操作符重载（一元 `-`、二元 `+`/`*`、`==` 判等、`[]` 取值/赋值、复合 `+=`、可调用 `()`）串成一个可运行程序。

<!-- example: cangjie/022-overloading.cj -->
```cangjie
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
```

预期输出：

```text
Int64:5
two:5,6
int 1
float
string hi
Point: (0,0) (3,0) (3,4)
area(Sub) = 20
area(Base) = 10
neg = (-1,-2)
a+b = (11,22)
b*2 = (20,40)
eq = true
v[0]=7, v[1]=8
after set v[0]=100
acc = (3,4)
adder(1,2) = 103
```

> 说明：`area(Base())` 走的是父类 `Shape` 的 `area(scale: Base)`，返回 `10`；`area(Sub())` 走的是子类 `Circle` 的 `area(scale: Sub)`，返回 `20`。父子类在同一决议作用域里按**最匹配**选，不是"子类一定优先"。

## 5. 语言对比

| 特性 | 仓颉 | Java | C++ | Kotlin |
|---|---|---|---|---|
| 函数重载触发条件 | 名字同 + 参数不同（个数或类型）；**不看返回值** | 同 | 同 | 不支持同名不同参重载（默认参数替代） |
| 静态 vs 实例同名不同参 | **禁止**（`cannot mix static and non-static`） | 禁止 | 允许 | — |
| 变量与函数同名 | 禁止（`functions and variables cannot have the same name`） | 允许 | 不允许 | — |
| 操作符重载语法 | `operator func +`（在 `func` 前加 `operator`） | 不支持 | 成员/自由函数 `operator+` | `operator` 修饰符（`operator fun plus`） |
| 复合赋值自动获得 | 二元操作符返回类型 = 左操作数类型或其子类型即支持 | — | 需自行重载 `operator+=` | 由 `plus` + `assign` 组合 |
| 索引操作符重载 | `[]` 通过 `value!` 命名参数区分读/写 | — | `operator[]` 返回引用 | `get` / `set` operator |
| 函数调用 `()` 操作符 | 支持（`operator func ()`），`this()` 保留给构造器 | — | 支持 `operator()` | 支持 `operator fun invoke()` |
| 自定义操作符 | **禁止**（只能重脸上表列出的） | — | 禁止 | 禁止 |
| 泛型操作符函数 | **禁止** | — | 允许 | 允许 |

**从 Java 迁移**：仓颉的函数重载比 Java 更严——**静态和实例成员不能同名**，即使参数不同；Java 允许。
**从 C++ 迁移**：仓颉操作符重载**只能是实例成员，没有 static、自由函数、友元**这几条路。想给第三方的类型加操作符，只能走 `extend`。

## 6. 常见问题（FAQ）

### Q1: 两个函数只有返回值类型不同，算重载吗？

**不算**，是**重定义**，编译报错。重载只看参数（个数、类型）。

### Q2: 类里静态 `f(Int64)` 和实例 `f(Float64)` 能并存吗？

不能。cjc 会报 `overloaded functions 'f' cannot mix static and non-static`。这是仓颉 1.0.5 明确的规则。

### Q3: `f(Int64)` 与 `f(Float64)` 都能匹配整数字面量 `1` 怎么办？

按**最匹配**规则。字面量 `1` 的默认类型是 `Int64`，选 `f(Int64)`。若两个都不分上下（如都能通过转换匹配）会报 `ambiguous match for function call`（实测确认）。

### Q4: 操作符重载能改变优先级或结合性吗？

**不能**。`+` 重载后依然是原来的加减级别。要改变分组，用括号。

### Q5: 我能定义 `@`、`$` 这种新操作符吗？

不能。仓颉不支持自定义操作符，只能重载官方附录里那张表列出的操作符。

### Q6: `enum` 里既有 `X(Int64)` 构造器、又有 `operator func ()(p: Int64)`，`X(1)` 走哪个？

**优先构造器**。这是官方在文档里点明的规则。想调 `()` 操作符，把值取出来再调：`let e = X; e(1)`。

### Q7: 二元操作符返回 `Bool` 会有 `==` 一样的 `!` 复合赋值吗？

关系操作符（`<` `<=` `>` `>=` `==` `!=`）**不参与复合赋值机制**。复合赋值只对非关系类的二元操作符自动生效。

### Q8: struct 里的 `operator func []` 想修改成员必须写 `mut` 吗？

**必须**。struct 是值类型，未加 `mut` 的操作符函数按不可变对待，编译器会报 `instance member variable 'x' cannot be modified in immutable function`（实测确认）。

## 7. 总结

1. **函数重载**：同名 + 参数（个数或类型）不同；构造器之间、主构造与 `init`、父类与子类的同名不同参**都算**重载。返回值不参与判定。
2. **不算重载 / 不允许混用的四类**：变量与函数同名、两个同名函数类型变量、静态与实例成员同名、enum 内部构造器与成员函数同名。
3. **重载决议**：先按作用域级别（内层优先），再按最匹配；父子类视为同一作用域；**无唯一最匹配**时报错。
4. **操作符重载**：`operator func <符号>`；一元无参、二元一参；不能是泛型、不能是 static；只能定义在 class/struct/enum/interface/extend 内；不能自定义新符号。
5. **复合赋值**：非关系类二元操作符若返回类型 = 左操作数类型或其子类型，该类型自动获得 `+=` 等复合赋值形式。
6. **特殊重载**：索引 `[]` 通过带 `value!` 命名参数区分读/写，struct 中修改成员需 `mut`；函数调用 `()` 让实例可像函数一样被调用，`this()` 保留给构造器。
7. **给第三方类型加操作符只能走 `extend`**，本篇只讲类型体内定义，`extend` 细节留给《扩展机制》专题。

## 参考资料

1. 仓颉 1.0.5 LTS 函数重载：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/function/function_overloading.html
2. 仓颉 1.0.5 LTS 操作符重载：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/function/operator_overloading.html
3. 仓颉 1.0.5 LTS 附录：操作符：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/Appendix/operator.html
4. 仓颉 1.0.5 LTS 函数调用语法糖（含变长参数与重载决议的交互）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/function/function_call_desugar.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
