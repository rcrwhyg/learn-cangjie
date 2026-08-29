# 仓颉扩展机制

> **摘要**: 有时你只想给一个已有类型（甚至标准库的 `String`、`Array<T>`）加个方法，却改不了它的源码、也不想破坏它的封装。仓颉用 `extend` 关键字提供这种能力：**在不修改原类型的前提下，为其追加成员函数、成员属性、操作符重载，甚至实现接口**。本文依据仓颉 1.0.5 LTS 官方 extension 章节，讲透直接扩展与接口扩展、泛型扩展与"条件能力"写法、扩展的修饰符与访问/遮盖规则、孤儿规则与导出导入语义。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已完成《struct》《class》《接口、属性与子类型》《泛型编程》《函数重载与操作符重载》
- 已了解包与顶层可见性

## 1. 扩展能做什么、不能做什么

**扩展**为当前 `package` 中可见的类型（**除函数、元组、接口**三类不可扩展）添加新功能。典型场景：不能破坏被扩展类型的封装，但希望补点能力。

可以添加：

- 成员函数
- 操作符重载函数
- 成员属性
- 实现接口

按"是否实现新接口"，扩展分成两类：

- **直接扩展**：只加成员函数/属性/操作符，不含 `: 接口`。
- **接口扩展**：`extend 类型 <: 接口 { ... }`，为现有类型补上接口实现。

**硬性限制**（均经 cjc 实测，见 1.1）：

1. **不能增加成员变量**；
2. 扩展的函数和属性**必须拥有实现**（不能是抽象声明）；
3. 扩展的函数和属性**不能用 `open` / `override` / `redef` 修饰**；
4. 扩展**不能访问被扩展类型中 `private` 修饰的成员**；
5. 扩展**不能遮盖**被扩展类型或其他扩展中任何同名成员。

### 1.1 负面清单一览（实测报错）

| 违规写法 | cjc 实际报错 |
|---|---|
| `extend A { var x: Int64 = 0 }` | `unexpected variable declaration in extend body` |
| `public extend A {}` | `expected no modifier before extend declaration` |
| `extend A { public open func g() {} }` | `unexpected modifier 'open' on function declaration in extend body` |
| 扩展里访问 `private` 成员 | `can not access field 'v'` |
| 扩展方法与类型原成员同名 | `extend member 'f' is not allowed to shadow members of 'Class-A'` |
| 扩展里用 `super` | `'super' is not allowed inside an extend declaration` |
| `extend I {}`（I 是 interface） | `extending type 'Interface-I' is not allowed` |

> **💡 提示**：函数、元组、接口**三类不能作被扩展类型**。函数和元组本来就是类型构造器/结构而非具体命名类型；接口用另一种机制（接口的实现方直接实现即可，或用扩展去**给别的类型实现**这个接口）。

## 2. 直接扩展

最简单的一种：给一个类型加成员函数、属性、操作符。

```cangjie
extend String {
    public func shout(): String {
        "${this}!!!"
    }
}

main() {
    let a = "仓颉"
    println(a.shout())   // 仓颉!!!
}
```

- **`this`** 指向被扩展类型的当前实例（对 struct 是 `this`，对 class 也是 `this`）；扩展里的实例成员**不能**用 `super`（它不属于任何继承链）。
- 直接扩展**不能改变封装**——你只能访问在**当前包可见**的成员，被扩展类型内部的 `private` 成员看不见。
- **对 struct 类型的扩展可以声明 `mut` 函数**（示例 4 中的 `scaleBy`）——因为 struct 是值类型，未 `mut` 时修改成员会报"immutable function"。

### 2.1 属性扩展

给已有类型补一个只读或读写属性：

```cangjie
extend Vec {
    public prop lenSq: Int64 {
        get() { this.x * this.x + this.y * this.y }
    }
}
```

属性**必须有实现体**（`get { ... }` / `set { ... }`），不能只声明。

### 2.2 操作符扩展

在 `extend` 内定义 `operator func`，等价于把操作符挂到目标类型：

```cangjie
extend Vec {
    public operator func +(rhs: Vec): Vec {
        Vec(this.x + rhs.x, this.y + rhs.y)
    }
}
```

（操作符参数个数、`static` 禁用、泛型禁用、优先级不变等规则见《函数重载与操作符重载》专题。）

## 3. 泛型扩展

被扩展类型是泛型时，官方给了**两种**扩展写法：

