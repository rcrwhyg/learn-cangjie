# const 函数与常量求值：把计算搬到编译期

> **摘要**: 前面 41 篇讲"类型是编译期决策"、42 篇讲"分支/穷尽是编译器算的"——本篇讲**求值也可以搬到编译期**。`const 上下文`（`const` 变量初始化处）**永远编译期算**；`const 函数`是一类"**具备编译期求值能力**"的函数：在 `const` 上下文里调用它 → 编译期跑；在运行时上下文里调用它 → 和普通函数一样运行时跑（**同一个函数、两种时机**）。本篇把"什么样的表达式才算 `const` 表达式"、"const 函数为什么不能用 `var`/调非 const 函数/有副作用"、"编译期算错了怎么报"用 1.0.5 `cjc` 的**编译错证据**坐实。所有规则均本地实测；示例 `046-const-eval.cj` 用一个 `const func fact` 演示编译期递归。

## 前置知识

- 已完成《类型系统》（41）——"编译期管类型"到"编译期管值"是同一条路
- 已完成《cjc 编译器》（35）——`--int-overflow` 策略；本篇解释 `const` 上下文为什么**不吃**运行时溢出策略、直接编译错
- 见过任意一门语言的"编译期常量"（Rust `const fn` / C++ `constexpr` / Zig `comptime`）更好，不强制

> **本篇与基础篇的分界**：`const` 语法本身基础篇（3）已提过一句"不可变变量"；本篇讲的是**求值时机**这个更深的维度——不是"改了会不会报错"，而是"编译器什么时候算它"。

## 1. 两个求值域

一个程序里其实是**两套求值**：

- **编译期求值**：`cjc-frontend` 阶段就把表达式折成常量、把函数执行一遍。产物里没有这段计算，只有结果。
- **运行期求值**：程序跑起来才算。

`const` 系统 = 从"语言层"给编译器**承诺**"这段一定能编译期算出来"——它**同时**是一种**优化**（少点运行时指令）和一种**类型/值安全**（编译期就能拒的错别留到运行时）。

## 2. `const` 上下文：永远编译期算

**官方定义**："const 上下文是指 `const` 变量初始化表达式，这些表达式始终在编译时求值"。也就是说：只要一个表达式在 `const X = ...` 的 `...` 位置，它就在编译期跑。

```cangjie
const TRIPLE: Int64 = 3 * 14        // 编译期算，产物里直接是 42
const BAD: Int8 = 200               // 编译错：200 超出 Int8 范围
```

第二条的报错（实测，`cjc`）：

```text
error: the number '200' exceeds the value range of type 'Int8'
```

> **⚠️ 别把 `const` 与"运行时不可变变量"混**：`const` 声明的变量**必须在编译期算得出值**——不是"运行时不能改"，而是"值本身就是编译期常量"。运行时不可变用 `let`；编译期常量用 `const`。

## 3. `const` 表达式清单（照官方 + 本地实测）

在 `const` 上下文里能出现的表达式，官方规则（要点）：

- 字面量：数值/`Bool`/`Unit`/`Rune`/`String`；**元组字面量**；**`VArray` 字面量**（定长数组——`Array` 类型不行）
- `const` 变量、`const` 函数形参、`const` 函数中的局部变量
- **`const` 函数**本身、满足 `const` 要求的 lambda、以及它们返回的函数表达式
- **`const` 函数调用**（**含 `const` 构造函数**）——且**每个实参都得是 `const` 表达式**
- **enum 构造器调用**（无参构造器、或所有实参都 `const` 的构造器）
- 数值/`Bool`/`Rune`/`String` 上的算术/关系/位运算——操作数都得 `const`
- `if`、`match`、`try`、`throw`、`return`、`is`、`as`——**里面的子表达式也得全 `const`**
- `const` 表达式的**成员访问**（**不含属性 getter**）、元组索引
- `const init`、`const` 函数里的 `this`/`super`、`const` 表达式上的 `const` 实例成员函数调用（实参全 `const`）

> **⚠️ 一处坑**：官方明写"**当前编译器实现暂不支持 `throw` 作为 `const` 表达式**"——`const X = throw ...` 编译错（实测：`expected 'const' expression guaranteed to be evaluated at compile time`）。这条随时会变，用之前先看 1.0.5 手册。

## 4. `const` 函数：一类"能在编译期跑"的函数

```cangjie
const func sq(x: Int64): Int64 { x * x }
```

它的**关键性质**（官方一句话）：
> 在 `const` 上下文中调用时，**这些函数会在编译时执行计算**；在其他非 `const` 上下文，`const` 函数**会和普通函数一样在运行时执行**。

也就是**同一个函数、两种时机**：

```cangjie
const func sq(x: Int64): Int64 { x * x }

const S: Int64 = sq(5)         // 编译期算 → 25，产物里就是常量
func compute(n: Int64): Int64 {
    return sq(n)               // 运行时算 → 编译期不知道 n 是多少
}
```

