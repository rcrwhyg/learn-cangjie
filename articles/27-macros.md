# 仓颉宏与编译时元编程

> **摘要**: 宏是"输入程序、输出程序"的特殊函数——它在**编译期**展开，把一段 `Tokens` 换成另一段 `Tokens` 后参与后续编译，用来实现 DSL、代码生成、调试打印这类常规函数做不到的事（例如把表达式原文连同它的值一起打印）。仓颉 1.0.5 把宏定义放在独立的**宏包（`macro package`）**里，用 `Tokens` 表示词法片段、用 `quote + $(...)` 构造输出片段，分**非属性宏**与**属性宏**两种形态。本文依据仓颉 1.0.5 LTS 官方 Macro 章，讲清宏的定位、宏包与项目布局、`@name(...)` 调用语法、`Tokens`/`quote`/插值、非属性宏与属性宏，以及嵌套宏的行为。配一个用 `cjpm` 构建、CI 里跑通的 **`dprint` 调试宏**示例。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK（含 `cjpm`）
- 已完成《包、模块与程序入口》（cjpm 项目结构、`cjpm.toml`）
- 了解 AST、词法/语法分析的基本概念

> 说明：仓颉的宏必须在**独立的宏包**中定义，`cjc file.cj` 单文件模式无法声明宏。所以本篇的示例是一个 **cjpm 多包项目**（`examples/cangjie/032-macro-dprint/`），CI 会 `cjpm check` 校验结构、Linux 上 `cjpm build && cjpm run` 跑真实输出。

## 1. 宏是什么

宏可以理解为**一种特殊的函数**——普通函数在"值"上计算、输出"值"；宏在"程序"上计算、输出"程序"。输入一段代码，输出一段新代码，输出的代码继续参与编译和执行。

区分宏调用与函数调用，靠**`@` 前缀**。经典示例 `dprint`：把表达式的**原文**连同**值**一起打印：

```cangjie
let x = 3
let y = 2
@dprint(x)        // 打印 "x = 3"
@dprint(x + y)    // 打印 "x + y = 5"
```

`dprint` 不可能写成普通函数——函数只能拿到传入表达式的**值**，拿不到**表达式本身**。而宏拿到的是输入表达式对应的**程序片段（Tokens）**，既能转成字符串打印、又能原样嵌入到生成的代码里。

## 2. 宏包（`macro package`）与项目布局

**宏必须声明在独立的宏包里**，含有宏的包用 `macro package` 声明，不能与其他普通 `public` 函数混编。目录布局（cjpm 项目）：

```
src/
|-- main.cj            # 普通包，import 并使用宏
|-- define/            # 宏包子目录
|   |-- cjpm.toml      # 宏包的模块配置
|   |-- dprint.cj      # macro package ...; public macro ...
|-- cjpm.toml          # 模块根配置
```

主模块的 `cjpm.toml` 用 `[macro-dependencies]` 声明宏依赖：

```toml
[macro-dependencies]
  [macro-dependencies.define]
    path = "./src/define"
```

编译期解析顺序：`cjpm check` 会告诉我们依赖合法顺序，比如本示例里：

```text
The valid serial compilation order is:
    macro_dprint.define -> macro_dprint
```

## 3. 宏定义与非属性宏

一个最基本的非属性宏（`dprint`）：

```cangjie
macro package macro_dprint.define

import std.ast.*

public macro dprint(input: Tokens): Tokens {
    let inputStr = input.toString()
    let result = quote(
        print($(inputStr) + " = ")
        println($(input)))
    return result
}
```

逐行看：

- **`macro package macro_dprint.define`**：声明这是一个宏包，cjpm 中宏包名要用 `<模块>.<子包>` 的限定形式。
- **`import std.ast.*`**：`Tokens`、`quote`、语法节点类型都在 `std.ast`，任何宏实现都得先引入它。
- **`public macro dprint(input: Tokens): Tokens`**：宏定义必带 `public`（否则跨包不可见）；这个宏是**非属性宏**——只有 1 个 `Tokens` 入参（输入），返回也是 `Tokens`（输出程序片段）。
- **`input.toString()`**：把输入的程序片段转成字符串（`x` 得到 `"x"`，`x + y` 得到 `"x + y"`）。
- **`quote(...)`**：从代码模板构造 `Tokens`；模板里的 `$(...)` 是**插值**，把上下文里可转成 `Tokens` 的表达式拼进去。这里 `$(inputStr)` 插入带引号的字符串常量、`$(input)` 原样插入输入表达式。若输入是 `x + y`，生成的 `Tokens` 相当于：

  ```cangjie
  print("x + y" + " = ")
  println(x + y)
  ```
- **`return result`**：返回构造出的程序片段。

## 4. 属性宏与非属性宏

按入参个数区分：

| 类型 | 定义 | 调用 |
|---|---|---|
| **非属性宏** | 一个 `Tokens` 入参（对应输入） | `@name(输入)`，**不能**带 `[]` |
| **属性宏** | 两个 `Tokens` 入参（属性、输入） | `@name[属性](输入)` 或 `@name[属性] 声明` |

