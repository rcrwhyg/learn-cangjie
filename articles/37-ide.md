# 仓颉 IDE 与语言服务：VS Code 插件的补全、诊断、构建、调试与检查

> **摘要**: 前面 `cjc`（文章 35）、`cjpm`（文章 36）都在终端里敲；这篇把它们收进 **VS Code 插件**里可视化操作。内容全部**取材官方《IDE 插件使用指南》**（`/cjnative/` 版），覆盖：插件安装与 SDK 路径配置、**语言服务**（高亮/补全/跳转/引用/诊断/悬浮/重命名/类型与调用层次）、**工程管理**、**编译构建**（背后仍是 `cjpm`）、**三方库导入**、**调试服务**（基于 `cjdb`）、**格式化/静态检查/覆盖率**。
>
> **⚠️ 本篇没有可运行示例**：IDE 是图形界面，补全弹窗、断点、调试面板这类东西**无法用 `cjc`/CI 跑出来逐行核对**，与本项目"每篇配一个 CI 实测示例"的惯例不同——所以这篇**不附 `examples/` 代码、没有"预期输出"**，只在能证的地方给配置片段（`cjpm.toml`/`launch.json`），并把**能力边界**（哪些平台不支持调试、哪些目录不享受语言服务）如实列出。请把这当作**官方文档的中文导读 + 选型地图**来读。

## 前置知识

- 已装 1.0.5 LTS SDK（文章 2），会用 `cjpm init/build/run`（文章 36）
- 装过任一语言的 VS Code 插件、知道 `.vsix` / `launch.json` / `settings` 是什么

> 定位：阶段四"工具链"第三篇。`cjdb`（调试器）、`cjfmt`/`cjlint`/`cjcov`/`cjdoc`（命令行）本篇只讲它们在 IDE 里的"入口"，各自的命令行细节留给文章 39/40。

## 1. 插件到底给了什么

官方口径：装了**仓颉 VS Code 插件 + 配好 SDK 路径**后，插件提供 **7 类能力**——语言服务、工程管理、编译构建、调试服务、格式化、静态检查、代码覆盖率统计。其中"编译构建"可视化的底层就是 `cjpm`，"调试"底层是 `cjdb`，"格式化/检查/覆盖率"底层是 `cjfmt/cjlint/cjcov`。**IDE 是壳，命令行工具是芯**——所以你在终端会的事，插件基本都给了按钮版。

## 2. 安装：插件 + SDK 路径两步

1. **VS Code**：建议 **1.67 及以上**。
2. **装插件**：从仓颉官方渠道（GitCode）下 `Cangjie-vscode-<version>.tar.gz`，解压得到 `.vsix`，在 VS Code 扩展面板"从 VSIX 安装"选它；装好的插件在 `INSTALLED` 里能看到。
3. **配 SDK 路径**（关键，也是最容易漏的一步）：设置里搜 `cangjie` → `Cangjie Language Support`：
   - `Cangjie Sdk: Option` 选后端 **CJNative**（默认）；
   - `Cangjie Sdk Path: CJNative Backend` 填 SDK **绝对路径**；
   - **重启 VS Code** 生效。

> 插件也提供"下载/更新最新版 SDK"的图形功能；不想用它可以官网下 SDK 再手动填路径。**没配 SDK 路径 = 构建/格式化/检查/覆盖率全部用不了**（三平台皆如此）。

## 3. 语言服务：编辑时最常用的一组

打开工程里的 `.cj` 即可。支持的交互能力（快捷键为官方值）：

