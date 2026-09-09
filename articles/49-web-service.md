# 仓颉 Web 服务实战（占位·CI 验证中）

> 占位文：先接入 CI 验证 stdx.net.http 能否构建运行，通过后再补全正文。

<!-- example: cangjie-stdx/051-web-service/src/main.cj -->
```cangjie
package webdemo

// stdx.net.http 实战：一个进程内同时起 HTTP 服务端与客户端，请求 /hello 打印响应体。
// 结构与官方《HTTP 编程》示例一致（ServerBuilder/ClientBuilder/distributor.register）。
// port(0) 让 OS 分配空闲端口、避开 CI 端口冲突；输出确定：`Hello Cangjie!`。

import stdx.net.http.*
import std.time.*

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
