// 基础 I/O 示例
// 演示：字符串流（StringWriter/StringReader）、缓冲流（BufferedOutputStream/BufferedInputStream）、
// 文件读写（File.create / File.readFrom / exists / remove）、以及用 try-with-resources 自动关闭文件。
//
// 输出刻意保持单行、无内嵌换行，便于逐行核对；文件写到当前目录的临时文件并在结束时删除。

import std.io.{ByteBuffer, BufferedInputStream, BufferedOutputStream, StringReader, StringWriter, readToEnd}
import std.fs.{File, exists, remove}

main(): Int64 {
    // ---- 1) 字符串输出流：StringWriter 写入，readToEnd 取出全部字节 ----
    let wbuf = ByteBuffer()
    let sw = StringWriter(wbuf)
    sw.write("Hello ")
    sw.write("I/O")
    sw.flush()
    let sOut = String.fromUtf8(readToEnd(wbuf))
    println("sw = ${sOut}")                     // sw = Hello I/O

    // ---- 2) 字符串输入流：StringReader 按行读取 ----
    let rbuf = ByteBuffer()
    rbuf.write("line1\nline2".toArray())
    let sr = StringReader(rbuf)
    let l1 = sr.readln()                        // "line1"（不含换行）
    let l2 = sr.readln()                        // "line2"
    println("sr = ${l1 ?? "?"} / ${l2 ?? "?"}")  // sr = line1 / line2

    // ---- 3) 缓冲输出流 + 缓冲输入流：绕 ByteBuffer 做一次往返 ----
    let bbuf = ByteBuffer()
    let bos = BufferedOutputStream(bbuf)
    bos.write("buffered-io".toArray())
    bos.flush()                                 // 缓冲区数据落到内部流
    let bis = BufferedInputStream(bbuf)
    let out = Array<Byte>(32, repeat: 0)
    let n = bis.read(out)
    println("buffered = ${String.fromUtf8(out[..n])}")  // buffered = buffered-io

    // ---- 4) 文件读写：File.create 写、File.readFrom 读、exists/remove ----
    let path = "./cj_io_tmp.txt"
    if (exists(path)) {
        remove(path)
    }
    try (f = File.create(path)) {               // File 实现 Resource：离开作用域自动 close
        f.write("hello cangjie".toArray())      // File 也是 IOStream
    }
    let content = File.readFrom(path)           // 一次性读出全部字节
    println("file = ${String.fromUtf8(content)}")          // file = hello cangjie
    println("exists before remove = ${exists(path)}")      // true

    remove(path)
    println("exists after remove = ${exists(path)}")       // false

    return 0
}
