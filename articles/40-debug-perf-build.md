# 仓颉工具链补全：cjdb 调试、cjprof 性能分析与构建发布

> **摘要**: 阶段四工具链收官篇。把 `cjdb`（调试器）、`cjprof`（性能分析）、构建产物 `target/`、运行时配置、以及打包发布（`cjpm install`）串成一条"从写代码到交付"的链路。**核验级别分三档，逐节标注**：① 本地实测——`cjdb` 确为 **lldb 15.0.4 内核**（`cjdb -v`）、其命令行选项（`cjdb -h`）、`cjpm install` 的子命令与参数；② 官方手册——`cjdb` 的调试会话（launch/attach/断点/`cjthread`）、`cjprof` 的 `record/report/heap`（**`cjprof` 仅支持 Linux、本机 SDK 未提供**）；③ 承前文——`target/` 结构、四个运行时环境变量在文章 35/36 已实测。
>
> **⚠️ 本篇无可运行示例（同文章 37）**：调试要能跑的调试目标二进制、性能分析要 Linux + `perf` 权限，而本机 macOS 既链接不出可执行文件（文章 35/36 的 `ld64` 坑）、`cjdb` 图形调试又只支持 Win/Linux、`cjprof` 干脆 Linux-only——这些**没法用编译/运行逐行核对**。故本篇不附 `examples/` 代码、无"预期输出"，把**可证的东西证到底、不可证的东西明确标注来源**。

## 前置知识

- 文章 35（`cjc` 参数/产物/运行时环境变量）、36（`cjpm`）、37（IDE 里的调试按钮）、38（覆盖率）、39（格式化/检查）
- 知道 `lldb`/`gdb`/`perf`/火焰图 等概念更好，不强制

## 1. 调试器 cjdb

### 1.1 它是什么（本地实测）

`cjdb -v` 实测直接吐出：

```text
lldb version 15.0.4 (revision bd0f7a...)
  clang revision bd0f7a...
  llvm revision bd0f7a...
```

**`cjdb` 是基于 LLDB 封装的仓颉命令行调试器**——`cjdb -h` 的 `OVERVIEW: LLDB` 和一大票标准 lldb 选项（`--batch/-b`、`--attach-pid/-p`、`--attach-name/-n`、`--one-line/-o`、`--source/-s` 等，实测）都印证这点。会 lldb 的人几乎零成本上手；仓颉在其上加了**源码语言映射**与**自定义命令**。官方手册列的特性：

- 被调程序的 **launch / attach**
- **源码断点 / 函数断点 / 条件断点**
- 变量查看 / 修改（`print` / `set`）
- 表达式计算（`expr`）
- **仓颉线程查看（`cjthread`）**——仓颉自己的 lldb 扩展命令
- （IDE 侧还有反向调试、汇编视图等，见文章 37）

### 1.2 常用姿势（官方手册示例）

```text
$ cjdb test                       # 启动即指定目标
(cjdb) target create "test"       #   或用 file 命令加载
(cjdb) file test
(cjdb) break test.cj:7            # 源码行断点
(cjdb) run                        # 启动运行
(cjdb) bt                         # 看调用栈
(cjdb) print x                    # 查看变量
(cjdb) expr add(1,2)              # 表达式求值
(cjdb) cjthread                   # 查看仓颉线程
(cjdb) attach 15325               # 附加到已运行进程（按 pid）
```

手册里 attach 一个进程后能直接看到映射回仓颉源码的栈帧：`frame #0: ... test\`default.main() at test.cj:7:9`——断点/栈/变量都对齐到 `.cj`。

> **🚫 边界（务必知道）**：**调试目前只支持 Windows 与 Linux**（文章 37 的 IDE 限制，命令行同理），且依赖 SDK 内的 `liblldb`。**本机这台 macOS 更是连可执行文件都链接不出来**（文章 35 第 6 节的 `ld64` 坑），所以 `cjdb` 的调试**会话**我没法在这里实跑——上面代码块取自官方手册，请照此在 Linux/Windows 上用。

## 2. 性能分析 cjprof（本机未含，取自手册）

> **诚实声明**：本机 SDK **没有 `cjprof`**（`command -v cjprof` 为空），且**`cjprof` 官方明确"仅支持 Linux"**（依赖内核 `perf`）。本节全部来自官方《性能分析工具》手册。

`cjprof`（Cangjie Profile）三大能力：**CPU 热点函数采样**、**采样数据分析（文本报告 / 火焰图）**、**堆内存导出与分析**。三个子命令对应：`record` / `report` / `heap`。

```shell
# 采集：跑程序并采样（默认 1000 Hz）
cjprof record ./test arg1 arg2          # 产出 cjprof.data
cjprof record -f max -- ./test          # 用系统最大频率
cjprof record -f 10000 -p 12345 -o s.data   # 采指定 pid、自定义输出
# 分析：文本报告 or 火焰图
cjprof report -i cjprof.data            # 热点函数文本排名
cjprof report -F -o FlameGraph.svg      # 火焰图（仅 -F 时 -o 生效）
```

