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

---

## 文章 23《仓颉线程与协程使用》核验记录

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（28/28 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/028-thread-usage.cj --output-type staticlib`
- [x] 4 个官方 1.0.5 dev-guide concurrency 链接已实际访问核验（create_thread / use_thread / terminal_thread / sleep）

**覆盖矩阵（官方 concurrency 章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|---|---|
| `concurrency/create_thread.html` `spawn{=>...}`、主线程结束带走子线程、`sleep` 预告 | 文章 1 节 |
| `concurrency/use_thread.html` `Future<T>`：`get/get(timeout)/tryGet` 原型、`Thread`（currentThread/id/hasPendingCancellation）、`fut.thread` | 文章 2-3 节 |
| `concurrency/terminal_thread.html` `cancel()` + `hasPendingCancellation` 协作式终止、`SyncCounter` 门控示例 | 文章 4 节 |
| `concurrency/sleep.html` `sleep(Duration)`、`<=Zero` 仅让出、`Duration.second/millisecond` | 文章 5 节 |
| `concurrency/sync.html`（锁/通道等同步原语） | 明确留给《同步与并发原语》（24） |

**撰写过程 cjc 语义核验**

正例（示例 028 整体编译通过 + CI 将执行验证）：

- [x] `Future<Int64>.get()` 阻塞取值；`tryGet(): Option<T>` 完成后 Some
- [x] `Thread.currentThread.id`、任务内返回自身 `id`、比较不同线程
- [x] `fut.get(Duration.millisecond)` 对睡 1s 任务 → 必定 TimeoutException
- [x] `fut.cancel()` + `hasPendingCancellation`（SyncCounter 门控）→ "cancelled"
- [x] `sleep(Duration.millisecond)`、`Duration.second`、`100 * Duration.millisecond` 语法
- [x] `import std.sync.SyncCounter` + `waitUntilZero()/dec()` 编译通过

**确定性设计（诚实标注，不靠运气）**

- 不打印易变 id 数值，仅打印 `mainId != taskId` 布尔（官方明确"id 会变化"）
- 取消用 `SyncCounter(1)` 门控：先 `cancel()` 再 `dec()` 放行，保证 `hasPendingCancellation` 醒来时已为 true → 确定输出 `cancelled`
- 超时用 1s 睡眠 vs 1ms 等待，时序差 1000 倍，稳定触发 TimeoutException
- 残留 1s 睡眠任务 `f3`：主线程 return 时按官方"子线程随主线程终止"一并结束，不影响退出

**状态**

🔄 初稿完成（本地静态库编译通过），等待用户验收；真实运行输出待 GitHub Actions 确认（重点验证协作式取消与超时两条的确定性）。

---

## 文章 24《仓颉同步与并发原语》核验记录

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（29/29 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/029-sync-primitives.cj --output-type staticlib`
- [x] 官方 `concurrency/sync.html`、`terminal_thread.html` 链接已实际访问核验

**覆盖矩阵（官方 sync.html → 文章承接）**

| 官方内容 | 覆盖位置 |
|---|---|
| 原子操作 AtomicInt*/UInt*/Bool/Reference、load/store/swap/CAS/fetchAdd... 返回旧值、内存排序仅 seq_cst | 文章 2 节 |
| 可重入 Mutex lock/unlock/tryLock/condition、可重入需 lock/unlock 配对、三种错误示例 | 文章 3 节 |
| synchronized 语句 + 表达式、控制转移自动解锁 | 文章 4 节 |
| Condition wait/notify/notifyAll/waitUntil、必须持锁+同锁+谓词循环、有界队列 | 文章 5 节 |
| ThreadLocal get():Option/set | 文章 6 节 |

**撰写过程 cjc 语义核验**

- [x] `import std.sync.{AtomicInt64, AtomicBool, AtomicReference, Mutex, Condition}` 全部可导入
- [x] `synchronized(m){}` 语句 + `synchronized(m){ m.condition() }` 表达式
- [x] 关键发现：把**局部 var** 闭包进 `spawn` 报 `lambda capturing mutable variables needs to be called directly`；官方示例用**全局 var** 配 Mutex/Atomic → 正文与示例据此采用全局共享变量
- [x] `AtomicReference.compareAndSwap` 按引用同一性判定
- [x] 可重入锁 foo→bar 同锁不死锁，220；谓词循环 Condition 输出确定

