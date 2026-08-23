# 仓颉包、模块与程序入口

> **摘要**: 当项目规模扩大，单一文件无法承载所有源代码时，需要把代码按功能拆分到不同文件、不同包乃至不同模块中。本文依据仓颉 1.0.5 LTS 官方文档，系统介绍仓颉的**包（package）**、**模块（module）**、**程序入口（main）** 三大顶层概念，覆盖 `package` 声明、`import` 各种语法、访问修饰符、`main` 函数合法签名，以及 `cjpm` 项目管理工具。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已了解变量、函数、自定义类型（struct / class / enum）
- 已了解字符串、Array、Collection 等常用类型
- 已完成《仓颉结构类型 struct》《仓颉类类型 class》《仓颉 Collection 集合类型》

## 1. 顶层作用域与程序入口

在仓颉中，扩展名为 `.cj` 的源文件里，**不被任何大括号 `{}` 包围的代码**所在的作用域称为**顶层作用域（top-level scope）**。在顶层作用域中，可以定义：

- **全局变量**（`let` / `var` / `const` 修饰）
- **全局函数**（`func` 修饰）
- **自定义类型**（`struct` / `class` / `enum` / `interface`）
- **程序入口**（`main` 函数，详见第 5 节）

> 注意：在自定义类型体内定义的变量和函数，分别称为**成员变量**和**成员函数**，不属于顶层作用域；`enum` 和 `interface` 中仅支持定义成员函数，**不支持成员变量**。

```cangjie
// example.cj — 顶层作用域示例
let a = 2023
func b() { /* 全局函数 */ }
struct C {}
class D {}
enum E { F | G }

main() {
    println(a)
    b()
}
```

## 2. 包（package）

### 2.1 什么是包

> 包是仓颉编程语言中**编译的最小单元**。每个包可以单独输出 AST 文件、静态库文件、动态库文件等产物。

包的关键特性：

- **独立编译**：每个包可单独编译为静态库 / 动态库 / AST 等产物。
- **独立名字空间**：同一个包内**不允许有同名的顶层定义或声明**（函数重载除外）。
- **可包含多个源文件**：一个包可分布在多个 `.cj` 文件中。
- **必须声明**：每个源文件**必须**以 `package` 声明开头（除非没有包声明的特殊场景，例如教学示例）。

### 2.2 package 声明

```cangjie
package demo
```

- `package` 声明必须出现在**源文件的第一行非空行**。
- 同一包名下的多个源文件构成**同一个包**，共享名字空间。
- 子包通过点号分隔：`package a.b.c` 表示 `c` 是 `a.b` 的子包。

### 2.3 访问修饰符

`package` 声明支持 `internal` / `protected` / `public` 三种修饰符，**默认是 public**：

| 修饰符 | 文件 | 包及子包 | 模块 | 所有包 |
|---|---|---|---|---|
| `private` | ✓ | ✗ | ✗ | ✗ |
| `internal`（默认） | ✓ | ✓ | ✗ | ✗ |
| `protected` | ✓ | ✓ | ✓ | ✗ |
| `public`（package 默认） | ✓ | ✓ | ✓ | ✓ |

```cangjie
internal package demo.internal  // 内部包，仅当前包及子包可见
protected package demo.module   // 模块内可见
public package demo.api         // 默认：外部模块也可见
```

### 2.4 顶层声明的可见性

顶层声明（变量、函数、类型）支持 4 种可见性修饰符：

| 修饰符 | 默认（省略时） | 含义 |
|---|---|---|
| `private` | — | 仅当前文件内可见 |
| `internal` | ✓（其他顶层声明的默认） | 仅当前包及子包内可见 |
| `protected` | — | 仅当前模块内可见 |
| `public` | — | 模块内外均可见 |

> **访问级别排序**：`public > protected > internal > private`。一个声明的访问修饰符**不得高于其用到的类型的访问修饰符**。

```cangjie
package a

private func f1(): Int64 { 1 }      // 仅当前文件内可见
func f2(): Int64 { 2 }              // 默认 internal：当前包及子包内可见
protected func f3(): Int64 { 3 }    // 仅当前模块内可见
public func f4(): Int64 { 4 }       // 任何模块都可见
```

完整可运行示例（`examples/cangjie/019-package-module-entry.cj`）：