属性宏相当于给宏多加了一个"元信息"通道：开发者可以用 `[]` 传任意 `Tokens`（比如策略标记），宏实现里把这个额外输入与主输入组合。

> **⚠️ 定义与调用必须匹配**：定义为**两个入参**（属性宏）则调用**必须**写 `[]`（内容可为空）；定义为**一个入参**（非属性宏）则调用**不能**写 `[]`。

## 5. Tokens / Token 与 quote

宏的基本类型是 `Tokens`，代表"一串词法单元"。

**Token**：一个可操作的词法单元（标识符、字面量、关键字、运算符…）；包含类型、内容、位置信息。类型是 `enum TokenKind`；提供 `TokenKind` + 值可直接构造 Token。

**Tokens**：若干 Token 的序列。可用 `Token` 数组构造，支持：

| 方法 | 作用 |
|---|---|
| `size` | Token 个数 |
| `get(index: Int64)` / `[]` | 按下标取 Token |
| `+` | 拼接 `Tokens`，或 `Tokens` + `Token` |
| `dump()` | 打印所有 Token（调试） |
| `toString()` | 打印对应的程序片段 |

**quote 表达式**：从代码模板构造 `Tokens`，模板里可用 `$(...)` 插值——**只要类型实现了 `ToTokens` 接口就能被插入**。标准库已实现 `ToTokens` 的类型包括：所有语法节点类型、`Token`/`Tokens`、所有基础数据类型（整数/浮点/`Bool`/`Rune`/`String`）、`Array<T>`/`ArrayList<T>`（按 T 类型选分隔符）。

**quote 里的转义规则**：

- 括号不匹配要转义（`\(`、`\)`）
- `$` 表示"普通 Token 而非插值"时，用 `\$`
- 其他 `\` 出现在 quote 里编译报错

## 6. `@name` 调用位置与语法

- 宏调用可以出现在**任何允许表达式**的地方；也可以作为**声明位置的前缀**，如 `@attr struct Foo {}`、`@attr let x = ...`、`@attr func f() {}`、`@attr enum`、`@attr class`、`@attr interface`、`@attr extend`、`@attr property` 等。
- **带括号的输入**（`@name(...)`）可以是任意合法 `Tokens`（不能为空）。
- **不带括号**（直接跟在声明前）时，输入被限定为"紧跟其后的那条声明"。
- 宏调用参数/属性里出现未成对括号、未成对中括号、`@` 本身，都需要 `\` 转义。

## 7. 宏是编译期执行

宏在**编译期**被"运行"：编译器把宏调用替换成宏返回的程序片段，之后新片段参与常规编译与语义分析。所以：

- 宏定义体里的 `println("Compiling...")` 这类打印，是在**编译时**输出，不是运行时。
- **宏对运行时不可见**，运行时已经没有宏了。

## 8. 嵌套宏

- **不支持宏定义的嵌套**（不能在宏定义里再定义一个宏）。
- **有条件地支持在宏定义和宏调用中嵌套宏调用**。
- 内层宏可用 `assertParentContext` 强制"必须嵌套在某个外层宏里"，否则抛错；`insideParentContext` 做同类布尔判断。
- 内层宏还可通过 `setItem` 向外层"发键值对"，外层用 `getChildMessages` 接收——这是宏之间传递消息的标准机制。

## 9. 完整可运行示例（cjpm 项目）

本项目目录：`examples/cangjie/032-macro-dprint/`，两个源文件都被本文章的 code block 引用；cjpm 项目根 `cjpm.toml` 声明了 `[macro-dependencies]`。

**宏定义** `src/define/dprint.cj`：

<!-- example: cangjie/032-macro-dprint/src/define/dprint.cj -->
```cangjie
macro package macro_dprint.define

import std.ast.*

// dprint：调试用的非属性宏。输入是一段 Tokens（原样程序片段），
// 用 quote + 插值把 `expr` 展开成 `print("expr = "); println(expr)`。
public macro dprint(input: Tokens): Tokens {
    let inputStr = input.toString()
    let result = quote(
        print($(inputStr) + " = ")
        println($(input)))
    return result
}
```

**主程序** `src/main.cj`：

<!-- example: cangjie/032-macro-dprint/src/main.cj -->
```cangjie
package macro_dprint

import macro_dprint.define.*

// 使用宏：`@dprint(表达式)` 会打印"表达式原文 = 表达式值"。
main(): Int64 {
    let x = 3
    let y = 2
    @dprint(x)
    @dprint(x + y)
    return 0
}
```

**模块根 `cjpm.toml`**（示意，非同步对象）：

```toml
[package]
  cjc-version = "1.0.5"
  name = "macro_dprint"
  version = "0.1.0"
  output-type = "executable"

[dependencies]

[macro-dependencies]
  [macro-dependencies.define]
    path = "./src/define"
