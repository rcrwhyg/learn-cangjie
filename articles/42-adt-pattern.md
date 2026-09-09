# 代数数据类型与模式匹配原理：和之积、穷尽性、不可反驳性与死分支

> **摘要**: 基础篇（10 枚举 / 11 模式匹配 / 20 Option）教过"怎么写 enum、怎么 match"。本篇讲**背后的代数**：类型怎么由"**积**（product，struct/元组式的"并且"）"与"**和**（sum，enum 式的"或者"）"搭出来，`Option` 为什么只是一个再普通不过的 enum，`match` 为什么既能**反演积**（把字段拆出来）又要求**穷尽和**（每个分支都得给答案），编译器**如何靠"不可反驳性"决定 `let` 能不能用某模式**、又**如何识别出永远进不去的死分支**（实测 `warning: unreachable pattern`）。每条都用 1.0.5 `cjc` 的编译错/告警坐实；示例 `045-adt-pattern.cj` 用一个 enum + 一个自定义 Option 讲透"和之积"。

## 前置知识

- 已完成《枚举类型》（10）、《模式匹配》（11）、《Option》（20）——**知道语法**，本篇讲的是"编译器为什么这么管"
- 已完成《类型系统》（41）——本篇里 `Nothing` / 类型格的心智直接承接
- 接触过任一门带 sum type 的语言（Rust `enum` / OCaml `type` / Haskell `data`）更好；没有也不影响

> **本篇与基础篇的分界**：基础篇说 `enum Shape { | Circle(Int64) }` 能这么写；本篇说"**为什么少写一支 match 编译器会拒绝你的程序**"——从编译错反推设计。

## 1. ADT = 和 × 积：一句话讲清

"代数数据类型"（Algebraic Data Type, ADT）里"代数"两字来自——**类型可以用两种运算搭**：

- **积类型（product）**：`同时`。`struct Rect(w, h)` = "**既有 w 又有 h**"；元组 `(a, b)`、class 的多字段也是积。**取值靠"投影"**（`.w` / `._1`）。
- **和类型（sum）**：`或者`。`enum Shape { | Circle(R) | Rect(w,h) | Empty }` = "**是 Circle、或者 Rect、或者 Empty 之一**"。**取值靠"分支"**（`match`）。

**ADT 就是"和的每个分支又是一个积"**。用 `enum` + 构造器参数表达，`Shape` 是 3 个积的和：

```text
Shape  =  Square(Int64)       ← 积：1 字段
       +  Rect(Int64, Int64)  ← 积：2 字段
       +  Empty               ← 积：0 字段（单元类型 Unit，也是积）
```

`|`（enum 构造器分隔）= 和；`(a, b)`（构造器参数）= 积。

> **💡 "基数"直觉**：如果一种类型 `X` 有 `|X|` 个取值，那么 `Product(A, B)` 有 `|A|·|B|` 个、`Sum(A, B)` 有 `|A|+|B|` 个——"积""和"两个词不是比喻，是**基数**。`Bool = |True| + |False| = 2`；`Option<Int64> = 1 + |Int64|`——`Option` 只是"多塞一个 `None`"的**和**。

## 2. `Option<T>` 就是一个普通 enum（破除"特殊类型"神话）

Cangjie std 里：

```cangjie
enum Option<T> { | Some(T) | None }
```

**没有任何语言级特殊**——就是"和的分支一个是带 T 的积、另一个是单元积"。你完全可以自己写一个：

```cangjie
enum MyOpt { | V(Int64) | N }
main(): Int64 {
    let o = MyOpt.V(5)
    return match (o) { case V(v) => v; case N => 0 }   // 与 Option 完全同构
}
```

`cjc` 编译通过（实测）。`Option` 只是 std 里**预定义 + 一堆 helper（`.map`/`.getOrElse`/`for` 支持）**的普通 enum。

这条心智很重要：**只要 `match` 处理了 enum 的所有构造器，编译器就认为你处理完了**——不管那个 enum 叫 `Option` 还是 `MyOpt`。第 41 篇讲"Option 不自动解包"就是这个原理的直接后果：**它是 enum，就得走 enum 的规则**。

## 3. 泛型 enum：让"积里那一格"由调用者填

`Option<T>` 就是**带类型参数的和之积**——`Some` 那一支的积大小由 `T` 决定。定义方式：

```cangjie
enum Opt2<T> { | Some2(T) | None2 }
```

同参数化用法：`Opt2<Int64>` 与 `Opt2<String>` 之间也**没有子类型关系**（承 41 的泛型不变）。

## 4. `match` 的两个动作：反演积 + 穷尽和

