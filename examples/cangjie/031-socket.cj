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