**确定性设计**：所有计数统一 `Future.get()` join 后再打印；Condition 用 `while(!ready)` 谓词使顺序无关；输出 6 行确定值。

**状态**：🔄 初稿完成，等待用户验收；并发密集，push 后将多次运行 CI 验证稳定性。

---

## 文章 25《仓颉基础 I/O》核验记录

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（30/30 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/030-basic-io.cj --output-type staticlib`
- [x] 3 个官方 1.0.5 dev-guide Basic_IO 链接已实际访问核验（overview / source_stream / process_stream）

**覆盖矩阵（官方 Basic_IO 章节 → 文章承接）**

| 官方章节 | 覆盖位置 |
|---|---|
| `Basic_IO/basic_IO_overview.html` 流的抽象、InputStream/OutputStream、flush、节点流 vs 处理流 | 文章 1-2 节 |
| `Basic_IO/basic_IO_source_stream.html` 标准流(getStdIn/Out/Err, ConsoleReader/Writer)、File 常规操作与文件流、OpenMode、try-with-resources | 文章 3-4 节 |
| `Basic_IO/basic_IO_process_stream.html` BufferedInput/OutputStream、StringReader/StringWriter | 文章 5-6 节 |

**撰写过程 cjc 语义核验**（示例 030 编译通过 + CI 将真实跑文件读写）

- [x] `import std.io.{ByteBuffer, BufferedInputStream, BufferedOutputStream, StringReader, StringWriter, readToEnd}` 全部可导入
- [x] `import std.fs.{File, exists, remove}`；`File.create(path)`→`f.write(Array<Byte>)`→自动 close；`File.readFrom(path)`
- [x] `StringWriter(buf).write(str)`+flush → `String.fromUtf8(readToEnd(buf))` 往返
- [x] `StringReader.readln(): ?String`；`"s".toArray()`、`String.fromUtf8`
- [x] `BufferedOutputStream.flush()` 后 `BufferedInputStream.read` 往返
- [x] 网络流(Socket)、Path/Directory 等属后续《网络编程》《标准库》专题，本篇不展开

**运行时注意（诚实）**

- 示例在 cwd 写 `./cj_io_tmp.txt` 再 `remove`，真实文件读写结果以 Linux CI 为准；本地 macOS 只能 staticlib 编译
- 输出刻意单行、无内嵌换行：规避了官方 `StringWriter.write(Float64)` 会打印 `100.000000` 及 `writeln` 注入换行带来的多行/格式不确定，保证逐行可核

**状态**：🔄 初稿完成（编译通过），等待用户验收；文件往返与缓冲/字符串流真实输出待 GitHub Actions(Linux) 确认。

---

## 文章 26《仓颉 Socket 网络编程（TCP 与 UDP）》核验记录

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`python3 .github/scripts/sync_examples.py`（31/31 示例一致）
- [x] 本地静态库编译通过：`cjc examples/cangjie/031-socket.cj --output-type staticlib`
- [x] 官方 `Net/net_overview.html`、`Net/net_socket.html` 链接已实际访问核验

**范围决策（与用户确认）**

- 官方 `Net` 章含 Socket / HTTP / WebSocket。经核：`std.net`（Socket）**在 1.0.5 SDK 内**，可本地编译 + CI 运行；`stdx.net.http` **不在 SDK**（官方 note："net、log 等库已从 SDK 移到 stdx，需下载并配 cjpm.toml"），本机 `can not find package 'stdx.net.http'`。
- 用户选择：**文章26 只写 Socket 传输层(std.net)**，HTTP/WebSocket 拆为独立专题（编号待阶段二重排）。学习计划与覆盖矩阵已同步。

**覆盖矩阵（官方 Socket → 文章承接）**

| 官方内容 | 覆盖位置 |
|---|---|
| `Net/net_overview.html` StreamSocket/DatagramSocket、TCP/UDP/Unix domain、阻塞式(仅阻塞仓颉线程) | 文章 1 节 |
| `Net/net_socket.html` TCP 六步模型(bind/accept/connect/read/write)、UDP(sendTo/receiveFrom)、可选手动绑定 | 文章 2-3 节 |

**撰写过程 cjc 语义核验**（示例 031 编译通过；CI 将真实跑本机回环 socket）

- [x] `import std.net.*`：`TcpServerSocket(bindAt: UInt16)`、`bind()`、`accept()`、`localAddress as IPSocketAddress)?.port`
- [x] `TcpSocket(host, port)`、`connect()`、`read/write`；`UdpSocket(bindAt)`、`sendTo(IPSocketAddress, data)`、`receiveFrom(buf): (addr, count)`
- [x] `bindAt: 0` 临时端口 + 回读真实端口（避免 CI 端口冲突）
- [x] TCP 分片风险 → `readExactly` 读满定长；TCP/UDP 两阶段串行 + `Future.get()` 锁定打印顺序
- [x] `IPSocketAddress(...).address.toString()` 得到 "127.0.0.1"（官方 UDP 示例印证）

**确定性设计**：全 `127.0.0.1` 回环、端口 0 交系统分配、`readExactly` 补齐、串行阶段+join → 3 行输出确定：
`tcp server recv: [1, 2, 3]` / `tcp client echo: [1, 2, 3]` / `udp server recv 3 from 127.0.0.1: [4, 5, 6]`

**状态**：🔄 初稿完成（编译通过），等待用户验收；真实 socket 收发以 GitHub Actions(Linux) 为准。

---

## 文章 27《仓颉宏与编译时元编程》核验记录

**版本基线**：仓颉 1.0.5 LTS / CJNative

**范围决策（与用户确认）**

- 官方 Macro 章要求宏定义必须在**独立的 `macro package`** 中（cjc 实测：`macro declaration must be defined in macro package`），且 `cjpm.toml` 需 `[macro-dependencies]`。
- 现有 CI/门禁只跑单文件 `examples/cangjie/*.cj`。用户选择：**先扩基础设施再写文章**——已修改 `tools/test-local.sh` 增加 `test_cangjie_projects`：
  - macOS：`cjpm check` 校验结构（同 staticlib 语义，避开 macOS SDK 链接不兼容）
  - Linux：`cjpm build` + 若为 executable 则 `cjpm run`
- 未修改 `sync_examples.py`：它早已 `glob("**/*")` 支持任意子路径，marker 引用形如 `cangjie/<name>/src/xxx.cj`。

