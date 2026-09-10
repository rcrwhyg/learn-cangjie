# 仓颉综合项目与最佳实践：一条完整工程流水线的复盘

> **摘要**: 阶段五收官、也是全系列的终章。前 51 篇把仓颉从语法、库、工具链、原理、实战逐层铺开；这一篇不再讲新 API，而是把"**做一个能长期维护的仓颉项目**"的全生命周期收敛成一份**可复制的最佳实践清单**——项目结构、代码组织、依赖与版本、测试与质量门、CI、文档、发布——并且**以本教程仓库自身为案例**（52 篇讲义 + 59 个可在 CI 实跑的规范示例 + sync/编译/stdx 三道 CI 门禁）复盘"我们是怎么保证一篇篇讲义不出错、可复现的"。这是把前面所有单点知识**串成工程闭环**的一篇。
>
> **⚠️ 本篇无运行示例**（同文章 37/47）：它是复盘与规范综述，不引入新代码。所引实践均可回指对应实测篇。

## 前置知识

- 走过本系列前 51 篇（本篇是总纲，反复引用前面结论）
- 或至少熟悉 35（cjc）/36（cjpm）/38（测试）/39（格式化检查）/40（构建发布）/44–45（内存/并发模型）

> 定位：全 52 篇的收官。目标不是"再学一个 API"，而是"**怎么把前面所有东西组织成一个不烂尾的工程**"。

## 1. 案例：本仓库本身就是一条 CI 流水线

与其空谈，直接复盘这个教程仓库的工程做法——它把"最佳实践"落成了**三道自动门禁**：

| 门禁 | 工具/脚本 | 挡住的错误 |
|---|---|---|
| **一致性** | `.github/scripts/sync_examples.py` | 文章里贴的代码 ≠ `examples/` 里的"规范示例"（每个 cangjie 块用 `<!-- example: 路径 -->` 绑定唯一真源） |
| **可编译/可运行** | `tools/test-local.sh`（本地 macOS + CI Linux） | 语法错、API 拼错、弃用项、运行时崩溃 |
| **平台真实** | GitHub Actions（Linux） | 本机 macOS SDK 链接不了 std 可执行、`std.reflect`/`stdx` 本机缺失 → 一律以 **Linux CI 实跑**为准 |

**关键设计**：每个示例"**单一真源**"——`examples/cangjie/NN-xxx.cj` 是唯一权威文件，文章里的是它的镜像；`sync_examples.py` 双向校验"每个规范示例都被某篇引用、每篇引用块与文件逐字节一致"。这就杜绝了"文档和代码各说各话"这一教程/工程通病。52 篇下来，59 个规范示例、`cjpm` 工程、乃至 stdx HTTP 服务全在 CI 上真跑过。

## 2. 项目结构：从单文件到多包模块

- **起步**（文章 15/36）：`cjpm init` 生成 `cjpm.toml` + `src/main.cj`；包名 = 模块名，`src/` 下子目录即子包。
- **分层**（承文章 48 实战）：按职责切文件——纯逻辑（可测）/ 参数解析 / IO 入口 / 测试各居其位。`clitool` 的 `wc.cj`/`args.cj`/`main.cj`/`wc_test.cj` 就是范例：**把有副作用的 IO 关在最薄的一层**，核心全是可单测的纯函数。
- **库分层**（承文章 30）：想清楚依赖落在 base `std` 还是扩展 `stdx`（HTTP/JSON/TLS/Crypto 都在 stdx、要单独获取，见文章 49）。别把 stdx 能力当成"装了 SDK 就有"。

**规范**：一个模块 = 一个 `cjpm.toml`；`cjpm.lock` **入库**（钉版本、保证同事/CI 拉到同一依赖）；`target/` **不入库**（`.gitignore`）。

## 3. 依赖与版本管理

1. **锁基线**（承文章 35/49）：`cjpm.toml` 里 `cjc-version = "1.0.5"`，全项目统一锁 **LTS**。本系列锁 1.0.5 LTS 正是因为 LTS 才稳、STS/Nightly 会漂移。
2. **依赖来源**（承文章 36）：同模块多包直接 `import <模块>.<子包>`；外部依赖 `[dependencies]` 用 path（本地）或 git（远端）；二进制预编译库走 `[target.<triple>.bin-dependencies].path-option`（文章 49 的 stdx 就是这么挂的）。
3. **更新有度**：改 `cjpm.toml` 后用 `cjpm update` 刷 `cjpm.lock`；`cjpm check`/`cjpm tree` 看依赖图与编译顺序（36）。
4. **跨版本无承诺的地方**（承文章 45/49 实测）：`stdx` 明说"不承诺跨版本 ABI 兼容"、`cjc` 的 `--enable-borrows` 是实验项——**这类东西要么锁死版本、要么别当稳定 API 依赖**。

