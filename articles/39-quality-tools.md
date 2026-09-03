# 仓颉质量工具链：cjfmt 格式化、cjlint 静态检查与 cjdoc 文档

> **摘要**: 文章 37 里 IDE 上那些 `Format`/`CodeCheck` 按钮，命令行真身就是本篇三位主角——**`cjfmt`**（格式化）、**`cjlint`**（静态检查/代码规范）、**`cjdoc`**（API 文档生成）。`cjfmt`/`cjlint` 的**用法、配置、真实输出**都在 1.0.5 本地实测（含把 043 示例喂给 cjlint、精准复现 `G.NAM.02` 文件名建议）；**`cjdoc` 未随本机 macOS SDK 提供**（与 `std.reflect` 一样缺失），其命令与 `Doxyfile` 用法**取自官方手册、标注未本地实测**。配套示例 `043-quality-tools.cj` 本身即"cjfmt 规范 + 代码 cjlint 合规 + 带 cjdoc 文档注释"的活样板。

## 前置知识

- 已完成《cjc 编译器》（文章 35）、《cjpm》（文章 36）——`cjpm build -l/--lint` 会串 `cjlint`
- 已完成《IDE 插件》（文章 37）——知道 `Ctrl+Alt+F/C/G` 背后就是本篇工具
- 装好 1.0.5 SDK 并 `source envsetup.sh`

> 定位：阶段四"工具链·质量"。覆盖率 `cjcov`（文章 38）、调试 `cjdb`/性能 `cjprof`（文章 40）是另外的工具。

## 1. 三件套一览

| 工具 | 管什么 | 触发方式 | 本机可用? |
|---|---|---|---|
| `cjfmt` | 代码格式（缩进/空格/换行/对齐） | `cjfmt -f x.cj` | ✅ 实测 |
| `cjlint` | 编码规范（命名/写法/潜在坑），出 json/csv 报告 | `cjlint -f dir` | ✅ 实测 |
| `cjdoc` | 从文档注释生成 HTML API 文档 | `cjdoc <Doxyfile>` | ❌ 本机 SDK 未含，仅手册 |

版本：`cjfmt -v` / `cjlint -v`（实测 `Cangjie Lint: 1.0.5`）。注意它们的帮助用**短选项**——`cjfmt -h`/`cjlint -h`，写 `--help` 反而报 `illegal option`（实测踩过）。

## 2. cjfmt：格式化

用法骨架（本地 `cjfmt -h` 实测）：

```shell
cjfmt -f a.cj              # 格式化单文件
cjfmt -f a.cj -o b.cj      # 结果写到 b.cj（不改原文件）
cjfmt -d src/              # 递归格式化整个目录
cjfmt -d src/ -o out/      # 格式化输出到 out/
cjfmt -f a.cj -l 1:25      # 只格式化第 1~25 行（单文件才有效）
cjfmt -f a.cj -c myfmt.toml  # 指定格式化配置
```

- **配置文件**：`cangjie-format.toml`；不指定 `-c` 时先找 `CANGJIE_HOME` 下的默认配置，再退到内置配置。
- **幂等**：对已规范的文件再跑一次 `cjfmt`，内容不变。本仓库 CI 就是靠这点保证示例格式统一。

**实测前后对比**（同一段代码喂 `cjfmt`）：

```cangjie
package   fmt
func  add( a:Int64,b:Int64 ) :Int64{
return a+b
}
```

`cjfmt -f` 后：

```cangjie
package fmt

func add(a: Int64, b: Int64): Int64 {
    return a + b
}
```

它干的事：`package` 后多余空格压成一个、补空行分隔顶层声明、参数表 `a: Int64, b: Int64` 空格归一、`{` 前补空格、函数体缩进 4 空格。这些正是 `cjfmt` 的默认风格。

> **💡 在 CI 里当格式闸门**：把文件 `cjfmt -f x.cj -o tmp.cj` 后 `diff x.cj tmp.cj`，非空即格式不合规 → 退出非 0。本系列的 `tools/test-local.sh` 可据此扩一道 lint 门（当前用 sync + 编译两道）。

## 3. cjlint：静态检查

用法骨架（本地 `cjlint -h` 实测）：

```shell
cjlint -f src/                     # 检查目录，输出默认 json 报告
cjlint -f src/ -r csv -o ./out     # 出 csv；-o 指定输出路径（目录则默认名 cjReport）
cjlint -f src/ -e "src/a.cj:src/b/"  # 排除文件/目录/规则，冒号分隔，支持正则
cjlint -f src/ -c <cfgdir> -m <moddir>  # 手动指定配置/模块目录（否则用 CANGJIE_HOME 自动定位）
```

> **⚠️ 实测配置坑**：cjlint 要读规则配置（`cjlint_rule_list.json`，在 `$CANGJIE_HOME/tools/config`）和 std 模块 `.cjo`（`$CANGJIE_HOME/modules/<平台>`）。**直接 `cjlint -f <dir>`（配好 `CANGJIE_HOME`）最省事**；反而手动传 `-c`/`-m` 容易因层级判断报 `Can not find modules` / `open json file failed`。IDE 里点 CodeCheck 时插件已经帮你把这两条路径配好了（文章 37）。

