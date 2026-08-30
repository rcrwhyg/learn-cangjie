# 文章审核记录

> 每篇正式文章在进入发布流程前必须完成一次完整审核并记录在此。审核依据：`rules/content-quality.md` + `rules/official-docs.md` + `rules/code-testing.md`。

## 2026-08-26（文章 9 用户评审意见修复）

### 文章：`articles/09-interface.md`（仓颉接口、属性与子类型）

**核验方式**：逐条回到官方 1.0.5 `class_and_interface/interface.html` 与 `class_and_interface/prop.html` 原文核对。

**用户意见与修复**

| 位置 | 用户意见 | 官方核实结论 | 修复 |
|----|----|----|----|
| 1.3 节（原 96 行） | "`override` 或 `redef` 修饰符可选" | 官方：函数定义前的 `override` **或 `redef`** 修饰符是可选的；文章漏掉了 `redef` | 补上 `redef`，并注明实例成员用 `override`、`redef` 用于同名静态成员的重定义 |
| Q3 | 同样遗漏 `redef` | 同上 | 同步修正 |
| FAQ 新增 | 新增"已经有成员变量了为什么还要有属性？" | 官方 prop 章节明确：属性提供 getter/setter 间接访问，使用与普通变量无异，可更便利地实现访问控制、数据监控、跟踪调试、数据绑定等机制；抽象属性比函数对约定更直观 | 新增 Q9，从封装访问控制、数据校验、派生值（计算属性）、监控/调试/数据绑定、接口约定直观性五个方面详细讲解，并新增规范示例 `examples/cangjie/020-prop-vs-member.cj`（文章 Q9 代码块通过 `example` 标记绑定到该规范源） |

**门禁复验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（20/20 示例一致）
- [x] 本地静态库编译通过：`./tools/test-local.sh`（20/20 通过，含新增 `020-prop-vs-member.cj`）
- [ ] 完整运行验证待 GitHub Actions（Linux runner）完成；Q9 示例输出采用布尔断言（`true`），避免在无法实跑的 macOS 上臆测 Float64 打印格式

**状态**

✅ 用户审核通过并已发布。

## 2026-08-25（阶段一发布状态更新）

- 用户确认：阶段一文章 1 至文章 8 均已完成审核并发布。
- 阶段一当前进度：**8/15 篇已发布**。
- 下一篇待推进文章：文章 9《仓颉接口、属性与子类型》。

## 2026-08-26（阶段一发布进度更新）

- 用户确认：文章 9、10、11 均已完成审核并发布。
- 阶段一当前进度：**11/15 篇已发布**。
- 下一篇待推进文章：文章 12《仓颉数组、元组与区间》（审核中）。

## 2026-08-26（阶段一发布进度更新 · 续）

- 用户确认：文章 12《仓颉数组、元组与区间》完成审核并发布。
- 阶段一当前进度：**12/15 篇已发布**。
- 下一篇待推进文章：文章 13《仓颉字符串与字符处理》。

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

## 2026-08-25（文章 7 用户评审意见修复）

### 文章：`articles/07-struct.md`（仓颉结构类型 struct）

**核验方式**：逐条回到官方 1.0.5 `struct/define_struct.html` 与 `function/operator_overloading.html` 原文核对。

**用户意见与修复**

| 行（修复前） | 用户意见 | 官方核实结论 | 修复 |
|----|----|----|----|
| 26（成员属性） | 结构体是否含成员属性？后文未详述 | `define_struct` 明确：struct 定义体可含"成员属性（参见属性）"，合法 | 保留该条目，并加注"定义方式与 class 一致，详见官方《属性》章节，将在《接口、属性与子类型》展开" |
| 30（操作符函数） | 结构体是否支持操作符函数？后文未详述 | `define_struct` 明确 struct 成员含"操作符函数"；`operator_overloading` 明确"操作符函数只能定义在 class、interface、struct、enum 和 extend 中" | 保留该条目，并加注"详见官方《操作符重载》，后续函数专题展开" |
| 118（主构造等价） | 等价介绍不明确 | 官方：主构造函数"同时扮演定义成员变量和构造函数参数的功能" | 改写为"先声明两个 let 成员 + 再写把参数赋给成员的普通构造函数"，并给出展开后的等价代码 |
| 159（实例函数访问成员） | 去掉"同名的"，需代码示例 | 官方：实例成员函数中可通过 `this` 访问实例成员变量 | 删除"同名的"，新增 `Counter` 示例演示直接访问与 `this` 消歧 |
| 205（访问修饰符） | 区分当前模块/外部模块，当前模块应优先 `protected` | 官方：`protected`=当前模块可见，`public`=模块内外均可见 | 改写为按"同模块内其他包用 protected / 跨模块用 public"区分 |
| 209（递归禁止） | 参照官方核实 | `define_struct`：递归和互递归定义的 struct 均是非法的 | 加"官方《定义 struct 类型》明确禁止" |
| 224（布局） | 应描述编译器确定内存布局 | — | "确定布局"改为"确定内存布局" |
| 251 & Q5 | 突出引用类型成员状况，Q5 拆分"不影响/影响" | 官方 `create_instance`：成员变量为引用类型时仅复制引用 | 新增 7.1 节专门讲引用类型成员（含 `Pair` 示例）；Q5 拆分：Q5 值类型成员不影响、Q6 引用类型成员会互相影响 |
| 411（Q7 条件） | — | — | 随 Q5 拆分顺延为 Q8 |

