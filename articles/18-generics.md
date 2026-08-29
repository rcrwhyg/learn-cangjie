# 仓颉泛型编程

> **摘要**: 泛型（参数化类型）让你在声明时不写死具体类型，而在使用处再指定，`Array<T>`、`Option<T>` 都是它的产物。本文依据仓颉 1.0.5 LTS 官方 generic 章节，系统讲清泛型术语（类型形参/类型变元/类型实参/类型构造器）、泛型函数（含 `where` 约束）、泛型 class / struct / enum / interface、泛型成员函数与静态泛型函数、泛型类型构造器的**不变性**、静态成员不能引用类型形参的限制，以及类型别名与泛型别名。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已完成《struct》《class》《接口、属性与子类型》《enum》《函数类型、Lambda 与闭包》
- 已了解 `Option<T>`、`Array<T>`、`ArrayList<T>`、`<:`（子类型）、`where` 约束

> 泛型 `extend`（给已有类型扩展泛型成员）与扩展机制本篇只带到，细节留给《扩展机制》专题。

## 1. 泛型术语

泛型指**参数化类型**：声明时类型未知，使用时才指定。`function`、`class`、`interface`、`struct`、`enum` 的声明**都可以带类型形参**（都可以是泛型的）。类型形参写在名字后用 `<>` 括起，多个用 `,` 分隔。

```cangjie
class List<T> {
    var elem: Option<T> = None
    var tail: Option<List<T>> = None
}
func sumInt(a: List<Int64>) { }
```

官方定义了四个术语，务必分清：

| 术语 | 含义 | 上例中的例子 |
|---|---|---|
| **类型形参** | 声明处待定的类型（带标识符） | `List<T>` 里的 `T` |
| **类型变元** | 声明体中对该形参的引用 | `Option<T>`、`List<T>` 里的 `T` |
| **类型实参** | 使用处指定的具体类型 | `List<Int64>` 里的 `Int64` |
| **类型构造器** | 需要 0 或多个类型实参才能成为类型 | `List`（`List<Int64>` 才是完整类型） |

## 2. 泛型函数

### 2.1 全局泛型函数

类型形参紧跟函数名：

```cangjie
func id<T>(a: T): T {
    return a
}
```

可以有多个类型形参，也能把函数类型作为参数。下面这个 `composition` 声明了 3 个类型形参，把 `f: (T1)->T2` 和 `g: (T2)->T3` 复合成 `(T1)->T3`：

```cangjie
func composition<T1, T2, T3>(f: (T1) -> T2, g: (T2) -> T3): (T1) -> T3 {
    return { x: T1 => g(f(x)) }
}
```

调用时可显式给出类型实参 `composition<Int64, Int64, Int64>(times2, plus10)`。

### 2.2 局部泛型函数

局部（嵌套）函数也可以是泛型的，在其外层函数体内定义、使用。

### 2.3 泛型成员函数

`class` / `struct` / `enum` 的成员函数可以带**自己的**类型形参（与所属类型的形参相互独立）：

```cangjie
class A {
    func foo<T>(a: T): Unit where T <: ToString {
        println("${a}")
    }
}
```

`extend` 里也能定义泛型成员函数（细节见《扩展机制》）。

### 2.4 静态泛型函数

`interface` / `class` / `struct` / `enum` / `extend` 中可定义**静态泛型函数**：

```cangjie
import std.collection.ArrayList

class ToPair {
    public static func fromArray<T>(l: ArrayList<T>): (T, T) {
        (l[0], l[1])
    }
}
```

## 3. `where` 泛型约束

一个**无约束**的泛型形参 `T`，你只能"透传"它——不能 `a + 1`、不能 `println(a)`，因为 `T` 可能是任意类型。要"用"它，就得加约束。约束写在声明体之前，用 `where` 引入。

### 3.1 接口约束

```cangjie
func genericPrint<T>(a: T) where T <: ToString {
    println(a)
}
```

同一类型变元的多个接口约束用 `&` 连接：`where T <: Interface1 & Interface2`。若类型实参不满足约束，编译器报错：

```cangjie
genericPrint<(Int64) -> Int64>({ i => 0 })   // 报错：函数类型不满足 T <: ToString
```

