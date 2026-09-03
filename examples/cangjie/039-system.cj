// 标准库系统能力示例（1.0.5 base SDK：std.env + std.process）
// 演示：读当前进程信息（getProcessId / getHomeDirectory）、用 std.process.execute 跑一条
// 外部命令并拿回退出码。全部本地可 staticlib 编译；输出确定（echo 的退出码恒为 0）。
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
    let code = execute("echo cangjie")
    println("process: execute(echo) exit=${code}")           // process: execute(echo) exit=0

    return 0
}