| 能力 | 触发方式 | 备注 |
|---|---|---|
| 语法高亮 | 自动 | 随 VS Code 主题 |
| 自动补全 | 输 `.`/关键字 | 带参函数/泛型有**模块化补齐**（Tab 跳参数） |
| 定义跳转 | `F12` / `Ctrl+单击` / 右键 Go to Definition | **支持跨文件** |
| 跨语言跳转 | 对 `foreign` 函数 `F12` | 需装华为 C++ 插件 + 配 C 源码目录 + `compile_commands.json` |
| 查找引用 | 右键 Find All References | |
| 诊断报错 | 自动（红色波浪线） | 悬停看错误文本；改对即消失 |
| 悬浮提示 | 鼠标悬停 | 变量显类型、函数显原型 |
| 签名帮助 | 输入 `(` 或 `,` 触发 | 高亮当前参数位 |
| 重命名 | `F2` / 右键 Rename Symbol | class/func/struct/enum/变量/宏名等 |
| 定义搜索 | `Ctrl+T` | 搜 class/enum/interface/struct/prop/typealias/函数/变量 |
| 类型层次 | 右键 Show Type Hierarchy | 在 class/enum/interface/struct 名上 |
| 调用层次 | 右键 Show Call Hierarchy | 在函数名上，可切"调用者/被调用者" |
| 大纲 / 面包屑 | OUTLINE 视图 / 顶部路径 | 两层（顶层声明 + 成员） |

> 语言服务的"诊断报错"用的就是文章 35 讲的那套**前端语义检查**——你在编辑器看到的红波浪线错误文本（如 `mismatched types ... expected 'Int64', found ...`）和 `cjc` 命令行里打的是**同一套**诊断，插件只是把它画在编辑器里。

## 4. 使用限制（务必先读，否则会"莫名不工作"）

官方列了三条硬限制，也是最常踩的坑：

1. **只管"打开的文件夹"以内**：VS Code 以你打开的文件夹为项目根 `PROJECTROOT`（未指定模块名时**用目录名当模块名**）。`PROJECTROOT/src` 下的源码享受语言服务；`PROJECTROOT` 下非 `src` 的源码也支持；但 **`PROJECTROOT` 之外的"外部源码"不支持语言服务**。
2. **非 `src` 目录每个文件夹算一个包**，可 `import` 标准库和 `src` 下的包，但**不能被别的包 `import`**。
3. **三平台都要先配好 SDK 路径**（同第 2 节）。

> 实务建议：**用 `cjpm init` 生成的标准布局**（`src/main.cj` + `cjpm.toml`，文章 36），整个工程目录作为 `PROJECTROOT` 打开，别把源码散落在工程外——这样语言服务/构建/调试都最顺。

## 5. 工程管理：图形化建工程

两种建法（本质都是帮你生成第 36 节那套 `cjpm.toml` + `src/`）：

- **命令面板**：`F1` → 搜 `Cangjie` → 选创建工程 → 选后端(CJNative) → 选模板 → 选路径 → 输入名字。
- **可视化界面**：命令面板选"可视化创建"命令 → 选工程类型 → 选路径 → 输入名字 → `Confirm`。

## 6. 编译构建：可视化背后全是 cjpm

> **前提**：IDE 可视化构建**依赖 `cjpm`**，要求工程内有规范的 `cjpm.toml`；没有它就只能回终端用 `cjc`（文章 35）。

并行编译(`Parallelled Build`)后产物在 **`target/release/`**：`.build-logs`(日志)、`bin`(可执行文件，仅 `output-type=executable` 时生成)、`<工程名>`(中间产物)——与文章 36 终端 `cjpm build` 的产物目录**完全一致**。命令面板里一大堆构建变体，其实就是把 `cjpm build` 的参数做成菜单：

| IDE 命令 | 等价的 cjpm/cjc |
|---|---|
| `Parallelled Build` | `cjpm build` |
| `Build With Verbose` | `cjpm build -V` |
| `Build With Debug` | `cjpm build -g` |
| `Build With Coverage` | `cjpm build --coverage` |
| `Build With Increment` | `cjpm build -i` |
| `Build With Alias` | `cjpm build -o <名字>` |
| `Build With Jobs` | `cjpm build -j <N>`（范围 (0, 核数*2]） |
| `Build With TargetDir` | `cjpm build --target-dir` |
| `Build With CodeCheck` | 构建 + `cjlint` 静态检查 |
| `Build With CustomizedOption` | 透传 `cjpm.toml` 里 `customized-option` |
| `Update Cjpm.toml` | `cjpm update`（刷新 `cjpm.lock`） |
| `Clean Build Result` | `cjpm clean` |

还有：**编辑区"▶运行按钮"**=编译+运行（`output-type=executable` 才在终端打印运行结果）、**"🔨锤子按钮"**=只编译不运行。`cjpm.toml` 与 `.vscode/cjpm_build_args.json` 可通过 `Edit Configuration (UI)` **可视化编辑**（改完同步回文件）。