### 3.1 针对**完全实例化**类型扩展

`extend` 后面直接跟一个实例化好的类型；被扩展类型的**类型实参必须满足定义处的约束**。

```cangjie
class Foo<T> where T <: ToString {}

extend Foo<Int64> {}   // OK
class Bar {}
extend Foo<Bar> {}     // 报错：Bar 不满足 Foo 的 T <: ToString
```

实测错误：`generics type arguments do not match the constraint`。

### 3.2 泛型扩展：`extend` 后带类型形参

`extend<T> MyType<T> { ... }` 用来扩展未完全实例化的泛型类型。规则（每条都实测过）：

| 写法 | 结果 |
|---|---|
| `extend<T> MyList<T> {}` | OK |
| `extend<R> MyList<R> {}` | OK（形参名可改） |
| `extend<T, R> MyList<(T, R)> {}` | OK（组合实参） |
| `extend MyList {}` | 报错：`generic type should be used with type argument` |
| `extend<T, R> MyList<T> {}` | 报错：`type parameter 'R' must be used in extended type` |
| `extend<T, R> MyList<T, R> {}`（MyList 只 1 个形参时） | 报错：`type argument's number does not match` |

### 3.3 条件能力：约束决定成员是否可见

这是仓颉泛型扩展最有味道的一手：**给一个泛型扩展加 `where` 约束，扩展里的函数就只在实参满足约束时可用**——不需要为每种组合写重载。

```cangjie
class Pair<T1, T2> {
    var first: T1
    var second: T2
    public init(a: T1, b: T2) { first = a; second = b }
}

interface Eq<T> { func equals(other: T): Bool }

// 只有当 T1、T2 各自实现了 Eq，Pair 才有 equals
extend<T1, T2> Pair<T1, T2> where T1 <: Eq<T1>, T2 <: Eq<T2> {
    public func equals(other: Pair<T1, T2>): Bool {
        first.equals(other.first) && second.equals(other.second)
    }
}
```

`Pair<Foo, Bar>` 里 `Foo`、`Bar` 都实现 `Eq`，`a.equals(b)` 才能编译过；任何一个不实现，`equals` 就"看不见"。这实现了"能力随类型参数出现"的组合式语义。

## 4. 接口扩展

`extend 类型 <: 接口 { ... }` 给**已经存在**的类型补上接口实现。

```cangjie
interface PrintSizeable {
    func printSize(): Unit
}

extend<T> Array<T> <: PrintSizeable {
    public func printSize(): Unit {
        println("The size is ${this.size}")
    }
}

main() {
    let a: PrintSizeable = [1, 2, 3]
    a.printSize()   // The size is 3
}
```

要点：

- **一个扩展可同时实现多个接口**，用 `&` 分隔，接口顺序无意义：`extend Foo <: I1 & I2 & I3 { ... }`。
- **接口扩展里也能声明 `where` 约束**，实现条件式接口。
- 如果被扩展类型**已经有**接口要求的方法/属性，扩展里**不需要**也**不能**再重新实现。

```cangjie
interface Sizeable { prop size: Int64 }
extend<T> Array<T> <: Sizeable {}    // 空扩展即可，Array 本身就有 size
```

### 4.1 父子接口扩展的解析顺序

多个接口扩展实现的接口存在继承关系时，按**先父后子**顺序检查；子接口的默认实现会**覆盖**父接口继承来的实现：

```cangjie
interface I1 { func foo(): Unit { println("I1 foo") } }
interface I2 <: I1 { func foo(): Unit { println("I2 foo") } }
class A {}
extend A <: I1 {}
extend A <: I2 {}
main() { A().foo() }   // 输出：I2 foo
```

**冲突情况**：

- 同一类型的两个接口扩展实现的接口存在**无法确定检查顺序**的继承冲突 → 编译报错 `unable to decide which extension happens first`。
- 两个接口的**默认实现签名相同但接口之间无继承关系** → 报错 `multiple default implementations, need to re-implement ... in ...`；此时需要在**该类型的定义处或某一个扩展里**手写一遍来消除歧义。

> **⚠️ 注意（官方点名的一个坑）**：当类 `A <: B<Int64>`，且 `B<T>` **通过扩展**实现了接口 `I<R>`，接口里带**默认实现**的函数在 `B<T>` 和其扩展里都没被重写、`A` 也没直接实现 `I`，通过 `A` 的实例调用该默认实现函数会**产生非预期行为**。这类场景请显式在 `B<T>` 或 `A` 里重写一次。