关键参数：`-f/--freq`（采样 Hz，默认 1000，`max` 取系统上限）、`-o/--output`、`-p/--pid`；`report -F` 出火焰图、`-i` 指定输入数据（默认 `cjprof.data`）。

> **⚠️ 权限门槛**：`cjprof record` 依赖 `perf`，需**二选一**——用 `root`/`sudo` 执行，或把 `/proc/sys/kernel/perf_event_paranoid` 设为 `-1`。采样直到被采程序退出才结束，可 `Ctrl+C` 提前停。`heap` 子命令做堆内存导出与分析（细节见手册）。

## 3. 构建产物：target/ 里都有什么

`cjpm build` 在工程下生成 `target/`（文章 36 实测），分层如下：

```text
target/
├── release/               # 默认（不加 -g）
│   ├── bin/               # 可执行文件（仅 output-type=executable）→ main 或 -o 指定名
│   ├── <模块名>/          # 各包中间产物：.cjo（AST 导出）等
│   ├── <模块名>-cache.json / incremental-cache.json   # 增量/依赖缓存
│   └── .build-logs/       # 每个包的编译 out/err 日志
└── debug/                 # cjpm build -g（带调试信息，供 cjdb/cjdb-IDE 用）
```

- **要调试** → 用 `-g`（且须 `-O0`，文章 35）产出 `target/debug/`，cjdb 加载它。
- **要发布小体积** → 编译期 `--strip-all`（剥符号）、`--lto=full/thin`（链接时优化，Linux 专属，文章 35/IDE 里 `Build With Debug` 等）。
- `cjpm clean`（可 `-g` 只清 debug）删 `target/`，不动 `cjpm.toml`/`cjpm.lock`。

## 4. 运行时配置（交付到别的机器要会这个）

承文章 35：`cjc` **默认静态链接 std**，产物自包含、换机即跑。一旦用 `--dy-std`/`--dy-libs` **动态**链接，或产物依赖 C `.so`，就要管运行时库路径。四个关键环境变量：

| 变量 | 阶段 | 作用 |
|---|---|---|
| `CANGJIE_HOME` | 编译 | SDK 根（IDE/工具都靠它定位 config/modules） |
| `CANGJIE_PATH` | 编译期 | 导入模块 `.cjo` 搜索路径（`--import-path` 覆盖） |
| `LIBRARY_PATH` | 链接期 | 链接器额外库目录（`-L` 覆盖） |
| `LD_LIBRARY_PATH` | **运行期**(Linux) | 动态链接器找 `.so`；产物动态依赖运行前必设对 |

**免设环境变量的部署技巧**：编译时加 `--set-runtime-rpath`，把运行时目录写进产物 rpath，拷走即用。`cjprof record` 这类要 `LD_LIBRARY_PATH` 含 SDK 的 `lib`，CI 里我们也是这么配的（文章 35 的 workflow）。详见《runtime 环境变量使用手册》。

## 5. 打包与发布

仓颉 1.0.5 **没有 `cjpm publish`**（和文章 36 的"无 `cjpm fetch`"一样，别再凭印象找它）。"发布"实际靠这几条腿：

1. **库形态分发**：把模块编成 `staticlib`(`.a`) / `dylib`(`.so`)（文章 35/36），连同 `.cjo`（AST 导出）一起给别人；使用者用 `--import-path`/`CANGJIE_PATH` 指过去。
2. **可执行安装**：`cjpm install`（本地实测选项）把编好的二进制装到指定位置：

   ```shell
   cjpm install --root /opt/myapp/bin     # 安装可执行到 --root
   cjpm install -g                        # 装 debug 版
   cjpm install --path ../othermodule     # 从别的模块目录装
   cjpm uninstall                         # 卸载
   ```

3. **源码/仓库依赖**：把工程推到 git 仓库，别人在其 `cjpm.toml` 的 `[dependencies]` 里以 git/path 形式引（文章 36）。

**发布前质量闸门**（把 38/39 串起来）：

```shell
cjpm build -l        # 构建 + cjlint（"要求"级违规会挡构建）
cjpm test            # 全量单测（文章 38）
cjfmt -d src -o /tmp/fmt && diff -rq src /tmp/fmt   # 格式一致性（文章 39）
cjpm test --coverage && cjcov                       # 覆盖率报告（文章 38）
```

## 6. 工具全景（阶段四合集）

| 工具 | 干什么 | 平台 | 本地可跑? | 哪篇细讲 |
|---|---|---|---|---|
| `cjc` | 编译/链接 | 跨平台 | ✅(编译) | 35 |
| `cjpm` | 包管理/构建 | 跨平台 | ✅ | 36 |
| cjls(IDE) | 语言服务 | Win/Linux/mac | ❌(随插件) | 37 |
| `cjdb` | 调试 | **Win/Linux** | 部分(有二进制,mac链不出) | 40(本篇) |
| `cjprof` | CPU/堆性能 | **仅 Linux** | ❌(本机未含) | 40(本篇) |
| `cjcov` | 覆盖率报告 | 跨平台 | ✅ | 38 |
| `cjfmt` | 格式化 | 跨平台 | ✅ | 39 |
| `cjlint` | 静态检查 | 跨平台 | ✅ | 39 |
| `cjdoc` | API 文档 | — | ❌(本机未含) | 39 |

