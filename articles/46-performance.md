# 性能分析与优化：先测量、少分配、看 GC

> **摘要**: 承文章 35（`cjc` 优化参数）与 40（`cjprof` 工具）——**那两篇讲"有哪些开关、怎么测"，本篇讲"拿到数据后往哪优化"**。仓颉程序性能三大成本来源：① 算法/数据结构，② **堆分配与 GC 压力**（本篇重点，给 `Array` 预分配、`VArray` 零堆、`StringBuilder`、`std.objectpool` 等**实测**写法），③ 并发提速的正确姿势。所有 idiom 在 1.0.5 本地 `cjc` 编译通过；示例 `049-performance.cj` 证"写法正确"（输出确定）——**性能数字必须靠 `cjprof` 测、本篇不空口给加速比**。一句话方法论：**没有测量的优化都是猜**。

## 前置知识

- 已完成《cjc 编译器》（35）——`-O0..-Oz`、`--lto`、`--fast-math`、`--int-overflow` 等**参数**本篇不重列，只说"何时值得开"
- 已完成《cjdb/cjprof》（40）——`cjprof record/report/heap` **怎么测**在那篇；本篇用"测出来之后"
- 已完成《值/引用与内存管理》（44）——`Array` 别名 vs `VArray` 值、class 在堆、struct 值语义，是本篇分配优化的地基

> **本篇与 35/40 的分界**：35 = 编译器选项清单；40 = 性能剖析工具；46 = **拿到 profile 后的决策树 + 减少分配的写法库**。

## 1. 方法论：闭环，别跳步

```
① 先跑对 —— 功能错误谈不上性能（cjpm test，文章 38）
② 测基线 —— cjprof record ./app ；cjprof report -F 出火焰图（文章 40）
③ 找热点 —— 看 top 函数；别优化"你以为慢"而 profile 里没有的
④ 改一类 —— 多数时候是"少分配 / 换数据结构 / 加并行"，而非调编译开关
⑤ 再测 —— 用同一 profile 对比；没有可测量收益就回滚
```

> **⚠️ 最大的反模式**：跳过 ②③，直接 `-O2` + 手动内联 + 换 `wrapping`——在**没被 profile 证实**的地方优化，通常 0 收益还添复杂度。**先测**。

## 2. 三层成本，各归一篇

| 层 | 抓手 | 归属 |
|---|---|---|
| 算法/数据结构 | 换 `HashMap` 代替线性查找、预分配、局部性 | 本篇 §3 |
| 编译优化 | `-O2`/`--lto`/`--fast-math`/`--int-overflow` | 参数在 **35**，"何时开"在 §5 |
| 分配与 GC | 少 new、复用、值类型、池化 | **本篇 §3**（重点） |
| 并发 | `spawn` 分区、无锁队列 | 本篇 §6 |
| 测量 | `cjprof record/report/heap` | **40** |

本篇独占的是"**分配与 GC**"——因为它是 GC 语言里**最常被 profile 确认、又最容易被忽视**的热点来源（示例 049 就练这个）。

## 3. 减少堆分配与 GC 压力（实测写法）

GC 语言的隐性成本：每次 `class` 实例化、每次 `Array` 扩容、每次字符串拼接，都在**堆上留垃圾**，攒多了触发 GC 停顿。四个高收益 idiom：

### 3.1 `Array` 预分配，别反复 `add` 触发扩容

```cangjie
let a = Array<Int64>(n, { i => i })   // 一次分配 n 个、按初始化器填充
```

`Array` 是引用式结构（承 44）：`add` 到满会"分配更大 backing + 拷贝旧的"，反复如此就是 O(n) 次拷贝。**已知规模**时直接 `Array<T>(size, init)` 或 `.reserve`。

### 3.2 小定长缓冲用 `VArray<T,$N>`（零堆）

```cangjie
let v: VArray<Int64, $4> = [1, 2, 3, 4]
for (i in 0..v.size) { ... v[i] ... }   // VArray 不实现 for-in，用索引
```

`VArray` 是**真值数组**（承 44 §5），数据内联、不占堆、**不参与 GC**——热点小数组（如 RGB、坐标、长度≤几百的定长窗口）首选。**限制**：`$N` 要字面量、元素不能含引用类型/枚举/lambda。

### 3.3 字符串累积走 `StringBuilder`

```cangjie
let sb = StringBuilder()
for (_ in 0..n) { sb.append("x") }      // 一个可变缓冲
return sb.toString()
```

反面：`s = s + part` 循环 n 次 = 造 n 个中间 String、O(n²) 拷贝。拼字符串要么 `StringBuilder`，要么 `String.join`（一次分配）。

### 3.4 反复创建同类对象：`std.objectpool.ObjectPool`

对"创建昂贵、用完即弃"的对象（连接、大 buffer、解析器），用 `std.objectpool` 的 `ObjectPool` **借出→归还→复用**，摊薄分配成本。