## 5. 修饰符与可见性

### 5.1 扩展本身不能带修饰符

```cangjie
public class A {}
public extend A {}   // 报错：expected no modifier before extend declaration
```

### 5.2 扩展成员能带哪些修饰符

`static` / `public` / `protected` / `internal` / `private` / `mut` 都可以：

- `private`：只在**本扩展内**可见。
- `internal`（默认）：当前包及子包内可见。
- `protected`：本模块内可见；被扩展类型是 class 时其**子类定义体**也能访问。
- `public`：模块内外都可见。
- `static`：只能通过类型名访问，不能通过实例访问。
- `mut`：只能在**对 struct 的扩展**里用（配合值类型可修改语义）。

**不能用**：`open`、`override`、`redef`（见 1.1）。

### 5.3 访问与被遮盖规则

- 扩展的实例成员**可以用 `this`**（省略 `this` 直接引用也支持），**不能用 `super`**（不在任何继承链上）。
- **不能访问被扩展类型的 `private` 成员**（同包也不行）。
- **不能遮盖**被扩展类型自带的任何成员，也不能遮盖**其他扩展**已经加进去的成员。

### 5.4 同包多次扩展互访

同一包内可以对同一类型**扩展多次**；只要不是 `private`，一个扩展里可以直接调用另一个扩展加进来的成员：

```cangjie
extend Counter { public func bump(): Unit { this.count += 1 } }
extend Counter { public func bumpTwice(): Unit { this.bump(); this.bump() } }
```

## 6. 泛型扩展之间的可见性

对同一个泛型类型有多个泛型扩展时，可见性由**约束**决定：

- **约束相同** → 两个扩展互相可见。
- **约束有包含关系** → **更宽松**的扩展对**更严格**的扩展可见；反之不可见。
- **约束不存在包含关系** → 两个扩展互相不可见。

例：`extend<X> E<X> <: I1 where X <: B` 与 `extend<X> E<X> <: I2 where X <: A`（B `<: A`），扩展 1（`X <: B` 更严格）**可以**调用扩展 2 的 `f2`，扩展 2 **不能**调用扩展 1 的 `f1`。

## 7. 孤儿规则

`extend 别的包的类型 <: 另一个包的接口` 会导致"类型 A 意外被认为实现了接口 B"的困扰——**仓颉禁止孤儿扩展**：接口扩展必须至少让"被扩展的类型"和"要实现的接口"**之一与扩展定义处在同一个包**。

```
package a: public class Foo {}
package b: public interface Bar {}
package c: import a.Foo
            import b.Bar
            extend Foo <: Bar {}   // 报错：孤儿扩展
```

只能在 `package a` 或 `package b` 里定义这个接口扩展。

## 8. 扩展的导入与导出

- 扩展本身**不能加可见性修饰符**，但**成员**可以按 5.2 修饰。
- **不需要显式 `import` 扩展**：只要导入了被扩展类型（对接口扩展还要一并导入接口与泛型约束用到的类型），可访问的扩展成员就自动可用。
- **导出规则**：直接扩展能否被外部包访问，取决于"被扩展类型 + 所有泛型约束"的可见性；接口扩展取决于"实现接口 + 泛型约束"的可见性。细节规则见官方 access_rules 章，这里不逐条罗列。
- **接口扩展导出的成员仅限于接口中声明的成员**——扩展里加的额外 `public func f3()` **不会**通过接口扩展导出到别的包。

## 9. 完整可运行示例

以下示例把上文用法串成一个可运行程序：给 `String` 直接扩展一个方法、给自定义 struct `Vec` 扩展属性/操作符/`mut` 函数、给 `Array<T>` 接口扩展 `PrintSizeable`、用**泛型扩展 + 约束**给 `Pair` 加"条件式 equals"、以及**同包多次扩展互相调用**。