Cangjie 的 `match` 是**模式匹配**，但它做的两件事是**互相独立、又缺一不可**的：

```cangjie
func area(s: Shape): Int64 {
    return match (s) {
        case Square(k) => k * k      // ① 反演积：把 Square 那格的 Int64 拆出来叫 k
        case Rect(w, h) => w * h     // ① 反演积：把 Rect 那两格拆出来叫 w、h
        case Empty => 0              // ② 覆盖和：Empty 那一支也得给答案
    }
}
```

**① 反演积（destructuring）**：`case Square(k)` 把"和里 Square 这一分支"的字段绑给 `k`。**没有这一步，你拿到的是"哪个分支"信息，拿不到分支里的值**。

**② 穷尽和（exhaustiveness）**：编译器把"这个 enum 有几个构造器"当成一张清单，你少写一支 = **有一类输入没有答案** = 编译错。实测：

```cangjie
enum E { | A | B }
main(): Int64 { let e = E.A; return match (e) { case A => 1 } }
// error: non-exhaustive patterns
```

少了 `case B`，`e` 是 `B` 时"该返回什么"没定义——编译期直接拒。这是 41 篇"类型安全保证"里的第一条，本篇看到它的**根因**：和类型必须覆盖全部"或"分支。

## 5. 不可反驳性（irrefutability）：为什么 `let Some(v) = x` 不合法

**"反驳"** 在这里 = "有输入使这个模式匹配失败"。**不可反驳模式**（irrefutable）保证**对所有输入都能匹配成功**；**可反驳模式**（refutable）**可能匹配失败**。

- `case Square(k)` 是**可反驳**：`s` 可能是 `Rect`，那 `Square(k)` 匹配失败。
- `case _` 是**不可反驳**：什么都接。
- `let x = expr` 里的 `x`（普通变量）也是**不可反驳**：永远绑得上。

Cangjie（和 Rust）的铁律：**`let` 的左边必须不可反驳**——因为 `let` 没有"匹配失败走 else 分支"这条路。实测：

```cangjie
main(): Int64 {
    let o: Option<Int64> = Some(5)
    let Some(v) = o        // error: the pattern isn't irrefutable pattern and it can not be initialized
    return v
}
```

`Some(v)` 是**可反驳**的（万一是 `None` 呢？），所以不能出现在 `let` 左边。**同样这个模式放进 `match` 就合法**——因为 match 里你可以写 `case None => ...` 兜住另一种可能。理解这一点，就懂了"为什么解构 Option 只能 `match` / `.get()` / `.map`，不能 `let Some(v) = o`"。

> 反过来，`let (a, b) = tuple` 合法——元组模式**不可反驳**（元组本来就是积、结构固定）。`let x: Int64 = 5` 合法——单个变量名是**最简单的不可反驳模式**。

## 6. 穷尽性和 `_`：编译器还管"死分支"

`_`（通配）是**不可反驳**模式，放在最后一支 = 把所有剩下的输入全接住 = **穷尽性自动满足**：

```cangjie
enum E { | A | B | C }
main(): Int64 { let e = E.A; return match (e) { case A => 1; case _ => 0 } }
// 有 `_` 兜底，少写了 B、C 也过
```

但**别乱加 `_` 兜底**——它会让编译器不再提醒"未来给 enum 加了 `D` 你得处理"。**更妙的是**：如果你**已经把所有构造器都写了还加 `_`**，编译器会**识别出那一支永远不会进**：

```cangjie
enum E { | A | B }
main(): Int64 { let e = E.A; return match (e) { case A => 1; case B => 2; case _ => 3 } }
// warning: unreachable pattern
```

（实测，1.0.5 `cjc` 就报 `unreachable pattern`。）穷尽性分析不只是"够不够"——它还算"**多不多**"。这条对**演进型 enum** 很关键：加了新构造器时，之前用 `_` 兜底的 `match` 会**静默**地少处理一种情形——不加 `_` 让编译错替你把这种坑堵掉，是 ADT 项目最常用的经验。

## 7. 或模式与嵌套模式

- **或模式**（`case A | B => e`）：两个模式共用同一支；`e` 里不能引用只在其中一个绑到的变量（那些变量名可能没值）。穷尽性计算**把它当成两笔**。

  ```cangjie
  enum E { | A | B | C }
  main(): Int64 { let e = E.A; return match (e) { case A | B => 1; case C => 2 } }   // 通过（实测）
  ```

- **嵌套模式**：`case Some(Some(_)) => ...` 一次解到底，不用 `match` 套 `match`。编译器的穷尽性分析会**穿透**这些嵌套：

  ```cangjie
  main(): Int64 {
      let x: Option<Option<Int64>> = Some(Some(3))
      return match (x) { case Some(Some(_)) => 1; case _ => 0 }     // 通过（实测）
  }
  ```