### 3.1 报告长什么样（实测）

对一个不规范函数名，cjlint 产出结构化条目（json 每行一项 / csv 有表头 `SourceFile,Line,Column,Description,DefectType,DefectLevel`）：

```json
{
  "file": ".../bad.cj",
  "line": 3, "column": 1,
  "analyzerName": "cangjieCodeCheck",
  "description": "G.NAM.04: Function name 'ADD_numbers' recommend to use lower camel case",
  "defectLevel": "SUGGESTIONS",
  "defectType": "G_NAM_04_function_naming_information"
}
```

拆解：
- **规则码**：`G.NAM.04`（通用·命名·第 4 条）——命名类是 `NAM`，按前缀分类。
- **defectLevel 缺陷级别**：`SUGGESTIONS`（建议）——文章 37 提到还有**"要求"级**：cjpm/IDE 构建时命中"要求"级会**判失败**、"建议"级仅告警（`cjpm build -l/--lint` 或 IDE `Build With CodeCheck` 触发）。

### 3.2 一个惊喜：cjlint 连文件名都管

把本篇配套示例 `043-quality-tools.cj` 原样喂给 `cjlint`，它对**文件内容**零告警，却对**文件名**报了一条：

```text
G.NAM.02: Filename '043-quality-tools.cj' is recommended to use digits, lowercase letters and underscores(_)
```

即"文件名建议只用数字/小写字母/下划线"——我们仓库示例名里的连字符 `-` 属"建议级"偏差（不影响编译，只影响规范评分）。这是**在自家示例上跑 cjlint 的真实收获**，也说明规则覆盖面比"只看代码"更广。

> 想自定义开/关哪些规则、改级别，就动配置目录里的 `cjlint_rule_list.json`（`-c` 指向含 `config/` 的目录）。全量规则清单以官方《静态检查工具》手册为准。

## 4. cjdoc：API 文档生成（本机未含，取自手册）

> **诚实声明**：本机 macOS 1.0.5 SDK 里**没有 `cjdoc` 可执行文件**（`find` 全盘无 `cjdoc*`，`command -v cjdoc` 为空），与文章 30 遇到的 `std.reflect` 缺失同类。本节命令与配置**全部取自官方《API 文档生成工具》手册，未在本地跑通**，读时请以此为准。

`cjdoc`（Cangjie Doc）是**接口文档生成器**，能提取源文件里全局变量、函数、类、结构体、接口、枚举、扩展的**文档注释**，输出 **HTML** API 文档。它**思路接近 Doxygen**（用 `Doxyfile` 配置）。

- **文档注释风格**：以 `/** ` 开头、` */` 结尾，多行每行以 `*` 起始（起始是 `/**` 而非 `/*` 或 `//`，这是与普通注释的分界）。043 示例的函数上就是这么写的。
- **常用命令**：

```shell
cjdoc -g              # 生成默认配置文件 Doxyfile
cjdoc -g mydoc        # 生成名为 mydoc 的配置模板
cjdoc                 # 用当前目录 Doxyfile 生成文档
cjdoc mydoc.conf     # 用指定配置生成
```

- **Doxyfile 关键字段**：`PROJECT_NAME`（页面标题）、`INPUT`（要抽文档的源文件/目录，多个空格分隔，`INPUT +=` 追加）、`EXCLUDE`（排除）、`GENERATE_LATEX`（默认 YES，建议设 NO，只留 HTML）。`INPUT` 里写了不存在的路径会给 `warning: source 'xxx' is not a readable file... skipping`。

> 文档注释里 cjdoc 支持若干"注解"（param/return 等）组织"描述部分 + 注解部分"。具体注解集合以手册为准（本文不逐一罗列未实测项）。

## 5. 完整示例（三位一体的样板）

`043-quality-tools.cj`——`cjfmt` 跑过（幂等）、代码 `cjlint` 无内容告警、带 `cjdoc` 风格块注释：

<!-- example: cangjie/043-quality-tools.cj -->
```cangjie
/**
 * 质量工具链示例：cjfmt 规范化、cjlint 代码合规、cjdoc 文档注释。
 * cjdoc 是仓颉的 API 文档生成器（思路接 Doxygen），识别块文档注释。
 * 提示：cjlint 也检查文件名，本文件名含连字符会触发一条 G.NAM.02 建议（见正文）。
 */
package quality

/**
 * 摄氏转华氏（整数版）。
 * @param celsius 摄氏温度
 * @returns 对应的华氏温度
 */
public func celsiusToFahrenheit(celsius: Int64): Int64 {
    return celsius * 9 / 5 + 32
}

main(): Int64 {
    println("0C -> ${celsiusToFahrenheit(0)}F")
    println("100C -> ${celsiusToFahrenheit(100)}F")
    return 0
}
```

用它跑三件套：