<!-- example: cangjie/024-extension.cj -->
```cangjie
// 扩展机制示例
// 演示：直接扩展（成员函数 / 成员属性 / 操作符重载 / mut 函数）、
// 接口扩展（为已有类型实现接口）、泛型扩展与条件能力（带 where 约束）、
// this 可用而 super 不可用、同包多次扩展互相调用

// ========== 1) 直接扩展 ==========

// 给 String 直接扩展一个成员函数
extend String {
    public func shout(): String {
        "${this}!!!"
    }
}

// 给自定义 struct 扩展成员属性 + 操作符 + mut 函数
struct Vec {
    public var x: Int64
    public var y: Int64
    public init(x: Int64, y: Int64) {
        this.x = x
        this.y = y
    }
}

extend Vec {
    // 成员属性：长度平方和（避免浮点格式化，只读）
    public prop lenSq: Int64 {
        get() {
            this.x * this.x + this.y * this.y
        }
    }

    // 操作符重载：Vec + Vec
    public operator func +(rhs: Vec): Vec {
        Vec(this.x + rhs.x, this.y + rhs.y)
    }

    // struct 扩展里定义 mut 函数：缩放自身
    public mut func scaleBy(k: Int64): Unit {
        this.x = this.x * k
        this.y = this.y * k
    }
}

// ========== 2) 接口扩展：给 Array 实现一个自定义接口 ==========

interface PrintSizeable {
    func printSize(): Unit
}

// 泛型接口扩展：Array<T> 实现 PrintSizeable
extend<T> Array<T> <: PrintSizeable {
    public func printSize(): Unit {
        println("size = ${this.size}")
    }
}

// ========== 3) 泛型扩展 + 条件能力：两个元素都可判等时，Pair 才能 equals ==========

class EqInt {
    public var v: Int64
    public init(v: Int64) { this.v = v }
}
interface Eq<T> {
    func equals(other: T): Bool
}
extend EqInt <: Eq<EqInt> {
    public func equals(other: EqInt): Bool {
        this.v == other.v
    }
}

class Pair<T1, T2> {
    public var first: T1
    public var second: T2
    public init(a: T1, b: T2) {
        first = a
        second = b
    }
}

// 只在 T1、T2 都实现 Eq 时，才给 Pair 增加 equals
extend<T1, T2> Pair<T1, T2> where T1 <: Eq<T1>, T2 <: Eq<T2> {
    public func equals(other: Pair<T1, T2>): Bool {
        first.equals(other.first) && second.equals(other.second)
    }
}

// ========== 4) 同包多次扩展互相调用（非 private 可见） ==========

class Counter {
    public var count: Int64 = 0
}

extend Counter {
    public func bump(): Unit {
        this.count += 1
    }
}

extend Counter {
    public func bumpTwice(): Unit {
        this.bump()   // 直接调用同类型其他扩展里的公开成员
        this.bump()
    }
}

main(): Int64 {
    // 直接扩展
    let s: String = "仓颉"
    println("shout = ${s.shout()}")        // 仓颉!!!

    // 成员属性 + 操作符重载 + mut 函数
    let v1 = Vec(3, 4)
    println("lenSq = ${v1.lenSq}")           // 25
    let v2 = Vec(1, 1)
    let v3 = v1 + v2
    println("v3 = (${v3.x}, ${v3.y})")       // (4, 5)
    var mv = Vec(2, 2)
    mv.scaleBy(3)
    println("scaled = (${mv.x}, ${mv.y})")   // (6, 6)

    // 接口扩展：Array 作为 PrintSizeable 使用
    let arr: PrintSizeable = [1, 2, 3]
    arr.printSize()                          // size = 3

    // 泛型扩展 + 条件能力：EqInt 都实现 Eq，Pair 可用 equals
    let pa = Pair<EqInt, EqInt>(EqInt(1), EqInt(2))
    let pb = Pair<EqInt, EqInt>(EqInt(1), EqInt(2))
    println("pair equals = ${pa.equals(pb)}") // true

    // 同包多次扩展互相调用
    let c = Counter()
    c.bumpTwice()
    println("counter = ${c.count}")          // 2

    return 0
}
```

预期输出：

```text
shout = 仓颉!!!
lenSq = 25
v3 = (4, 5)
scaled = (6, 6)
size = 3
pair equals = true
counter = 2
```

## 10. 语言对比

| 维度 | 仓颉 extend | Kotlin extension | Swift extension | Rust impl |
|---|---|---|---|---|
| 语法 | `extend 类型 { ... }` | `fun 类型.方法()` | `extension 类型 { ... }` | `impl 类型 { ... }` |
| 能否加存储属性/成员变量 | **不能** | 不能 | 只能加计算属性，存储不能 | 只能加方法，存储不能 |
| 能否实现别的包的接口 | 受**孤儿规则**限制 | — | 允许 | 允许（同 crate 或类型定义方所在 crate） |
| 能否操作符重载 | 可以（同 `operator func` 语法） | 运算符函数 | 可以（`static func +`） | Trait 里的操作符 |
| 能否带约束的条件式扩展 | 可以（`extend<T1,T2> Pair<T1,T2> where ...`） | — | `extension ... where ...` | `impl<T: Bound>` |
| `this` 关键字 | 用 `this` | `this`（或省略） | `self` | `self` |
| 同类型多次扩展 | 允许，非 private 互相可见 | 允许（不同文件均可） | 允许 | 同一 crate 内允许多个 `impl` 块 |