**新增参考链接（已实际访问 200 OK）**

- 属性：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/class_and_interface/prop.html
- 操作符重载：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/function/operator_overloading.html

**门禁复验**

- [x] 同步检查通过（`sync_examples.py`，19/19 一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/011-struct.cj --output-type staticlib`（新增 `Pair` 引用类型示例编译通过）

**状态**

✅ 已按用户评审意见修复，用户审核通过并已发布。


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

✅ 初稿已完成，用户审核通过并已发布。


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

✅ 用户审核通过并已发布。


---

## 2026-08-23（文章 11 撰写过程核验）

### 文章：`articles/11-pattern.md`（仓颉模式匹配）

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（15/15 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/015-pattern.cj --output-type staticlib`
- [x] 4 个官方 1.0.5 enum_and_pattern_match 链接已实际访问核验

**覆盖矩阵（官方章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|----------|----------|
| `enum_and_pattern_match/pattern_overview.html` 6 种模式 | 文章 2-7 节 |
| `enum_and_pattern_match/match.html` match 表达式 | 文章 9 节 |
| `enum_and_pattern_match/other.html` 模式在其他位置 | 文章 10 节 |

**撰写过程 cjc 语义核验**

- [x] 常量、通配符、绑定、Tuple、类型、enum 六种模式都覆盖
- [x] 模式守卫 where 子句
- [x] 嵌套模式（Tuple 内嵌 enum，enum 内嵌常量/绑定）
- [x] irrefutable 模式在 let / for-in 中可用
- [x] 常量传播：match 目标值为编译期常量时，编译器会告警"不可达"分支（已通过将匹配封装在函数中规避）

**状态**

✅ 用户审核通过并已发布。

---

## 2026-08-23（文章 12 撰写过程核验）

### 文章：`articles/12-array-tuple-range.md`（仓颉数组、元组与区间）

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（16/16 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/016-array-tuple-range.cj --output-type staticlib`
- [x] 3 个官方 1.0.5 basic_data_type 链接已实际访问核验（array / tuple / range）

**覆盖矩阵（官方章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|----------|----------|
| `basic_data_type/array.html` Array 创建/访问/切片/操作符/类型转换/VArray | 文章 1-3 节 |
| `basic_data_type/tuple.html` Tuple 字面量/类型参数/访问/多赋值 | 文章 4 节 |
| `basic_data_type/range.html` Range 字面量/遍历/steps 形式 | 文章 5 节 |
| FAQ + 总结 + 参考资料 | 文章 6-7 节 + FAQ + 总结 |

**撰写过程 cjc 语义核验**

- [x] `Array<Int64>` 通过字面量 `[1, 2, 3]` 创建，元素读取 `a[0]`、修改 `a[0] = 100`（下标类型为 Int64）
- [x] 数组切片 `arr1[0..5]`（半开，得 [0,1,2,3,4]）、`arr1[..3]`（省略 start，得 [0,1,2]）、`arr1[2..]`（省略 end，得 [2,3,4,5,6]）
- [x] Array 引用语义：`let arr2 = arr1` 后 `arr2[0] = 99` 同时影响 `arr1`（内部持有元素引用，不拷贝）
- [x] `VArray<Int64, $3>` 栈上定长值类型数组，支持 `for-in` 与下标读写
- [x] Tuple 多类型字面量 `(3.14, "PI")`；通过 `pi[0]`/`pi[1]` 下标访问（下标须为 0 起整数字面量）
- [x] Tuple 多赋值 `var (x, y) = (1, 2)` 与 `(x, y) = (y, x)` 交换
- [x] 命名元组 `let p: (name: String, age: Int64) = ("Alice", 30)`：参数名仅用于类型标注，`p.name` 编译报错，只能经 `p[0]`/`p[1]` 下标访问
- [x] `Range<Int64>` 字面量 `0..10`（左闭右开）、`0..=10`（双闭）、`0..10 : 2`（带步长，默认 1 且不能为 0）
- [x] `for (i in 0..5) { ... }` 与 `for-in` 遍历 Array / VArray / Range 一致行为

**状态**

✅ 用户审核通过并已发布。

---

## 2026-08-26（文章 12 独立核实修复）

### 文章：`articles/12-array-tuple-range.md`（仓颉数组、元组与区间）

**核验方式**：回到官方 1.0.5 `basic_data_type/array.html`、`tuple.html`、`range.html` 原文逐条核对。

**发现的问题与修复**

| 位置 | 问题 | 官方核实结论 | 修复 |
|----|----|----|----|
| 1.0 节（原第 14 行） | "Array 是引用类型" 与官方及本文后文（Q1、1.4 节）矛盾 | 官方：`Array 虽然是 struct 类型，但其内部持有的只是元素的引用` | 改为"Array 是 struct 类型（值类型），但内部持有元素引用，因此表现为引用语义" |
| 1.2.3 节下标示例 | "负数下标运行时异常""越界" 均标为运行时异常 | 官方：编译器能检查出的非法下标会**编译报错**，否则才运行时异常；字面量下标属编译期可判定 | 改为"编译报错" |
| Q8 | "Range 实现了迭代器协议...支持 Iterator 接口的 next()" 过度声明 | 官方 range 文档仅确认 `for-in` 可遍历，未明说实现 `Iterator` 接口 | 改为"支持 `for-in` 遍历，底层遵循标准库迭代器协议（详见标准库）" |

**门禁复验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（20/20 示例一致，文章 12 仅改正文未动规范源）
- [x] 本地静态库编译通过：`./tools/test-local.sh`（20/20 通过，`016-array-tuple-range.cj` 未改动）

**状态**

✅ 用户审核通过并已发布。

---

## 2026-08-23（文章 13 撰写过程核验）

### 文章：`articles/13-strings-and-characters.md`（仓颉字符串与字符处理）

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（17/17 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/017-strings-and-characters.cj --output-type staticlib`
- [x] 2 个官方 1.0.5 basic_data_type 链接已实际访问核验（strings / characters）

