# 仓颉反射、注解与动态特性

> **摘要**: 反射让程序在**运行时**获知类型信息、枚举并调用其成员；注解（编译标记）则给类型/成员附上元数据，供反射读取或改变编译期行为。仓颉 1.0.5 的反射由 `std.reflect` 提供，核心类型是 `TypeInfo`（配合 `ClassTypeInfo`、`PrimitiveTypeInfo`、`ParameterInfo` 等）；注解分**内置编译标记**（整数溢出策略 `@OverflowThrowing/Wrapping/Saturating`、测试 mock 的 `@EnsurePreparedToMock`）和**自定义注解**（`@Annotation` 修饰的类 + `const init`）。本文依据仓颉 1.0.5 LTS 官方 `reflect_and_annotation` 两章，讲清 `TypeInfo` 的三种获取方式、反射读写成员、只能访问 `public` 的限制、`TypeInfo.get` 的完全限定名规则、三种溢出策略、自定义注解与 `findAnnotation`。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已完成《class 类类型》《接口、属性与子类型》《enum 枚举类型》（`Option`）《泛型编程》
- 已了解 `const`/编译期求值概念（自定义注解要求 `const init`）

> 关于本地验证：本文示例 `import std.reflect`。官方 1.0.5 标准库**含 `std.reflect`**（已在其 Linux SDK 中确认存在并能编译运行）；个别 macOS 机器上的 1.0.5 开发环境可能因系统升级导致 SDK 不完整而缺少该包。故反射示例的编译与运行**以 Linux CI 为准**（项目的"远程运行结果是可运行性唯一事实来源"原则）。

## 1. 反射是什么、什么时候用

反射是"程序访问/检测/修改自身类型与成员"的机制。优点：

- 提升程序灵活性与扩展性；
- 运行时获知对象类型，对其成员做枚举、调用；
- 允许运行时创建，不必提前硬编码。

但**反射调用的性能通常低于直接调用**，所以它主要用于框架这类对灵活性/扩展性要求高的系统，日常业务代码别滥用。

## 2. 获取 TypeInfo

`TypeInfo` 记录任意类型的类型信息，并提供获取信息、设置值等方法。配套还有 `ClassTypeInfo`、`PrimitiveTypeInfo`、`ParameterInfo` 等。用三种静态 `of` 方法构造：

```cangjie
public class TypeInfo {
    public static func of(a: Any): TypeInfo
    public static func of(a: Object): ClassTypeInfo
    public static func<T>(): TypeInfo
}
```

- `of(实例)`：得到该实例的**运行时**类型信息；
- `of<T>()`：得到传入类型的**静态**类型信息。两者信息内容相同，但不保证是同一对象。

```cangjie
import std.reflect.*
class Foo {}
main() {
    let a: Foo = Foo()
    println(TypeInfo.of(a))      // default.Foo
    println(TypeInfo.of<Foo>())  // default.Foo
}
```

### 2.1 `TypeInfo.get(名字)` 按名查类型

```cangjie
public class TypeInfo {
    public static func get(qualifiedName: String): TypeInfo
}
```

- 普通类型需符合 **`module.package.type`** 完全限定名，例如 `"default.Foo"`、`"std.socket.TcpSocket"`。
- **编译器预导入类型**（`core` 里的类型与内置类型，如 `Int64`、`Option`、`Iterable`）**直接写类型名、不带前缀**，例如 `TypeInfo.get("Int64")`。
- 运行时查不到对应类型实例 → 抛 `InfoNotFoundException`。
- **无法获取未实例化的泛型类型**：`TypeInfo.get("default.A<Int64>")` 只有当 `A<Int64>` 已被实例化（程序里真正用过）才查得到，否则抛 `InfoNotFoundException`。

## 3. 用反射访问成员

拿到 `TypeInfo` 后就能访问对应类的实例/静态成员。子类 `ClassTypeInfo` 还提供访问公开构造函数、成员变量、属性、函数的接口。

> **⚠️ 关键限制：反射只能访问 `public` 成员**——`private` 与 `protected` 修饰的成员在反射中不可见。

### 3.1 读写成员变量

```cangjie
import std.reflect.*
public class Foo {
    public static var param1 = 20
    public var param2 = 10
}

main() {
    let obj = Foo()
    let info = TypeInfo.of(obj)
    let sv = info.getStaticVariable("param1")
    let iv = info.getInstanceVariable("param2")
    println((sv.getValue() as Int64).getOrThrow())        // 20
    println((iv.getValue(obj) as Int64).getOrThrow())     // 10
    sv.setValue(8)
    iv.setValue(obj, 25)
    println((iv.getValue(obj) as Int64).getOrThrow())     // 25
}
```

