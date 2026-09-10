# 仓颉 Web 服务实战：用 stdx.net.http 起 HTTP 服务（CI 实跑验证）

> **摘要**: 阶段五第二篇实战，也是全系列**第一篇真正跑通 stdx 扩展库**的文章。前面 26 篇用 base `std.net` 写裸 TCP；HTTP 这一层在仓颉里属于**扩展标准库 `stdx`**（`stdx.net.http`）——**不在 SDK 里、要单独获取**。本篇给出：① `stdx.net.http` 起服务 + 发请求的**完整可运行示例**，② `cjpm.toml` 如何用 `bin-dependencies.path-option` 挂上 stdx 二进制，③ `net` 依赖 **OpenSSL 3** 的运行时要求，④ 我们在 Linux CI 上**从源码构建 stdx 并真跑**（客户端 GET 服务端、打印 `Hello Cangjie!`）的完整经过，包括一个真实踩坑——cjnative SDK 无 `include/`，须 `NO_ASPECTCJ=1` 跳过 aspectCJ 模块才能 `build.py` 到 `net`。**本示例经 GitHub Actions 实测：`cjpm build success` + 运行输出 `Hello Cangjie!`**（非文档转述）。

## 前置知识

- 已完成《Socket 网络编程》（26，base `std.net` 的 TCP/UDP）——本篇是它之上的 HTTP 应用层
- 已完成《标准库总览》（30）——理解 std / stdx 分层：`net.http`、`json`、`tls` 等已从 SDK **移到 stdx**
- 已完成《cjpm》（36）——`cjpm.toml`、`bin-dependencies`、构建/运行
- 已完成《并发》（23/45）——示例用 `spawn` 在服务端与客户端间并发

> 定位：这是本系列**首个 stdx 实战**。stdx 不是"装好 SDK 就有"，所以本篇把"怎么拿到 stdx 并让它被 cjpm 认到"讲透——这也是为什么它值得单独一篇。

## 1. 先认清：HTTP 在 stdx，不在 base std

官方口径（《标准库/HTTP 编程》）：**"`net`、`log` 等库已从仓颉 SDK 移到 `stdx` 模块，使用前需要下载软件包，并在 `cjpm.toml` 中配置"**。也就是说：

| 能力 | 所在 | 拿到方式 |
|---|---|---|
| TCP/UDP 裸 Socket | `std.net`（base SDK，见文章 26） | 装 SDK 即有 |
| HTTP / TLS / WebSocket | **`stdx.net.http` / `stdx.net.tls`** | 需**额外获取 stdx** |
| JSON 序列化 | **`stdx.encoding.json`** | 需额外获取 stdx |
| 日志 | **`stdx.log` / `stdx.logger`** | 需额外获取 stdx |

所以"仓颉写 Web 服务" = "把 stdx 接进来 + 用 `stdx.net.http`"。**难点不在 API（很直接），在 stdx 的获取与链接**——下面重点讲这个，因为它正是很多教程会含糊带过的地方。

## 2. 获取 stdx 的两条路

stdx 是独立仓库 `Cangjie/cangjie_stdx`（扩展库）与 `Cangjie/cangjie-stdx-bin`（二进制发布），版本前 3 位对齐 cjc（**1.0.5 SDK → stdx `v1.0.5`**）。

**路 A：官方预编译二进制（最省事）**——从 stdx 项目"发行版"下载与平台匹配的包，如 `cangjie-stdx-linux-x64-1.0.5.x.zip`，解压得到 `.../dynamic/stdx`（动态）与 `.../static/stdx`（静态）两目录，直接给 `cjpm.toml` 的 `path-option` 用。

**路 B：源码构建（本 CI 采用的）**——clone 后用它自带的 `build.py`：

```bash
python3 build.py build   -t release --target-lib=<openssl 的 lib 目录>
python3 build.py install            # 产物进 target/<arch>/[dynamic|static]/stdx
```