**覆盖矩阵（官方章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|----------|----------|
| `basic_data_type/strings.html` 字符串字面量（单行/多行/原始）、插值、关系运算、+、常用方法 | 文章 1-4 节 |
| `basic_data_type/characters.html` Rune 字面量（单字符/转义/通用字符）、Rune 关系运算、Rune↔UInt32 转换 | 文章 5 节 |
| String 与 Rune 互转（`toRuneArray`、ASCII 字面量→Byte/Rune） | 文章 6 节 |
| FAQ + 总结 + 参考资料 | 文章 7-8 节 + FAQ + 总结 |

**撰写过程 cjc 语义核验**

- [x] 单行字符串双引号/单引号等价（`"..."` == `'...'`）
- [x] 多行字符串 `"""..."""` 可跨行、可含插值
- [x] 多行原始字符串 `##"..."##` 中 `\n`、`\u{4f60}` 不转义
- [x] 字符串插值 `${expr}` 与多表达式序列（用 `;` 分隔，取最后一个值）
- [x] 字符串关系运算 `==`/`<`/`<=`/`>`/`>=`/`!=` 是内容相等
- [x] `+` 拼接：`"abc" + "ABC"` 正常
- [x] 常用方法：`size`、`isEmpty`、`contains`、`startsWith`、`endsWith`、`indexOf`、`count`、`split`、`replace`、`toAsciiUpper`、`toAsciiLower`、`toRuneArray` 全部可用
- [x] `String[i]` 返回 `Byte`（UInt8），不是 `Rune`
- [x] `String.toRuneArray(): Array<Rune>` 按 Unicode 码点拆分
- [x] Rune 字面量 `r'a'`、`r'\n'`、`r'\u{4f60}'`（通用字符 1~8 位十六进制）
- [x] Rune 关系运算按 Unicode 码点比较（`'你' > 'A'`，因为你 = 0x4f60）
- [x] `UInt32(r)` 与 `Rune(UInt32(65))` 双向转换
- [x] 文档中提到的 Byte↔ASCII 字符串字面量、Rune↔单字符字符串字面量的隐式赋值（仅限字面量场景）

**状态**

🔄 初稿已完成，等待用户验收后进入审核流程。

---

## 2026-08-23（文章 14 撰写过程核验）