cjc 实测报 `generics type arguments do not match the constraint`。

### 3.2 class 类型约束

约束也可以是"class 子类型"：

```cangjie
abstract class Animal { public func run(): String }
class Dog <: Animal { public func run(): String { "dog run" } }

class Zoo<T> where T <: Animal {
    // 可以对 T 实例调用 Animal 的 run()
}
```

> **⚠️ 注意（官方硬性规则）：**
> 1. 泛型变元的约束**只能是具体的 class 类型或 interface**。
> 2. 一个变元若有**多个 class 类型上界**，它们**必须在同一条继承链上**。
>
> 实测：`where T <: A & B`（A、B 无继承关系）报 `generic parameter 'T' cannot have two or more class upper bounds ... without subtype relation`；若 B `<: A` 则通过。

## 4. 泛型 class / struct / enum / interface

### 4.1 泛型类

```cangjie
open class Node<K, V> where K <: Hashable & Equatable<K> {
    var key: Option<K> = Option<K>.None
    var value: Option<V> = Option<V>.None
    init() {}
    init(key: K, value: V) {
        this.key = Option<K>.Some(key)
        this.value = Option<V>.Some(value)
    }
}
```

**静态成员不能引用类型形参**——因为泛型类的静态成员在所有实例化之间共享内存：

```cangjie
class B<T> {
    static var err1: B<T> = B<T>()   // 报错：static member cannot depend on generic parameter
    static var ok: Int64 = 1         // 正确：不引用 T
}
```

而且这份 `ok` 在 `B<Int32>` 与 `B<Int64>` 之间**是同一块内存**：`B<Int32>.ok = 2` 之后 `B<Int64>.ok` 读到的就是 `2`（示例中已验证）。此外，静态成员变量的初始化表达式里**不能调用泛型类的静态成员函数**（会隐式引用到类型形参）。

### 4.2 泛型结构体

与 class 类似：

```cangjie
struct Pair<T, U> {
    let x: T
    let y: U
    public init(a: T, b: U) { x = a; y = b }
    public func first(): T { x }
    public func second(): U { y }
}
```

### 4.3 泛型枚举

标准库的 `Option<T>` 就是泛型 enum 的经典：

```cangjie
public enum Option<T> {
    Some(T) | None
    public func getOrThrow(): T { ... }
}
```

用它可以写出"不抛异常的安全除法"：

```cangjie
func safeDiv(a: Int64, b: Int64): Option<Int64> {
    match (b) {
        case 0 => None
        case _ => Some(a / b)
    }
}
```

### 4.4 泛型接口

标准库 `Iterable` / `Iterator` / `Collection` 都是泛型接口：

```cangjie
public interface Iterable<E> {
    func iterator(): Iterator<E>
}
public interface Collection<T> <: Iterable<T> {
    prop size: Int64
    func isEmpty(): Bool
}
```

## 5. 泛型类型构造器的不变性

这是从 Java/C++ 迁移最容易踩的认知差。实例化后的泛型类型之间也有子类型关系，但**仓颉中用户自定义的泛型类型在其类型变元处是"不型变"（invariant）的**：

给定 `interface I<X>`，只有当 `A = B` 时，才有 `I<A> <: I<B>`。

```cangjie
open class C {}
class D <: C {}
interface I<X> {}
// 即使 D <: C 成立，I<D> <: I<C> 也不成立。
```

三种型变定义（了解即可）：

- **不型变**：`T(A) <: T(B)` 当且仅当 `A = B`。
- **协变**：`T(A) <: T(B)` 当且仅当 `A <: B`。
- **逆变**：`T(A) <: T(B)` 当且仅当 `B <: A`。

**内建类型是例外**：元组类型对每个元素类型**协变**；函数类型在入参处**逆变**、在返回类型处**协变**。

```cangjie
open class C {}
class D <: C {}
let t: (C, C) = (D(), D())          // OK：元组元素协变
let f: (C) -> D = { c => D() }
let g: (D) -> C = f                  // OK：入参逆变 + 返回协变
```

> **💡 提示**：不型变牺牲了一点表达力，但换来了类型安全——它天然规避了"协变数组在运行时抛元素类型异常"的经典陷阱。想表达"某容器能装 `Animal` 的一切子类型"，仓颉的做法不是 `Container<Animal>`，而是给变元加约束、或用接口/上界通配的思想另行设计。