**门禁校验**

- [x] `python3 .github/scripts/sync_examples.py`：**33 canonical examples**（31 单文件 + 2 项目源文件，均带 marker）
- [x] `bash tools/test-local.sh`：Passed: 32（31 单文件编译 + 1 cjpm 项目 `cjpm check` 成功），`[PROJECT] examples/cangjie/032-macro-dprint/` 步骤输出 `cjpm check success`

**示例项目**：`examples/cangjie/032-macro-dprint/`（cjpm 项目）
- `cjpm.toml`：主模块，`[macro-dependencies]` 指向 `./src/define`
- `src/main.cj`：`package macro_dprint`，`import macro_dprint.define.*`，`@dprint(x)` 与 `@dprint(x + y)`
- `src/define/cjpm.toml`：`output-type = "static-impl"`
- `src/define/dprint.cj`：`macro package macro_dprint.define; public macro dprint(input: Tokens): Tokens { ... quote(...) ... }`
- cjpm 依赖解析顺序：`macro_dprint.define -> macro_dprint`（cjpm check 输出）

**正文事实来源（官方）**

- `Macro/macro_introduction.html`：dprint 案例 + Tokens/quote/插值 + `macro package` 与目录布局 + 编译期执行
- `Macro/implementation_of_macros.html`：非属性宏 vs 属性宏、定义与调用形态匹配、嵌套宏、`assertParentContext`/`setItem`/`getChildMessages`
- `Macro/Tokens_types_and_quote_expressions.html`：`Token`/`TokenKind`/`Tokens`（`size`/`get`/`[]`/`+`/`dump`/`toString`）、`quote` 转义（`\$` `\(` `\)`）、`ToTokens` 覆盖类型

**诚实标注**

- 属性宏、语法节点、宏诊断等更细节的宏 API（超出 dprint 案例范围的部分）在正文以官方定义/表格描述，未编写第二个 cjpm 项目示例；不声称"已运行验证"
- 项目 Linux 真实运行输出（`x = 3` / `x + y = 5`）将在 GitHub Actions 验证

