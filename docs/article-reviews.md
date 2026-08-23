# 文章审核记录

> 每篇正式文章在进入发布流程前必须完成一次完整审核并记录在此。审核依据：`rules/content-quality.md` + `rules/official-docs.md` + `rules/code-testing.md`。

## 2026-08-22

### 文章：`articles/06-functions.md`（仓颉函数基础）

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（10/10 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/010-functions.cj --output-type staticlib`（仅 `main` 未被显式调用的无害 warning，与其他示例一致）
- [x] 参考资料 3 个官方 1.0.5 链接已于 2026-08-21 完成实际访问检查（见 `reference-link-checks.md`）
- [x] 文章结构完整：标题 / 摘要 / 前置知识 / 7 章正文 / 常见问题 / 总结 / 参考资料 / 版权声明
- [x] 所有代码块使用 `cangjie` 标记；完整可运行示例绑定 `<!-- example: cangjie/010-functions.cj -->`
- [x] 章节覆盖矩阵：基于 `basic_programming_concepts/function.html` + `function/define_functions.html` + `function/call_functions.html` 三章官方内容

**语义核验（额外 cjc 验证）**

- [x] 参数同名重定义报错：在 `func f1(a: Int64)` 函数体内 `var a = 1` 编译报 `redefinition of declaration 'a'`，文章 2.5 节表述正确
- [x] 局部 `var` 遮盖全局 `let`：正常编译通过
- [x] 嵌套函数在外层函数体内定义：正常编译通过
- [x] `greet(name!: String = "仓颉"): String { "你好, ${name}" }` 函数体类型推导为 `String`：正常编译通过
- [x] 命名参数乱序调用 `calculate(1, c: 20, b: 2)`：正常编译通过

**审核中发现并已修复的问题**

1. 4.2 节措辞生硬：「嵌套函数在外层函数调用时被定义」改为「嵌套函数定义在外层函数体内」。
2. 5.2 节对比表格不准确：Go 的「必须显式标注（多返回值除外）」改为「可省略（命名返回值自动推断）」，更贴合 Go 实际语义。

**结论**

✅ 审核通过，可进入待发布状态。

**遗留事项**

- 完整运行验证需在 Linux/Windows 环境或 GitHub Actions 上完成（macOS native runtime 链接限制为已知问题，符合 `rules/code-testing.md` 规范）。
- 与本文章相关的 `function/const_func_and_eval.html`（常量函数）将在后续文章 16 或独立专题承接。


---

## 2026-08-22（文章 7 撰写过程核验）

### 文章：`articles/07-struct.md`（仓颉结构类型 struct）

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（11/11 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/011-struct.cj --output-type staticlib`
- [x] 4 个官方 1.0.5 struct 链接已实际访问核验（define_struct / create_instance / mut / generic_struct）

**覆盖矩阵（官方章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|----------|----------|
| `struct/define_struct.html` 结构体定义、成员变量、静态初始化器、构造函数、成员函数、访问修饰符、禁止递归 | 文章 1-6 节 |
| `struct/create_instance.html` 创建实例、值类型拷贝语义 | 文章 7 节 |
| `struct/mut.html` mut 函数 | 文中 Q7 提示 + 留待后续专题 |
| `generic/generic_struct.html` 泛型结构体 | 留待后续专题 |

**撰写过程 cjc 语义核验**

- [x] `let` 成员无初值时可在 init 中赋值（与官方示例一致）
- [x] `let` 成员有初值时不可在 init 中再赋值（`cannot assign to immutable value`）
- [x] 递归 struct 定义被拒绝（`value type recursive detected: 'R1->R1'`）
- [x] 所有成员有初值且无自定义构造函数时，可调用自动生成的无参 init

**审核中发现并已修复的问题**

1. Q7 关于 `mut` 函数与 `let` 成员的描述不准确：明确说明 `mut` 函数也不能修改 `let` 成员。

**状态**