（实测两段一起编译通过。）这条心智特别重要：**`const func` 不是"只能在编译期用"的函数、是"可以两边都用"**——它的效果是"调用点决定求值时机"。

## 5. `const` 函数的三条铁律（编译错实测）

因为要保证"编译期能算得出来"，编译器对 `const func` 严加管束。四条常见违反，各对应一个错误：

### 5.1 不能有可变局部（`var`）
```cangjie
const func sum(n: Int64): Int64 { var s = 0; s += n; s }
// error: cannot define 'var' variable in 'const' function
```
**副作用**、可变状态都会破坏"编译期可确定"。

### 5.2 不能调用非 `const` 函数
```cangjie
func h(): Int64 { 1 }
const func g(): Int64 { h() }
// error: expected 'const' expression
```
被调方没有"保证编译期能算"，调用它当然不能算。

### 5.3 不能有 I/O 等副作用
```cangjie
const func g(): Int64 { println("hi"); 1 }
// error: expected 'const' expression
```
`println` 是普通函数（有 I/O），走 5.2。

### 5.4 允许递归
```cangjie
const func fact(n: Int64): Int64 {
    if (n <= 1) { 1 } else { n * fact(n - 1) }
}
const F5: Int64 = fact(5)   // 编译期算出 120
```
（实测通过。）只要**能被编译期收敛**，递归本身合法——但编译器**不保证**一定折叠（依赖参数与内建求值器；对纯字面量参数会折，运行时传参就是普通递归）。

## 6. `const` 求值就是编译期算术

看两个直接对照：

```cangjie
// (a) 编译期溢出：const 上下文
const BAD: Int8 = 200
// error: the number '200' exceeds the value range of type 'Int8'

// (b) 运行时溢出：非 const 上下文，走 --int-overflow 策略
main(): Int64 {
    let x = Int8(Int64.MaxValue)   // 编译期无错
    ...                             // 运行时按 throwing(默认) 抛 / wrapping 回绕
}
```

**同一件事（超范围）在两个上下文里表现完全不同**——因为 `const` 上下文**必须编译期算得出**，而运行时把这件事推到 `--int-overflow` 策略。**这不是编译器的"严格"，是语义决定的**：`const` 表达式的值就是编译期常量，编译期算不出来，只能拒。

## 7. `const` 与类：`static const` 与 `const init`

**类级常量**：`static const`（`struct` 里同样、单独 `const` 会报 "expected static before const member variable"）：

```cangjie
class Magic {
    public static const SEVEN: Int64 = 7
}
main(): Int64 { println(Magic.SEVEN); return 0 }        // 编译期常量
```

**`const` 构造函数 / `const init`**：让**实例本身**能进编译期。官方例子（本文实测语法变体过）：

```cangjie
const Point(let x: Float64, let y: Float64) {}
const func distance(a: Point, b: Point): Float64 { ... }   // 编译期可算的 Point 距离
```

要点：`const init`（或 `const Point(...)` 主构造器）产出的实例**是编译期常量**，能出现在 `const` 上下文；否则实例是运行时对象、进不了 `const` 表达式。这条让"编译期向量 / 编译期配置结构"这类需求能落地。

## 8. 完整示例（编译期递归 fact + 组合 const 函数）

`046-const-eval.cj`：

<!-- example: cangjie/046-const-eval.cj -->
```cangjie
package ct

// const 函数与常量求值示例（配合文章 43）。
// const func 关键：在 const 上下文里编译期算；在其他上下文里运行时算（同一个函数、两种时机）。

const func sq(x: Int64): Int64 { x * x }                        // 纯、无 var、无副作用
const func hyp(a: Int64, b: Int64): Int64 { sq(a) + sq(b) }     // 调另一个 const func

// const func 允许递归（实测通过）：只要能被编译期收敛。
const func fact(n: Int64): Int64 {
    if (n <= 1) { 1 } else { n * fact(n - 1) }
}

// —— const 上下文：这些初始化表达式全部在编译期求值 ——
const TRIPLE: Int64 = 3 * 14                    // 42（编译期折叠）
const HYP: Int64 = hyp(3, 4)                    // 25（编译期调用 const func）

class Magic {
    public static const SEVEN: Int64 = 7        // 类级 const（struct/class 单写 const 会报"expected static"）
}

// 运行时函数：从外部拿参数（模拟非 const 输入），
// 然后调用同一个 const func sq——这一次它在运行期算，不是编译期算。
func runtimeSquares(n: Int64): Int64 {
    var acc = 0
    for (i in 1..n) { acc += sq(i) }
    return acc
}

main(): Int64 {
    const local: Int64 = fact(5)                // 编译期算 120
    println("TRIPLE=${TRIPLE}")                 // 42
    println("HYP=${HYP}")                       // 25
    println("fact5=${local}")                   // 120
    println("MAGIC=${Magic.SEVEN}")             // 7
    println("runtime_sq_1_to_4=${runtimeSquares(4)}")   // 14（1..4 上界不含 → i=1,2,3 → 1+4+9）
    return 0
}
```