> **⚠️ 终端跑 cjpm 的小坑**：想在 VS Code 内置终端直接敲 `cjpm`，官方要求**关掉工程重开 VSCode**（reload 窗口不算）。

## 7. 三方库导入（cjpm.toml 的图形入口）

`cjpm.toml` 里可配的依赖类型，插件在资源管理器加了 **`CANGJIE LIBRARY`** 侧栏做图形增删（同步写回 `cjpm.toml`）：

| 字段 | 含义 |
|---|---|
| `dependencies` | 构建所需依赖（版本+路径，**首选**） |
| `dev-dependencies` | 仅开发/测试用依赖（格式同上） |
| `bin-dependencies` | 导入已编译好的包（`package-option` 按 `模块_包`→`.cjo`；或 `path-option` 列目录，二者同包时 `package-option` 优先） |
| `ffi` | 依赖外部 **C 库**（名称+路径，承文章 34 的 C 互操作） |

> **诚实提示**：链接了动态库（C 库/仓颉 `.so`）时，**运行期要自己设 `LD_LIBRARY_PATH`**，否则构建期会失败——这跟文章 35/36 讲的"动态库运行时加载"是同一件事，IDE 里也一样。

## 8. 调试服务：基于 cjdb，但有平台限制

功能很全：Launch（起进程调试）/ Attach（附加到已有进程）、源码/函数/数据/汇编断点、单步/步入步出/运行到光标、**仓颉-C 互操作调试**（continue/步入进 C）、表达式求值、变量查看修改、**反向调试**、**unittest 的运行与调试**（`@Test`/`@TestCase` 行上的 run/debug 按钮）。

配置靠 `.vscode/launch.json`，`type` 填 `cangjieDebug`，最小示例：

```jsonc
{
  "name": "Cangjie Debug (cjdb): main",
  "type": "cangjieDebug",
  "request": "launch",
  "program": "${workspaceFolder}/target/release/bin/main"
}
```

> **🚫 本篇最重要的边界**：**调试服务目前只支持 Windows 和 Linux 版 VS Code——macOS 不支持调试**。且调试依赖 SDK 内的 `liblldb`（需先配好 SDK 路径）。另外官方提示：循环里带条件断点时 `PAUSE` 可能卡住后续调试；表达式求值暂不支持元组和基础 Collection 类型。
> 单文件调试：右键 `Cangjie: Build and Debug File`（自动生成 `task.json` + 编译脚本）。远程调试：远端起 `lldb-server`、`launch.json` 里 `remote:true` + `remoteAddress` 等（仅 remote-linux）。

## 9. 格式化 / 静态检查 / 覆盖率：命令入口

| 能力 | IDE 入口 / 快捷键 | 底层命令行工具 | 细节 |
|---|---|---|---|
| 格式化 | 右键 `[Cangjie] Format` / `Ctrl+Alt+F` | `cjfmt` | 单文件 / 整个文件夹 |
| 静态检查 | 右键 `[Cangjie] CodeCheck` / `Ctrl+Alt+C` | `cjlint` | **仅扫 `src/` 下**；"要求"级违规算错、"建议"级仅告警 |
| 覆盖率 | 右键 `[Cangjie] Coverage` / `Ctrl+Alt+G` | `cjcov` | 生成覆盖率报告（承文章 35 `--coverage`） |

命令行 `cjfmt/cjlint/cjcov/cjdoc/cjprof` 的独立用法放在**文章 39**（格式化/检查/文档）和**文章 40**（调试/性能/构建部署）细讲，本篇只给它们的 IDE 按钮在哪。

## 10. 与其它语言的 VS Code 插件对照

| 维度 | 仓颉插件 | Rust Analyzer | Go 扩展 |
|---|---|---|---|
| 语言服务协议 | ✅（cjls 随插件） | ✅ rust-analyzer | ✅ gopls |
| 构建按钮背后 | `cjpm` | `cargo` | `go build` |
| 调试 | `cjdb`/lldb（**Win/Linux**） | CodeLLDB/lldb | delve |
| 格式化 | `cjfmt` | rustfmt | gofmt |
| 静态检查 | `cjlint` | clippy | vet/staticcheck |
| 覆盖率 | `cjcov` | tarpaulin/llvm-cov | `go test -cover` |