**状态**：✅ CI(Linux) 已验证：`cjpm build success` + `cjpm run` 输出 `x = 3` / `x + y = 5` 与正文逐行匹配。CI 基础设施（`tools/test-local.sh` 支持 cjpm 项目 + workflow PATH/LD_LIBRARY_PATH 配齐 cjpm）已跑通。

---

## 文章 28《仓颉反射、注解与动态特性》核验记录

**版本基线**：仓颉 1.0.5 LTS / CJNative

**SDK 可用性调查（本会话专门核实）**

- 用户质疑"标准库到底有没有 reflect"。对照实验（同一 shell、同一条 `cjc staticlib`）：`std.net`✅、`std.sync`✅、`std.reflect`❌`can not find package`。
- 产物核查：本地 mac 1.0.5 SDK `modules/.../std/` 有 44 个 .cjo，含 `std.ref`（弱引用）但**无 `std.reflect.cjo`**；lib/ 下也无 reflect 库。
- **CI(Linux) 官方 1.0.5 SDK 探针**：`std.reflect.cjo` + `libstd.reflect.bc` 均在，且逐字照抄官方 `TypeInfo.of<Int64>()` 例子编译并运行输出 `Int64`。
- 结论：**std.reflect 是 1.0.5 标准库正式成员**；本地 macOS SDK 因系统升级(26.5.2)+老包时间戳(2023-01-02)不完整。基线维持 LTS 1.0.5，反射示例以 Linux CI 为验证权威。
- 配套 `tools/test-local.sh` 增加 `[SKIP-DARWIN]`：macOS 上含 `import std.reflect` 的示例跳过本地静态编译（避免不完整 SDK 误报），Linux CI 仍完整 build+run。

**门禁校验**

- [x] `sync_examples.py`：**34 canonical examples**（033 被本文两处 marker 引用）
- [x] `test-local.sh`：macOS 下 `[SKIP-DARWIN] 033...` + 其余 Passed: 32；Linux CI 将实际编译运行 033
- [x] 官方 `reflect_and_annotation/dynamic_feature.html`、`reflect_and_annotation/anno.html` 两页已实际访问（200，正文完整）

**覆盖矩阵（官方 reflect_and_annotation → 文章承接）**

| 官方内容 | 覆盖位置 |
|---|---|
| `dynamic_feature.html` TypeInfo.of(Any/Object)/of<T>()/get(名字)、InfoNotFoundException、未实例化泛型取不到、静态/实例成员读写、属性、getStaticFunction+apply、只能反射 public | 文章 1-3 节 |
| `anno.html` @OverflowThrowing/Wrapping/Saturating 三策略+默认+编译期检出+运算符溢出表、@EnsurePreparedToMock、@Annotation+const init+[]参数+不可重复+不被继承+target:AnnotationKind、findAnnotation | 文章 4-7 节 |

**示例 033 覆盖**：`TypeInfo.of(A())`→`default.A`；`findAnnotation<Version>()`→1.0/1.1；`getInstanceVariable("balance")` getValue/setValue→100/250；`@OverflowWrapping Int8 105+105`→-46。

**状态**：🔄 初稿完成（本地按策略跳过 reflect 静态检查，sync 全绿）；033 的真实编译+运行 6 行输出待 Linux CI 确认。

**CI(Linux) 实测 + SDK/文档差异记录**

- ✅ CI 编译运行 033，6 行输出与正文逐行匹配：`type of A = default.A` / `version = 1.0` / `version = 1.1` / `balance = 100` / `balance after = 250` / `wrap 105+105(Int8) = -46`
- ⚠️ SDK 弃用告警：1.0.5 编译器对 `TypeInfo.of(Object)` 报 `function 'of' is deprecated. Use 'ClassTypeInfo.of(Object)' instead.`；但官方 1.0.5 文档示例仍用 `TypeInfo.of`。本文保留 `TypeInfo.of`（与文档一致、CI 实测可跑），在 2.2 节与 FAQ Q9 诚实标注该差异，并说明新代码可改用 `ClassTypeInfo.of`。→ 更新：文章 28 增补 2.2 节 + Q9。

---

## 文章 29《仓颉-C 互操作》核验记录

