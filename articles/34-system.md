# 仓颉标准库：系统能力（环境 / 进程 / 端序 / POSIX）

> **摘要**: 承接文章 26 的传输层 Socket，本篇覆盖"程序与操作系统交互"这一层——`std.env`（进程号、家目录、命令行参数、环境变量、标准流）、`std.process`（`execute` 跑外部命令拿退出码、`SubProcess` 起子进程读写管道）、`std.binary`（大/小端序读写扩展）、`std.posix`（POSIX 常量与系统调用封装）。**注意**：HTTP/WebSocket 属 `stdx.net`（同前面拆解的 `stdx` 系），本篇**不覆盖**、留给"stdx 网络专题"；`std.binary`/`std.posix` 的完整签名以官方库 API 为准，本文只写本地/CI 实测过的部分。示例聚焦 `std.env` + `std.process`，输出完全确定。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已完成《包、模块与程序入口》（`main(args: Array<String>)`）、《Socket 网络编程》（文章 26）、《标准库总览》（文章 30）
- 了解"进程 / 环境变量 / 退出码 / 字节序"等系统概念

> 定位：这是阶段三"标准库网络与系统能力"的落地。网络层已分两篇——传输层 Socket（26）、应用层 HTTP/WebSocket（属 stdx，另立）；本篇补齐**系统能力**（env/process/binary/posix）。

## 1. `std.env`：环境与进程信息

`std.env` 提供"我在哪个进程、什么环境里"的入口（`getStdIn/getStdOut/getStdErr` 已在文章 25 讲过，此处只列新增）：

| API | 返回 | 说明 |
|---|---|---|
| `getProcessId()` | 整数 | 当前进程 OS pid |
| `getHomeDirectory()` | `Path`（**不是 String**，用 `.toString()`） | 用户家目录 |
| `getCommandLine()` | 命令行 | 完整命令行字符串 |
| `getCurrentProcessInfo()` / `getProcessInfo(pid)` | `ProcessInfo` | 进程信息（含 `arguments`/`environment`/`workingDirectory`） |
| `getEnvirments()` | 环境变量映射 | 全部环境变量 |

> **⚠️ 命名坑**：函数名是 `getEnvirments`（历史拼写，非 `getEnvironments`）。`getHomeDirectory` 是 `Path` 而非 `String`；`args`/`getVar` 这类常见命名在 1.0.5 都不存在——用上面的实际名字。

**教程/CI 里怎么打不"漏"**：pid/家目录字符串**每台机器不同**、`getProcessId()` 每次不同，所以**别打印易变值本身**，只打印"是否 > 0"这类布尔判定，保证输出稳定。命令行参数同理。

## 2. `std.process`：起子进程

### 2.1 `execute` 跑命令

```cangjie
import std.process.*
let exitCode: Int64 = execute("/bin/echo", ["cangjie"])   // 可执行文件 + 参数数组
```

**`execute(可执行文件, 参数数组, ...): Int64`**——同步执行外部命令、继承当前进程标准流、**返回退出码**（0 表成功）。注意第一个参数是**可执行文件路径本身**（如 `/bin/echo`），命令与参数**分开传**；把 `"echo cangjie"` 整串当一个路径会报 `No such file or directory`（本文实测踩坑）。想拿子进程 stdout 内容，用 **`executeWithOutput`**。

> **💡 与"退出码"有关的心智**：`execute` 是 fire-and-forget 版（输出直连父进程 stdout）；`executeWithOutput` 是"我要看结果"版。要完全掌控 stdin/stdout/stderr/参数分开传，用下面的 `SubProcess`。

### 2.2 `SubProcess`：细粒度管道控制

```cangjie
let proc = SubProcess(command = "/bin/sh", arguments: ["-c", "echo hi"])
proc.useStdInPipe(); proc.useStdOutPipe()
proc.spawn()
let out = proc.waitOutput()        // 等子进程结束、拿 stdout
proc.close()
```

`SubProcess` 提供 `useStdInPipe/useStdOutPipe/useStdErrPipe` 拿到管道端点，`spawn()` 起进程、`wait()`/`waitOutput()` 等待。适合"喂输入→读输出"的交互式场景。`CurrentProcess.stdIn/stdOut/stdErr` 则拿本进程标准流（与 `std.env` 一组函数功能重叠）。