### 文章：`articles/14-collection.md`（仓颉 Collection 集合类型）

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（18/18 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/018-collection.cj --output-type staticlib`
- [x] 1 个官方 1.0.5 文档索引链接（https://docs.cangjie-lang.cn/docs/1.0.5/ ）已实际访问核验（200 OK）

**关于参考链接的特殊说明**

仓颉 1.0.5 LTS 标准库文档托管在 `cangjie-lang.cn` 域名（**注意没有 `docs.` 前缀**），通过 `/docs?url=/1.0.5/libs/std/collection/...` 形式访问。最初仅探测了 `docs.cangjie-lang.cn` 域名，误判为不存在；用户提示真实 URL 后，6 个链接全部 200 OK（约 26~27KB 字节数）。文章 14 的 API 描述与官方 `libs/std/collection/...` 章节保持一致。

**覆盖矩阵（SDK 模块 → 文章承接）**

| 类型 / 功能 | 覆盖位置 |
|---|---|
| `ArrayList<T>` 创建、属性（size / first / last / capacity）、增删改查、reverse、slice、clear、toArray | 文章 2.1-2.5 节 |
| `ArrayList<T>` 排序（`std.sort.sort` 全局函数） | 文章 2.4 节 |
| `HashSet<T>` 创建、add/remove/contains、集合运算 `\|` `&` `-`、subsetOf、retain、toArray、遍历 | 文章 3.1-3.5 节 |
| `HashMap<K, V>` 创建、`[]` get/set、add/remove/contains、keys()/values()、遍历、词频统计 | 文章 4.1-4.4 节 |
| 集合选型指南 | 文章 5 节 |
| FAQ + 总结 + 参考资料 | 文章 6-7 节 + FAQ + 总结 |

**撰写过程 cjc 语义核验**

- [x] `ArrayList<T>(arr)` 从 Array 构造；`ArrayList<T>([...])` 从字面量构造
- [x] `ArrayList<T>(n, {i => v})` 长度 n 的 lambda 初始化
- [x] `first` / `last` 是**属性**而非方法（`list.first` 正确，`list.first()` 编译报错）
- [x] `add(value)` / `add(value, at: idx)` / `add(all: collection)`
- [x] `remove(at: idx)` 按下标删；`remove(range)` 按区间删；**无 `remove(value)`**，按值删用 `removeIf(closure)`
- [x] `remove(value)` 直接调用会与 `remove(range)` 歧义报 `cannot convert an integer literal to type 'Struct-Range<Int64>'`
- [x] `[]` 下标可读可写；`get(idx)` 同步取值
- [x] `ArrayList.sort()` 已废弃，推荐用 `import std.sort.sort; sort(unsorted)` 全局函数
- [x] `HashSet<T>` 的 `add` / `remove` 返回 `Bool`（是否真的改变了集合）
- [x] `HashSet` 三个运算符 `|`（并）/ `&`（交）/ `-`（差）返回**新集合**
- [x] `subsetOf(other)` 子集判断
- [x] `retain(all: collection)` 原地保留交集
- [x] `HashMap<K, V>` 的 `[]` get 返回值类型（缺失键返回零值，**不抛异常**）；`[]` set 写值
- [x] `map[k]` 缺失键时若 V 是引用类型返回 `null`，需要 `??` 兜底
- [x] `keys(): Collection<K>`、`values(): Collection<V>` 是方法（带括号）
- [x] `for ((k, v) in map)` 元组解构遍历
- [x] `ArrayList` / `HashSet` / `HashMap` 都实现 `Equatable`，可用 `==` 比较内容

**状态**

🔄 初稿已完成，等待用户验收后进入审核流程。

---

## 2026-08-23（文章 15 撰写过程核验）

### 文章：`articles/15-package-module-entry.md`（仓颉包、模块与程序入口）

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（19/19 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/019-package-module-entry.cj --output-type staticlib`
- [x] 6 个官方 1.0.5 dev-guide 链接已实际访问核验（全部 200 OK）

**覆盖矩阵（官方章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|---|---|
| `basic_programming_concepts/program_structure.html` 顶层作用域、变量、作用域 | 文章 1 节 |
| `package/package_overview.html` 包的定义、模块的定义 | 文章 2、3 节 |
| `package/import.html` import 各种语法、隐式 import core、import as、重导出、import 可见性 | 文章 4 节 |
| `package/entry.html` main 入口合法签名与限制 | 文章 5 节 |
| `package/toplevel_access.html` 4 级访问修饰符、默认修饰符 | 文章 2.3-2.4 节 |
| `first_understanding/hello_world.html` cjpm init / cjpm run | 文章 3 节 |
| FAQ + 总结 + 参考资料 | 文章 7-8 节 + FAQ + 总结 |

**撰写过程 cjc 语义核验**

- [x] `package` 声明必须出现在源文件首行
- [x] `import std.collection.ArrayList` 单个导入
- [x] `import std.collection.{HashSet, HashMap}` 批量导入
- [x] `import std.collection.ArrayList as AL` 重命名导入
- [x] 顶层变量 `public let / let / private let` 三种可见性
- [x] 顶层函数 `public / internal / protected` 三种可见性
- [x] 顶层 struct / class / enum 的 public 声明
- [x] `String` / `Int64` / `Array` / `Range` 隐式导入（无需 import）
- [x] `main(): Int64` / `main(): Unit` / `main(args: Array<String>): Int64` / `main(args: Array<String>): Unit` 四种合法签名
- [x] `main` 不可被访问修饰符修饰
- [x] `Range.size` 不存在（用 `r.start` / `r.end` 属性）
- [x] `enum` 不实现 `ToString`，不能直接 `${c}` 插值；用 `match` 转换
- [x] `main` 返回 String 编译报错：`expected 'Int64', found 'Struct-String'`
- [x] `import std.io.*` 通配符导入若未使用会报 unused import warning