> **⚠️ 注意**：官方补充——`class` **以外**的类型实现某接口，该类型与该接口间的子类型关系**不能**作为协变/逆变的依据。

## 6. 类型别名

用 `type 别名 = 原类型` 给复杂/不直观的类型换个名字：

```cangjie
type I64 = Int64
```

**规则**（均经 cjc 实测）：

- **只能在源文件顶层**定义，`main` 里写 `type I64 = Int64` 会报 `unexpected type alias declaration in main function body`。
- 原类型必须在别名定义处**可见**（引用未定义类型报错）。
- **禁止直接或间接循环引用**：`type A = (Int64, A)` 报 `refered itself`。
- 别名**不产生新类型**，只是原类型的另一个名字。

别名可用于：① 作类型；② 指向 class/struct 时**作构造器名**（`type A = B` 后可 `A()`）；③ 指向 class/interface/struct 时**作访问静态成员的类型名**（`A.foo()`）；④ 指向 enum 时**作构造器的类型名**（`type Time = TimeUnit` 后 `Time.Day`）。

> **⚠️ 注意**：自定义类型别名**暂不支持用在类型转换表达式**里——`type MyInt = Int32` 后 `MyInt(0)` 报 `no matching function for operator '()'`（因为它被当函数调用而非类型转换）。

### 6.1 泛型别名

类型别名也能带类型形参，但**不能对形参写 `where` 约束**：

```cangjie
struct RecordData<T> { var a: T; public init(x: T) { a = x } }
type RD<T> = RecordData<T>          // RD<Int32> 代指 RecordData<Int32>
```

## 7. 完整可运行示例

下例串起：泛型函数（无约束 / `where ToString` 约束 / 多形参组合）、泛型 struct/class/enum、泛型成员函数与静态泛型函数、泛型接口、泛型不变性（只能用严格相同实参）、类型别名与泛型别名。