> **⚠️ 平台差异**：`"echo"`、`"sh -c"` 这些命令是 **POSIX 常见**，Windows 上不一定有——跨平台教程要意识到这点。CI runner 是 Linux，示例可跑。

## 3. `std.binary`：字节序（大端/小端）

`std.binary` 提供把整数/浮点按指定**字节序**读写到 `Array<Byte>`/流的扩展。核心类型是**接口**：

| 接口 | 语义 |
|---|---|
| `EndianOrder` | 端序抽象 |
| `BigEndianOrder` | 大端（网络序） |
| `LittleEndianOrder` | 小端（x86/ARM 常见主机序） |
| `SwapEndianOrder` | 翻转 |

具体读写用哪个函数名/签名（如 `writeInt32`/`readInt64`）**以库 API 为准**——本文在本地试编译时接口形状有多种候选，为避免凭印象写错，**不列出未验证的完整签名**；请用 `import std.binary.*` 后按 IDE 补全或库 API 页查。用法大方向：给一个流/字节缓冲 + 传入一个 `EndianOrder` 实例，就能按端序读写。

## 4. `std.posix`：POSIX 系统调用与常量

`std.posix` 把常用 POSIX 常量/系统调用封装成仓颉 API（跨平台一致性由 std 层做）。常见常量：

- 打开标志：`O_RDONLY`/`O_WRONLY`/`O_RDWR`/`O_CREAT`/`O_TRUNC`/`O_APPEND`/`O_EXCL`/`O_NONBLOCK` …
- `access` 模式：`F_OK`/`R_OK`/`W_OK`/`X_OK`
- `fcntl`/`mmap`/`epoll` 等相关常量

系统调用函数（`open`/`read`/`write`/`close`/`stat`/`fork`/`exec` 等）**在 `std.posix` 里以带 `Int32` 返回码的形式提供**，需要 unsafe 与手动 `errno` 处理。**跨平台代码优先用 `std.fs`**（文章 25 已讲），只有需要 POSIX 独有能力时才用 `std.posix`。

## 5. 完整可运行示例（`std.env` + `std.process`）

只放**输出稳定、跨机器一致**的部分：pid/家目录存在性布尔判定 + `execute("echo cangjie")` 退出码。

<!-- example: cangjie/039-system.cj -->
```cangjie
// 标准库系统能力示例（1.0.5 base SDK：std.env + std.process）
// 演示：读当前进程信息（getProcessId / getHomeDirectory）、用 std.process.execute 跑一条
// 外部命令（可执行文件 + 参数数组）并拿回退出码。本地可 staticlib 编译；输出确定。
//
// 说明：HTTP/WebSocket 属 stdx.net、序列化端序 std.binary 的完整签名以库 API 为准；
// Socket 见文章 26《Socket 网络编程》。本篇聚焦"系统/进程/环境"。

import std.env.*
import std.process.*

main(): Int64 {
    // 1) 运行环境：进程号、家目录（只判定"存在"，不打印易变的具体值）
    let hasPid = getProcessId() > 0
    let hasHome = getHomeDirectory().toString().size > 0
    println("env: has_pid=${hasPid}, has_home=${hasHome}")   // env: has_pid=true, has_home=true

    // 2) 起子进程：execute 跑一条命令，返回其退出码（Int64）
    let code = execute("/bin/echo", ["cangjie"])   // execute(可执行文件, 参数数组)
    println("process: execute(echo) exit=${code}")   // process: execute(echo) exit=0

    return 0
}
```

预期输出：

```text
env: has_pid=true, has_home=true
process: execute(echo) exit=0
```

## 6. 语言对比

