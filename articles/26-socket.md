# 仓颉 Socket 网络编程（TCP 与 UDP）

> **摘要**: 仓颉用 `std.net` 提供传输层网络编程，把可靠/不可靠传输分别抽象为 `StreamSocket`（典型 TCP）与 `DatagramSocket`（典型 UDP），具体类型有 `TcpSocket`/`TcpServerSocket`/`UdpSocket`。要点：服务端**先 bind 再 accept**、客户端**指定远端再 connect**；UDP 无需区分端、`sendTo`/`receiveFrom` 收发数据报；仓颉网络是**阻塞式**，但阻塞的是**仓颉线程**而非系统线程。本文依据仓颉 1.0.5 LTS 官方 `Net` 概述与 Socket 页，用一个**本机回环、输出确定**的示例跑通 TCP 回显与 UDP 收发。HTTP 与 WebSocket 属 `stdx.net` 包（需另行安装），**留待后续专题**。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已完成《基础 I/O》（流、`read`/`write`/`flush`、`Resource`/try-with-resources）与《线程与协程使用》（`spawn`/`Future`/`sleep`）
- 了解 TCP/UDP、IP 地址与端口的基本概念

> 范围说明：官方 `Net` 章含 Socket、HTTP、WebSocket 三块。HTTP/WebSocket 依赖 `stdx.net`（官方明确"net、log 等库已从 SDK 移到 stdx，需下载包并在 `cjpm.toml` 配置"），**本环境与本篇不做编译验证**，故本篇只覆盖 **`std.net` 传输层 Socket**；HTTP/WebSocket 将单列一篇。

## 1. 传输层抽象：StreamSocket 与 DatagramSocket

仓颉把传输层协议按可靠性抽象成两类：

| 抽象 | 含义 | 常见协议 | 具体类型 |
|---|---|---|---|
| `StreamSocket` | 可靠、面向字节流传输 | TCP | `TcpSocket`、`TcpServerSocket` |
| `DatagramSocket` | 不可靠、面向数据报传输 | UDP | `UdpSocket` |

也支持 Unix Domain 协议（可靠/不可靠两种方式）。

> **💡 关键特性：阻塞式，但只阻塞仓颉线程。** 仓颉的网络 I/O 是阻塞式的——`accept`、`read`、`receiveFrom` 会挂起当前**仓颉线程**。但因为 M:N 模型，被阻塞的仓颉线程会把**系统线程让渡**出去，所以不会真正卡死一条 OS 线程。你仍应把阻塞调用放在线程/任务里跑（本篇示例就这么做）。

## 2. TCP：面向连接的可靠传输

TCP 的编程模型（官方六步）：

1. 创建**服务端套接字**，指定本端绑定地址（`TcpServerSocket(bindAt: port)`）。
2. `bind()` 执行绑定。
3. `accept()` 阻塞等待，直到拿到一个客户端连接（返回**新的**套接字）。
4. 客户端创建 `TcpSocket(host, port)`，指定远端地址。
5. `connect()` 连接远端。
6. 连接成功后，服务端用 `accept()` 返回的新套接字读写，客户端用其自身读写收发报文。

- **客户端**：必须指定远端地址，可选手动绑定本端；`connect()` 成功后才能收发。
- **服务端**：必须绑定本端地址；绑定后才能收发。

```cangjie
import std.net.*

func runTcpServer(port: UInt16) {
    try (serverSocket = TcpServerSocket(bindAt: port)) {
        serverSocket.bind()
        try (client = serverSocket.accept()) {
            let buf = Array<Byte>(10, repeat: 0)
            let count = client.read(buf)
            println("Server read ${count} bytes: ${buf}")
        }
    }
}
```

> **⚠️ 注意：TCP 是字节流、不保留消息边界。** 一次 `read` 可能拿到**部分**数据、也可能一次读到多条。要读"恰好 N 字节"，得像本篇示例那样循环补齐（`readExactly`）。想要"一条一条"的语义请用 UDP 或自己加长度前缀。

`port` 传 `0` 表示让系统分配一个临时的空闲端口，随后用 `localAddress` 取回真实端口（本机测试/CI 里尤其好用，避免端口冲突）。

## 3. UDP：无连接的数据报传输

UDP 不区分客户端/服务端，双方都是 `UdpSocket`：

1. 创建套接字并指定本端绑定地址（`UdpSocket(bindAt: port)`）。
2. `bind()`。
3. `sendTo(远端地址, data)` 指定远端发送。
4. `receiveFrom(buf)` 接收，返回 `(远端地址, 字节数)`——不连接的话可收来自不同远端的数据报。

```cangjie
import std.net.*

func runUdpServer(port: UInt16) {
    try (serverSocket = UdpSocket(bindAt: port)) {
        serverSocket.bind()
        let buf = Array<Byte>(3, repeat: 0)
        let (clientAddr, count) = serverSocket.receiveFrom(buf)
        let sender = (clientAddr as IPSocketAddress)?.address.toString() ?? ""
        println("Server receive ${count} bytes from ${sender}")
    }
}
```