> **💡 更根本的一招——能 `struct` 就别 `class`**：值类型不进堆、GC 不碰它（承 44）。把"短命的小数据对象"从 `class` 改成 `struct`，常常比任何池化都省事。

## 4. GC 友好 = 少制造"长寿垃圾"

- **临时对象**（用完即废）GC 收得快、便宜。
- **长寿垃圾**（还活着但逻辑上已无用的对象）最伤——它逼 GC 反复扫描。**尽早断引用**（置 `None`、移出容器、别把大数组挂在长命对象字段上）。
- `~init`（承 44 §8）**不是**释放时机的保证，别用它做性能/资源假设。
- 真要观测回收：`import std.runtime.*; gc(heavy: true)`（44 实测存在）+ `cjprof heap`（40）看堆分布，而非盲调。

## 5. 编译优化：知道边界，别乱开（承 35，不重列参数）

- **默认 `-O0`**。发布构建至少 `-O1`/`-O2`；`-O2` 会额外开常量传播/内联/去虚化（35 实测参数表）。
- **`--lto=thin`** 常是"免费"提速（链接期跨模块优化）；注意 macOS/Windows 不支持、且不能配 `-Os/-Oz`（35）。
- **`--fast-math`**：浮点提速，但**改变精度语义**（可能合并/重排），数值敏感别碰。
- **`--int-overflow=wrapping`**：去掉溢出检查开销，但**静默回绕**——只在 profile 证明溢出检查确是热点、且回绕可接受时才换。
- **`-Os`/`-Oz`**：体积优先（嵌入式/下载体积敏感），可能牺牲速度。

> 这些是"锦上添花"，通常在 §3 的"少分配"做完之后才有意义。**优化顺序：算法 → 分配 → 编译开关**。

## 6. 并发提速：`spawn` 分区（承 23）

CPU 密集任务切分给多 `spawn` 任务并行（M:N 调度，22）。要点：

- **分区**别共享可变状态：能"各算各的、最后归约"就别在热路径上抢 `Mutex`（24/45）。
- **归约**用 `AtomicInt64`/无锁 `ConcurrentLinkedQueue`（45）；别为一个计数器上全局锁。
- **别过度并行**：任务粒度小于调度开销会**更慢**；先测串行版基线。
- 内存模型：跨任务可见性只由同步建立（45 §3）——并行≠免同步。

I/O 密集则靠并发等待而非堆核（23 的 `sleep`/阻塞 IO 会挂起当前任务、让 native 线程调度别的）。

## 7. 完整示例（少分配的三种正确写法）

`049-performance.cj`——证**写法正确**，不证速度：

<!-- example: cangjie/049-performance.cj -->
```cangjie
package perf

// 性能分析与优化示例（配合文章 46）。演示"少分配、少 GC"的几个正确写法。
// 注意：本程序证明**写法正确**（结果确定、可编译），**不证明速度**——
// 真实性能必须用 cjprof（文章 40）在 Linux 上测量，别凭感觉。
import std.convert.*

// 1) Array 预分配：一次到位，避免 add 触发多次"扩容 + 拷贝"
func sumPreallocated(n: Int64): Int64 {
    let a = Array<Int64>(n, { i => i })      // 给定长度 + 初始化函数，一次分配
    var s: Int64 = 0
    for (x in a) { s += x }
    return s
}

// 2) VArray<T,$N>：定长小数组、零堆分配（承文章 44），适合热点里的小缓冲区
func sumVArray(): Int64 {
    let v: VArray<Int64, $4> = [1, 2, 3, 4]
    var s: Int64 = 0
    for (i in 0..v.size) { s += v[i] }        // VArray 不实现 for-in，用索引遍历
    return s
}

// 3) 字符串累积：走 StringBuilder，避免 s = s + x 每次造中间串
func buildLabel(): String {
    let sb = StringBuilder()
    for (_ in 0..3) { sb.append("x") }
    return sb.toString()
}

main(): Int64 {
    println("prealloc_sum=${sumPreallocated(5)}")   // 0+1+2+3+4 = 10
    println("varray_sum=${sumVArray()}")            // 1+2+3+4 = 10
    println("label=${buildLabel()}")                // xxx
    return 0
}
```

编译并运行（Linux）：

```shell
cjc -O2 049-performance.cj -o perf && ./perf
```

预期输出：

```text
prealloc_sum=10
varray_sum=10
label=xxx
```

> 想给这版和"反复 `add` 版 / `s = s + x` 版"比快慢，用 `cjprof record`（文章 40）各测一遍火焰图，**别信本文或你的直觉**。

## 8. 性能自查清单