| 主题 | 仓颉 | Go | Rust (std) | Java |
|---|---|---|---|---|
| 环境变量 | `std.env.getEnvirments()` | `os.Getenv` | `std::env::var` | `System.getenv` |
| 家目录 | `getHomeDirectory(): Path` | `os.UserHomeDir` | `dirs` crate | `user.home` 属性 |
| 起子进程 | `execute(cmd): Int64`（退出码） | `exec.Command().Run()` | `std::process::Command::status()` | `ProcessBuilder.start().waitFor()` |
| 拿子进程输出 | `executeWithOutput` / `SubProcess.waitOutput` | `cmd.Output()` | `.output()` | 手动读 `InputStream` |
| 端序 | `std.binary`（EndianOrder 接口） | `encoding/binary` | `byteorder` crate | `ByteBuffer.order()` |
| POSIX | `std.posix`（含系统调用） | `syscall`/`golang.org/x/sys/unix` | `libc`/`nix` crate | JNA/JNI |

**从 Go 迁移**：`execute(cmd): Int64` 相当于 `cmd.Run()` 只看退出码；想看输出用 `executeWithOutput` 或 `SubProcess`，对应 `cmd.Output()`。
**从 Rust 迁移**：`SubProcess` 类似 `Command`+`Stdio::piped()` 组合；`Path` 返回值对应 Rust `PathBuf`。

## 7. 常见问题（FAQ）

### Q1: `main` 参数、`std.env` 的 args、`ProcessInfo.arguments` 有啥区别？

`main(args: Array<String>)` 是**你进程**的命令行参数（文章 15 讲过）；`ProcessInfo.arguments` 也可拿到"当前进程参数"；两者数据同源、视角不同。要**另一个进程**的参数，用 `getProcessInfo(pid).arguments`。

### Q2: `getHomeDirectory()` 直接当字符串用？

不能——它是 `Path`。要字符串就 `.toString()`；要与文件系统交互，直接给 `std.fs` 那些 API 用。

### Q3: `execute` 拿不到子进程 stdout？

`execute` 让子进程**继承**你的 stdout（直接打到屏幕）。想把内容读进变量，用 `executeWithOutput` 或 `SubProcess` + `waitOutput()`。

### Q4: `execute` 第一个参数能写整条命令吗？
不能。第一个参数是**可执行文件路径**（如 `/bin/echo`），参数要放数组里。跨平台还要考虑路径差异（Windows 上 `echo` 是 cmd 内建、无 `/bin/echo`）。

### Q5: `std.posix` 与 `std.fs` 用哪个？

优先 `std.fs`（跨平台）；需要 POSIX 独有系统调用/常量才 `std.posix`（且要处理 unsafe 与 `errno`）。

### Q6: 序列化大端小端怎么调？

`std.binary` 提供 `BigEndianOrder`/`LittleEndianOrder`/`SwapEndianOrder` 三种端序接口；具体读写函数签名以库 API 为准（本文不臆造）。

### Q7: HTTP/WebSocket 在哪篇？

**属 `stdx.net`**，与本文的 `std.net` Socket（文章 26）不是一个包；需 `cjpm` 下载。本系列把 HTTP/WebSocket 拆到"stdx 网络专题"，本篇只覆盖 base SDK。

## 8. 总结

1. **`std.env`**：`getProcessId`、`getHomeDirectory(): Path`、`getCommandLine`、`getCurrentProcessInfo`/`getProcessInfo(pid)`、`getEnvirments`；教程别打易变值。
2. **`std.process`**：`execute(String): Int64` 拿退出码；`executeWithOutput` 拿输出行；`SubProcess` 走 stdin/stdout/stderr 全管道。
3. **`std.binary`**：以 `EndianOrder` 接口为入口，具体读写函数签名走库 API（本文不臆造）。
4. **`std.posix`**：常量 + 系统调用；跨平台优先 `std.fs`。
5. **HTTP/WebSocket 属 `stdx.net`**：另立专题；`std.net` 只有 Socket（文章 26 已覆盖）。

## 参考资料

1. 仓颉 1.0.5 LTS 程序入口（`main` 参数）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/package/entry.html
2. 仓颉 1.0.5 LTS Socket 编程（承接本篇"网络"上游）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/Net/net_socket.html
3. 仓颉 1.0.5 LTS 标准库总览（`std.env`/`std.process`/`std.binary`/`std.posix` 库 API 查法）：见 articles/30

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
