package jsondemo

// stdx.encoding.json 实战（配合文章 49 的 JSON 小节）。
// 只用官方文档确证的 API：JsonValue.fromStr / toString / JsonInt / JsonArray.get/size。
// 刻意用"数组+标量"（顺序确定），不依赖 object 的键序（HashMap 顺序不定）。
// 输出确定，Linux CI 实跑核对。

import stdx.encoding.json.*

main(): Int64 {
    // 1) 解析 JSON 数组字符串 → JsonValue → 再序列化回紧凑串（往返，顺序确定）
    let src = ##"[1,2,3,true,\"cj"]"##
    let jv = JsonValue.fromStr(src)
    println("roundtrip=${jv.toString()}")

    // 2) 构造：把 Int64 包成 JsonValue 再转串
    println("made=${JsonInt(7).toString()}")

    // 3) 按类型取用：as 下转到 JsonArray（返回 Option），拿 size
    let size = match (jv as JsonArray) {
        case Some(a) => a.size()
        case None => 0
    }
    println("size=${size}")
    return 0
}
