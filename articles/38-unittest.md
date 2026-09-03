# 仓颉单元测试与覆盖率：cjpm test、@Test/@TestCase、断言宏与 cjcov

> **摘要**: 代码写得对不对，靠测试说话。仓颉内置 `std.unittest` 框架 + `cjpm test` 一键跑测 + `cjcov` 出覆盖率报告。本篇覆盖：**测试结构**（`@Test` 函数 / `@Test` 类 + `@TestCase`）、**生命周期钩子**（`@BeforeEach/@AfterEach/@BeforeAll/@AfterAll`）、**断言宏**（`@Assert` 快速失败 vs `@Expect` 继续、`@Fail`/`@FailExpect`）、**运行方式**（`cjpm test` 自动识别 `*_test.cj`、`cjc --test` 单文件、`--filter` 过滤）、**结果解读**（TP/TCS/CASE/Summary）、**覆盖率**（`cjpm test --coverage` → `cjcov`）。所有断言宏与 `cjpm check`/`cjcov --help` 在 1.0.5 本地实测；`cjpm test` 的**运行**在 Linux CI 核对（macOS SDK 链不动，同文章 35/36）。**配套示例 `042-unittest`** 是含 `adder.cj` + `adder_test.cj` 的 cjpm 工程，3 个用例全 PASSED。

## 前置知识

- 已完成《cjpm 包管理器》（文章 36）——本篇用 `cjpm` 工程 + `cjpm test`
- 已完成《cjc 编译器》（文章 35）——`--test` 是它的编译选项
- 会写 `package`/`func`/`class`/`Exception`（前面基础篇）

> 定位：阶段四"质量与工具链"的测试篇。

## 1. 心智模型：测试文件靠命名识别

仓颉的单元测试有两条铁律：

1. **测试写在文件名以 `_test.cj` 结尾的文件里**——`cjpm` 靠这个后缀区分"生产代码"和"测试代码"：**正常 `cjpm build` 不编 `_test.cj`**，只有 `cjpm test` 才把它们拉进测试模式编译。
2. **测试用宏标记**——`@Test` 标一个测试函数或测试类，`@TestCase` 标类里的每个用例，断言用 `@Assert`/`@Expect` 等宏。这些宏来自 `std.unittest.testmacro`，框架 API 在 `std.unittest`；官方说**在 cjpm 工程里无需显式 import 也能用**（本示例仍显式 import，便于 IDE 补全，也更醒目）。

一个最小工程长这样：

```text
042-unittest/
├── cjpm.toml            # output-type = "static"（库工程即可，无需 main）
└── src/
    ├── adder.cj         # 生产代码：public func add / divide
    └── adder_test.cj    # 测试代码：@Test / @TestCase / @Expect / @Assert
```

## 2. 测试结构：函数式 vs 类式

### 2.1 独立测试函数（最简单）

`@Test` 直接修饰一个顶层函数，函数体里放断言：

```cangjie
@Test
public func addIdentity() {
    @Expect(add(7, 0), 7)
}
```

### 2.2 测试类 + 用例 + 生命周期

需要"多个用例共享 setup/teardown"时，用 `@Test` 修饰 class，内部每个方法用 `@TestCase` 标记：

```cangjie
@Test
public class AdderTests {
    @BeforeEach public func setUp() {}     // 每个用例前跑
    @AfterEach  public func tearDown() {}  // 每个用例后跑

    @TestCase public func addPositives() { @Expect(add(2, 3), 5) }
    @TestCase public func addNegatives() { @Assert(add(-1, -1), -2) }
}
```

4 个生命周期钩子（只能挂在 `@Test` **类**上，顶层函数不行）：

| 钩子 | 时机 | 能否有参数 |
|---|---|---|
| `@BeforeAll` | 整个测试类开始前**一次** | 不能带参数（常配 `static`） |
| `@BeforeEach` | **每个** `@TestCase` 前 | 可带一个 `String`（或不带） |
| `@AfterEach` | **每个** `@TestCase` 后 | 可带一个 `String` |
| `@AfterAll` | 整个测试类结束后**一次** | 不能带参数 |

## 3. 断言宏：@Assert（快速失败）vs @Expect（继续）

两类断言，**语义相同、失败行为不同**：

- **`@Assert(...)` = fail-fast**：一旦这条失败，**本用例后续断言全部不再执行**，直接判失败。
- **`@Expect(...)` = 记录并继续**：失败也**只记录**，本用例后面的断言**照样跑**（一次看全所有问题，写断言密集的用例更省事）。

常用形态（都在本地实测通过）：

```cangjie
@Expect(add(2, 3), 5)     // 相等断言：两参数比较是否相等（左类型须 Equatable）
@Assert(add(1, 1), 2)     // 同上，但 fail-fast
@Expect(1 < 2, true)      // 布尔断言：与 true/false 比
@FailExpect("这里必失败")  // 无条件让本用例失败，但继续检查后续
@Fail("致命")             // 无条件失败且中止（返回类型 Nothing）
```