| 症状（profile 里常见） | 优先改法 | 篇目 |
|---|---|---|
| `malloc`/GC 占大头 | 预分配 / VArray / struct 化 / 池化 | §3、§4 |
| 字符串拼接热点 | `StringBuilder`/`String.join` | §3.3 |
| `Array.add` 循环触发扩容 | `Array(size, init)`/`reserve` | §3.1 |
| 哈希查找线性扫 | 换 `HashMap`/`HashSet` | 31 |
| 单线程 CPU 打满、多核空转 | `spawn` 分区 + 无锁归约 | §6 |
| 溢出检查开销明显 | 谨慎 `--int-overflow=wrapping` | §5 |
| 已用 `Array` 却当值拷来拷去 | 认清 `Array` 别名、必要时 `clone` 或用 `VArray` | 44 |

## 9. 与其它语言性能心智对照

| 语言 | 首要优化直觉 | 仓颉对应 |
|---|---|---|
| Rust | 少 `clone`、`&str` 切片、`iter` 零成本 | 少分配、`VArray`、`Array` 别名（44） |
| Go | 少 `new`、`sync.Pool`、`slice` 预容量 | `Array(size,init)`、`ObjectPool`（46 §3） |
| Java | 少对象、`StringBuilder`、JIT 预热 | `StringBuilder`、struct 化、`-O2` |
| C++ | RAII、移动语义、避免拷贝 | 靠 struct 值语义 + 预分配（无 move，44 §11） |

Cangjie 因**有 GC、无 move/借用**（44 §11），性能心智最接近 **Java/Go**：盯**分配**和 **GC**，而不是盯 move/COW。

## 10. FAQ

### Q1: 我该先调 `-O2`/`--lto` 还是先改代码？

**先改代码里的分配**（§3）。GC 语言 80% 的性能问题在"造了太多临时对象"，编译开关救不了这个。调开关是 §5 的收尾动作。

### Q2: `cjprof` 测出来一堆 `cjc-rt`/GC 帧怎么办？

说明分配压力高——回 §3 减分配（预分配、VArray、struct 化、池化）。`cjprof report -F` 火焰图（40）里 GC 占比是"分配是否过量"的直接指标。

### Q3: 小数组到底用 `Array` 还是 `VArray`？

长度**固定且小**、且在热点里 → `VArray<T,$N>`（零堆、不进 GC）。长度要动态增长、要 `.push`/迭代器/传参 → `Array`（但注意它是**别名**、赋值不拷，44 §4）。

### Q4: 加 `spawn` 一定更快吗？

不一定（§6）。任务粒度太小、调度与同步开销会吃掉收益；共享可变状态还会引入锁/竞争（45）。**先测串行基线**，分区只在 CPU 密集且能"各自算再归约"时划算。

### Q5: `--int-overflow=wrapping` 能白提速吗？

它去掉每次整数运算的溢出检查开销，**但把溢出变成静默回绕**（数值 bug 隐患）。只在 profile 证明溢出检查确实是热点、且你确认不会溢出（或回绕可接受）时才用（§5、35）。

### Q6: 怎么验证我的优化真的有效？

**唯一标准：同一 `cjprof` 前后对比**（40），外加 `cjpm test`（38）保证没改错。不接受"看起来更优雅"。

## 11. 总结

1. **方法论**：闭环——跑对→测基线→找热点→改一类→再测；**没测就优化 = 猜**。
2. **成本三层**：算法 / 分配与 GC / 并发；编译开关（35）和测量工具（40）各归其篇，本篇主攻**分配**。
3. **少分配四招（实测）**：`Array(size,init)` 预分配、`VArray<T,$N>` 零堆、`StringBuilder`/`String.join` 拼接、`std.objectpool.ObjectPool` 复用；**能 struct 就别 class**。
4. **GC 友好**：少造"长寿垃圾"、早断引用；`~init` 不作时机保证；观测用 `cjprof heap` + `std.runtime.gc`。
5. **编译开关**：`-O2`/`--lto=thin` 常值、`--fast-math`/`--int-overflow=wrapping` 有**语义代价**需谨慎（35）。
6. **并发**：分区 + 无锁归约、防过度并行、并行≠免同步（23/45）。
7. 本篇示例 049 只证**正确写法**；**加速比必须由 `cjprof` 实测**，不空口承诺。

## 参考资料

1. cjc 编译选项（优化级别 / `--lto` / `--fast-math` / `--int-overflow`）：https://docs.cangjie-lang.cn/cjnative/user_manual/source_zh_cn/Appendix/compile_options.html
2. 性能分析工具 cjprof：https://docs.cangjie-lang.cn/cjnative/tools/source_zh_cn/tools/cjprof_manual_cjnative.html
3. 数组类型（`Array` 别名 / `VArray` 值 / 预分配）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/array.html
4. 值/引用与内存管理（GC 背景）：articles/44-value-ref-memory.md
5. 并发原语与内存模型：articles/24-sync-primitives.md、articles/45-concurrency-model.md

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写。§3 各写法（`Array(n,init)`、`VArray` 索引遍历、`StringBuilder`、`std.objectpool`）均本地 `cjc` 实测编译；"性能数字须 cjprof 实测"为贯穿全篇的方法论纪律（工具用法在文章 40）。

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