<!-- example: cangjie/023-generics.cj -->
```cangjie
// 泛型编程示例
// 演示：泛型函数（无约束 + where 约束）、泛型 class/struct/enum、泛型成员函数与
// 静态泛型函数、泛型接口、类型别名（含泛型别名）与泛型类型构造器的不变性

import std.collection.ArrayList

// ========== 1) 泛型函数 ==========

// 1.1 无约束泛型：只透传，不做任何类型相关操作
func id<T>(a: T): T {
    a
}

// 1.2 接口约束：需要 ToString 才能打印
func showAny<T>(a: T) where T <: ToString {
    println("showAny: ${a}")
}

// 1.3 多类型形参 + 函数类型作为参数（组合）
func compose<T1, T2, T3>(f: (T1) -> T2, g: (T2) -> T3): (T1) -> T3 {
    return { x: T1 => g(f(x)) }
}

func times2(a: Int64): Int64 { a * 2 }
func plus10(a: Int64): Int64 { a + 10 }

// ========== 2) 泛型 struct / class / enum ==========

struct Pair<T, U> {
    let x: T
    let y: U
    public init(a: T, b: U) {
        x = a
        y = b
    }
    public func first(): T { x }
    public func second(): U { y }
}

class Stack<T> {
    private var items: ArrayList<T> = ArrayList<T>()
    public func push(v: T) {
        items.add(v)
    }
    public func pop(): Option<T> {
        if (items.isEmpty()) {
            return None
        }
        let v = items.remove(at: items.size - 1)
        Some(v)
    }
    public func size(): Int64 { items.size }
}

enum MyOption<T> {
    | SomeVal(T)
    | Empty

    public func getOrDefault(default: T): T {
        match (this) {
            case SomeVal(v) => v
            case Empty => default
        }
    }
}

// ========== 3) 泛型接口 + 泛型成员函数 + 静态泛型函数 ==========

interface Describable<T> {
    func describe(x: T): String
}

class IntDescriber <: Describable<Int64> {
    public func describe(x: Int64): String { "int:${x}" }
}

class Box<T> {
    public var content: T
    public init(c: T) { content = c }

    // 成员函数也可以再声明自己独立的类型形参
    public func mapInto<U>(f: (T) -> U): U {
        f(content)
    }

    // 静态泛型函数
    public static func singleton(v: T): Box<T> {
        Box<T>(v)
    }
}

// ========== 4) 泛型不变性演示 ==========

open class Animal {
    public init() {}
    public open func speak(): String { "animal" }
}
class Dog <: Animal {
    public override func speak(): String { "woof" }
}

interface Container<X> {
    func get(): X
}
class Holder<X> <: Container<X> {
    public var v: X
    public init(v: X) { this.v = v }
    public func get(): X { v }
}

// 只要形参一致，就只接受严格相同实参
func takesAnimalContainer(_: Container<Animal>) {
    println("got a Container<Animal>")
}

// ========== 5) 类型别名（含泛型别名） ==========

type Ints = Array<Int64>
type PairSI = Pair<String, Int64>

// 泛型别名：短一点的写法
type MyStack<T> = Stack<T>

main(): Int64 {
    // 泛型函数：显式类型实参 + 通过变量类型推断
    let n: Int64 = id<Int64>(42)
    println("id(42) = ${n}")
    showAny<Int64>(7)
    showAny<String>("hi")

    let composed = compose<Int64, Int64, Int64>(times2, plus10)
    println("composed(9) = ${composed(9)}")   // (9*2)+10 = 28

    // 泛型 struct
    let p: PairSI = PairSI("hello", 0)
    println("Pair.first=${p.first()} second=${p.second()}")

    // 泛型 class：栈
    let s: MyStack<Int64> = MyStack<Int64>()
    s.push(1)
    s.push(2)
    let popped = s.pop()
    match (popped) {
        case Some(v) => println("pop=${v}, size=${s.size()}")
        case None => println("empty stack")
    }

    // 泛型 enum
    let a: MyOption<Int64> = SomeVal(3)
    let b: MyOption<Int64> = Empty
    println("a=${a.getOrDefault(0)} b=${b.getOrDefault(-1)}")

    // 泛型接口 + 实现
    let d: Describable<Int64> = IntDescriber()
    println("describe = ${d.describe(99)}")

    // 泛型成员函数（U 独立于 Box 的 T）
    let box = Box<Int64>(5)
    let toStr = { x: Int64 => "n=${x}" }
    let shown: String = box.mapInto<String>(toStr)
    println("box.mapInto = ${shown}")   // n=5

    // 静态泛型函数（与类同类型形参）
    let sb = Box<Int64>.singleton(100)
    println("singleton content = ${sb.content}")

    // 泛型不变性：把 Holder<Dog> 传给 Container<Animal> 会编译报错，
    // 所以此处只能构造严格 Holder<Animal> 传入。
    let hc: Container<Animal> = Holder<Animal>(Animal())
    takesAnimalContainer(hc)
    println("hc.get().speak() = ${hc.get().speak()}")

    // 类型别名
    let nums: Ints = [1, 2, 3]
    println("nums.size = ${nums.size}")

    return 0
}
```

预期输出：

```text
id(42) = 42
showAny: 7
showAny: hi
composed(9) = 28
Pair.first=hello second=0
pop=2, size=1
a=3 b=-1
describe = int:99
box.mapInto = n=5
singleton content = 100
got a Container<Animal>
hc.get().speak() = animal
nums.size = 3
```

## 8. 语言对比

| 维度 | 仓颉 | Java | Kotlin | C++ |
|---|---|---|---|---|
| 泛型可用于 | function/class/interface/struct/enum | 类/接口/方法 | 类/接口/函数 | 函数/类 |
| 约束语法 | `where T <: Iface & Cls`（`<:` 子类型） | `<T extends Bound>` 上界 | `<T : Bound>` | Concepts / SFINAE |
| 多 class 上界 | 允许，但须**同一继承链** | 不支持（`extends` 只能单类） | 一个上界 + 交叉类型 | 模板约束 |
| 类型构造器型变 | 用户类型**不型变**；元组协变、函数逆变/协变 | 泛型默认不型变，靠通配符 `? extends`/`? super` | 声明处 `out`/`in` | 模板实参不型变 |
| 类型别名 | `type X = Y`，顶层，仅重命名 | 无（Java 无 typedef） | `typealias X = Y` | `using X = Y` / `typedef` |
| 别名参与转换 | 不支持 `X(0)` 形式 | — | 一般视为构造 | `X(0)` 可 |