`getValue()`（静态）/ `getValue(obj)`（实例）返回的是可空装箱值，故常写 `as Int64).getOrThrow()`。

### 3.2 读写属性

`instanceProperties`（可 `toArray()`）枚举实例属性，`getInstanceProperty("p1")` 取某个 `PropertyInfo`，用 `isMutable()` 判断能否 `setValue`：只读 `prop` 改不动，`mut prop` 可改。

### 3.3 反射调用函数

```cangjie
public class Foo {
    public static func f1(v0: Int64, v1: Int64): Int64 { v0 + v1 }
}
main() {
    let intInfo = TypeInfo.of<Int64>()
    // 按参数类型定位到具体重载
    let funcInfo = TypeInfo.of<Foo>().getStaticFunction("f1", intInfo, intInfo)
    let num = (funcInfo.apply(TypeInfo.of<Foo>(), [1, 1]) as Int64).getOrThrow()
    println(num)   // 2
}
```

`getStaticFunction(名字, 形参类型...)` 用形参类型消歧；`apply(实例或类型, 实参数组)` 执行调用。

## 4. 注解总览

仓颉提供内置编译标记处理特殊情况，并允许自定义注解给反射读取。

## 5. 内置编译标记：整数溢出策略

三个内置标记控制整数运算/整型转换的溢出策略，**当前只能标注在函数声明上**，作用于函数体内：

| 标记 | 策略 | 溢出行为 |
|---|---|---|
| `@OverflowThrowing` | 抛异常（**默认**） | 抛出（编译期可检出的溢出会直接编译报错） |
| `@OverflowWrapping` | 高位截断 | 丢弃超出目标位宽的高位 |
| `@OverflowSaturating` | 饱和 | 取目标类型的最小/最大极值 |

**默认（不加标记）即 `@OverflowThrowing`。**

- **Wrapping 示例**：`Int8` 下 `105 * 4 = 420`，二进制 `1 1010 0100` 超出 8 位，截断为 `1010 0100`，即有符号 **-92**。
- **Saturating 示例**：`Int8` 下 `-100 - 45 = -145` 下溢，取最小值 **-128**；`Int8(1024)` 上溢，取最大值 **127**。
- **Throwing + 编译期可检出**：`@OverflowThrowing main(){ let x: Int8 = Int8(100) + Int8(29) }` 会被编译器直接判定溢出报错。

> **✅ 什么时候用哪个**：要"结果必须与数学值一致"就用 **Throwing**（溢出即抛 `ArithmeticException`，可被捕获）；要"允许环绕"（如哈希、位打包）才用 Wrapping；要"钉到边界"用 Saturating。反例：安全运算却写成 `@OverflowWrapping`，会静默截断得到错误结果。

**哪些操作会触发整数溢出**（官方表，节选）：算术 `+ - * / **`、自增 `++`、自减 `--`、移位 `<<`、复合赋值里对应的 `+= -= *= /= **= <<= ...` **可能**溢出；而 `%`、位运算 `! & | ^`、关系/判等、普通赋值 `=` **不**引发溢出。

## 6. 内置编译标记：测试 mock

`@EnsurePreparedToMock` 用于测试框架 mock **静态/顶级声明**时，指示编译器预先准备被 mock 目标。约束（官方）：只能用在 lambda 上、且该 lambda 最后一个表达式是对**顶级函数/变量、静态函数/属性/字段、foreign 声明**的调用/成员访问/引用；需配合 `--test`/`--test-only` 与 `--mock=on`/`--mock=runtime-error` 编译。日常应通过 `std.unittest.mock` 的标准接口间接使用，而非直接写这个注解。

## 7. 自定义注解

自定义注解让**反射**读取标注内容，给类型元数据之外补充信息。规则：

- 用 `@Annotation` 修饰一个 **`class`**（该类不能是 `abstract`/`open`/`sealed`）来定义注解。
- 该 `class` **必须至少提供一个 `const init`**，否则编译报错（注解要在编译期构造出实例）。

```cangjie
package pkg
import std.reflect.TypeInfo

@Annotation
public class Version {
    let code: String
    const init(code: String) { this.code = code }
}

@Version["1.0"] class A {}
@Version["1.1"] class B {}

main() {
    for (obj in [A(), B()]) {
        let annOpt = TypeInfo.of(obj).findAnnotation<Version>()
        if (let Some(ann) <- annOpt) {
            println(ann.code)     // 1.0 然后 1.1
        }
    }
}
```