**状态**

🔄 初稿已完成，等待用户验收后进入审核流程。

---

## 文章 16《仓颉函数类型、Lambda 与闭包》核验记录

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（21/21 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/021-functions-lambda-closure.cj --output-type staticlib`
- [x] 5 个官方 1.0.5 dev-guide function 链接已实际访问核验（全部返回对应页面内容）

**覆盖矩阵（官方 function 章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|---|---|
| `function/first_class_citizen.html` 函数类型、类型参数名、作参数/返回值/变量、`->` 右结合 | 文章 1 节 |
| `function/nested_functions.html` 嵌套函数作用域/返回 | 文章 2 节 |
| `function/lambda.html` Lambda 定义、`=>`、参数与返回类型推断、立即调用 | 文章 3 节 |
| `function/closure.html` 变量捕获定义、可见/初始化约束、捕获 var 不可一等公民、传递性 | 文章 4 节 |
| `function/function_call_desugar.html` 尾随 lambda、pipeline、composition、变长参数 | 文章 5 节 |
| `function/function_overloading.html` + `operator_overloading.html` | 拆分为独立专题篇（本次不写） |

**撰写过程 cjc 语义核验（正例：示例 021 整体编译通过；负例：以下均以报错确认）**

- [x] 函数类型 `(T1,T2)->R`、作参数/返回值/变量；`->` 右结合
- [x] 函数类型类型参数名"全写或全不写"：混写报 `either all parameters must be named, or none of them`
- [x] 重载函数名作表达式：`var f = add` 报 `ambiguous use of 'add'`；带目标类型 `var plus: (Int64,Int64)->Int64 = add` 通过
- [x] Lambda 参数类型可由变量类型 / 形参类型推断
- [x] 捕获 `var` 的闭包赋值给变量：报 `function capturing mutable variables needs to be called directly`
- [x] 命名参数不能用变长语法：`length(1,2,3)` 报 `expected 1 argument, found 3`
- [x] 尾随 lambda `myIf(true){100}`、唯一 lambda 实参省略圆括号 `callWithLambda { i => i*i }`
- [x] pipeline `5 |> inc |> square`、composition `inc ~> double`
- [x] 变长参数 `sum()` / `sum(1,2,3)`

**状态**

🔄 初稿已完成（同步 + 本地编译通过），等待用户验收；真实运行输出将在 GitHub Actions（Linux）确认。

---

## 文章 17《仓颉函数重载与操作符重载》核验记录

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（22/22 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/022-overloading.cj --output-type staticlib`
- [x] 4 个官方 1.0.5 dev-guide function + Appendix 链接已实际访问核验（全部返回对应页面内容）

**覆盖矩阵（官方 function 章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|---|---|
| `function/function_overloading.html` 重载定义、构造器重载、跨作用域/父子类重载、非重载情形、决议规则 | 文章 1-2 节 |
| `function/operator_overloading.html` 五条限制、可重载操作符表、复合赋值、`[]` get/set、`()`、`extend` 定义 | 文章 3 节 |
| `Appendix/operator.html` 完整操作符优先级/结合性表（用于对照） | 文章 3.2 节 |
| `function/function_call_desugar.html` 变长参数与重载决议的交互 | 已并入文章 16 |

**撰写过程 cjc 语义核验**

正例（示例 022 整体编译通过 + CI 将执行验证）：

- [x] 参数个数不同的函数重载
- [x] 参数类型不同的函数重载
- [x] 构造器重载（无参 / 一参 / 两参）
- [x] 父类与子类同名不同参 → 构成重载
- [x] 按实参类型选最匹配（`area(Sub())` vs `area(Base())`）
- [x] 一元 `-`、二元 `+`/`*`、`==` 判等操作符重载
- [x] 索引 `[]` 取值 / 赋值分离（`value!` 命名参数、struct 需 `mut`）
- [x] 复合赋值 `+=` 自动获得（`+` 返回类型 = 左操作数类型）
- [x] 函数调用 `()` 操作符重载

负例（cjc 实测报错，与官方文档表述一致或更精确）：

- [x] 静态与实例同名不同参 → `overloaded functions 'f' cannot mix static and non-static`
- [x] 两个同名函数类型变量 → `redefinition of declaration 'f'`
- [x] 变量与函数同名 → `functions and variables cannot have the same name`（官方文档说明）
- [x] `public` 声明使用 `internal` 类型 → `'public' declaration uses 'internal' types`
- [x] `static operator func` → `'operator' and 'static' modifiers conflict on function declaration`
- [x] `operator func` 为泛型 → `generic is not allowed in operator overload function`
- [x] `extend Int64` 重载同签名 `+` → `operator func +(Int64) of type Int64 is a built-in function and cannot be overridden`
- [x] 二元操作符返回类型不匹配左操作数 → 复合赋值 `a += b` 报 `type incompatible in this compound assignment expression`
- [x] 同等匹配两个候选 → `ambiguous match for function call`