> **💡 提示：数据报有边界。** 一个 `sendTo` 发多少，对端一次 `receiveFrom` 一般就收到完整那一条（不像 TCP 会粘/拆包）。UDP 也可 `connect` 到固定远端，之后 `send` 免带地址、只收该远端报文。

## 4. 地址与套接字类型

- `IPSocketAddress("127.0.0.1", port)`：IP 地址 + 端口，是最常用的地址类型。
- 套接字的 `localAddress` / 远端地址是通用的地址对象，用 `as IPSocketAddress` 转型后读 `.address`、`.port`。
- `UInt16` 表示端口号；`bindAt: 0` = 让系统分配临时端口。

## 5. 完整可运行示例（本机回环，输出确定）

TCP 与 UDP 都绑 `0`（临时端口）、都走 `127.0.0.1`，不依赖外部网络、不硬编码端口，CI 友好。TCP 用 `readExactly` 补齐分片、TCP/UDP 两阶段**串行**执行，保证三行输出顺序与内容都确定。

<!-- example: cangjie/031-socket.cj -->
```cangjie
// Socket 网络编程示例（传输层：TCP + UDP，基于 std.net）
// 演示：TCP 服务端/客户端（bindAt:0 取临时端口 -> connect -> 双向收发）、
// UDP 收发（bindAt:0 + sendTo/receiveFrom），全程走本机回环 127.0.0.1，
// 用 readExactly 把 TCP 可能的分包读补齐，保证输出逐字节确定。
//
// 说明：HTTP / WebSocket 属 stdx.net 包（需另装），本篇不覆盖，留待后续专题。

import std.net.*
import std.io.IOStream

// 阻塞式读满 want 个字节（应对 TCP 分片），返回正好 want 个 Byte
func readExactly(stream: IOStream, want: Int64): Array<Byte> {
    let out = Array<Byte>(want, repeat: 0)
    var off: Int64 = 0
    while (off < want) {
        let tmp = Array<Byte>(want - off, repeat: 0)
        let r = stream.read(tmp)
        if (r <= 0) {
            break
        }
        for (k in 0..r) {
            out[off + k] = tmp[k]
        }
        off += r
    }
    out
}

// ---- TCP：服务端 accept 后回显客户端发来的 3 字节 ----
var tcpPort: UInt16 = 0

func tcpServer() {
    try (ss = TcpServerSocket(bindAt: 0)) {
        ss.bind()
        tcpPort = (ss.localAddress as IPSocketAddress)?.port ?? 0
        try (c = ss.accept()) {
            let got = readExactly(c, 3)
            println("tcp server recv: ${got}")   // tcp server recv: [1, 2, 3]
            c.write(got)                          // 原样回显
        }
    }
}

// ---- UDP：服务端收一个数据报 ----
var udpPort: UInt16 = 0

func udpServer() {
    try (s = UdpSocket(bindAt: 0)) {
        s.bind()
        udpPort = (s.localAddress as IPSocketAddress)?.port ?? 0
        let buf = Array<Byte>(3, repeat: 0)
        let (addr, n) = s.receiveFrom(buf)
        let ip = (addr as IPSocketAddress)?.address.toString() ?? "?"
        // 数据报有边界，一次 receiveFrom 即拿到完整 3 字节
        println("udp server recv ${n} from ${ip}: ${buf[..n]}")   // udp server recv 3 from 127.0.0.1: [4, 5, 6]
    }
}

main(): Int64 {
    // 两个阶段串行执行，保证三行输出顺序确定：
    //   tcp server recv -> tcp client echo -> udp server recv
    // （服务端打印各自早于其客户端打印，且 TCP 阶段整体先于 UDP 阶段）

    // ---- TCP 阶段 ----
    let ft = spawn { tcpServer() }
    var guardT = 0
    while (tcpPort == 0 && guardT < 2000) {   // 等端口就绪
        sleep(Duration.millisecond)
        guardT += 1
    }
    try (tc = TcpSocket("127.0.0.1", tcpPort)) {
        tc.connect()
        tc.write([1, 2, 3])
        let echoed = readExactly(tc, 3)
        println("tcp client echo: ${echoed}")     // tcp client echo: [1, 2, 3]
    }
    ft.get()

    // ---- UDP 阶段 ----
    let fu = spawn { udpServer() }
    var guardU = 0
    while (udpPort == 0 && guardU < 2000) {
        sleep(Duration.millisecond)
        guardU += 1
    }
    try (uc = UdpSocket(bindAt: 0)) {
        uc.bind()
        uc.sendTo(IPSocketAddress("127.0.0.1", udpPort), [4, 5, 6])
    }
    fu.get()

    return 0
}
```