```shell
cjfmt  -f 043-quality-tools.cj -o /tmp/fmt.cj && diff 043-quality-tools.cj /tmp/fmt.cj   # 无 diff=已规范
cjlint -f .            # 内容无告警；仅文件名一条 G.NAM.02（建议级）
cjpm build -l         # 构建时顺带 cjlint，"要求"级会挡住构建
```

程序运行输出（Linux CI 核对，确定值）：

```text
0C -> 32F
100C -> 212F
```

## 6. 串进 CI 当质量门

把三者接到提交/流水线里，形成"格式 → 规范 → 文档"的闭环（本仓库已有 sync + 编译两道门，可再加 cjfmt/cjlint）：

```shell
cjfmt  -d examples/cangjie -o /tmp/fmt_out && diff -rq examples/cangjie /tmp/fmt_out  # 格式门
cjlint -f examples/cangjie -o ./cjReport.json   # 规范门（可脚本判 defectLevel 含"要求"则 fail）
```

> 与文章 52 的"持续集成"篇呼应：`cjfmt`/`cjlint` 退出码 + 报告解析，是比"人肉 review 风格"更稳的工程实践。

## 7. 与其它语言工具对照

| 能力 | 仓颉 | Rust | Go | C/C++ |
|---|---|---|---|---|
| 格式化 | `cjfmt` | `rustfmt` | `gofmt` | `clang-format` |
| 静态检查 | `cjlint` | `clippy` | `go vet` | `clang-tidy` |
| 文档生成 | `cjdoc` | `rustdoc` | `godoc` | Doxygen |
| 一键串起 | `cjpm build -l` | `cargo clippy` | CI 脚本 | — |

`cjdoc` 明确是 **Doxygen 血统**（`Doxyfile`、`/** */` 注释、`INPUT`/`EXCLUDE`）——会 Doxygen 的直接迁移；`cjfmt`/`cjlint` 分别对标 `rustfmt`/`clippy`。

## 8. 常见问题（FAQ）

### Q1: `cjfmt --help` 报错？

它用短选项：`cjfmt -h`。同理 `cjlint -h`。长选项 `--help` 会 `illegal option`（实测）。

### Q2: cjlint 老说找不到 modules/config？

别手动传 `-c/-m`，**配好 `CANGJIE_HOME` 后直接 `cjlint -f <dir>`** 让它自动定位（第 3 节）。IDE 的 CodeCheck 已代配。

### Q3: 检查到问题会拦构建吗？

分级别：**"要求"级**在 `cjpm build -l`/IDE `Build With CodeCheck` 下会导致**构建失败**；**"建议"级**（如我们示例文件名的 `G.NAM.02`、`ADD_numbers` 的 `G.NAM.04`）只告警不拦。

### Q4: 我的示例名有连字符，是不是不合规？

对 `cjlint` 的命名建议而言算"建议级"偏差（数字+小写+下划线为推荐）。教程用 `NN-name.cj` 是为可读排序，不强制改；要过 lint 评分可改下划线，但会与本仓库其余 40+ 示例命名不一致。

### Q5: 本机能跑 cjdoc 吗？

**这台 macOS SDK 没带 `cjdoc`**，第 4 节命令未本地实测。要生成文档请在含 cjdoc 的完整发行版（或 Linux 对应 SDK）上做；本文对 cjdoc 的描述以官方手册为事实源。

### Q6: cjfmt 能把风格改成我团队的？

有限自定义：`cjfmt -c <cangjie-format.toml>` 指定配置；默认风格（4 空格缩进、声明间空行、`a: T, b: T` 空格）由配置决定。深度自定义能力以手册为准。

## 9. 总结

1. **cjfmt**：`-f`单文件 / `-d`目录 / `-o`输出 / `-c`配置 / `-l`行区间；**幂等**，可做 CI 格式门；本机实测。
2. **cjlint**：`-f`检查 / `-e`排除 / `-o`输出 / `-r json|csv`；报告含**规则码**(`G.NAM.*`) + **defectLevel**(要求拦构建/建议告警)；配好 `CANGJIE_HOME` 免传 `-c/-m`；**连文件名都查**（043 实测 `G.NAM.02`）；本机实测。
3. **cjdoc**：Doxygen 风 `Doxyfile` + `/** */` 注释生成 HTML API 文档；**本机 SDK 未含、命令未本地实测**（诚实标注）。
4. **串 CI**：`cjpm build -l` 把 cjlint 纳入构建质量门；格式/规范/文档三闸门自动化。

## 参考资料

1. 格式化工具 cjfmt：https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/tools/cjfmt_manual.html
2. 静态检查工具 cjlint：https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/tools/cjlint_manual_community.html
3. API 文档生成工具 cjdoc：https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/tools/cjdoc_manual.html
4. 上一篇：单元测试与覆盖率（articles/38-unittest.md）

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写。**诚实标注**：`cjfmt`/`cjlint` 用法与输出为本地实测；`cjdoc` 未随本机 macOS SDK 提供（同 `std.reflect` 缺失），第 4 节内容取自官方手册、未本地跑通。工具文档在 `/cjnative/`（latest）路径。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