## 8. 各分支返回值类型必须一致（match 是表达式）

Cangjie 的 `match` 是**表达式**（有类型），所有 `case` 的分支表达式类型必须统一，否则 `mismatched types`（实测）：

```cangjie
enum E { | A | B }
main(): Int64 { let e = E.A; return match (e) { case A => 1; case B => "s" } }
// error: mismatched types（一支 Int64、一支 String）
```

含义：`match` 的**类型**=所有分支类型的**公共类型**（Cangjie 不做自动"上推到 Any"，所以要么都同型要么显式转）。

## 9. 编译到 tag dispatch（不夸大）

`enum` 的运行时形状 = "一个整数 tag（哪一支）+ 那一支的字段存储"。`match` 编译后就是一串按 tag 分支的跳转——所以 `case A => 1; case B => 2` 和 `case A => 2; case B => 1` 运行时**开销一致**，顺序不影响性能。`cjc -V` 实测能看到编译流水线的 `cjc-frontend → llvm`（把源码→LLVM IR）——`match` 是在 cjc-frontend 阶段就被降解成 tag 分支的（具体中间表示 CHIR 见文章 35 `--emit-chir` 一节）。

> **⚠️ 别把"match 编译成什么"和"match 语义"混起来**：语义 = "反演积 + 穷尽和"（第 4 节）；实现 = "tag dispatch"（本节）。**语义保证类型安全**，实现保证 O(1) 常数。

## 10. 完整示例（一个 enum + 一个自定义 Option）

`045-adt-pattern.cj`：把第 1–4 节拧到能跑、能测的代码上——`Shape` 演示"和的每支是积"、`Opt` 演示"Option 不是特殊"、`Opt2<T>` 演示"泛型和之积"：

<!-- example: cangjie/045-adt-pattern.cj -->
```cangjie
package adt

// 代数数据类型与模式匹配原理示例（配合文章 42）。
// 基础篇（10 枚举 / 11 模式匹配 / 20 Option）教"怎么写"；本篇用**同一个 enum**
// 拆出"为什么 match 是穷尽 + 反演积 + 编译器能识别死分支"。

// —— 和类型(sum type)：Shape 是 3 个"积"的和 ——
enum Shape {
    | Square(Int64)          // 积：1 个字段
    | Rect(Int64, Int64)     // 积：2 个字段
    | Empty                  // 积：0 个字段（单元/元积）
}

// 每个"和的分支"给一个答案——这就是穷尽性；每个"积"用 case 反演回字段。
func area(s: Shape): Int64 {
    return match (s) {
        case Square(k) => k * k         // 反演带 1 字段的积
        case Rect(w, h) => w * h        // 反演带 2 字段的积
        case Empty => 0                 // 反演 0 字段的积；漏这一支 non-exhaustive
    }
}

// —— Option 就是一个和类型，不是"语言级特殊"——
// 官方 std 的 `Option<T> = enum { Some(T) | None }`。这里自定义 Opt 演示同构。
enum Opt {
    | V(Int64)
    | N
}
func orElse(o: Opt, d: Int64): Int64 {
    return match (o) { case V(v) => v; case N => d }
}

// —— 泛型 enum = "带类型参数的和之积"，Option<T> 的通用形式 ——
enum Opt2<T> {
    | Some2(T)
    | None2
}
func count<T>(o: Opt2<T>): Int64 {
    return match (o) { case Some2(_) => 1; case None2 => 0 }   // `_` 只判存在、不绑值
}

main(): Int64 {
    println("area Square3=${area(Shape.Square(3))}")     // 9
    println("area Rect2x5=${area(Shape.Rect(2, 5))}")    // 10
    println("area Empty=${area(Shape.Empty)}")           // 0
    println("orElse(N,7)=${orElse(Opt.N, 7)}")           // 7
    println("orElse(V3,7)=${orElse(Opt.V(3), 7)}")       // 3
    let a: Opt2<String> = Opt2.Some2("hi")
    println("count=${count(a)}")                          // 1
    return 0
}
```

编译并运行（Linux）：

```shell
cjc 045-adt-pattern.cj -o adt && ./adt
```

预期输出：

```text
area Square3=9
area Rect2x5=10
area Empty=0
orElse(N,7)=7
orElse(V3,7)=3
count=1
```

## 11. 与其它语言 ADT 对照