**与官方表述的小差异（更精确化）**

- 官方文档对 `enum` 里 `X(Int64)` 构造器与 `operator func ()(p: Int64)` 同时匹配时优先构造器：文档明确写了这条规则，示例 022 未演示（避免混淆）
- 官方文档示例里给"this() 调 `()` 操作符"标为 Error；1.0.5 SDK 实际报 `invalid calling 'this' outside the constructor`（措辞差异，语义一致：`this()` 属于构造器语法）

**状态**

🔄 初稿完成（本地静态库编译通过），等待用户验收；真实运行输出待 GitHub Actions 确认。

---

## 文章 18《仓颉泛型编程》核验记录

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（23/23 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/023-generics.cj --output-type staticlib`
- [x] 9 个官方 1.0.5 dev-guide generic 链接已实际访问核验（全部返回对应页面内容）

**覆盖矩阵（官方 generic 章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|---|---|
| `generic/generic_overview.html` 类型形参/变元/实参/构造器术语 | 文章 1 节 |
| `generic/generic_function.html` 全局/局部/成员/静态泛型函数、extend 泛型函数 | 文章 2 节 |
| `generic/generic_constraint.html` 接口约束、class 约束、多 class 上界同链 | 文章 3 节 |
| `generic/generic_class.html` 泛型类、静态成员不能引用类型形参 | 文章 4.1 节 |
| `generic/generic_struct.html` 泛型结构体 | 文章 4.2 节 |
| `generic/generic_enum.html` 泛型枚举、Option、safeDiv | 文章 4.3 节 |
| `generic/generic_interface.html` 泛型接口 | 文章 4.4 节 |
| `generic/generic_subtype.html` 不型变、元组协变、函数逆变/协变 | 文章 5 节 |
| `generic/typealias.html` 类型别名规则、泛型别名 | 文章 6 节 |
| `generic/generic_function.html` 中 extend 泛型成员函数细节 | 只带到，留给《扩展机制》专题（19） |

**撰写过程 cjc 语义核验**

正例（示例 023 整体编译通过 + CI 将执行）：

- [x] 泛型函数 `id<T>`、`where T <: ToString` 接口约束、多形参 `compose<T1,T2,T3>`
- [x] 泛型 struct `Pair<T,U>`、class `Stack<T>`、enum `MyOption<T>`、interface `Describable<T>`
- [x] 泛型成员函数（Box 的 `mapInto<U>` 独立于类形参 `T`）
- [x] 静态泛型函数（`Box<Int64>.singleton(100)`）
- [x] 泛型不变性：只能构造 `Container<Animal>` 用 `Holder<Animal>` 传入
- [x] 类型别名作变量类型 / 构造器名、泛型别名 `MyStack<T> = Stack<T>`
- [x] 元组协变 `(D,D): (C,C)`；函数入参逆变 + 返回协变 `(C)->D` 可作 `(D)->C`

负例（cjc 实测报错，与官方文档一致）：

- [x] 泛型类静态成员引用类型形参 → `static member cannot depend on generic parameter 'Generics-T'`
- [x] `I<D> <: I<C>` 违反不型变 → `mismatched types`
- [x] `where T <: A & B` 两条独立继承链 → `cannot have two or more class upper bounds ... without subtype relation`
- [x] 别名定义在 main 内 → `unexpected type alias declaration in main function body`
- [x] 别名循环引用 `type A = (Int64, A)` → `undeclared type name 'A'`
- [x] 别名作类型转换 `MyInt(0)` → `no matching function for operator '()' function call`
- [x] 泛型别名带 `where` → `expected ';' or '<NL>', found keyword 'where'`
- [x] 违反 `T <: ToString` 约束 → `generics type arguments do not match the constraint`

**状态**

🔄 初稿完成（本地静态库编译通过），等待用户验收；真实运行输出待 GitHub Actions 确认。

---

## 文章 19《仓颉扩展机制》核验记录

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（24/24 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/024-extension.cj --output-type staticlib`
- [x] 4 个官方 1.0.5 dev-guide extension 链接已实际访问核验（全部返回对应页面内容）

**覆盖矩阵（官方 extension 章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|---|---|
| `extension/extend_overview.html` 扩展四类能力、两类用法、四条限制 | 文章 1 节 |
| `extension/direct_extension.html` 直接扩展、泛型扩展两种形式、条件能力 `where` | 文章 2、3 节 |
| `extension/interface_extension.html` 接口扩展、多接口 `&`、默认实现解析顺序 | 文章 4 节 |
| `extension/access_rules.html` 扩展修饰符、`this/super`、遮盖、同包互访、可见性、孤儿规则、导入导出 | 文章 5-8 节 |