**版本基线**：仓颉 1.0.5 LTS / CJNative

**门禁校验**

- [x] 同步检查通过：`sync_examples.py`（35 canonical examples）
- [x] **本地 macOS staticlib 编译通过**：`examples/cangjie/034-c-interop.cj`（C 互操作不依赖缺失的 std.reflect，本地即可编译预检；仅 main-unused 警告）
- [x] 官方 `FFI/cangjie-c.html` 链接已实际访问核验（正文完整）

**覆盖矩阵（官方 FFI cangjie-c → 文章承接）**

| 官方内容 | 覆盖位置 |
|---|---|
| foreign 声明调 C + 6 条规则（无实现/类型映射/unsafe/@C 限定/无命名参数默认值支持变长/栈溢出注意） | 文章 2 节 |
| CFunc 三形式 + CPointer→CFunc 危险 + 不捕获 | 文章 3 节 |
| inout 引用传参约束（不能 class 成员/let/字面量/CString） | 文章 4 节 |
| unsafe（lambda 不传递 unsafe 陷阱） | 文章 5 节 |
| @CallingConv CDECL/STDCALL | 文章 6 节 |
| 类型映射：基础类型表/@C struct/CPointer/VArray/CString/sizeOf-alignOf/CType | 文章 7 节 |
| C 调仓颉（CFunc 回调 + CJ_ 前缀告警）+ 编译链接 -L/-l | 文章 8-9 节 |
| 线程局部/fork/长阻塞/进程退出等副作用 | 文章 10 节 |

**撰写过程 cjc 语义核验（本地即通过）**

- [x] `foreign func strlen(s: CString): UIntNative`（返回对应 size_t，用 UIntNative；曾误写 Int64 被本地编译抓出）
- [x] `@C struct Point` + `sizeOf<Point>()=16`
- [x] `LibC.mallocCString` → `CString.toString()` → `LibC.free`
- [x] `@C func` + `CPointer<Point>` read/write + `inout pt`（局部 var 允许）
- [x] `inout value`（Int64 局部变量）传给 `@C func(CPointer<Int64>)`
- 本地编译一度报错：`LibC.malloc` 需命名参数 `count:`、`strlen` 返回类型不匹配——均据实修正，体现 C 互操作在本地可完整编译验证

**与 reflect 篇的区别**：C 互操作只用系统 libc + 内置 LibC，**本地 macOS 能编译**（不需 SKIP-DARWIN），只是本地不能运行（macOS 链接老问题），故运行以 Linux CI 为准。

**状态**：🔄 初稿完成（本地编译通过），等待用户验收；Linux CI 将实际运行 034，核对 4 行输出。

**CI 复核修正**：文章29 示例首次 CI 运行揭示 `"hello cangjie"` 实际长度 **13**（含空格），我文档初稿误记为 11。已同步修正 example 034 注释 + 文章内嵌示例注释 + 预期输出块为 `len = 13`；sync 35/35 仍通过。

---

## 文章 30《仓颉标准库总览与使用方法》核验记录

**版本基线**：仓颉 1.0.5 LTS / CJNative

**范围说明**：本篇是"方法论/导航"章（学习计划：标准库分层、模块导入、API 文档、版本匹配、示例阅读方法），不新增语言 API；一切"包是否存在/属 std 还是 stdx"的判断以**本机 1.0.5 SDK 实测**为准。

**门禁校验**

- [x] `sync_examples.py`：36 canonical examples（035 被 marker 引用）
- [x] 本地 macOS staticlib 编译通过：`examples/cangjie/035-std-overview.cj`
- [x] 4 条参考链接已 curl 访问核验（200）

**事实来源（实测，非记忆）**

- std 包清单：来自 1.0.5 SDK `ls modules/*/std/*.cjo` 的 44 个实际包（core/collection/sort/math/sync/io/fs/net/ast/reflect/deriving/unittest/time/env/...）；纠正了"std.ref（弱引用）≠ std.reflect（反射）"易混点。
- 分层模型（core 隐式 / std.* / stdx.*）：`stdx.net.http` 本机 `can not find package`（前文 HTTP 篇已证）；`std.reflect` 在 Linux CI 存在、本机 mac 缺失（反射篇已证）。
- 文档两种视图：叙事 `docs.cangjie-lang.cn/...dev-guide...` 可 curl；库 API `cangjie-lang.cn/docs?url=...` 为 SPA（curl 只得壳）——本项目 std.collection/HTTP 篇已反复验证。
- 版本现状：官方下载/文档版本下拉显示**最新 LTS=1.0.5、最新 STS=1.1.3**（本文据此建议锁 LTS）。