预期输出：

```text
tcp server recv: [1, 2, 3]
tcp client echo: [1, 2, 3]
udp server recv 3 from 127.0.0.1: [4, 5, 6]
```

> 之所以能确定：① 端口用 `bindAt: 0` 交给系统分配，避免与 CI 环境其它进程端口冲突；② 全走 `127.0.0.1` 回环，不依赖外网；③ TCP 两端都用 `readExactly` 读满 3 字节，规避粘/拆包；④ TCP、UDP 两阶段串行 + 各自 `Future.get()`，锁定打印顺序。

## 6. 语言对比

| 维度 | 仓颉 | Go | Java | Rust |
|---|---|---|---|---|
| TCP 服务端 | `TcpServerSocket(bindAt:port)`+`bind`+`accept` | `net.Listen`+`Accept` | `ServerSocket.accept` | `TcpListener` |
| TCP 客户端 | `TcpSocket(host,port)`+`connect` | `net.Dial` | `Socket(host,port)` | `TcpStream::connect` |
| UDP | `UdpSocket(bindAt)`+`sendTo`/`receiveFrom` | `net.ListenUDP`/`WriteToUDP` | `DatagramSocket` | `UdpSocket` |
| 收发单位 | 字节流(read/write) / 数据报 | `[]byte` | 流 / `byte[]` 数据报 | `Read`/`Write` |
| 阻塞语义 | 阻塞仓颉线程（让渡系统线程） | 阻塞 goroutine | 阻塞平台线程 | 阻塞 OS 线程（异步需 tokio） |
| 自动关 | `Resource` → try-with-resources | `defer conn.Close()` | try-with-resources / `close` | Drop |

**从 Go 迁移**：`accept` 返回新连接、读写用 `read/write`，与 Go 的 `Conn.Read/Write` 接近；Go 的 `defer Close()` 在仓颉换成 `try (s = ...) {}`。
**从 Java 迁移**：`TcpServerSocket`≈`ServerSocket`、`accept` 语义一致；`bindAt:0` 取临时端口对应 Java 传端口 0 再 `getLocalPort()`。

## 7. 常见问题（FAQ）

### Q1: `accept()` 会一直占着一个系统线程吗？

不会。它阻塞的是**仓颉线程**，系统线程被让渡去跑别的仓颉线程。但建议把服务端 `accept`/`read` 放 `spawn` 里，别让主流程干等。

### Q2: 为什么我 `read` 只读到一半数据？

TCP 是字节流、不保留消息边界，一次 `read` 可能只返回部分。要读定长就循环补齐（见 `readExactly`），要分条语义就加长度前缀或改用 UDP。

### Q3: 测试/CI 里端口总撞车怎么办？

绑定时传 `bindAt: 0`，让系统分配临时端口，再用 `localAddress as IPSocketAddress)?.port` 读回真实端口给对端连。

### Q4: UDP 会像 TCP 那样粘包吗？

不会——数据报有边界，`sendTo` 一条通常对端 `receiveFrom` 一次收全。但 UDP **不保证送达、不保证顺序**，这是"不可靠"的含义。

### Q5: 本篇怎么没有 HTTP / WebSocket？

官方把它们放在 `stdx.net`（已从 SDK 拆出，需 `cjpm` 下载并在 `cjpm.toml` 配置）。本环境未安装该包，为遵守"示例必须编译运行验证"的规矩，本篇只做 `std.net` 传输层，HTTP/WebSocket 另起一篇。

### Q6: 用完套接字要关吗？

要。套接字是系统资源，`File`/Socket 都实现 `Resource`，优先 `try (s = ...) {}` 自动关。

## 8. 总结

1. `std.net` 把传输层抽象为 **`StreamSocket`(TCP)** 与 **`DatagramSocket`(UDP)**，具体 `TcpSocket`/`TcpServerSocket`/`UdpSocket`；支持 Unix Domain。
2. TCP：服务端 `bindAt`+`bind`+`accept`（返回新连接），客户端 `TcpSocket(host,port)`+`connect`；**字节流不保边界**，定长读要补齐。
3. UDP：两端都是 `UdpSocket`，`bind`+`sendTo`/`receiveFrom`；**数据报有边界但不保证可靠**。
4. `bindAt: 0` 让系统分配临时端口，配 `localAddress` 读回——本机/CI 首选；地址用 `IPSocketAddress`。
5. 网络 I/O **阻塞的是仓颉线程**（M:N 下让渡系统线程）；套接字实现 `Resource`，用 try-with-resources 关闭。
6. HTTP/WebSocket 属 `stdx.net`，另起专题。

## 参考资料

1. 仓颉 1.0.5 LTS 网络编程概述：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/Net/net_overview.html
2. 仓颉 1.0.5 LTS Socket 编程：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/Net/net_socket.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
