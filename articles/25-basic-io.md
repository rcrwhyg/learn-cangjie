# 仓颉基础 I/O

> **摘要**: 仓颉把所有对外交互（标准输入输出、文件、网络、字符串、加密、压缩）统一抽象成**流（Stream）**，最小单位是 `Byte`，用 `InputStream`/`OutputStream` 两个接口表达读与写。流又分**节点流**（直接对接外部资源，如 `ConsoleReader/ConsoleWriter`、`File`）和**处理流**（包装别的流以增强能力，如 `BufferedInputStream/BufferedOutputStream`、`StringReader/StringWriter`）。本文依据仓颉 1.0.5 LTS 官方 Basic I/O 三页，讲清流的抽象、标准流、文件读写与 `OpenMode`、缓冲流原理与 `flush`、字符串流按行读写，以及"`File` 实现 `Resource` → 用 `try-with-resources` 自动关闭"这条资源纪律。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已完成《数组、元组与区间》（`Array<Byte>`、切片）、《资源管理》（`Resource`、try-with-resources）
- 已了解 `String` 与字节（UTF-8）的关系

## 1. 一切皆流

仓颉把与外部载体的交互都叫 **I/O**（输入 Input / 输出 Output），并统一抽象为**数据流**：一串连续的字节数据，像管道，一端进、一端出。

- **输入流 `InputStream`**：把数据从外存读进内存。
- **输出流 `OutputStream`**：把数据从内存写到外存。

标准输入输出、文件、网络、字符串流、加密流、压缩流……都用同一套 `Stream` 接口表达。`Stream` 被定义成 `interface`，因而可以用**装饰器模式**层层组合（处理流包住节点流），扩展性很强。

两个核心接口：

```cangjie
interface InputStream {
    func read(buffer: Array<Byte>): Int64      // 把可读数据写进 buffer，返回本次读到的字节数
}

interface OutputStream {
    func write(buffer: Array<Byte>): Unit      // 把 buffer 数据写入流
    func flush(): Unit { /* 默认空实现 */ }     // 统一 flush 语义
}
```

`flush` 为什么存在：有些输出流带**缓冲**，`write` 不立即落盘，要攒够或主动 `flush` 才真写——`flush` 的默认空实现抹平了这一差异。

## 2. 节点流 vs 处理流

| 类别 | 定义 | 常见类型 |
|---|---|---|
| **节点流** | 直接对接外部资源（文件、网络、控制台） | `ConsoleReader`/`ConsoleWriter`、`File`、`Socket` |
| **处理流** | 代理别的流做增强 | `BufferedInputStream`/`BufferedOutputStream`、`StringReader`/`StringWriter`、`ChainedInputStream` |

处理流的构造通常是"把一个已有的流传进构造函数"，从而给它加缓冲、加字符串语义等。

## 3. 标准流（控制台）

标准输入/输出/错误，通过 `std.env` 的三个全局函数获取，返回 `ConsoleReader`/`ConsoleWriter`（对底层字节流的易用封装，支持基于 `String` 的读写、多种重载）：

```cangjie
import std.env.getStdIn
main() {
    let txt = getStdIn().readln()    // 从标准输入读一行；返回 ?String
    println(txt ?? "")
}
```

```cangjie
import std.env.getStdOut
main() {
    let w = getStdOut()
    for (_ in 0..1000) { w.writeln("hello, world!") }
    w.flush()                          // 写完必须 flush，内容才完整落到标准流
}
```

要点：

- `ConsoleReader`/`ConsoleWriter` 是**并发安全**的，可在任意线程读写——比裸 `print` 更适合多线程日志。
- `ConsoleWriter` 有缓冲，**用完记得 `flush()`**。
- 标准错误流也是输出流，用 `getStdErr()` 获取（同样是 `ConsoleWriter`）。

> **⚠️ 注意**：在 CI/无交互环境下别真的 `getStdIn().readln()` 阻塞等键盘。示例里的文件/内存流才是可自动化的部分。

## 4. 文件流 `File`