心智完全对齐：**插件 = 语言服务器(LSP) + 把 `cjpm/cjfmt/cjlint/cjdb` 包成按钮**。用过 Rust/Go 插件的可直接类比。

## 11. 常见问题（FAQ）

### Q1: 为什么我打开的 `.cj` 没有补全、也不报错？

多半是 **SDK 路径没配**或**文件在 `PROJECTROOT` 之外**（第 4 节限制一）。先配 `Cangjie Sdk Path: CJNative Backend` 并重启，再确认是把**整个工程目录**作为文件夹打开的。

### Q2: macOS 能调试吗？

**不能**。官方明确：调试服务当前只支持 **Windows 和 Linux** 版 VS Code。macOS 上写/补全/构建/格式化/检查都行，唯独图形化调试不行——要调试请用 Win/Linux 或远程 Linux。

### Q3: IDE 里点"构建"报错找不到 cjpm / 没产物？

可视化构建依赖 `cjpm` 和规范的 `cjpm.toml`（第 6 节前提）。没有 `cjpm.toml` 就只能回终端 `cjc`（文章 35）。产物在 `target/release/bin/`，只有 `output-type=executable` 才有可执行文件。

### Q4: 静态检查为啥扫不到我工程根目录下的 `.cj`？

`cjlint` **只检测 `src/` 下的仓颉文件**（第 9 节）。放在 `src` 外的文件不在检查范围。

### Q5: 调试时程序要用的 `.so` 加载不到？

跟命令行一样：运行期设 `LD_LIBRARY_PATH`（第 7 节）。在 `launch.json` 的 `env` 里给被调试进程加环境变量（追加用 `${env:LD_LIBRARY_PATH}`）。

### Q6: 反向调试、跨语言(C)跳转这些高级货要额外配吗？

要。反向调试在设置里勾 `Reverse Debug > Enable reverse debug`（记录历史停止点）；仓颉→C 跳转需**华为 C++ 插件 + 配 C 源码目录 + `compile_commands.json`**（第 3 节）。属于进阶，需要时回本手册查。

## 12. 总结

1. **插件 = 语言服务 + `cjpm/cjfmt/cjlint/cjdb/cjcov` 的图形壳**；先装 `.vsix`、再配 **SDK 路径**（CJNative 后端），否则功能半瘫。
2. **语言服务**覆盖高亮/补全/跳转(F12)/引用/诊断/悬浮/重命名(F2)/类型&调用层次；诊断与 `cjc` 同一套。
3. **限制要记牢**：只管打开文件夹以内、非 `src` 每个文件夹是一个包但不被导入、三平台都得配 SDK。
4. **构建/工程管理**是 `cjpm` 的按钮版（产物目录一致 `target/release/`）；**调试基于 cjdb 但 macOS 不支持**（仅 Win/Linux）；**静态检查只扫 `src/`**；格式化/覆盖率对应 `cjfmt/cjcov`。
5. 本篇**无 CI 运行示例**——IDE 图形能力按官方手册导读，可验证的编译链细节看文章 35/36。

## 参考资料（均为官方文档，本篇为文档来源）

1. IDE 插件使用指南（本篇主来源）：https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/IDE/user_manual_community.html
2. 命令行工具使用指南（总览）：https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/tools/user_manual_cjnative.html
3. 调试工具 cjdb：https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/tools/cjdb_manual_cjnative.html
4. 格式化工具 cjfmt：https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/tools/cjfmt_manual.html
5. 静态检查工具 cjlint：https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/tools/cjlint_manual_community.html
6. 覆盖率工具 cjcov：https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/tools/cjcov_manual_cjnative.html
7. 上一篇：cjpm 包管理器（articles/36-cjpm.md）

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写。**特别说明**：本篇是**工具链中唯一无 CI 运行示例**的一篇（IDE 图形能力无法用编译/运行逐行核对），内容以官方《IDE 插件使用指南》为准；文中所有"限制/平台支持"结论（调试不支持 macOS、静态检查仅 src、外部源码无语言服务）均直引官方文档。工具类文档官方仅以 `/cjnative/`（latest）路径发布。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