**从 Kotlin/Swift 迁移**：仓颉 `extend` 语义上更像 Swift `extension`——可以补方法、属性（计算）、操作符、接口实现，但不能补存储。注意**扩展本身不能有可见性修饰符**（Kotlin/Swift 都可以在 `extension`/顶层函数前放 `public`）。
**从 Rust 迁移**：Rust 的 `impl Trait for Type` 天然带"同 crate"约束；仓颉通过**孤儿规则**做了类似限制，但把"包"作为最小判定单位。

## 11. 常见问题（FAQ）

### Q1: 扩展能给类型加变量吗？

不能。成员变量只能由类型本体定义。cjc 会报 `unexpected variable declaration in extend body`。

### Q2: `extend A` 前面能写 `public` 吗？

**不能**。扩展**本身**不能被任何访问修饰符修饰；`public` 只能加到扩展**成员**上。

### Q3: 扩展能重写父类方法吗？

不能。扩展**不在**任何继承链上，既不能用 `super`，也不能用 `override` / `open` / `redef`。

### Q4: 同一类型可以扩展多次吗？

可以，只要**在同一包内**。而且非 `private` 的扩展成员彼此可以直接调用；但不能遮盖同名的类型成员或其他扩展成员。

### Q5: 使用扩展要 `import` 它吗？

**不需要显式 `import` 扩展**。导入被扩展类型即可（接口扩展还要一并导入接口与泛型约束用到的类型）。

### Q6: 泛型扩展里的 `where` 约束有什么妙用？

**条件能力**：`extend<T1,T2> Pair<T1,T2> where T1 <: Eq<T1>, T2 <: Eq<T2>` 里的 `equals`，只有当 `Pair` 的两个实参类型都实现 `Eq` 时才可访问，不满足就像"根本没这个方法"。

### Q7: 孤儿规则是什么？

`package c` 里 `extend package a 的 Foo <: package b 的 Bar` 是**禁止**的——接口扩展必须放在**接口所在包**或**被扩展类型所在包**里。

## 12. 总结

1. **扩展 = 不改原类型也能加功能**：成员函数、成员属性、操作符重载、接口实现四类；**函数、元组、接口不能被扩展**。
2. **两类扩展**：**直接扩展**（不带接口）和**接口扩展**（`extend 类型 <: 接口`）。
3. **泛型扩展**：可写"实例化好的类型"（要求实参满足约束），也可 `extend<T> MyType<T>` 形式；形参必须在被扩展类型中出现。
4. **条件能力**：给泛型扩展加 `where` 约束，扩展成员只在实参满足约束时可见——是仓颉表达"能力随类型出现"的核心手法。
5. **接口扩展** 允许一次实现多个接口（`&` 连接）；父子接口默认实现按"先父后子"检查，冲突时报 `unable to decide ...` 或 `multiple default implementations`。
6. **访问规则**：扩展可用 `this`、不能用 `super`；不能访问被扩展类型的 `private` 成员；不能遮盖原成员或其他扩展成员；同包多次扩展的非 `private` 成员互相可见。
7. **修饰符**：扩展本身**不能有修饰符**；成员可用 `public/protected/internal/private/static/mut`（`mut` 只对 struct 扩展有效），**不能用 `open/override/redef`**。
8. **孤儿规则**：接口扩展必须放在被扩展类型所在包或接口所在包，不允许第三方"包"里的孤儿扩展。
9. **导入导出**：使用扩展不需要 `import` 扩展；只要导入被扩展类型（接口扩展还要一并导入接口和约束用到的类型）即可。

## 参考资料

1. 仓颉 1.0.5 LTS 扩展概述：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/extension/extend_overview.html
2. 仓颉 1.0.5 LTS 直接扩展：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/extension/direct_extension.html
3. 仓颉 1.0.5 LTS 接口扩展：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/extension/interface_extension.html
4. 仓颉 1.0.5 LTS 访问规则：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/extension/access_rules.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