**示例 035（3 个 base SDK 包协同，输出确定）**：collection `sum=14,map.size=2` / math `sqrt(16)=4.000000`（沿用 Float64 六位小数实测格式）/ sync `count=10`。

**状态**：🔄 初稿完成（本地编译 + 链接核验通过），等待用户验收；Linux CI 复核 035 三行输出。

---

## 文章 31《仓颉标准库数据结构：迭代器、双端队列与集合算法》核验记录

**版本基线**：仓颉 1.0.5 LTS / CJNative；定位：文章 18 续集（只补迭代器协议/ArrayDeque/集合算法，不重复 ArrayList/HashMap 基础）

**门禁校验**
- [x] sync_examples.py：37 canonical examples（036 被 marker 引用）
- [x] 本地 macOS staticlib 编译通过 examples/cangjie/036-collections-advanced.cj（仅 main-unused）
- [x] 3 条参考链接 curl 200（collection_iterable_collections / collection_overview / function_call_desugar）

**API 通过本地 cjc 逐条实证（关键：不猜签名）**
- [x] Iterable<T>{iterator(): Iterator<T>}、Iterator<T>{next(): Option<T>}（官方 iterable 页原文）
- [x] for-in 脱糖 + while-let（官方原文 + 示例实测）
- [x] 自定义 Iterable/Iterator：class 实现 next() 不需 mut（曾误加 mut 报 unexpected modifier，改正后可编译）
- [x] ArrayDeque 可实例化；Deque 接口不可（`Deque<Int64>()` 报 interface cannot be instantiated）；addFirst/addLast/removeFirst/removeLast/first/last/size + for-in 通过
- [x] 集合算法为全局函数非成员：`nums.filter{}` 报 'filter' is not a member；`nums |> filter{}/map{}/reduce{x,y=>x+y}/any{}/all{}` 通过；filter/map 返回 Iterator 无 .size，用 for-in 落地；reduce 无初值折叠

**示例 036 输出（本地编译验证 + 数学核对，待 CI 运行核对）**：countdown sum=15 / manual iterator=321 / deque size=2 head=1 first=2 last=3 / even*10 sum=120 / reduce=21 / any>5=true / all>0=true

**状态**：🔄 初稿完成（本地编译 + 链接核验通过），等待用户验收；Linux CI 复核 7 行输出。

**复盘补充：31 篇漏项修订**（用户指出"上次怕重复砍内容是错的"后回查）

- **发现遗漏**：学习计划 31 的官方项是"ArrayList、HashMap、HashSet、Deque、迭代器、集合算法"。初稿只写了迭代器/ArrayDeque/算法三块，**没给 ArrayList/HashMap/HashSet 的"阶段三进阶"专章**。这是我上次用"避免与 18 重复"当理由过度收窄，动机错误。
- **cjc 逐条实测**（不猜签名）：
  - ArrayList：`sort()` **已弃用**（SDK 警告荐 std.sort.sort 全局函数）、`capacity`、`removeIf` 通过；`insert`/`removeFirst`/`removeLast`/`ensureTotalCapacity` **不存在**
  - HashMap：`[]` 索引读写、`get/remove` 返回 **`Option<V>`**、`keys()`/`values()` **是方法（带括号）**；`put`/`getOrPut`/`computeIfAbsent` **不存在**
  - HashSet：`subsetOf` 存在；`union/intersect/containsAll/removeAll` **不存在**（`| & -` 运算符 18 已讲）
- **修订**：新增 §3"三大容器进阶（承接 18）"，重编号 §4=ArrayDeque / §5=算法 / §6=示例 / §7=对比 / §8=FAQ / §9=总结；示例 036 加入"容器进阶"块（5 行新输出）；摘要与总结同步补记。
- **教训入则**：判"重不重复"只看该阶段目标下有无新 API/视角，不只看标题像不像；阶段三是"补全标准库目录"，只要一个 API/视角 18 没讲透就应写。