<!-- example: cangjie/019-package-module-entry.cj -->
```cangjie
// 包、模块与程序入口示例
// 演示：package 声明、import 单个 / 多个 / 通配符 / 重命名、
// 顶层变量与函数的可见性修饰符（public / internal / private / protected）、
// main 入口函数的合法签名（无参数 / Array<String> 参数、Unit / 整数类型返回值）

package demo

// 单个 import：导入 std.collection.ArrayList
import std.collection.ArrayList
// 多个 import：同一包下批量导入
import std.collection.{HashSet, HashMap}
// 通配符 import：导入 std.io 下所有可见声明
// import std.io.*    // 通配符 import：导入 std.io 下所有可见声明（按需启用）
// import as 重命名：解决不同包同名类型冲突
import std.collection.ArrayList as AL

// ========== 1) 顶层声明的可见性 ==========

// public 修饰：模块内外均可见
public let GREETING: String = "Hello, 仓颉"

// 默认（internal）：仅当前包及子包内可见
let packageOnly: String = "仅包内可见"

// private 修饰：仅当前文件内可见（本文件内任意位置可访问）
private let fileOnly: String = "仅当前文件可见"

public func greet(name: String): String {
    "${GREETING}, ${name}"
}

internal func packageFn(): Int64 {
    42
}

protected func moduleFn(): Int64 {
    100
}

// ========== 2) 自定义类型声明 ==========

public struct User {
    public User(public var name: String, public var age: Int64) {}
}

public class Counter {
    public var count: Int64 = 0
    public func inc(): Unit {
        count += 1
    }
}

public enum Color {
    Red | Green | Blue
}

// ========== 3) 隐式 import core 包 ==========

// 下列类型 String / Int64 / Array / Range 无需显式 import 即可使用，
// 因为编译器会自动为源码隐式导入 core 包中所有 public 修饰的声明
func showBuiltin(): Unit {
    let s: String = "隐式导入"
    let n: Int64 = 100
    let arr: Array<Int64> = [1, 2, 3]
    let r: Range<Int64> = 0..5
    println("${s}, ${n}, arr.size=${arr.size}, r=${r.start}..${r.end}")
}

// ========== 4) main 函数（程序入口） ==========

// main 没有参数，返回 Int64
main(): Int64 {
    println("=== main(): Int64 ===")
    println(greet("World"))              // 顶层 public 函数

    let user: User = User("Alice", 30)
    println("${user.name}, ${user.age}")  // 顶层 struct

    let counter: Counter = Counter()
    counter.inc()
    counter.inc()
    println("count = ${counter.count}")

    let c: Color = Color.Red
    let colorName: String = match (c) {
        case Red => "red"
        case Green => "green"
        case Blue => "blue"
    }
    println("color = ${colorName}")     // enum 通过 match 转换

    // 使用 import 导入的集合类型
    let list: ArrayList<Int64> = ArrayList<Int64>([1, 2, 3])
    let set: HashSet<String> = HashSet<String>(["a", "b", "c"])
    let map: HashMap<String, Int64> = HashMap<String, Int64>([("x", 1), ("y", 2)])
    println("list.size = ${list.size}")
    println("set.size  = ${set.size}")
    println("map.size  = ${map.size}")

    // 使用 import as 重命名后的别名
    let list2: AL<Int64> = AL<Int64>([10, 20, 30])
    println("list2.size = ${list2.size}")

    // 调用隐式导入的 builtin
    showBuiltin()
    println("fileOnly = ${fileOnly}")  // private 变量仅当前文件可见

    return 0
}

// 也可写一个无返回值的 main 入口
// main() {
//     println("无返回值的 main")
// }
// 也可写一个接收命令行参数的 main
// main(args: Array<String>): Unit {
//     for (arg in args) {
//         println(arg)
//     }
// }
```

## 3. 模块（module）

> 模块是**若干包的集合**，是第三方开发者**发布的最小单元**。

- 一个模块的程序入口只能在其**根目录**下。
- 模块的顶层最多只能有一个 `main` 函数。
- 仓颉的项目管理工具 `cjpm`（Cangjie Project Manager）以**模块**为单位创建、构建、运行项目。

### 3.1 cjpm 项目结构

```bash
cjpm init                    # 在当前目录初始化项目（要求目录为空或只有配置）
cjpm init --path hello_cjpm  # 自动创建目录并初始化
```

初始化的目录结构：

```
hello_cjpm/
├── cjpm.toml       # 模块的配置文件
└── src/
    └── main.cj     # 默认生成的源码文件
```

默认生成的 `main.cj`：

```cangjie
// main.cj
package hello_cjpm        // 声明当前源文件属于 hello_cjpm 包
main(): Int64 {
    println("hello world")
    return 0
}
```

### 3.2 cjpm.toml

`cjpm.toml` 是模块的清单文件，描述模块名、版本、依赖、构建选项等。最小化的 `cjpm.toml`：

```toml
[package]
name = "hello_cjpm"
version = "0.1.0"
description = "我的第一个仓颉模块"
cjc-version = "1.0.5"

[target]              # 构建目标

[dependencies]        # 依赖的其它模块
```

### 3.3 常用 cjpm 命令