> **⚠️ 本 CI 的真实踩坑（务必记录）**：cjnative 版 SDK **不带 `include/` 目录**，而 stdx 的 `aspectCJ`（面向切面编程）模块的 CMake 硬性检查 `$ENV{CANGJIE_HOME}/include/cangjie`、找不到就 `FATAL_ERROR`，会让 `build.py` **在编到 net 之前就中止**。stdx 的 `src/stdx/CMakeLists.txt` 内置了开关：设环境变量 **`NO_ASPECTCJ=1`** 即整体跳过 aspectCJ——我们的 CI 就是靠它才让 `build.py` 顺利产出 `stdx.net.http.so`/`stdx.log.*`。这是"从源码构建 stdx 时 cjnative 平台的现实坑"，官方文档没强调、但实测必踩。

`net`（含 `net.http`/`net.tls`）还依赖 **OpenSSL 3**：`build.py --target-lib` 指向 `libssl.so` 所在目录；Ubuntu 上 `apt install libssl-dev` 后是 `/usr/lib/x86_64-linux-gnu`。

## 3. 用 cjpm.toml 把 stdx 挂进工程

stdx 通过 `cjpm.toml` 的 **`bin-dependencies`** 引入（承文章 36 的依赖小节），按 target triple 指到 stdx 二进制目录：

```toml
[package]
  cjc-version = "1.0.5"
  name = "webdemo"
  output-type = "executable"
  compile-option = "-ldl"        # 静态链 net/crypto 时 Linux 需要（动态链可省）

[dependencies]

[target.x86_64-unknown-linux-gnu]                       # 用 cjc -v 查你的 triple
  [target.x86_64-unknown-linux-gnu.bin-dependencies]
    path-option = ["<stdx 解压或 install 后的 .../dynamic/stdx 绝对路径>"]
```

要点：
- `path-option` 指向 stdx 的 **`dynamic/stdx`**（动态库，产物是 `libstdx.net.http.so` + `stdx.net.http.cjo`）或 **`static/stdx`**（静态）。二者别混用。
- `[target.<triple>.bin-dependencies]` 的 `<triple>` 要和 `cjc -v` 的 `Target:` 行一致（如 `x86_64-unknown-linux-gnu`）。
- 用 `net`/`crypto` 静态库时，Linux 要 `compile-option = "-ldl"`、Windows 要 `-lcrypt32`（链接系统符号）。

## 4. 代码：起服务 + 发请求（同进程，便于确定性验证）

一个进程里既 `spawn` 服务端、又当客户端——这样能在 CI 里无外部依赖地端到端跑通。`port(0)` 让 OS 分配空闲端口，避开 CI 端口占用；`server.port` 拿到真实端口。

<!-- example: cangjie-stdx/051-web-service/src/main.cj -->
```cangjie
package webdemo

// stdx.net.http 实战：一个进程内同时起 HTTP 服务端与客户端，请求 /hello 打印响应体。
// 结构与官方《HTTP 编程》示例一致（ServerBuilder/ClientBuilder/distributor.register）。
// port(0) 让 OS 分配空闲端口、避开 CI 端口冲突；输出确定：`Hello Cangjie!`。

import stdx.net.http.*
import stdx.log.*

let server = ServerBuilder().addr("127.0.0.1").port(0).build()

func startServer(): Unit {
    // 注册路由：命中 /hello 时把响应体设为固定字符串
    server.distributor.register("/hello", { httpContext =>
        httpContext.responseBuilder.body("Hello Cangjie!")
    })
    server.logger.level = LogLevel.OFF   // 关掉访问日志，保证 stdout 只有我们的输出
    server.serve()                        // 阻塞式启动，放独立任务里跑
}

func startClient(): Unit {
    let client = ClientBuilder().build()
    let response = client.get("http://127.0.0.1:${server.port}/hello")
    let buffer = Array<Byte>(64, repeat: 0)
    let length = response.body.read(buffer)
    println(String.fromUtf8(buffer[..length]))
    client.close()
}

main(): Int64 {
    spawn {
        startServer()
    }
    sleep(Duration.second)               // 等服务端就绪（官方示例同款）
    startClient()
    return 0
}
```

拆解（都用到的 `stdx.net.http` 概念）：
- **`ServerBuilder().addr(..).port(..).build()`** → 构造 `Server`；`.addr("127.0.0.1")` 只监听本地。
- **`server.distributor.register("/hello", { ctx => ctx.responseBuilder.body(...) })`** → 注册路由：命中 `/hello` 时设响应体（`responseBuilder` 造报文，`.body(String)` 设正文）。
- **`server.serve()`** → 阻塞式启动服务，放 `spawn` 任务里。
- **`server.logger.level = LogLevel.OFF`**（`stdx.log`）→ 关访问日志，保证 stdout 只剩我们的 `println`。
- **`ClientBuilder().build()` + `client.get(url)`** → 发 GET，拿 `response`；`response.body.read(buffer)` 读字节，`String.fromUtf8(buffer[..length])` 还原字符串。