## 4. 语言与库选型的"原则层"（承阶段四）

做架构决策前，脑子里应有这几条**语言事实**（均本系列实测）：

- **类型安全是编译期给的**（41/42）：无隐式数值转换、`match` 穷尽性、`Option` 不自动解包、`const` 上下文编译期求值/溢出报错——**别绕过它**（比如别为了"少写转换"去 `as` 来 `as` 去）。
- **值/引用是语义分水岭**（44）：`struct` 拷贝、`class`/`Array` 共享（注意 `Array` 是"名值实引用"）；热路径小定长数据用 `VArray`。
- **泛型不变、名义子类型**（41）：别指望 `Box<Int64>` 当 `Box<Any>` 用；`struct` 不进子类型格。
- **并发只认同步建立的可见性、原子只有 SeqCst**（45）：不加锁/原子就是 race；1.0.5 无 `Channel`/`actor` 关键字、消息传递靠 `ConcurrentLinkedQueue`；`MemoryOrder` 已弃用、内存序不进公开 API。

这些决定了"这个语言适合怎么写"——本系列判断：**仓颉是"带现代类型系统的 GC 工程语言"**（承 47），不是 Rust，别硬套零成本/无 GC 的架构。

## 5. 测试与代码质量：CI 里的质量门

承文章 38/39/46，一个仓颉项目的 CI 最小质量门应是：

```shell
cjfmt  -d src -o /tmp/fmt && diff -rq src /tmp/fmt   # ① 格式一致（cjfmt 幂等，39）
cjlint -f src -o ./report.json                        # ② 静态检查（规则码 G.*；"要求"级该拦，39）
cjpm build -l                                         # ③ 构建内建检查（"要求"级违规挡构建，48）
cjpm test                                             # ④ 单测（@Test/@Expect/@Assert，38）
cjpm test --coverage && cjcov --html-details          # ⑤ 覆盖率（gcno/gcda→html，38）
```

- 测试**分层**：纯函数用 `@Expect`/`@Assert` 直接喂数据断言（本系列 050 的 `WcTests` 即范式）；跨线程行为测确定性不变量（如 `052` 的可交换归约——只断言"结果与调度无关"，不测时序）。
- 1.0.5 单测断言是**宏** `@Expect`/`@Assert`（fail-fast vs 记录继续），不是 `assertEquals` 函数（38 实测）；异常/`@Ignore`/`@Tag` 的确切宏属性本文未全实测，用时查手册（38）。
- `cjfmt`/`cjlint` 用**短选项** `-h`/`-v`（39 实测 `--help` 反而报错）。

## 6. 文档与可复现性

1. **代码即文档**：`cjdoc` 抽 `/** */` 块文档注释生成 HTML API 文档（39；注意本机 macOS SDK 未含 cjdoc，命令以手册为准）。公共 API 的类型/函数都应有文档注释。
2. **示例可跑**：本系列的核心做法——**文档里的每段代码都对应一个 CI 实跑的规范示例文件**。教程/内部文档最怕"代码贴错了还没人发现"，单一真源 + sync 校验根治这个。
3. **版本信息随行**：每篇/每个库标"基于 X 版本"（本系列每篇末尾都有）；API 有"本版本缺失"的（argopt 撞名、无 `cjpm publish`、无 Channel、C 回调类型未验证）**如实标注、给查证路径**，绝不用"应该可以"糊过去——这是本系列一以贯之的纪律（29/36/38/45/49/51）。
4. **CHANGELOG / 版本策略**：本仓库用 `specs/version-strategy.md` 固化"锁 LTS + 每篇绑版本 + 升级重跑回归"。真实项目同理：语义化版本、CHANGELOG、破坏性变更单独标。

## 7. 构建、发布与部署（承文章 40）

- **产物**：`cjpm build` → `target/release/bin/<exe>`；调试 `-g`→`target/debug/`（且须 `-O0`，35）。
- **瘦身**：发布可执行考虑 `--strip-all`、`--lto=thin`（Linux 专属，35/40）。
- **运行时**：默认静态链 std、产物自包含；动态链 std/C 库则运行期靠 `LD_LIBRARY_PATH` 或编译期 `--set-runtime-rpath`（35/40/49）。
- **安装/分发**：可执行 `cjpm install --root`；库形态 `.a/.so`+`.cjo` 经 `--import-path`/`CANGJIE_PATH` 给对方，或推 git 仓库让对方 `[dependencies]` 引（36/40）。**1.0.5 无 `cjpm publish`**（实测），发布靠这三条腿。
- **发布前自检**：§5 质量门全绿 + `cjpm test` 无失败 + 覆盖率达标 + 弃用告警清零（35/38/39）。