| 命令 | 作用 |
|---|---|
| `cjpm init` | 在当前目录初始化一个模块 |
| `cjpm build` | 编译模块 |
| `cjpm run` | 编译并运行模块 |
| `cjpm test` | 运行模块的单元测试 |
| `cjpm clean` | 清理构建产物 |
| `cjpm update` | 更新依赖 |

```bash
cd hello_cjpm
cjpm run
# 输出：
# hello world
# cjpm run finished
```

## 4. import 语句

`import` 用于在当前源文件中导入其他包中的顶层声明或定义。它必须位于**包声明之后、其他声明之前**。

### 4.1 导入单个声明

```cangjie
import std.collection.ArrayList
import package1.foo
```

### 4.2 批量导入同一包的多个声明

```cangjie
import std.collection.{HashSet, HashMap}

// 等价于
import std.collection.HashSet
import std.collection.HashMap
```

### 4.3 通配符导入

```cangjie
import std.collection.*         // 导入 std.collection 包中所有可见声明
import {std.collection.*, std.io.*}   // 同时导入多个包的所有声明
```

通配符导入会让当前作用域**污染**所有可见名字，应谨慎使用。

### 4.4 import as 重命名

```cangjie
// 重命名单个声明
import package1.foo as myFoo
// 重命名整个包
import std.collection.ArrayList as AL
```

重命名常用于**解决不同包中同名声明的冲突**：

```cangjie
package pkga
import p1.C as C1
import p2.C as C2

main() {
    let _ = C1()   // OK
    let _ = C2()   // OK
}
```

### 4.5 import 可见性

`import` 可以被 `private` / `internal` / `protected` / `public` 修饰，**默认是 private**：

| 修饰符 | 含义 |
|---|---|
| `private`（默认） | 仅当前文件内可访问导入的成员 |
| `internal` | 当前包及其子包内可访问 |
| `protected` | 当前模块内可访问 |
| `public` | 外部模块也可访问（**重导出**） |

```cangjie
package a
public import a.b.f       // 重导出：导入 a.b.f 并允许其它包通过 import a.f 使用
public let x = 0
```

> **注意**：**包不能被重导出**。如果 import 的是包，该 import 不允许被 `public` / `protected` / `internal` 修饰。

### 4.6 import 的规则

- 导入的成员的作用域**级别低于**当前包声明的成员（同名时当前包的优先）。
- **禁止包间的循环依赖**导入，否则编译器报错。
- **禁止导入当前包**的声明或定义。
- **只允许导入可见的声明**：导入 `internal` 修饰的成员到非本包会报错。

### 4.7 隐式 import core 包

`String` / `Int64` / `Array` / `Range` 等内置类型**无需显式 `import` 即可使用**，这是因为**编译器会自动为源码隐式导入 `core` 包中所有 `public` 修饰的声明**。

```cangjie
// 无需 import 即可使用
let s: String = "仓颉"
let n: Int64 = 100
let arr: Array<Int64> = [1, 2, 3]
let r: Range<Int64> = 0..5
```

## 5. main 函数（程序入口）

> 仓颉程序入口为 `main`，**源文件根目录下的包的顶层最多只能有一个 `main`**。

### 5.1 main 的合法签名

`main` 函数有 4 种合法签名：

```cangjie
// 1. 无参数，返回整数类型
main(): Int64 {
    return 0
}

// 2. 无参数，返回 Unit
main(): Unit {
    println("Hello, 仓颉")
}

// 3. 参数为 Array<String>，返回整数类型
main(args: Array<String>): Int64 {
    for (arg in args) {
        println(arg)
    }
    return 0
}

// 4. 参数为 Array<String>，返回 Unit
main(args: Array<String>): Unit {
    for (arg in args) {
        println(arg)
    }
}
```

### 5.2 错误的 main 签名（编译报错）

```cangjie
// 错误：返回类型不是整数或 Unit
main(): String {
    return ""
}
// 错误：参数类型不是 Array<String>
main(args: Array<Int8>): Int64 {
    return 0
}
// 错误：源文件顶层有多个 main
main(args: Array<String>): Int32 { return 0 }
main(): Int8 { return 0 }
```

### 5.3 main 的限制

- `main` 函数**不可被访问修饰符修饰**（不能写 `public main()`）。
- 当一个包被导入时，包中定义的 `main` **不会被导入**。
- `main` 必须定义在**源文件根目录下的包的顶层**，否则编译器找不到入口会报错。

### 5.4 编译运行

直接使用 `cjc` 编译运行（适合单个或几个源文件）：

```bash
cjc hello.cj -o hello
./hello
```

或者使用 `cjpm`（适合多文件模块）：

```bash
cjpm run
```

## 6. 实战：典型多文件包

设想一个 `geometry` 包，包含 `circle` 和 `rectangle` 两个类型。目录结构：