**撰写过程 cjc 语义核验**

正例（示例 024 整体编译通过）：

- [x] `extend String { shout }`（直接扩展成员函数）
- [x] `extend Vec { prop lenSq }`（成员属性）
- [x] `extend Vec { operator func + }`（操作符重载）
- [x] `extend Vec { mut func scaleBy }`（struct 扩展 mut 函数）
- [x] `extend<T> Array<T> <: PrintSizeable`（接口扩展 + 泛型）
- [x] `extend EqInt <: Eq<EqInt>`（对自定义类接口扩展）
- [x] `extend<T1, T2> Pair<T1,T2> where T1<:Eq<T1>, T2<:Eq<T2>`（泛型扩展 + 条件能力）
- [x] 同包多次扩展互访非 private 成员（`bumpTwice` 调 `bump`）

负例（cjc 实测报错，与官方文档表述一致）：

- [x] `extend A { var x }` → `unexpected variable declaration in extend body`
- [x] `public extend A {}` → `expected no modifier before extend declaration, found 'public'`
- [x] `extend A { public open func g() }` → `unexpected modifier 'open' on function declaration in extend body`
- [x] 扩展里访问被扩展类型的 private → `can not access field 'v'`
- [x] 扩展同名成员遮盖被扩展类型成员 → `extend member 'f' is not allowed to shadow members of 'Class-A'`
- [x] 扩展里用 `super` → `'super' is not allowed inside an extend declaration`
- [x] 不能扩展 interface → `extending type 'Interface-I' is not allowed`
- [x] `extend MyList {}`（未实例化）→ `generic type should be used with type argument`
- [x] `extend<T,R> MyList<T> {}`（R 未使用）→ `type parameter 'R' must be used in extended type`
- [x] `extend Foo<Bar> {}`（Bar 不满足 Foo 的 `T<:ToString`）→ `generics type arguments do not match the constraint`

**未纳入示例但正文说明的官方规则**

- 接口扩展父子接口默认实现"先父后子"、冲突时 `unable to decide which extension happens first` / `multiple default implementations`（示例 024 未演示）
- 官方点名的泛型基类 + 扩展实现接口 + 默认实现调用"非预期行为"陷阱（正文以⚠️ 注意形式提示）
- 孤儿规则、扩展导出/导入细则（正文以规则形式列出，跨包测试非单文件示例范畴）

**状态**

🔄 初稿完成（本地静态库编译通过），等待用户验收；真实运行输出待 GitHub Actions 确认。

---

## 文章 20《仓颉错误处理与 Option》核验记录

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（25/25 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/025-error-option.cj --output-type staticlib`
- [x] 5 个官方 1.0.5 dev-guide 链接已实际访问核验（error_handle 3 页 + enum_and_pattern_match/option_type + error_handle/use_option）

**覆盖矩阵（官方 error_handle 与 Option 章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|---|---|
| `error_handle/exception_overview.html` Error/Exception 分支、自定义异常、`getClassName` | 文章 1 节 |
| `error_handle/handle.html` throw/try-catch-finally/CatchPattern/try-with-resources | 文章 2-4 节 |
| `error_handle/common_runtime_exceptions.html` 5 个内置运行时异常 | 文章 5 节 |
| `enum_and_pattern_match/option_type.html` Option 定义、`?T` 语法糖、自动装箱、`None<T>` | 文章 6.1 节 |
| `error_handle/use_option.html` match / `??` / `?.` / `getOrThrow` | 文章 6.2-7 节 |

**撰写过程 cjc 语义核验**

正例（示例 025 整体编译通过 + CI 将执行验证）：

- [x] 自定义 `AppException <: Exception` 且重写 `getClassName`
- [x] `throw` + `try-catch-finally`（含 finally 必执行）
- [x] `catch (e: A | B)` 联合类型模式，`e.message` 走公共父类
- [x] `catch (_)` 通配符模式
- [x] try 作表达式：类型 = finally 外各分支的最小公共父类型
- [x] try-with-resources：`try (w = Worker)` 自动 close
- [x] `?Int64` = `Option<Int64>`；`let c: Option<Int64> = 300` 自动 Some 装箱
- [x] `match` / `??` / `?.` / `getOrThrow` 四种 Option 解构
- [x] `safeDiv(a, b): ?Int64` 用 Option 传播"可预期失败"

负例（cjc 实测报错，与官方一致）：

- [x] 不能继承 Error 自定义异常（文档明确规则；本文档未生成具体报错文本以避免臆测）
- [x] 1.0.5 SDK **不存在** `Result<T,E>`：`let x: Result<Int64,String>` → `undeclared type name 'Result'`、`undeclared identifier 'Ok'`
- [x] 联合模式最小公共父类：官方文档示例 `e is Father` → `true`

**关键差异提示**

- 与 Rust/Kotlin 迁移读者明确说明：仓颉 1.0.5 **没有 `Result`**，**`?` 只做类型糖/安全访问**（不是早返回运算符）。

**状态**

🔄 初稿完成（本地静态库编译通过），等待用户验收；真实运行输出待 GitHub Actions 确认。

---

## 文章 21《仓颉资源管理》核验记录

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（26/26 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/026-resource-management.cj --output-type staticlib`
- [x] 2 个官方 1.0.5 dev-guide 链接已实际访问核验（class.html 含终结器小节 + error_handle/handle.html 含 try-with-resources）