- **使用形态**：`@Version["1.0"]`，`[]` 里按顺序或命名传参，参数必须是 **const 表达式**。
- 有**无参 `const init`** 的注解，可写 `@Marked` 或 `@Marked[]`（省略中括号）。
- **同一目标上同一注解类不可重复标注**（`@Marked` 写两次 → 报错）。
- **注解不被继承**：`B <: A`，即使 `A` 带 `@Marked`，`B` 也不自带，需要时用反射自行查父类。
- `findAnnotation<T>()` 返回 `Option<T>`。

### 7.1 用 `target` 限定注解可用位置

定义 `@Annotation` 时传 `target: Array<AnnotationKind>` 可限制其使用位置；不写则所有位置可用。`AnnotationKind` 是标准库 `enum`：

```cangjie
public enum AnnotationKind {
    | Type | Parameter | Init | MemberProperty | MemberFunction | MemberVariable
}
```

例如 `@Annotation[target: [MemberFunction]]` 的注解只能标成员函数，标到类型上编译报错。自定义注解可用于类型声明、参数、构造函数、成员函数、成员变量、成员属性声明。

> 另外，**编译期求值/`const`** 相关（注解参数必须是 const 表达式）在《const 函数与常量求值》专题展开。

## 8. 完整可运行示例

下例覆盖：`TypeInfo.of` 取类型、反射读写实例成员、自定义注解 `@Version` + `findAnnotation`、`@OverflowWrapping` 溢出截断。

<!-- example: cangjie/033-reflect-annotation.cj -->
```cangjie
// 反射、注解与动态特性示例（基于 1.0.5 标准库 std.reflect）
// 演示：TypeInfo 获取（of/泛型 of/get）、反射读写实例成员、
// 自定义注解 @Annotation + const init + findAnnotation 读取、
// 编译期整数溢出注解 @OverflowWrapping。
//
// 注意：本文件 import std.reflect，本地 macOS(1.0.5) SDK 缺该包会被
// tools/test-local.sh 跳过；真正的编译与运行以 Linux CI 为准。

import std.reflect.*

// ---- 自定义注解：@Annotation 修饰的 class，必须提供至少一个 const init ----
@Annotation
public class Version {
    let code: String
    const init(code: String) {
        this.code = code
    }
}

@Version["1.0"] class A {}

@Version["1.1"] class B {}

// ---- 反射读写成员用的普通类（成员需 public 才可见）----
public class Account {
    public var balance: Int64 = 100
}

// ---- 编译期整数溢出策略注解（编译器内置，不依赖 std.reflect）----
// Wrapping：溢出后高位截断。Int8 下 105 + 105 = 210 -> 截断为 -46。
@OverflowWrapping
func addWrap(a: Int8, b: Int8): Int8 {
    a + b
}

main(): Int64 {
    // 1) 运行时类型信息：of 实例 / of<静态类型> 打印的都是类型全名
    let infoA: TypeInfo = TypeInfo.of(A())
    println("type of A = ${infoA}")           // type of A = default.A

    // 2) 反射读取自定义注解（顺序无关，A、B 各一条）
    for (o in [A(), B()]) {
        if (let Some(v) <- TypeInfo.of(o).findAnnotation<Version>()) {
            println("version = ${v.code}")     // version = 1.0 / version = 1.1
        }
    }

    // 3) 反射访问并修改实例成员变量
    let acc = Account()
    let field = TypeInfo.of(acc).getInstanceVariable("balance")
    println("balance = ${(field.getValue(acc) as Int64).getOrThrow()}")   // balance = 100
    field.setValue(acc, 250)
    println("balance after = ${(field.getValue(acc) as Int64).getOrThrow()}")  // balance after = 250

    // 4) 整数溢出：Wrapping 高位截断
    println("wrap 105+105(Int8) = ${addWrap(105, 105)}")   // wrap 105+105(Int8) = -46

    return 0
}
```

预期输出：

```text
type of A = default.A
version = 1.0
version = 1.1
balance = 100
balance after = 250
wrap 105+105(Int8) = -46
```

## 9. 语言对比