**从 Java 迁移**：仓颉泛型的子类型是"不变"的，`List<Dog>` 不是 `List<Animal>`；Java 靠 `List<? extends Animal>` 表达，仓颉则倾向用**约束**（`where T <: Animal`）或接口来表达，没有通配符 `? extends` 那一套。
**从 Kotlin 迁移**：仓颉没有声明处型变（`out`/`in`）；泛型变元一律不型变，协变/逆变只存在于内建元组与函数类型。

## 9. 常见问题（FAQ）

### Q1: `Array<T>`、`Option<T>` 里的 `T` 是什么角色？

`Array`/`Option` 是**类型构造器**，`T` 是**类型形参**；写 `Array<Int64>` 时 `Int64` 是**类型实参**，`Array<T>` 体内引用的 `T` 是**类型变元**。

### Q2: 无约束的泛型形参能做什么、不能做什么？

只能透传（赋值、返回、作为其它泛型的实参）。不能做 `+`、不能直接 `println`——这些都需要 `where T <: 某接口`。

### Q3: 为什么我的泛型类里 `static var` 引用了 `T` 就报错？

泛型类的静态成员在所有实例化间共享同一块内存，而 `T` 对不同实例化可能不同，语义矛盾，所以官方禁止静态成员的类型/表达式引用类型形参。

### Q4: `Dog <: Animal`，那 `Stack<Dog>` 能当 `Stack<Animal>` 传吗？

不能。用户自定义泛型类型**不型变**，只有实参完全相同才有 `Stack<Dog> <: Stack<Dog>`。要把"能装任意 Animal 子类型"表达出来，请对方法/类型的变元加约束。

### Q5: 元组和函数类型是特例吗？

是。元组对每个元素**协变**；函数类型入参**逆变**、返回**协变**。所以 `(C)->D` 可作为 `(D)->C` 使用。

### Q6: 类型别名算定义了新类型吗？

不算。`type A = B` 里 `A` 只是 `B` 的另一个名字；可用于类型、class/struct 的构造器名、访问静态成员的类型名、enum 构造器的类型名，但**不能用于 `A(x)` 类型转换表达式**。

### Q7: 泛型别名能写约束吗？

不能。`type X<T> = ...` 允许带类型形参，但**不能对形参写 `where` 约束**（官方明确）。

## 10. 总结

1. 泛型 = 参数化类型；**四个术语**（形参/变元/实参/类型构造器）要分清；function/class/interface/struct/enum **都能泛型**。
2. 泛型函数可有多个类型形参、可作局部/成员/静态函数；成员函数的形参与所属类型独立。
3. **`where` 约束**决定泛型形参能用哪些能力：接口约束、class 子类型约束；多接口用 `&`，多 class 上界必须同继承链。
4. 泛型类的**静态成员不能引用类型形参**（共享内存），但静态成员**在所有实例化间是同一块内存**。
5. 用户自定义泛型类型**不型变**（`I<D>` 不是 `I<C>`）；**内建元组协变、函数入参逆变/返回协变**是例外。
6. **类型别名** `type X = Y` 仅顶层、不可循环引用、不产生新类型；可做构造器名/静态访问名/enum 构造器名，但不能做 `X(0)` 类型转换；泛型别名不能写 `where`。

## 参考资料

1. 仓颉 1.0.5 LTS 泛型概述：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/generic/generic_overview.html
2. 仓颉 1.0.5 LTS 泛型函数：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/generic/generic_function.html
3. 仓颉 1.0.5 LTS 泛型接口：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/generic/generic_interface.html
4. 仓颉 1.0.5 LTS 泛型类：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/generic/generic_class.html
5. 仓颉 1.0.5 LTS 泛型结构体：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/generic/generic_struct.html
6. 仓颉 1.0.5 LTS 泛型枚举：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/generic/generic_enum.html
7. 仓颉 1.0.5 LTS 泛型类型的子类型关系：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/generic/generic_subtype.html
8. 仓颉 1.0.5 LTS 类型别名：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/generic/typealias.html
9. 仓颉 1.0.5 LTS 泛型约束：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/generic/generic_constraint.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