🔄 初稿已完成，等待用户验收后进入审核流程。


---

## 2026-08-23（文章 8 撰写过程核验）

### 文章：`articles/08-class.md`（仓颉类类型 class）

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（12/12 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/012-class.cj --output-type staticlib`
- [x] 4 个官方 1.0.5 class_and_interface 链接已实际访问核验

**覆盖矩阵（官方章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|----------|----------|
| `class_and_interface/class.html` class 定义、抽象类、构造函数、终结器、成员函数、This 类型、访问修饰符、创建对象、继承与覆盖 | 文章 1-10 节 |
| `class_and_interface/interface.html` | 留待文章 9 |
| `class_and_interface/prop.html` 属性 | 留待文章 9 |
| `class_and_interface/subtype.html` 子类型 | 留待文章 9 |

**撰写过程 cjc 语义核验**

- [x] 抽象函数无 `abstract` 关键字修饰（1.0.5 语法），通过"无函数体 + abstract class 上下文"判定
- [x] `This` 类型作为实例成员函数返回类型
- [x] 子类主构造函数不能重声明父类成员（`the variable 'a' must not shadow a member variable of the supertype`）
- [x] 子类 init 中 `super(args)` 必须作为函数体第一个表达式
- [x] 引用类型：多个变量指向同一对象，修改可见

**状态**

🔄 初稿已完成，等待用户验收后进入审核流程。


---

## 2026-08-23（文章 9 撰写过程核验）

### 文章：`articles/09-interface.md`（仓颉接口、属性与子类型）

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（13/13 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/013-interface.cj --output-type staticlib`
- [x] 4 个官方 1.0.5 class_and_interface 链接已实际访问核验

**覆盖矩阵（官方章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|----------|----------|
| `class_and_interface/interface.html` 接口定义、成员、默认实现、sealed、继承与实现、Any | 文章 1-3 节 |
| `class_and_interface/prop.html` 属性定义、mut、抽象属性、覆盖重定义 | 文章 4 节 |
| `class_and_interface/subtype.html` 子类型关系（class/interface/tuple/function/Nothing/Any/Object/transitivity） | 文章 5 节 |
| `class_and_interface/typecast.html` 类型转换 | 留待后续专题（文章 10 enum/pattern-match 中涉及） |

**撰写过程 cjc 语义核验**

- [x] Any 类型变量不能直接 println（需 ToString 接口），与官方示例一致
- [x] sealed interface 限制包外继承
- [x] 多接口实现 `class C <: A & B`
- [x] 抽象属性 `prop`/`mut prop` 与 getter/setter 实现

**状态**

🔄 初稿已完成，等待用户验收后进入审核流程。


---

## 2026-08-23（文章 10 撰写过程核验）

### 文章：`articles/10-enum.md`（仓颉枚举类型 enum）

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（14/14 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/014-enum.cj --output-type staticlib`
- [x] 4 个官方 1.0.5 enum_and_pattern_match 链接已实际访问核验

**覆盖矩阵（官方章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|----------|----------|
| `enum_and_pattern_match/enum.html` enum 定义、构造器、递归、成员、使用 | 文章 1-4 节 |
| `enum_and_pattern_match/pattern_overview.html` 模式类型 | 留待文章 11 |
| `enum_and_pattern_match/option_type.html` Option 类型 | 留待后续专题 |
| `enum_and_pattern_match/match.html` match 表达式 | 留待文章 11 |

**撰写过程 cjc 语义核验**

- [x] enum 类型不自动实现 ToString，无法直接 println 插值
- [x] 穷尽 enum 的 match 中 `case _` 不可达（编译器告警）
- [x] non-exhaustive enum（带 `...`）的 match 必须有 `case _` 兜底
- [x] 递归 enum（如 Expr 表达式树）正常编译
- [x] enum 实现 interface 正常

**状态**

🔄 初稿已完成，等待用户验收后进入审核流程。