`std.fs` 提供文件系统能力，屏蔽跨平台差异。`File` 类型**同时**是常规文件操作入口和数据流：

```cangjie
public class File <: Resource & IOStream & Seekable { ... }
```

因为它实现 `Resource`，所以能用 `try-with-resources` 自动关闭——**打开文件占系统资源，用完必须关**。

### 4.1 常规操作（静态函数）

```cangjie
import std.fs.{exists, copy, rename, remove, File}

let bytes = File.readFrom("./in.txt")   // 一次性读出全部字节
File.writeTo("./out.txt", bytes)         // 一次性写入
copy("./in.txt", to: "./dup.txt", overwrite: false)
rename("./dup.txt", to: "./mv.txt", overwrite: false)
remove("./mv.txt")
```

数据量不大时，`File.readFrom` / `File.writeTo` 是最省事的读写方式，不用手动管流。

### 4.2 作为流读写 + 打开模式

两种构造：

```cangjie
let f1 = File.create("./a.txt")   // 创建（只写！对它读会抛运行时异常）
f1.write("hi".toArray())
f1.close()

let f2 = File("./a.txt", Read)    // 按 OpenMode 打开
```

`OpenMode` 是 enum，提供 `Read`、`Write`、`Append`、`ReadWrite` 等模式。用 `try` 自动关闭更稳：

```cangjie
import std.io.readToEnd
try (f = File("./a.txt", Read)) {
    let data = readToEnd(f)        // 读尽
}                                  // 离开作用域自动 close
```

> **✅ 推荐**：优先 `try (f = File(...)) { ... }`；`File.create` 得到的是**只写**文件，别去读它。

## 5. 缓冲流

磁盘 I/O 远慢于内存。高频小数据读写用裸流会每次都触发磁盘操作；`BufferedInputStream`/`BufferedOutputStream` 用内部缓冲数组，攒够缓冲区才一次性读写磁盘，显著减少 I/O 次数。构造时传入被包装的流，可选 `capacity` 指定缓冲区大小。

**写**侧关键：没写满缓冲区不会真正落到内部流，**写完必须 `flush()`**：

```cangjie
import std.io.{ByteBuffer, BufferedOutputStream, readToEnd}
let sink = ByteBuffer()
let bos = BufferedOutputStream(sink)
bos.write("01234".toArray())
bos.flush()                         // 把缓冲区数据真正写入 sink
// 此时 sink 里可读到的就是 "01234"
```

**读**侧：`BufferedInputStream` 一次读满缓冲区，再多次小读命中内存。

## 6. 字符串流

字节流处理二进制很自然，处理文本就麻烦（要手动 `Byte`↔`String` 转换）。`StringReader`/`StringWriter` 补上按 `String` 读写、按行读写的易用能力：

```cangjie
import std.io.{ByteBuffer, StringWriter, StringReader, readToEnd}

let wb = ByteBuffer()
StringWriter(wb).write("number")     // 直接写字符串
// ...

let rb = ByteBuffer()
rb.write("012\n346789".toArray())
let sr = StringReader(rb)
let line = sr.readln()               // 读到换行前的一段："012"（不含换行）
```

- `StringWriter`：`write(str)` 写字符串、`writeln(...)` 写并转行、数字也有重载；写完同样要 `flush`。
- `StringReader`：`readln()` 按行读，返回 `?String`（读不到时 `None`）。

## 7. 完整可运行示例

下例把字符串流、缓冲流、文件读写串起来，并演示 `File` 的 `try-with-resources` 自动关闭与 `exists/remove` 生命周期。输出刻意做成单行、无内嵌换行，便于逐行核对；临时文件在结束时删除。

<!-- example: cangjie/030-basic-io.cj -->
```cangjie
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
```

预期输出：

```text
sw = Hello I/O
sr = line1 / line2
buffered = buffered-io
file = hello cangjie
exists before remove = true
exists after remove = false
```

## 8. 语言对比