---

## 文章 32《仓颉标准库：编码、转换、正则与内存流》核验记录

**版本基线**：1.0.5 LTS；定位：文章 25 的阶段三补全篇（25 讲流模型，本篇补编码/转换/正则/内存流的完整 std API）

**门禁**
- [x] sync 38/38（037 被 marker 引用；曾出现"嵌入块与文件不符"，已用函数式替换逐字重嵌）
- [x] 本地 macOS staticlib 编译通过 examples/cangjie/037-io-text.cj
- [x] 参考链接 process_stream 200

**API 全部本地 cjc 实测（本会话踩过的坑都写进正文/FAQ）**
- 编码：`String.toArray()` / `String.fromUtf8` / `toRuneArray`（承接 13；中文 UTF-8 字节≠字符数）
- convert：`Int64.parse` / `Int64.tryParse`→`Option`（在**目标类型**上，非 String 方法）、`toString(radix:)`、`StringBuilder`（**append 不可链式**、逐条调用）；`Int64("42")` 数值转换不接受字符串→须走 parse
- 正则：`Regex(#".."#)` raw string（`r".."` 会 unrecognized escape）；**`find`→Option / `findAll`→可迭代**；**`match` 是关键字、Regex 上无 `match` 方法**
- io：`ByteBuffer.write` + `readToEnd`

**诚实标注**：十六进制字母大小写不确定→示例刻意用 `radix: 2`（纯数字）保确定；未验证的 `format`/`parseFloat` 等不写进正文（只写实测存在的）。

**示例 037 输出**（本地编译过，CI 复核）：encode 2 bytes/round-trip=hi / convert parse=42, 255_binary=11111111 / regex find=true, count=3 / io readToEnd=buf / builder a=1

**状态**：🔄 初稿完成（本地编译+链接+sync 全绿），待 CI 运行核对。

---

## 文章 33《仓颉标准库：数学、时间与随机数》核验记录

**版本基线**：1.0.5 LTS

**范围裁定（诚实）**：计划 33 原文含"JSON/编码"。**base SDK 无 `std.json`**（`ls`+`import` 实测确认），JSON/序列化属 stdx（同 HTTP/WebSocket），本篇**明确不覆盖**并在 Q6 说明——不臆造 JSON API。

**门禁**
- [x] sync 39/39（038 被 marker 引用；曾漂移，逐字重嵌后通过）
- [x] 本地 staticlib 编译通过 examples/cangjie/038-math-time-random.cj
- [x] sleep + download 链接 curl 200

**API 全部 cjc 本地实测（不确定的一律不写死）**
- std.math：pow/sqrt/atan2 通过；**π/e 常量名未确定**（pi/e/PI/M_PI/Float64.PI 全部 undeclared）→ 正文不臆造，给 atan(1)*4 备选
- std.time：`Duration` 算术 + `toMilliseconds/toSeconds`；`DateTime.UnixEpoch`（大写U常量）+`addDays`+`year/month/dayOfMonth`（**不是 `day`**，实测）；不打印 now 保确定
- std.random：`Random(种子)` 同种子同序列（`nextInt64`），可复现

**确定性设计**：数学用 `==1024.0/3.0` 布尔判定（避开 6 位小数/浮点误差）；日期从 UnixEpoch.addDays(1) 派生；随机用双 42 种子相等性断言。

**示例 038 输出（待 CI 逐行核对）**：math pow/sqrt/atan2 + cmp=true / time 3500,3 / date 1970-1-2 / random same_seed_eq=true

**状态**：✅ CI(Linux) 通过，5 行输出逐行匹配；CI 抓出 `DateTime.month` 是枚举(`January`)非数字——已订正示例/正文/预期输出/FAQ Q3。

---

## 文章 34《仓颉标准库：系统能力（环境/进程/端序/POSIX）》核验记录

**版本基线**：1.0.5 LTS

**范围裁定（诚实）**：计划 34 = "标准库网络与系统能力：Socket/HTTP/WebSocket/进程/环境/平台API"。
- Socket 已在**文章 26** 覆盖，本篇承接引用不重讲。
- **HTTP/WebSocket 属 stdx.net**（本机/CI base SDK 无），按前面拆分原则**本篇不覆盖**。
- 本篇聚焦**可验证的 base SDK 系统能力**：`std.env`/`std.process`；`std.binary`/`std.posix` 只写实测到存在/接口/常量的部分，具体函数签名不臆造（指向库 API）。