| 概念 | 仓颉 | Rust | Haskell / OCaml |
|---|---|---|---|
| 和类型 | `enum { \| A \| B(T) }` | `enum { A, B(T) }` | `type t = A \| B of T` |
| 积类型 | `struct { a; b }` / 元组 | `struct { a, b }` / tuple | record / tuple |
| 分支选择 | `match (x) { case ... }` | `match x { ... }` | `match x with ...` |
| 穷尽性 | ✅ 编译错 | ✅ 编译错 | ✅ 编译错 |
| 通配 | `case _` | `_ =>` | `_ ->` |
| 或模式 | `case A \| B` | `A \| B` | `A \| B` |
| `let` 要求 | 不可反驳 | 不可反驳 | 不可反驳 |

**几乎没有翻译损耗**——任何一门带 ADT 的语言过来，术语和规则一一对应。跟 TypeScript/Java 那种"用 class 继承硬凑 sum type"的最大区别就是：**仓颉里"分支清单"是编译器**知道**的（enum 声明 = 清单），不是"运行时才知道"（class 继承体系对编译器开放-ended）**。

## 12. FAQ

### Q1: enum 里少一个 case，能用 `default` 兜住吗？

能，写 `case _ => ...`。但**不推荐**——加了新构造器时 `default` 会**吞掉**编译错、让你漏处理。第 6 节的 `unreachable pattern` 反过来也是提示：`_` 别乱加。

### Q2: `let Some(v) = opt` 为什么不能？

`let` 要求**不可反驳模式**——`Some(v)` 万一是 `None` 就"反驳"了。走 `match (opt) { case Some(v) => ... }` 或 `opt.map(...)` / `.get()`。

### Q3: Option 到底特殊不特殊？

**类型上完全不特殊**（就是一个 enum）；**语法/工具链上很特殊**——`for` 支持它、`.map/.flatMap` 一堆 helper、`?`-风格传播（`getOrThrow` 之类）都对着它。**理解它是 enum** 就理解了它所有"规则"的来源。

### Q4: `case A | B => x` 里的 `|` 和 enum 定义里的 `|` 是一回事吗？

**不是一回事**。定义里的 `|` 是"这一支/那一支"的分隔；case 里的 `|` 是"这一支 **或** 那一支都走这个分支"的合并。穷尽性计算时后者**展开成两个 case** 再算。

### Q5: enum 能带方法吗？

能（承 10 篇）。方法就是"这个和类型自带的公共行为"，比如 `Option<T>.getOrElse`——但**"分支处理"仍然只能在 match 或 helper 里做**，方法定义体不能对 `this` 少写 case。

### Q6: 分支返回值类型不一致为什么不能用公共父类型？

Cangjie 的 `match` 类型 = **各分支的类型**必须**直接**一致；不做"自动上推到 `Any`"——因为那会**骗人**（你以为是 `Int64` 其实是 `Any`）。要公共父就**每支显式** `upcast`（写 `... as Any`），或用 `let x: Any = 1; x` 之类。

## 13. 总结

1. **ADT = 和 × 积**：`enum` 是"或"、构造器参数是"并且"；`Option<T>` 就是一个"或 Some(T)、或 None"的和类型，不特殊。
2. **`match` 两件事**：**反演积**（把分支里的字段绑出来）+ **穷尽和**（每个构造器给答案）——少写一支是 `non-exhaustive patterns`。
3. **不可反驳性**：`let` 左边只能放"永远能匹配上"的模式（`Some(v)` 可反驳 → 只能进 `match`）。
4. **`_` 兜底有代价**：加了 `_` 编译器不再提醒新构造器；写满 enum 全分支还加 `_` → `unreachable pattern` **死分支告警**（编译器会看"多不多"）。
5. **或模式、嵌套、类型一致**：`case A | B` 展开穷尽；`case Some(Some(_))` 穿透解构；`match` 是表达式，各支类型必须一致。
6. **实现层面**是 tag dispatch，O(1) 常数；**语义层面**保证类型安全——两者别混。

## 参考资料

1. 模式概述（enum 与模式的关系）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/pattern_overview.html
2. 模式的 Refutability（不可反驳性）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/pattern_refutability.html
3. match 表达式：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/match.html
4. Option 类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/option_type.html
5. 枚举类型（构造器 = 和的分支）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/enum_and_pattern_match/enum.html
6. 泛型类型的子类型关系（`Opt2<T>` 不变）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/generic/generic_subtype.html
7. 上一篇：《仓颉类型系统》（articles/41-type-system.md）

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写。`non-exhaustive patterns` / `unreachable pattern` / `isn't irrefutable pattern` / `or-pattern` / `nested pattern` / `match 各支类型一致` 等结论均本地 `cjc` 编译错/告警实测；Option 与自定义 enum 同构亦实测编译通过。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