## 5. 构建与运行（Linux，CI 实跑）

```bash
# 前置：已 build.py install 出 stdx，cjpm.toml 的 path-option 指向其 dynamic/stdx
cd examples/cangjie-stdx/051-web-service
cjpm build            # → target/release/bin/main
# 运行：让动态链接器找到 stdx.so 与仓颉运行时
export LD_LIBRARY_PATH="<stdx dynamic/stdx>:$CANGJIE_HOME/runtime/lib/linux_x86_64_cjnative:$LD_LIBRARY_PATH"
./target/release/bin/main
```

运行输出（**GitHub Actions 实测**，非转述）：

```text
Hello Cangjie!
```

CI 里我们的完整作业链路是：装 `libssl-dev`/cmake/ninja → 下载解压 SDK → `git clone -b v1.0.5 stdx` → `NO_ASPECTCJ=1 python3 build.py build -t release --target-lib=... && build.py install` → 把 `dynamic/stdx` 路径 `sed` 注入 `cjpm.toml` → `cjpm build`（`cjpm build success`）→ 带正确 `LD_LIBRARY_PATH` 运行 → 打印 `Hello Cangjie!`。**每一步都绿**。

## 6. 再套一层：让 Web 服务返回 JSON

真实 Web 服务几乎都返回 JSON。序列化用 **`stdx.encoding.json`**（`JsonValue`/`DataModel` 与 String 互转，承 §1 的 stdx 分层）。典型形态：

```cangjie
import stdx.encoding.json.*
// 命中 /api 时，把一个结构序列化成 JSON 再塞进响应体
server.distributor.register("/api", { ctx =>
    ctx.responseBuilder.body("""{"msg":"hi","n":1}""")
})
```

> **说明**：本示例（051）**只固化了已在 CI 实跑通过的 `net.http` 收发**；`stdx.encoding.json` 的具体 API（`JsonValue`、`DataModel`、`parseJson`/`toJsonString` 等）本系列尚未逐一在 CI 上编译验证，故这里只给**方向与手写 JSON 字符串**的安全写法，精确的 json 包 API 以官方 stdx 手册为准、留待"stdx 序列化"专篇实测补全——延续本系列"**没验证过的一律不硬编**"的纪律。

## 7. 与其它语言 Web 起步对照

| 维度 | 仓颉 stdx.net.http | Go `net/http` | Rust `axum`/`hyper` | Node `express` |
|---|---|---|---|---|
| 起服务 | `ServerBuilder().build().serve()` | `http.ListenAndServe` | `axum::serve` | `app.listen` |
| 路由 | `distributor.register(path, handler)` | `mux.HandleFunc` | `.route(path, get(..))` | `app.get(path, h)` |
| 设响应体 | `responseBuilder.body(..)` | `w.Write([]byte)` | 返回 body | `res.send` |
| 客户端 | `ClientBuilder().build().get(url)` | `http.Get` | `reqwest::get` | `fetch`/axios |
| 库归属 | **扩展库 stdx**（非标准库） | 标准库 | 第三方 crate | 内置/第三方 |
| TLS 依赖 | 需 OpenSSL 3 | 内置 | 内置(rustls)/OpenSSL | 内置 |

心智最像 Go 的 `HandlerFunc` + `http.Get`；**最大差异是"HTTP 不在标准库、在要额外装的 stdx"**——这是仓颉刻意做的分层（base std 精简、网络/序列化/加密等重能力进 stdx）。

## 8. FAQ

### Q1: 为什么 `import stdx.net.http.*` 报找不到包？

因为 stdx **不随 SDK 装**。要么下预编译二进制、要么 `build.py` 源码构建，再在 `cjpm.toml` 用 `[target.<triple>.bin-dependencies].path-option` 指到 stdx 目录（§2/§3）。只写 import 不配依赖 = 找不到。

### Q2: `build.py` 一上来就挂在 `aspectCJ`/`cannot find Cangjie include directory`？