## 8. 性能：测了再优化（承文章 46）

工程纪律而非技巧：**先 `cjprof`（40，Linux-only）拿火焰图 → 定位热点 → 多为"少分配"→ 改完再测对比**。别一上来调 `-O2`/内存序。GC 语言最稳的收益常是 §4 的选型（值类型、`VArray`、`StringBuilder`、池化 `std.objectpool`）而非编译开关。

## 9. 复盘：本系列踩过的"真实世界"坑（也是最佳实践的来处）

把这些集中列出，因为它们每一条都对应一个通用教训：

| 现象 | 教训（普适） | 篇 |
|---|---|---|
| `MemoryOrder` 已弃用、只有默认强度 | 别假设并发原语有 C++/Rust 级细粒度 | 45 |
| `Array` 是 struct 却共享 backing | "值类型"标签不等于深拷贝，看内部字段 | 44 |
| `as` 返回 `Option`、无 `as?` | 迁移自其他语言的下转直觉会错，读官方 | 41 |
| `unittest` 是宏不是函数、`cjpm` 无 `fetch`/`publish` | 凭印象的工具链命令会翻车，`--help` 实测 | 36/38 |
| macOS SDK 链接不了 std exe / 缺 `std.reflect`/`stdx`/`cjdoc` | 本地环境 ≠ CI，运行行为以标准平台(CI Linux)为准 | 35/37/39/49 |
| stdx 要 `build.py`+`NO_ASPECTCJ`+OpenSSL3 | "扩展库"接入是独立工程，别低估 | 49 |
| C 回调函数指针类型本机不可验证 | 无法验证的一律不写进示例，标注查证路径 | 51 |
| `cjfmt --help` 报错要用 `-h` | 工具习惯也别想当然 | 39 |

一句话：**"实测优先、未验证不硬编、平台差异如实标注"**——这是全系列 52 篇的地基，也是任何仓颉项目该有的工程文化。

## 10. 一页速查（工程 checklist）

```text
立项   ├─ 锁 LTS 版本，写 cjc-version；想清 std vs stdx 依赖
结构   ├─ cjpm init；src 按 纯逻辑/解析/IO/测试 分层；target 忽略、lock 入库
编码   ├─ 顺类型系统(无隐式转换/穷尽 match/Option)；值引用分明；并发只用同步+原子
质量   ├─ cjfmt(幂等) + cjlint + cjpm build -l 全绿
测试   ├─ 纯函数 @Expect/@Assert；并发测确定性不变量；cjpm test --coverage + cjcov
文档   ├─ /** */ 文档注释 cjdoc；示例单一真源 + sync 校验；版本信息随行
构建   ├─ release/-O2/--lto、strip 瘦身；动态依赖配 LD_LIBRARY_PATH/rpath
发布   ├─ cjpm install / 库+git 分发（无 publish）；弃用告警清零；CI 全绿
性能   └─ cjprof 测了再优化，先减分配后调开关
```

## 11. 结语

从一个 `hello world`（文章 6）到一条完整的"编码→测试→CI→发布→复盘"流水线（本篇），仓颉给的是一个**类型安全、工具链齐全、心智负担偏低的现代 GC 语言**（承 47）。把它用好的秘诀，不在记住每个 API，而在**相信编译器、锁住版本、让代码可测、把一切可验证的东西交给 CI**。本系列 52 篇到此完结——但真正的"学会"，是你拿它去写第一个自己的 `cjpm init`。

## 参考资料

1. 版本策略（本仓库实践）：`specs/version-strategy.md`
2. 各专题实测篇：类型/ADT/const/内存/并发/性能 41–46；工具链 35–40；实战 48–51
3. 学习路线总纲：`specs/learning-plan.md`（52 篇规划 + 覆盖矩阵）
4. 官方入口：cjc 编译选项 https://docs.cangjie-lang.cn/cjnative/user_manual/source_zh_cn/Appendix/compile_options.html ｜ cjpm 手册 https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/tools/cjpm_manual_cjnative_community.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写。全系列收官综述/复盘篇（同 37/47 无运行示例）；所有引用的语言事实、工具行为、平台差异均见对应实测篇（41–51），并经 Linux CI 验证。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