> **异常断言**：框架还提供 `@AssertThrows` / `@ExpectThrows`（预期抛某类型异常，`|` 分隔多类型、缺省 `Exception`）。**这两个宏的确切入参写法我在 1.0.5 本地多次试写均报宏展开错**，为避免贴出未验证代码，本篇**示例里不放异常断言**——需要时请照官方《unittest 基础》页的写法用。同理 `@Ignore`（跳过用例）、`@Tag`（打标过滤）的准确属性形式本文**不臆造**，以库手册为准。

## 4. 运行测试

### 4.1 cjpm 工程（推荐）

```shell
cjpm test                 # 跑模块内所有包的 *_test.cj
cjpm test src/xxx         # 只测指定包
cjpm test --filter <expr> # 按表达式过滤用例子集
cjpm test --no-run        # 只编不跑
cjpm test -j 8            # 并行
```

`cjpm test` **自动**把 `*_test.cj` 用测试模式编译、其余按正常模式——你不用管 `--test`。

### 4.2 单文件（无 cjpm，用 cjc）

小脚本式验证，直接手动：

```shell
cjc adder.cj adder_test.cj --test -o adder_test   # --test：入口从 main 换成 test_entry
./adder_test
```

`--test` 的实质（承文章 35）：把程序入口由 `main` 换成框架生成的 `test_entry`。

### 4.3 读结果

`cjpm test` 输出（**计时每次不同，属正常**）大致长这样：

```text
--------------------------------------------------------------------------------------
TP: utdemo, time elapsed: 60989 ns, Result:
    TCS: AdderTests, time elapsed: 32804 ns, RESULT:
    [ PASSED ] CASE: addPositives (29195 ns)
    [ PASSED ] CASE: addNegatives (4021 ns)
Summary: TOTAL: 3
    PASSED: 3, SKIPPED: 0, ERROR: 0
    FAILED: 0
--------------------------------------------------------------------------------------
```

术语：**TP** = 测试程序(Test Program)，**TCS** = 测试套件(一个 `@Test` 类/函数)，**CASE** = 一个 `@TestCase`。看最后一行 `PASSED: 3 / FAILED: 0` 即全绿；有失败时看 `CASE:` 下的报错栈。

## 5. 覆盖率：cjpm test --coverage + cjcov

两步（选项/参数本地 `cjcov --help` 实测）：

```shell
cjpm test --coverage          # ① 带覆盖率插桩跑测试，产出 .gcno(编译期) + .gcda(运行期)
cjcov -r . --html-details     # ② 汇总成 HTML 报告；-x 出 xml、-j 出 json
```

`cjcov` 常用参数：`-r ROOT`（源码根）、`-o OUTPUT`（报告输出目录）、`--html-details`（每个源文件一页）、`-x/--xml`、`-j/--json`、`-b`（分支覆盖，实验性）、`-e`/`-i`（排除/包含文件）。

> 覆盖率走的是文章 35 讲的 `--coverage` 编译选项（**只能配 `-O0`**，否则 cjpm/编译器告警并强制回 O0）；`cjprof` 性能剖析、`cjlint` 静态检查等命令行工具在**文章 39/40** 展开。

## 6. 完整示例（cjpm test 全绿）

生产代码 `adder.cj`（`cjpm build` 会编）：

<!-- example: cangjie/042-unittest/src/adder.cj -->
```cangjie
package utdemo

// 被测代码（生产代码）——正常构建（cjpm build）时会编译本文件。
// 对应测试在同目录下的 adder_test.cj（文件名以 _test.cj 结尾），
// cjpm 在测试模式下才会编译它。

public func add(a: Int64, b: Int64): Int64 {
    return a + b
}

public func divide(a: Int64, b: Int64): Int64 {
    if (b == 0) {
        throw Exception("divide by zero")
    }
    return a / b
}
```

测试代码 `adder_test.cj`（`cjpm test` 才编）：

<!-- example: cangjie/042-unittest/src/adder_test.cj -->
```cangjie
package utdemo

// 单元测试：文件名以 _test.cj 结尾，cjpm 会识别它并"只在测试模式"下编译。
// 用法：cjpm test   （无需手动加 --test；cjpm 会调 cjc --test 把入口从 main 换成 test_entry）
import std.unittest.*
import std.unittest.testmacro.*

// 1) 独立测试函数：@Test 直接修饰一个顶层函数
@Test
public func addIdentity() {
    @Expect(add(7, 0), 7)          // @Expect：相等断言，失败也继续跑后续断言
}

// 2) 测试类：@Test 修饰 class，内部用 @TestCase 划分用例，可挂生命周期钩子
@Test
public class AdderTests {
    @BeforeEach
    public func setUp() {}          // 每个用例前执行

    @AfterEach
    public func tearDown() {}       // 每个用例后执行

    @TestCase
    public func addPositives() {
        @Expect(add(2, 3), 5)
        @Expect(add(0, 0), 0)
    }

    @TestCase
    public func addNegatives() {
        @Assert(add(-1, -1), -2)    // @Assert：fail-fast，本用例后续断言不再执行
        @Expect(add(-2, 5), 3)
    }
}
```

运行（Linux CI）：