| 概念 | 仓颉 | Java | Go | Rust |
|---|---|---|---|---|
| 顶层抽象 | `InputStream`/`OutputStream` 接口 | `InputStream`/`OutputStream` | `io.Reader`/`io.Writer` | `Read`/`Write` trait |
| 字节单位 | `Byte` | `byte` | `byte` | `u8` |
| 装饰器/包装 | `BufferedInputStream(in)` 等 | 同名装饰器 | `bufio.NewReader(r)` | `BufReader::new(r)` |
| 文本读写 | `StringReader/StringWriter` | `Reader/Writer` 字符流 | `bufio.Scanner` | `BufRead::read_line` |
| 文件关闭 | `Resource` + try-with-resources | `Closeable` + try-with-resources | `defer f.Close()` | Drop（自动） |
| 一次性读写 | `File.readFrom/writeTo` | `Files.readAllBytes/write` | `os.ReadFile/WriteFile` | `fs::read/write` |

**从 Java 迁移**：概念几乎逐一对应（连 `BufferedInputStream`、try-with-resources、`flush` 都同名同意），上手最快。
**从 Go 迁移**：Go 的 `defer f.Close()` 在仓颉里换成 `try (f = File(..)) {}`；Go 的 `bufio.Scanner` 对应 `StringReader.readln()`。
**从 Rust 迁移**：Rust 靠 Drop 自动关文件；仓颉**不会**替你自动关，必须 `close` 或用 `try-with-resources`——这是最需要注意的差别。

## 9. 常见问题（FAQ）

### Q1: `Stream` 和 `String` 什么时候各用哪个？

处理二进制/大文件用字节流（`InputStream`/`OutputStream`/`File`）；以文本为主、想按字符串/按行处理，用 `StringReader`/`StringWriter` 包一层。

### Q2: 为什么我写了数据却读不到？

十有八九是**没 `flush`**。`BufferedOutputStream`、`StringWriter`、`ConsoleWriter` 都有缓冲，写完要 `flush` 才真正落到内部流/磁盘/屏幕。

### Q3: `File.create` 出来的文件能读吗？

不能。`create` 得到的是**只写**文件，读它会抛运行时异常。要读，用 `File(path, Read)` 打开，或 `File.readFrom(path)`。

### Q4: 文件不 close 会怎样？

`File` 持有系统资源（句柄）。不关就可能泄漏、缓冲区数据也可能没落盘。所以**优先 `try (f = File(..)) {}` 自动关**，或记得 `f.close()`。

### Q5: `readln()` 返回的是含换行的整行吗？

不含换行；返回 `?String`，读不到内容时是 `None`（所以常配 `??`）。

### Q6: 处理流是怎么组合的？

把一个流对象传进处理流的构造函数，例如 `BufferedInputStream(someInputStream)`、`StringWriter(someOutputStream)`，形成装饰器链。

## 10. 总结

1. 仓颉把一切对外交互抽象成**流**，最小单位 `Byte`，读写分别由 `InputStream.read` / `OutputStream.write`(+`flush`) 表达；`Stream` 是 `interface`，可装饰器式组合。
2. **节点流**对接外部资源（`ConsoleReader/ConsoleWriter`、`File`、`Socket`），**处理流**包装别的流（缓冲流、字符串流）。
3. 标准流经 `std.env` 的 `getStdIn/getStdOut/getStdErr` 获取，`ConsoleWriter` **有缓冲要 `flush`**，且**并发安全**。
4. `File` 既是常规操作入口（`exists/copy/rename/remove/readFrom/writeTo`），又是 `Resource & IOStream & Seekable`；`create` 只写，按 `OpenMode`(Read/Write/Append/ReadWrite) 打开可读写，**用 try-with-resources 及时关**。
5. **缓冲流**减少磁盘 I/O；**字符串流** `StringReader/StringWriter` 让文本读写更友好。两者写完都要 `flush`。

## 参考资料

1. 仓颉 1.0.5 LTS I/O 流概述：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/Basic_IO/basic_IO_overview.html
2. 仓颉 1.0.5 LTS I/O 节点流：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/Basic_IO/basic_IO_source_stream.html
3. 仓颉 1.0.5 LTS I/O 处理流：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/Basic_IO/basic_IO_process_stream.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