> 三个本机 macOS 环境**用不了**的（cjls 二进制/cjprof/cjdoc），都已在对应篇如实标注、内容取自官方手册。

## 7. 与其它语言工具对照

| 能力 | 仓颉 | 通用等价 |
|---|---|---|
| 调试器 | `cjdb`（lldb 内核） | `lldb` / `gdb` |
| CPU 采样 | `cjprof record/report` | `perf` + FlameGraph |
| 堆分析 | `cjprof heap` | `valgrind massif` / `heaptrack` |
| 覆盖率 | `cjcov` | `llvm-cov` / `kcov` |
| 装可执行 | `cjpm install` | `cargo install` / `make install` |

`cjdb` 直接复用 lldb 命令词（`break`/`run`/`bt`/`print`/`expr`），只多一个 `cjthread`；`cjprof` 则像给 `perf` 套了个仓颉友好的 record/report 前端。

## 8. 常见问题（FAQ）

### Q1: cjdb 是不是要重学一套命令？

不用，它命令词就是 lldb（实测 `OVERVIEW: LLDB`）。`break`/`run`/`next`/`bt`/`print`/`expr` 全通用；仓颉特有的就一个 `cjthread`（看仓颉线程）+ 源码映射。

### Q2: macOS 能用 cjdb 调试吗？

**不能**。调试支持 **Windows/Linux**；且这台 macOS SDK 还链接不出可执行文件（文章 35/36 的 `ld64` 坑），根本没有调试目标。要调试上 Linux/Windows，或远程调试（launch.json `remote:true`，文章 37）。

### Q3: cjprof 报没权限 / 采不到？

`cjprof record` 要 `perf`：`sudo` 跑，或 `echo -1 > /proc/sys/kernel/perf_event_paranoid`。且 **cjprof 只有 Linux 版**，macOS/Windows 上没有。

### Q4: 编译好的程序拷到另一台机器说找不到 .so？

产物动态链接了运行时/std 就要运行期给库路径：设 `LD_LIBRARY_PATH`，或编译时 `--set-runtime-rpath` 把路径写进产物，或干脆别用 `--dy-std`（默认静态链最省事）。见第 4 节。

### Q5: 怎么把库发布给别人用？

1.0.5 无 `cjpm publish`：走"编 `.a`/`.so` + 附 `.cjo` → 对方 `--import-path`/`CANGJIE_PATH`"，或"推 git 仓库 → 对方 `[dependencies]` 引"。可执行则 `cjpm install --root`。见第 5 节。

### Q6: `cjpm install` 装了啥、装哪？

把当前（或 `--path` 指定）模块编出的**可执行文件**安装到 `--root` 下（默认在 SDK 的 bin 区）；`-g` 装 debug 版；`cjpm uninstall` 卸载。

## 9. 总结

1. **cjdb = LLDB 内核的仓颉调试器**（实测 lldb 15.0.4）：launch/attach/断点/print/set/expr + 仓颉 `cjthread`；**仅 Win/Linux 调试、macOS 不可**（会话按手册）。
2. **cjprof = CPU 采样 + 火焰图 + 堆分析**，`record/report/heap`，**仅 Linux**、需 perf 权限（本机未含、按手册）。
3. **构建产物 `target/`**：release/debug × bin/中间 cjo/.build-logs；`-g` 出 debug、`--strip-all`/`--lto` 瘦身发布。
4. **运行时**：默认静态链自包含；动态链要 `LD_LIBRARY_PATH` 或 `--set-runtime-rpath`；四环境变量分工（承文章 35）。
5. **打包发布**：**无 `cjpm publish`**；库靠 `.a/.so/.cjo`+git 依赖、可执行靠 `cjpm install --root`；发布前 `cjpm build -l` + `cjpm test` + `cjfmt` + `cjcov` 串质量门。
6. 本篇与文章 37 同为**无 CI 运行示例**的工具链导读，可证项（cjdb 内核/选项、cjpm install、target 结构）本地实测，不可证项（cjdb 会话、cjprof）标注取自手册。

## 参考资料

1. 调试工具 cjdb：https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/tools/cjdb_manual_cjnative.html
2. 性能分析工具 cjprof：https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/tools/cjprof_manual_cjnative.html
3. 包管理工具 cjpm（install/uninstall/依赖）：https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/tools/cjpm_manual_cjnative_community.html
4. runtime 环境变量使用手册：https://docs.cangjie-lang.cn/cjnative/user_manual/source_zh_cn/Appendix/runtime_env.html
5. 上一篇：质量工具链 cjfmt/cjlint/cjdoc（articles/39-quality-tools.md）

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写。**核验级别**：`cjdb -v`/`cjdb -h`/`cjpm install -h`/`target/` 结构为本地实测；`cjdb` 调试会话与 `cjprof`（本机未含、Linux-only）取自官方手册、未本地实跑；调试不支持 macOS 的结论直引官方文档。工具文档在 `/cjnative/`（latest）路径。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