**门禁**
- [x] sync 40/40（039 被 marker 引用）；[x] 本地 staticlib 编译通过 039；[x] 2 条链接 200

**API cjc 实测（纠正多个直觉误名）**
- std.env：`getProcessId()`、`getHomeDirectory(): Path`（**不是 String**、`.toString()` 才有 size）；`getEnvirments`（历史拼写）；`getVar`/`args` **不存在**
- std.process：`execute(String): Int64` 返回**退出码**（起初误以为返回 Array<String>，`for` 报 "type Int64 does not implement Iterator" → 确认是退出码）；`executeWithOutput(String): Array<String>` 拿输出行；`SubProcess` 走管道
- std.posix：`O_RDONLY` 等常量编译通过
- std.binary：BigEndianOrder/LittleEndianOrder 是**接口**（不能实例化），读写函数签名未在本文臆造

**示例 039（输出稳定）**：has_pid=true / has_home=true / execute(echo) exit=0（不打印 pid/路径等易变值）

**状态**：🔄 初稿完成，待 CI 运行核对。

**CI 复核修正（execute 签名）**：首版示例写 `execute("echo cangjie")`，CI(Linux) 运行抛 `ProcessException: Created process failed, No such file or directory`——因为 `execute` 第一参是**可执行文件路径**、非整条 shell 命令。改为 `execute("/bin/echo", ["cangjie"])`（exe + 参数数组），并订正正文 §2.1/§2.2/FAQ Q4 与"整串当路径"踩坑提示。本地 staticlib 能过、只有真跑才暴露——正是 CI 价值。

**CI 二次复核**：修正后 CI success；实际输出比"预期两行"多一行 `cangjie`（`execute` 继承子进程 stdout，`/bin/echo` 直接打屏）——已把预期输出块更新为 3 行，与正文"execute 继承 stdout"叙述一致。

---

## 文章 35《仓颉编译器 cjc：编译流程、产物、参数、诊断与链接》核验记录

**版本基线**：1.0.5 LTS（`Cangjie Compiler: 1.0.5 (cjnative)`）

**取材方式**：CLI 工具类文章。用本地 `cjc --help` + `cjc --version` 实测选项与产物名；官方文档 compile_options/cjc_usage 页面核对语义。诊断 JSON 用真实错误文件 `bad.cj` 跑出实测结构。

**本地 cjc 实测（1.0.5）**
- 默认产物：`cjc hello.cj` → exe 名 **`main`**（从 ld64 `-o .../main` 确认；本机 macOS SDK 链接失败但**名字规则**可辨）
- 库名：`--output-type=staticlib hello.cj` → **`libhello.a`**（实测生成，6072B）；dylib → `libhello.dylib`（mac）/`.so`（Linux，文档）
- `--int-overflow=throwing|wrapping|saturating`：三值前端均接受（staticlib 编译 0 error）；默认 throwing（文档）
- `--diagnostic-format=json` 实测结构：`{"Diags":[{"DiagKind":"sema_mismatched_types","Severity":"error","Message":"mismatched types","Location":{File,Line,Column},"MainHint":{Content}}]}`
- 类型错误文本实测：`mismatched types ... expected 'Int64', found 'Struct-String'`
- `-Woff unused` 实测消除 unused 警告；`-O` 级别 O0(默认)/O1/O2/Os/Oz（文档+help）

**诚实声明**：macOS 本机 `-o exe` 链接失败（SDK↔lld 不兼容，非代码问题），staticlib 前端编译可过；**运行输出以 Linux CI 为准**（正文第 6 节明说）。

**链接**：4 条 `/cjnative/user_manual/...` 全部 curl 200。注：编译器 user_manual 官方无 `/docs/1.0.5/` 版本化路径，只有 `/cjnative/`（latest）——正文版本信息注明。

**示例 040**：无溢出、结果与优化级别无关的确定性程序；预期 3 行 `sum=55 / 6*7=42 / cjc demo ok`。

**状态**：🔄 初稿完成，本地编译+sync 通过，待 CI 运行核对。