**覆盖矩阵（官方 资源管理相关章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|---|---|
| `class_and_interface/class.html` §class 终结器：`~init` 定义 + 12 条限制 | 文章 4 节 |
| `error_handle/handle.html` §try-with-resources：`Resource` 接口、多资源、类型 Unit | 文章 2-3 节 |
| `std.runtime.gc`（class 终结器官方示例中引用的 API） | 文章 5 节 |
| 内存模型 / GC 算法原理 | 明确延后到《值类型、引用类型与内存管理》专题 |

**撰写过程 cjc 语义核验**

正例（示例 026 整体编译通过 + CI 将执行验证）：

- [x] `class Conn <: Resource` 实现 isClosed/close，`try (c = Conn(..))` 自动关闭
- [x] 多资源 `try (r1 = .., r2 = ..)`
- [x] 手动 close 对照
- [x] 非 open class 带 `~init()`（内部计数，不打印，避免依赖时机）
- [x] `import std.runtime.gc` + `gc(heavy: true)` 编译通过（`gc()` 也通过）

负例（cjc 实测报错，逐条对应官方规则）：

- [x] 规则2：`open class C { ~init() {} }` → `finalizer is forbidden in class 'C' that is open`
- [x] 规则1：显式调用 `c.~init()` → `expected a member name after '.'`（语法不允许）
- [x] 规则4：`extend C { ~init() {} }` → `unexpected finalizer in extend body`
- [x] 规则1：`private ~init()` → `unexpected modifier 'private' on finalizer in class body`

**关键取舍（诚实标注，不臆测）**

- 官方**未承诺**多资源关闭顺序 → 正文与 Q7 明确"不要依赖关闭顺序"，示例注释也删去了"逆序"字样
- 终结器时机/线程/顺序不确定（规则5/6/7/12）→ 示例把可观察输出放在 try-with-resources，终结器不打印，避免 CI 输出不确定
- 未在正文声称具体 GC 触发后终结器一定运行（规则12 禁止同步依赖）

**状态**

🔄 初稿完成（本地静态库编译通过），等待用户验收；真实运行输出待 GitHub Actions 确认。

---

## 文章 22《仓颉并发模型概述》核验记录

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（27/27 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/027-concurrency-overview.cj --output-type staticlib`
- [x] 3 个官方 1.0.5 dev-guide concurrency 链接已实际访问核验（concurrency_overview / create_thread / use_thread）

**覆盖矩阵（官方 concurrency 章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|---|---|
| `concurrency/concurrency_overview.html` 语言线程 vs native 线程、1:1 vs M:N、抢占、阻塞再调度、foreign 注意事项 | 文章 1-4 节 |
| `concurrency/create_thread.html` `spawn { }` 创建任务 | 文章 5 节（只带到，API 细节给 23） |
| `concurrency/use_thread.html` `Future<T>`、`get()` 阻塞取结果 | 文章 5-6 节（仅用 get() 收敛确定性输出） |
| 线程访问/终止/睡眠、同步原语 | 明确留给《线程与协程使用》《同步与并发原语》（23/24） |

**撰写过程 cjc 语义核验**

- [x] `spawn { ... }` 返回 `Future<Int64>`；`get()` 阻塞并返回结果
- [x] 示例 027 用两个任务（求和 5050 / 阶乘 3628800）+ `get()` 收敛，输出确定，不依赖调度顺序
- [x] `import std.concurrent` 不存在（报 can not find package），确认 spawn/Future/Thread 属 core，无需 import
- [x] `sleep`/`ThisThread.current()` 等具体 API 未用于本篇示例（属 23 篇），未臆测其签名

**与官方一致的边界声明（诚实）**

- 本篇是"模型概述"，可运行示例刻意只做最小 spawn+get；线程终止/睡眠/锁等明确划归后续文章，不越界写未核验 API
- foreign 阻塞占住 native 线程、新线程随主线程结束等，均为官方 concurrency_overview/create_thread 原文要点

**状态**

🔄 初稿完成（本地静态库编译通过），等待用户验收；真实运行输出待 GitHub Actions 确认。