| 维度 | 仓颉 | Java | Kotlin | Rust |
|---|---|---|---|---|
| 类型信息入口 | `TypeInfo.of`/`of<T>`/`get(名字)` | `Class<T>`/`getClass()`/`Class.forName` | `KClass`/`typeOf<T>()`/`KType` | `TypeId`/`Any::type_id`（有限） |
| 反射成员访问 | `getStaticVariable`/`getInstanceVariable`/`getStaticFunction`+`apply` | `Field`/`Method` | `kotlin.reflect` 成员 API | 无标准反射（靠宏/库） |
| 可见性约束 | 只能反射 **public** 成员 | `setAccessible` 可破 private | 类似可破 | — |
| 注解定义 | `@Annotation` 修饰 class + `const init` | `@interface` | `annotation class` | 过程宏 attribute |
| 读取注解 | `findAnnotation<T>(): Option<T>` | `getAnnotation` | `findAnnotation<T>()` | 宏参数 |
| 注解作用域 | `target: [AnnotationKind]` 限定 | `@Target` | `@Target` | — |
| 编译期元编程标记 | `@Overflow*`、`@EnsurePreparedToMock` | — | — | — |

**从 Java 迁移**：`TypeInfo`↔`Class`、`findAnnotation`↔`getAnnotation`、`@Annotation class`↔`@interface`；但**仓颉反射只能看 public**，不像 Java 能 `setAccessible(true)` 破封装——这更安全，也更受限。
**从 Rust 迁移**：Rust 几乎没有运行时反射，靠过程宏在编译期生成代码；仓颉两者都有（`std.reflect` 反射 + 宏 + 注解）。

## 10. 常见问题（FAQ）

### Q1: 反射和直接调用比，代价在哪？

反射在运行时查类型、装箱/拆箱参数，性能低于直接调用。它适合框架、序列化、调试等对灵活性要求高的场景，不适合热路径。

### Q2: `TypeInfo.of(a)` 和 `TypeInfo.of<T>()` 一样吗？

内容一致（前者用 a 的运行时类型、后者用静态类型 T），但不保证返回同一对象。

### Q3: `TypeInfo.get("Int64")` 为什么不带包名？

`core` 类型与编译器内置类型（含 `Option`、`Iterable` 等）用**裸类型名**查；其它类型才用 `module.package.type` 完全限定名。查不到抛 `InfoNotFoundException`。

### Q4: 能反射读 private/protected 成员吗？

不能。仓颉反射只能访问 **public** 成员，`private`/`protected` 在反射里不可见。

### Q5: 自定义注解为什么必须 `const init`？

注解实例要在**编译期**生成并绑定到类型上，所以必须有一个 `const init`；`[]` 里的参数也必须是 const 表达式。

### Q6: `@Version` 标在父类，子类 `@findAnnotation` 能拿到吗？

不能。注解**不被继承**，类型的注解只来自它自己声明的那份；要父类注解得自己用反射显式查。

### Q7: `Int8(105)+Int8(105)` 会怎样？

看函数上的溢出标记：`@OverflowThrowing`（默认）溢出抛 `ArithmeticException`；`@OverflowWrapping` 截断成 `-46`；`@OverflowSaturating` 取到 `Int8.Max`（127）。

### Q8: 我在 mac 上 `import std.reflect` 报找不到包？

那是你本地 mac 的 1.0.5 SDK 不完整（本教程环境即如此）。`std.reflect` 是 1.0.5 标准库正式成员；在完整的官方 SDK（含 CI 的 Linux 版）里可正常编译运行。

## 11. 总结

1. 反射让程序运行时获知/操作自身类型与成员，灵活但**慢于直接调用**，主要用于框架；核心类型 **`TypeInfo`**（及 `ClassTypeInfo` 等）。
2. `TypeInfo` 三种获取：`of(实例)`（运行时）、`of<T>()`（静态）、`get("完全限定名")`（`core`/内置类型用裸名，查不到抛 `InfoNotFoundException`，未实例化泛型取不到）。
3. 反射可读写静态/实例成员变量、属性、调用函数（`getStaticVariable`/`getInstanceVariable`/`instanceProperties`/`getInstanceProperty`/`getStaticFunction`+`apply`）；**只能访问 public 成员**。
4. **内置编译标记**：`@OverflowThrowing`(默认)/`@OverflowWrapping`/`@OverflowSaturating` 控制整数溢出，只标函数声明、作用于体内；测试 mock 用 `@EnsurePreparedToMock`（一般经标准库间接使用）。
5. **自定义注解**：`@Annotation` 修饰的 class + 至少一个 `const init`；`@Name[const参数]` 使用、无参可省 `[]`；同目标不可重复；**不被继承**；`target: [AnnotationKind]` 限定可用位置；`findAnnotation<T>(): Option<T>` 读取。

## 参考资料

1. 仓颉 1.0.5 LTS 动态特性（反射）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/reflect_and_annotation/dynamic_feature.html
2. 仓颉 1.0.5 LTS 注解：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/reflect_and_annotation/anno.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