```

`cjpm run` 预期输出：

```text
x = 3
x + y = 5
```

> 项目结构在 macOS 上通过 `cjpm check` 校验（依赖编译顺序合法即通过）；`cjpm build`/`cjpm run` 的最终链接与运行将在 GitHub Actions 的 Linux runner 上执行，与本示例的预期输出逐行比对。

## 10. 语言对比

| 维度 | 仓颉 | Rust | C++ | Kotlin |
|---|---|---|---|---|
| 宏输入 | `Tokens`（词法片段） | `TokenStream` | 预处理器文本 | DSL 靠类型安全构建器 |
| 代码模板 | `quote(...)` + `$(...)` 插值 | `quote! { ... }` + `$var` | `#define` 宏 | 无 |
| 分类 | 非属性宏 / 属性宏 | `macro_rules!` / proc-macro 三类 | 单类 | 无（用注解处理器） |
| 展开期 | 编译期，宏代码本身也在编译期执行 | 编译期 | 预处理器 | 编译期注解处理 |
| 独立性 | 宏必须在专用 `macro package` | proc-macro crate 独立 | 头文件 | 注解在任意包 |
| 嵌套调用 | 有条件支持，父子宏可传键值 | 支持 | 支持 | 部分 |

**从 Rust 迁移**：概念接近（`Tokens`≈`TokenStream`、`quote`≈`quote!`、插值 `$(x)`≈`$x`）；仓颉要求**宏必须放在独立宏包**，比 Rust 的 proc-macro crate 稍强制但思路一致。
**从 C++ 迁移**：仓颉的宏是"类型化的词法/AST 变换"，不是文本替换的预处理器——没有 `#define` 那种一维字符串展开，也就少了很多"忘了加括号"的经典坑。

## 11. 常见问题（FAQ）

### Q1: 为什么 `cjc a.cj` 里 `public macro foo(...)` 报"must be defined in macro package"？

宏必须声明在**独立的宏包**（`macro package name`），且用 `cjpm` 构建带 `[macro-dependencies]` 的项目。单文件 cjc 模式无法声明宏。

### Q2: 非属性宏和属性宏怎么选？

只需要"输入一段程序 → 输出一段程序"就用非属性宏；还需要额外的元信息（策略标记、参数）就走属性宏（`@name[属性](输入)` 或 `@name[属性] 声明`）。

### Q3: 宏定义里 `println("...")` 的输出什么时候出现？

**编译时**。宏是编译期执行的"函数"，它跑的时候是 cjc 在编译；跑完的返回值再被当作源代码继续编译。

### Q4: 为什么宏要 `import std.ast.*`？

`Tokens`、`quote`、语法节点类型都在 `std.ast`；不用它就构造不出宏的输入/输出。

### Q5: quote 里想输出一个 `$` 或不成对的括号怎么办？

`$` 要写成 `\$`；括号不成对时，用 `\(` `\)` 转义那一个。

### Q6: 属性宏调用能不能省 `[]`？

不能。**定义与调用形态必须匹配**：两入参（属性宏）必须写 `[]`（内容可为空）；一入参（非属性宏）不能写 `[]`。

### Q7: 能在宏体里再定义一个宏吗？

不能。仓颉**不支持宏定义的嵌套**。但**支持在宏定义/调用里嵌套宏调用**，父子宏之间用 `setItem`/`getChildMessages` 传键值对。

## 12. 总结

1. 宏是"输入程序、输出程序"的编译期特殊函数；调用一律 `@name`；`Tokens` 是最基本的数据类型。
2. 宏**必须放在独立宏包**（`macro package <模块>.<子包>`），配 `cjpm` 的 `[macro-dependencies]`；单文件 `cjc` 无法声明宏。
3. **非属性宏**：`public macro name(input: Tokens): Tokens`；**属性宏**：`public macro name(attr: Tokens, input: Tokens): Tokens`，调用带 `[]`。
4. `quote(...)` 从代码模板构造 `Tokens`；`$(x)` 插值，`x` 类型必须实现 `ToTokens`。`$` 或不成对的括号需 `\` 转义。
5. 宏调用可作表达式、也可贴在各类声明前；`@name(输入)` 与 `@name 声明` 语义不同。
6. 宏体在编译期运行、对运行时不可见；不支持宏定义的嵌套，但**有条件支持宏调用嵌套**并提供 `assertParentContext`/`setItem`/`getChildMessages` 做父子通信。
7. 本篇示例是一个 cjpm 项目（`examples/cangjie/032-macro-dprint/`），Linux CI 通过 `cjpm build && cjpm run` 输出 `x = 3` / `x + y = 5`。

## 参考资料

1. 仓颉 1.0.5 LTS 宏的简介：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/Macro/macro_introduction.html
2. 仓颉 1.0.5 LTS 宏的实现：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/Macro/implementation_of_macros.html
3. 仓颉 1.0.5 LTS Tokens 与 quote：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/Macro/Tokens_types_and_quote_expressions.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