编译并运行（Linux）：

```shell
cjc 046-const-eval.cj -o ct && ./ct
```

预期输出：

```text
TRIPLE=42
HYP=25
fact5=120
MAGIC=7
runtime_sq_1_to_4=14
```

## 9. 与其它语言"编译期求值"对照

| 维度 | 仓颉 `const func` | Rust `const fn` | C++ `constexpr` | Zig `comptime` |
|---|---|---|---|---|
| 语法 | `const func f(...) T {}` | `const fn f() -> T {}` | `constexpr T f() {}` | `comptime` 块 |
| 触发时机 | **调用点**：`const` 上下文→编译期、否则运行 | 显式要求 const 上下文 | 显式或隐式（`consteval` 强制） | 语言级统一 |
| 允许 `var` 吗 | ❌（在 const func 里） | 部分（现代 Rust 允许 const-mut 局部） | C++20 起局部可 | ❌ |
| 递归 | ✅（实测 `fact`） | ✅ | ✅ | ✅ |
| 溢出/范围错 | 编译期直接拒（`exceeds the value range`） | 编译期拒 | 编译期拒 | 编译期拒 |
| 类型层面 const | 泛型参数不能传值 | 稳定支持（`const generics` 部分实验） | 支持非类型模板参数 | 一等公民 |

**心智迁移**：Cangjie 最接近 Rust 的 `const fn`（"能编译期算、也能运行期算"），**没有** Zig `comptime` 那种"元编程层统一"的野心；也**不做**泛型值参数（`Array<T, N>` 那种定长数组的 `N` 目前不是 `const` 表达式）。

## 10. FAQ

### Q1: 那 `const func` 是不是永远比 `func` 快？

**不是**。`const func` 只在**编译期能被算出来**时才"更快"（产物里就是常量、不生成指令）；一旦参数来自运行期，它就是普通函数、**同速**。`const` 不是速度关键字、是**能力声明**。

### Q2: 为什么我 `const func` 里 `for (i in 0..n) { s += i }` 报错？

`for` 需要 `var s`（累加器）→ 命中 5.1。**编译期算不出**"有可变状态"的东西。改用递归：`sum(n) = if (n<=0) 0 else n + sum(n-1)`。

### Q3: `const` 变量能在函数里当"运行时不可变变量"用吗？

**不能**——`const X = someRuntimeThing()` 编译错（"guaranteed to be evaluated at compile time"）。想要"运行时不可变"用 `let`。`const` 是"值本身就是编译期常量"。

### Q4: 官方 `const` 表达式规则我记不全怎么办？

**记不住没关系、编译器替你记**。写错了它会精确指出"这里得是 `const` 表达式"。理解一条就够：**`const` 上下文里的每一步都得是"编译期能算"的**。

### Q5: `const` 函数怎么测？

调用它、断言编译期结果即可（`const HYP: Int64 = hyp(3,4); assertEq(HYP, 25)`——但 `assert` 得**是 `const` 表达式**，简单办法：`const` 变量 + `main` 里 `println`；跑一遍看输出）。

### Q6: `throw` 在 const 表达式里到底能不能用？

**1.0.5 官方明确：暂不支持**（我实测 `const X = throw ...` 报错）。别把它写进 `const` 上下文。

## 11. 总结

1. **两个求值域**：编译期算 vs 运行时算。`const` 让**编译期算**成为可承诺的能力。
2. **`const` 上下文**（`const` 变量初始化处）**永远编译期求值**——`const BAD: Int8 = 200` 直接编译期拒。
3. **`const` 函数**："能在编译期跑的函数"；**调用点决定求值时机**——`const` 上下文→编译期算、否则→运行时算（同一函数、两种时机）。
4. 三条铁律（编译错坐实）：**不能 `var`、不能调非 `const` 函数、不能有 I/O 副作用**；**可以递归**。
5. `const` 表达式的完整清单见第 3 节（`Array` 不行 `VArray` 行、`throw` 暂不支持）；`const init`/`static const` 让"编译期实例/类级常量"成为可能。
6. **和运行时不可变区分**：`const` = 值本身就是编译期常量；`let` = 运行时不可变绑定。

## 参考资料

1. const 函数和常量求值：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/function/const_func_and_eval.html
2. 整数类型（数值字面量与 `T(e)` 转换）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/integer.html
3. 类型系统（编译期溢出与 `--int-overflow` 关系，承文章 41）：articles/41-type-system.md
4. cjc 编译器（`--int-overflow`、`--emit-chir` 与编译流水线）：articles/35-cjc-compiler.md

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写。所有 `const` 规则、限制与"两种时机"结论均本地 `cjc` 编译错/告警实测；官方"暂不支持 `throw` 作 const 表达式"亦经实测坐实。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