```shell
cd examples/cangjie/042-unittest
cjpm test
```

预期：3 个用例 `addIdentity` / `addPositives` / `addNegatives` **全 `[ PASSED ]`**，汇总 `PASSED: 3, FAILED: 0`（计时数值每次不同）。

## 7. 与其它语言测试框架对照

| 维度 | 仓颉 unittest | Rust | Go | Java JUnit |
|---|---|---|---|---|
| 标记 | `@Test`/`@TestCase` | `#[test]` | `func TestXxx(t *testing.T)` | `@Test` |
| 相等断言 | `@Expect(a, b)` | `assert_eq!` | `if got!=want {t.Errorf}` | `assertEquals` |
| fail-fast | `@Assert` | （`assert!` 即 panic） | `t.Fatalf` | `assert`（抛异常） |
| 记录继续 | `@Expect` | 手动 | `t.Errorf` | `soft assert`/Allure |
| 文件识别 | `*_test.cj` | `#[cfg(test)] mod` | `*_test.go` | 类名约定 |
| 运行 | `cjpm test` | `cargo test` | `go test ./...` | `mvn test` |
| 覆盖率 | `cjpm test --coverage`+`cjcov` | `cargo llvm-cov` | `go test -cover` | JaCoCo |

最独特的是 **`@Assert` 与 `@Expect` 拆成两个宏**（快速失败 vs 记录继续），比"只有一个 assert、失败即止"的语言在写多断言用例时更灵活。

## 8. 常见问题（FAQ）

### Q1: 为什么我 `cjpm build` 没把我的测试编进去 / 报错？

测试文件必须以 **`_test.cj`** 结尾——`cjpm build` 故意不编它们；跑测试用 **`cjpm test`**。（若你手搓 `cjc`，才需要显式 `--test`。）

### Q2: `@Assert` 和 `@Expect` 到底选哪个？

想让"第一个失败就停"→`@Assert`（fail-fast）；想"一次跑完看全部断言结果"→`@Expect`。同一用例里可混用。

### Q3: 本地 macOS `cjpm test` 跑不起来？

和文章 35/36 同因：本机 SDK 链接运行时失败。用 `cjpm check` 在本地验语法/宏展开（能过 = 测试代码合法），**真正的 `cjpm test` 运行交给 Linux CI**。

### Q4: 生命周期钩子挂在顶层 `@Test` 函数上没生效？

`@BeforeAll/@BeforeEach/@AfterEach/@AfterAll` **只能配在 `@Test` 类成员上**，顶层测试函数不支持。要用钩子就把用例组织进 `@Test class`。

### Q5: 覆盖率报告怎么生成？

`cjpm test --coverage` 跑完会留 `.gcno`/`.gcda`，再 `cjcov`（或 `cjcov --html-details`）生成 HTML。别用高优化级别（`--coverage` 只配 `-O0`）。

### Q6: 跳过某个用例 / 只跑某类用例？

框架有 `@Ignore`（跳过）和 `cjpm test --filter`（按表达式筛选）。`@Ignore`/`@Tag` 的确切宏属性写法本文未逐一实测，照官方《unittest 基础》页用；`--filter` 参数本身在 `cjpm test --help` 里可查。

## 9. 总结

1. **命名即约定**：测试写在 `*_test.cj`；`cjpm build` 不编它，`cjpm test` 自动以测试模式编、跑。
2. **结构**：`@Test` 标函数或类；类里 `@TestCase` 分用例；`@BeforeAll/@BeforeEach/@AfterEach/@AfterAll` 管生命周期（仅类成员）。
3. **断言**：`@Assert`（fail-fast）vs `@Expect`（记录继续）；`@Fail`/`@FailExpect` 强制失败；异常/忽略/标签宏以手册为准（本文只实测了前者）。
4. **运行**：`cjpm test [--filter|-j|--coverage|包路径]`；单文件回 `cjc --test`。输出看 `TP/TCS/CASE` + 末尾 `PASSED/FAILED`（计时非确定）。
5. **覆盖率**：`cjpm test --coverage` → `cjcov` 出 html/xml/json（`--coverage` 须 `-O0`）。
6. macOS 链接坑：本地 `cjpm check` 验合法性，运行/测试以 Linux CI 为准。

## 参考资料

1. Unittest 快速入门：https://docs.cangjie-lang.cn/docs/1.0.5/libs/std/unittest/unittest_samples/unittest_getting_started.html
2. Unittest 基础概念：https://docs.cangjie-lang.cn/docs/1.0.5/libs/std/unittest/unittest_samples/unittest_basics.html
3. std.unittest 包总览：https://docs.cangjie-lang.cn/docs/1.0.5/libs/std/unittest/unittest_package_overview.html
4. 覆盖率工具 cjcov：https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/tools/cjcov_manual_cjnative.html
5. 上一篇：cjpm 包管理器（articles/36-cjpm.md）

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写。库文档以 `/docs/1.0.5/libs/`（版本化）路径提供；工具文档（cjcov）在 `/cjnative/`。macOS 本机链接限制同文章 35/36。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
