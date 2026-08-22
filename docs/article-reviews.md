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