```
my_project/
├── cjpm.toml
└── src/
    ├── main.cj        # 包含 main 入口
    ├── circle.cj      # package geometry
    └── rectangle.cj   # package geometry
```

`circle.cj`：

```cangjie
package geometry

public struct Circle {
    public Circle(public var radius: Float64) {}
    public func area(): Float64 {
        3.14159 * radius * radius
    }
}
```

`rectangle.cj`：

```cangjie
package geometry

public struct Rectangle {
    public Rectangle(public var width: Float64, public var height: Float64) {}
    public func area(): Float64 {
        width * height
    }
}
```

`main.cj`：

```cangjie
package demo

import geometry.{Circle, Rectangle}

main(): Int64 {
    let c: Circle = Circle(2.0)
    let r: Rectangle = Rectangle(3.0, 4.0)
    println("Circle area = ${c.area()}")
    println("Rectangle area = ${r.area()}")
    return 0
}
```

`cjpm.toml`：

```toml
[package]
name = "demo"
version = "0.1.0"
cjc-version = "1.0.5"
```

运行 `cjpm run`，将看到两个图形的面积。

## 7. 常见问题（FAQ）

### Q1: 顶层作用域中能定义 `class` 吗？

可以。`struct` / `class` / `enum` / `interface` 都允许在顶层作用域中定义。

### Q2: 同一个包的不同源文件能相互访问对方的顶层声明吗？

可以。**同一个包内的源文件共享名字空间**，可以不导入就互相访问对方的顶层声明（只要可见性允许）。

### Q3: 顶层 `let` 声明必须有初始值吗？

必须有。**全局变量或静态成员变量必须指定初始值**；局部变量和实例成员变量可以省略初始值，但需标注类型，且要在使用前赋值。

### Q4: 顶层 `main` 能用 `public` 修饰吗？

不能。`main` 函数**不能被访问修饰符修饰**（文档明确说明）。

### Q5: 子包如何访问父包的 `internal` 声明？

`internal` 修饰的声明对**当前包及其子包（包括子包的子包）**可见，子包可以**通过 import 父包的声明**来访问。

### Q6: import 的命名冲突如何解决？

三种方式：
1. **使用 import as 重命名**：`import p1.C as C1`
2. **导入整个包作为命名空间**：`import p1; let _ = p1.C()`
3. **使用全限定名**：`let _ = p1.C()`

### Q7: 仓颉有 `internal` 包的概念吗？

有。`internal package demo.foo` 表示该包仅当前包及子包可见，不能被其他包 import。

### Q8: 怎么把 main 入口放到子目录的源文件里？

**不行**。`main` 函数必须定义在**源文件根目录下的包的顶层**。如果项目需要多个 main，应使用多个模块（每个模块独立 `cjpm run`）。

## 8. 总结

1. **顶层作用域**：不被 `{}` 包围的代码所在作用域，可定义全局变量 / 函数 / 自定义类型。
2. **包（package）**：编译的最小单元，必须以 `package 名字` 声明开头；同名包内不允许同名顶层定义（函数重载除外）。
3. **模块（module）**：若干包的集合，是发布的最小单元；用 `cjpm` 管理；模块根目录的顶层最多一个 `main`。
4. **访问修饰符（4 级）**：`public > protected > internal > private`；`package` 默认 `public`，其他顶层声明默认 `internal`，`import` 默认 `private`。
5. **import 语法**：`import pkg.item`（单个）、`import pkg.{a, b}`（批量）、`import pkg.*`（通配符）、`import pkg.item as 别名`（重命名）、`import pkg as 别名`（包重命名）。
6. **import 规则**：禁止循环依赖、禁止导入当前包、禁止导入不可见声明。
7. **隐式 import core 包**：`String` / `Int64` / `Array` / `Range` 等内置类型无需显式 import。
8. **main 合法签名**：4 种（无参/带参 × 整数/Unit），返回 `String` 等非整数非 Unit 类型编译报错；不能被访问修饰符修饰；不可被 import 导入。
9. **cjpm**：`cjpm init` / `cjpm run` / `cjpm build` / `cjpm test` / `cjpm clean` / `cjpm update` 是常用命令。

## 参考资料

1. 仓颉 1.0.5 LTS 包的概述：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/package/package_overview.html
2. 仓颉 1.0.5 LTS 使用 import 语句导入其他包中的声明或定义：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/package/import.html
3. 仓颉 1.0.5 LTS 顶层声明的可见性：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/package/toplevel_access.html
4. 仓颉 1.0.5 LTS 程序入口：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/package/entry.html
5. 仓颉 1.0.5 LTS 程序结构（顶层作用域、变量、作用域）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_programming_concepts/program_structure.html
6. 仓颉 1.0.5 LTS 运行第一个仓颉程序（cjpm init / cjpm run）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/first_understanding/hello_world.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