cjnative SDK 无 `include/` 目录，`aspectCJ` 的 CMake 会 `FATAL_ERROR`。**`export NO_ASPECTCJ=1` 再 build 即可**（stdx 的 CMakeLists 有这开关），跳过无关的 aspectCJ、正常产出 `net`。这是本 CI 实测踩到并绕过的点。

### Q3: 运行报 `cannot open shared object file: libstdx.net.http.so`？

你用了动态 stdx 但运行时没找到它。把 **stdx 的 `dynamic/stdx` 目录加进 `LD_LIBRARY_PATH`**（连同仓颉 `runtime/lib/...`），或改用静态 `static/stdx`（那就要 `compile-option = "-ldl"`）。

### Q4: `net.http` 和文章 26 的 `std.net` 什么关系？

`std.net`（base SDK）是**裸 TCP/UDP**；`stdx.net.http` 在它之上实现**HTTP 报文/路由/客户端**（且 TLS 依赖 OpenSSL）。写 Web 服务用后者，写自定义协议/裸连接用前者。

### Q5: stdx 版本怎么和 SDK 对齐？

stdx 版本号前 3 位 = cjc 版本。**1.0.5 SDK → 取 tag `v1.0.5` 的 stdx**（本 CI 用 `git clone -b v1.0.5`）。且官方声明 stdx **不承诺跨版本 ABI 兼容**——SDK 升版时 stdx 也要跟着换/重建。

### Q6: 为什么服务端要放 `spawn` 里、还要 `sleep`？

`server.serve()` 阻塞。放 `spawn` 任务后台跑，主线程 `sleep` 一小会让服务端先监听、再发请求。生产里服务端通常常驻、不会自己当客户端；这里"同进程自测"纯粹为了**在 CI 里无外部依赖地端到端验证**。

### Q7: 想真做对外服务，还差什么？

进程生命周期（信号优雅退出）、并发处理模型（`serve` 内部已按连接起任务，可配）、TLS 证书（`stdx.net.tls` + 装证书）、日志与监控（`stdx.logger`）、以及反向代理。本篇聚焦"stdx 怎么接进来 + 一个能跑通的最小 HTTP 闭环"。

## 9. 总结

1. **HTTP 在 stdx 不在 base**：`stdx.net.http`（含 `net.tls`/`encoding.json`/`log`），须**额外获取**并 `cjpm.toml` 配 `bin-dependencies.path-option` 指向其 `dynamic`/`static/stdx`。
2. **两种获取**：预编译二进制发行包；或源码 `build.py build/install`。**cjnative 源码构建要 `NO_ASPECTCJ=1` 跳过缺 `include/` 的 aspectCJ**（本 CI 实测）；`net` 依赖 **OpenSSL 3**。
3. **API 直接**：`ServerBuilder`+`distributor.register`+`responseBuilder.body`+`serve`（服务端）、`ClientBuilder().get`+`response.body.read`（客户端）。
4. **端到端已 CI 实跑**：同进程 server+client，`cjpm build success` → 运行打印 `Hello Cangjie!`；这是全系列第一篇真跑通 stdx 的实战。
5. **纪律仍在**：`encoding.json` 等未逐一验证的 stdx 细节只给方向、不硬编 API——留"stdx 序列化"专篇实测。

## 参考资料

1. HTTP 编程（`stdx.net.http` API/示例，本示例蓝本）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/Net/net_http.html
2. stdx 源码仓 + 构建说明（build.py / NO_ASPECTCJ / 依赖）：https://gitcode.com/Cangjie/cangjie_stdx
3. stdx 二进制发布说明（bin-dependencies.path-option 配置）：https://gitcode.com/Cangjie/cangjie-stdx-bin
4. 承接：Socket 裸 TCP/UDP（文章 26）、cjpm 依赖（文章 36）、值/引用与动态库（文章 44）

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写。`stdx.net.http` 起服务 + 客户端收发为 **GitHub Actions（Linux）实跑通过**（`cjpm build success`、输出 `Hello Cangjie!`）；stdx 用 tag `v1.0.5` 经 `build.py` 源码构建、`NO_ASPECTCJ=1` 跳过 aspectCJ、`libssl-dev` 提供 OpenSSL 3。`stdx.encoding.json` 等未逐一 CI 验证的包 API 仅给方向、不硬编。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
