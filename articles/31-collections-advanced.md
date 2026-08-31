# 仓颉标准库数据结构：容器进阶、迭代器、双端队列与集合算法

> **摘要**: 文章 18 已经讲过 `ArrayList`/`HashSet`/`HashMap` 的基础 CRUD；本篇按"标准库数据结构"完整覆盖，**深化**这三个容器的进阶 API（排序/容量、`Option` 返回值、视图/子集），再补齐三块 18 没讲的硬骨头：**一、迭代器协议**——`Iterable<T>`/`Iterator<T>` 两个接口是 `for-in` 的底层机制，`for-in` 其实就是"取迭代器 + 反复 `next()` 直到 `None`"的语法糖，自定义类型只要实现 `Iterable` 就能被 `for-in`；**二、`ArrayDeque`**——支持 `addFirst`/`addLast`/`removeFirst`/`removeLast` 的双端队列，可当队列/栈用；**三、集合算法**——`std.collection` 提供 `filter`/`map`/`reduce`/`any`/`all` 等，配合管道 `|>` 组合使用（`filter`/`map` 返回 `Iterator`，用 `for-in` 落地；`reduce`/`any`/`all` 直接产出结果）。本文依据 1.0.5 LTS 官方文档 + SDK 实测。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已完成《数组、元组与区间》《Collection 集合类型》（`ArrayList`/`for-in`）、《函数类型、Lambda 与闭包》（管道 `|>`）、《错误处理与 Option》（`Option`/`while-let`）

> 定位：本篇是文章 18 的**续集**，只讲 18 没覆盖的迭代器协议、`ArrayDeque`、集合算法，不重复 `ArrayList`/`HashMap` 基础用法。

## 1. 一切 `for-in` 的背后：Iterable / Iterator

仓颉里 `Range`、`Array`、`ArrayList`、`HashSet`、`HashMap` 能 `for-in`，靠的都是它们实现了 `Iterable` 接口。协议就两个内置接口：

```cangjie
interface Iterable<T> {
    func iterator(): Iterator<T>
    ...
}

interface Iterator<T> <: Iterable<T> {
    mut func next(): Option<T>
    ...
}
```

- **`Iterable<T>`**：能被遍历的东西，负责 `iterator()` 造出一个迭代器；
- **`Iterator<T>`**：遍历的光标，`next()` 每次返回 `Option<T>`——有值给 `Some`、耗尽给 `None`。

### 1.1 `for-in` 就是语法糖

官方给出脱糖：下面这段 `for-in`

```cangjie
let list = [1, 2, 3]
for (i in list) {
    println(i)
}
```

**完全等价于**：

```cangjie
let list = [1, 2, 3]
var it = list.iterator()
while (true) {
    match (it.next()) {
        case Some(i) => println(i)
        case None => break
    }
}
```

还能用 `while-let` 写得更紧凑（这是本篇示例会用到的形态）：

```cangjie
var it = list.iterator()
while (let Some(i) <- it.next()) {
    println(i)
}
```

> **💡 提示**：`Iterator` 里的 `next()` 在接口上标了 `mut`。你用 **`class` 实现迭代器时不用写 `mut`**（类是引用类型、字段本就可变）；用 **`struct` 实现时才需要 `mut`**。

## 2. 自定义可迭代类型

让你的类型支持 `for-in`，只需实现 `Iterable<T>` 的 `iterator()`，再配一个实现 `Iterator<T>` 的 `next()`。下面这个 `Countdown(n)` 从 n 倒数到 1：

```cangjie
import std.collection.*

class Countdown <: Iterable<Int64> {
    let n: Int64
    init(n: Int64) { this.n = n }
    public func iterator(): Iterator<Int64> { CountdownIter(n) }
}

class CountdownIter <: Iterator<Int64> {
    var cur: Int64
    init(n: Int64) { cur = n }
    public func next(): Option<Int64> {
        if (cur <= 0) { return None }
        let v = cur
        cur -= 1
        Some(v)
    }
}

main() {
    for (x in Countdown(5)) { println(x) }   // 5 4 3 2 1
}
```

`for (x in Countdown(5))` 能被编译器展开成"`Countdown(5).iterator()` + 反复 `next()`"——这就是协议的威力：**只要实现 `Iterable`，你的类型立刻能进 `for-in`、也能进集合算法管道**。

## 3. 三大容器进阶（承接文章 18）

文章 18 已过 `ArrayList`/`HashMap`/`HashSet` 的基础增删改查；这里补三个**日常一定会碰到、但 18 没展开**的点——全部 1.0.5 实测。

### 3.1 ArrayList：排序、容量与批量删除

- **`capacity`**：底层缓冲区当前容量（`>= size`）；日常只关心 `size`，性能调优才看 `capacity`。
- **原地排序**：**`l.sort()` 已被弃用**（1.0.5 SDK 明确警告），改走 `std.sort.sort` 全局函数：

  ```cangjie
  import std.sort.sort
  sort(l)                                    // 升序；`sort(l, descending: true)` 降序
  ```

- **`removeIf { 谓词 }`**：按条件批量删除，比手写 `for + remove(at:)` 更快且安全。

  ```cangjie
  l.removeIf { x => x > 100 }
  ```

- **复杂度**：随机下标 `l[i]` O(1)、尾部 `add` 摊还 O(1)、**中间 `add(el, at:)` 与 `remove(at:)` 是 O(n)**（要挪后续元素）。

### 3.2 HashMap：`[]` 读写、Option 返回值与视图

- **写用 `[]`、读回是 `Option<V>`**（这是最容易踩的点）：

  ```cangjie
  let m = HashMap<String, Int64>()
  m["a"] = 1
  let v: Int64 = m["a"] ?? -1        // Some → 1；不存在 → -1
  ```

- **`get(k) / remove(k)` 都返回 `Option<V>`**：`get` 只查不删；`remove` 返回**被删的旧值**：

  ```cangjie
  let old = m.remove("a") ?? -1
  ```

- **视图 `keys()` / `values()` 是方法（要带 `()`）**，返回可迭代视图：

  ```cangjie
  for (k in m.keys())   { println(k) }
  for (v in m.values()) { println(v) }
  ```

- **遍历无序**——别依赖 `keys()`/`values()` 的输出顺序。

### 3.3 HashSet：子集判断与批量删除

文章 18 已讲运算符 `|`（并）/`&`（交）/`-`（差）；这里补两点：

- **`subsetOf(other): Bool`**：判自己是不是 `other` 的子集。
- **`removeIf { 谓词 }`**：条件删除（同 ArrayList）。

```cangjie
let small = HashSet<Int64>([1, 2])
let big   = HashSet<Int64>([1, 2, 3])
println(small.subsetOf(big))   // true
```

> **⚠️ 别乱猜方法名（本会话实测清单）**：以下**都不是** 1.0.5 `std.collection` 的成员：`ArrayList.insert / removeFirst / removeLast / ensureTotalCapacity`、`HashMap.put / getOrPut / computeIfAbsent`、`HashSet.union / intersect / containsAll / removeAll`。用**运算符**（`| & -`）、**`[]`**、**`add / remove / contains / subsetOf / removeIf`** 这套既有能力即可。

## 4. `ArrayDeque`：双端队列

`Deque`（双端队列）是接口，base SDK 里的具体实现是 **`ArrayDeque`**（`Deque<Int64>()` 会报"interface 不能实例化"，要用 `ArrayDeque`）。它在**两端**都能增删，因此既能当队列（FIFO）又能当栈（LIFO）：

| 操作 | 作用 |
|---|---|
| `addLast(v)` / `addFirst(v)` | 从尾/头入 |
| `removeFirst()` / `removeLast()` | 从头/尾出，返回 `Option<T>`（空则 `None`） |
| `first` / `last` | 头/尾元素（`Option<T>`，可能为空） |
| `size` | 元素数 |
| 支持 `Iterable` | 可直接 `for-in` |

```cangjie
let dq = ArrayDeque<Int64>()
dq.addLast(2); dq.addLast(3); dq.addFirst(1)   // [1, 2, 3]
let head = dq.removeFirst()                     // 1，剩 [2, 3]
println(dq.size)                                // 2
```

> **✅ 选择**：需要"两端进出"（滑动窗口、BFS 队列、表达式求值栈）用 `ArrayDeque`；只在尾部追加、要下标随机访问用 `ArrayList`；要唯一性用 `HashSet`。

## 5. 集合算法：`filter` / `map` / `reduce` / `any` / `all`

`std.collection` 提供一批作用于 `Iterable` 的**全局算法函数**，配合**管道 `|>`**（见《函数类型、Lambda 与闭包》）串联最自然。关键区分两类返回：

- **返回 `Iterator`（惰性、可继续串）**：`filter`、`map`；
- **返回结果值（终止操作）**：`reduce` 返回 `Option<T>`（空序列则 `None`）、`any`/`all` 返回 `Bool`。

```cangjie
import std.collection.*
let nums = ArrayList<Int64>([1, 2, 3, 4, 5, 6])

// filter/map 得到 Iterator，用 for-in 落地
for (x in (nums |> filter { v => v % 2 == 0 } |> map { v => v * 10 })) {
    // 20, 40, 60
}

// reduce/any/all 直接出值
let s = (nums |> reduce { x, y => x + y }).getOrThrow()   // 21（reduce 返回 Option）
let hasBig = nums |> any { v => v > 5 }     // true
let allPos = nums |> all { v => v > 0 }     // true
```

要点（均经 SDK 实测）：

- `filter { 谓词 }` / `map { 变换 }` 用 `|>` 接在集合后面，返回 `Iterator`；要落地就用 `for-in` 遍历它（`Iterator` 本身没有 `.size`）。
- `reduce { 二元闭包 }` 是**无初值**折叠（拿首元素当起点，`{ x, y => x + y }` 形式），所以要求元素类型可两两合并。
- `any { 谓词 }`/`all { 谓词 }` 返回 `Bool`。

> **⚠️ 注意**：这些算法是 **`std.collection` 里的全局函数**，不是集合类型的成员方法——写 `nums.filter{...}` 会报 `'filter' is not a member`，正确是 `nums |> filter {...}` 或 `filter` 配合 `|>`。

## 6. 完整可运行示例

把三块拼在一起：自定义 `Iterable`（`Countdown`）+ `while-let` 手动迭代 + `ArrayDeque` 双端队列 + 集合算法管道。输出完全确定。

<!-- example: cangjie/036-collections-advanced.cj -->
```cangjie
// 标准库数据结构示例：三大容器进阶 + 迭代器协议 + ArrayDeque + 集合算法（管道写法）
// 覆盖文章 18 之外的部分：ArrayList/HashMap/HashSet 进阶 API、自定义 Iterable/Iterator、
// for-in 脱糖、while-let 手动驱动、ArrayDeque 双端队列、以及 filter/map/reduce/any/all 组合。
//
// 全部为 1.0.5 base SDK 自带（std.collection），本地可 staticlib 编译。

import std.collection.*
import std.sort.sort   // ArrayList.sort() 已弃用，排序走 std.sort 全局函数

// ===== 自定义可迭代类型：实现 Iterable<T>，提供 iterator() =====
class Countdown <: Iterable<Int64> {
    let n: Int64
    init(n: Int64) { this.n = n }
    public func iterator(): Iterator<Int64> { CountdownIter(n) }
}

// 配套的迭代器：实现 Iterator<T> 的 next()，耗尽返回 None
class CountdownIter <: Iterator<Int64> {
    var cur: Int64
    init(n: Int64) { cur = n }
    public func next(): Option<Int64> {
        if (cur <= 0) {
            return None
        }
        let v = cur
        cur -= 1
        Some(v)
    }
}

main(): Int64 {
    // 1) 自定义 Iterable 直接被 for-in 遍历
    var total = 0
    for (x in Countdown(5)) {
        total += x                 // 5+4+3+2+1 = 15
    }
    println("countdown sum = ${total}")   // countdown sum = 15

    // 2) 手动驱动迭代器：while + let Some 模式（等价于 for-in 的脱糖形式）
    let it = Countdown(3).iterator()
    var seq = ""
    while (let Some(v) <- it.next()) {
        seq += "${v}"              // "321"
    }
    println("manual iterator = ${seq}")   // manual iterator = 321

    // 3) ArrayDeque：双端队列（文章 18 未覆盖的容器）
    let dq = ArrayDeque<Int64>()
    dq.addLast(2)
    dq.addLast(3)
    dq.addFirst(1)                 // 队列为 [1, 2, 3]
    let head = dq.removeFirst().getOrThrow()   // removeFirst 返回 Option，取出 1
    println("deque size=${dq.size} head=${head} first=${dq.first.getOrThrow()} last=${dq.last.getOrThrow()}")
    // deque size=2 head=1 first=2 last=3

    // 4) 三大容器进阶（承接文章 18 基础 CRUD 之外的常用能力）
    //    ArrayList：原地排序 + 容量；HashMap：[] 读写、get/remove 返回 Option、keys() 视图；HashSet：subsetOf
    let v = ArrayList<Int64>([5, 3, 1])
    sort(v)                          // 升序 [1, 3, 5]
    println("sorted first=${v[0]}, capacity>=size=${v.capacity >= v.size}")   // sorted first=1, capacity>=size=true

    let hm = HashMap<String, Int64>()
    hm["a"] = 1                      // 下标赋值写入
    hm["b"] = 2
    println("hm get=${hm.get("a") ?? -1}, removed=${hm.remove("a") ?? -1}, size=${hm.size}")
    // hm get=1, removed=1, size=1
    var keyCnt = 0
    for (k in hm.keys()) { keyCnt += 1 }   // keys() 返回视图，可迭代
    println("keys left=${keyCnt}")         // keys left=1

    let hs = HashSet<Int64>([1, 2])
    let superSet = HashSet<Int64>([1, 2, 3])
    println("subsetOf=${hs.subsetOf(superSet)}")   // subsetOf=true

    // 5) 集合算法（管道 `|>` 写法）：filter 与 map 返回 Iterator，用 for-in 落地
    let nums = ArrayList<Int64>([1, 2, 3, 4, 5, 6])
    var evenSum = 0
    for (x in (nums |> filter { v => v % 2 == 0 } |> map { v => v * 10 })) {
        evenSum += x               // 偶数 [2,4,6] → *10 → 20+40+60 = 120
    }
    println("even*10 sum = ${evenSum}")   // even*10 sum = 120

    // reduce / any / all 直接产生结果值
    println("reduce = ${(nums |> reduce { x, y => x + y }).getOrThrow()}")   // reduce = 21
    println("any>5 = ${nums |> any { v => v > 5 }}")          // any>5 = true
    println("all>0 = ${nums |> all { v => v > 0 }}")          // all>0 = true

    return 0
}
```

预期输出：

```text
countdown sum = 15
manual iterator = 321
deque size=2 head=1 first=2 last=3
sorted first=1, capacity>=size=true
hm get=1, removed=1, size=1
keys left=1
subsetOf=true
even*10 sum = 120
reduce = 21
any>5 = true
all>0 = true
```

## 7. 语言对比

| 概念 | 仓颉 | Rust | Java | Go |
|---|---|---|---|---|
| 可迭代协议 | `Iterable<T>::iterator()` | `IntoIterator::into_iter` | `Iterable<T>::iterator()` | 无（slice/map 直接 range） |
| 迭代器协议 | `Iterator<T>::next(): Option<T>` | `Iterator::next(): Option<Item>` | `Iterator::hasNext/next` | — |
| for-in 脱糖 | iterator + next 到 None | `for` = `IntoIterator` | `for(:)` = `Iterable` | `for range` |
| 惰性→拉取 | `filter/map` 返回 Iterator | 迭代器惰性 | Stream 惰性 | 手写 |
| 归约 | `\|> reduce {x,y=>…}` → Option | | `.fold`/`.reduce` | `Stream.reduce` | 手写 |
| 双端队列 | `ArrayDeque` | `VecDeque` | `ArrayDeque` | 切片模拟 |

**从 Rust 迁移**：`Iterable`≈`IntoIterator`、`Iterator::next()->Option<T>` 与 Rust 几乎一字不差，`|> filter |> map |> reduce` 对应 Rust 的 `.filter().map().fold()` 链式；差别是仓颉用管道 `|>` 把函数"外置"。
**从 Java 迁移**：`Iterable`/`Iterator` 同名同意，但仓颉的 `next()` 返回 `Option<T>` 而不是"抛 `NoSuchElementException` + 先 `hasNext()`"，更符合函数式习惯。

## 8. 常见问题（FAQ）

### Q1: 我的类型想被 `for-in`，要做什么？

实现 `Iterable<T>`，提供 `iterator(): Iterator<T>`；再写一个实现 `Iterator<T>` 的 `next(): Option<T>`（耗尽返回 `None`）。就这两步。

### Q2: `Iterator` 接口里写了 `mut func next()`，我实现时要加 `mut` 吗？

用 `class` 实现**不用**（类字段本就可变）；用 `struct` 实现**要** `mut`（struct 是值类型，改字段需显式可变）。

### Q3: `for-in` 和手写 `while (let Some(v) <- it.next())` 有啥区别？

前者是后者的语法糖（官方给出等价脱糖）。需要"跨多个集合手动交替取元素"等高级控制时，用 `while-let` 手驱动迭代器更灵活。

### Q4: `filter`/`map` 结果为什么没有 `.size`？

它们返回的是 **`Iterator`（惰性）**，不是集合。要大小/内容，用 `for-in` 遍历它、或收集到新 `ArrayList`。

### Q5: `reduce` 怎么没有初值？

1.0.5 的 `nums |> reduce { x, y => x + y }` 是**无初值折叠**：取序列首元素当累积起点、从第二个开始合并，所以要求元素类型满足合并闭包。

### Q6: 为什么 `nums.filter{...}` 报错？

因为 `filter`/`map`/`reduce`/`any`/`all` 是 **`std.collection` 的全局函数**，不是集合成员方法。写 `nums |> filter { ... }`（管道）或 `filter` 形式调用。

### Q7: `ArrayDeque` 和 `ArrayList` 怎么选？

两端都要增删（队列/栈/滑窗）→ `ArrayDeque`；只需尾部增删 + 随机下标访问 → `ArrayList`。

## 9. 总结

1. **三大容器进阶**：`ArrayList` 排序走 `std.sort.sort`（`l.sort()` 已弃用）、有 `capacity`/`removeIf`；`HashMap` 读写用 `[]` 且 `get/remove/[]` 读回**都是 `Option`**、`keys()`/`values()` 是方法视图；`HashSet` 有 `subsetOf`/`removeIf`，并/交/差仍是 `|&-` 运算符。**别猜不存在的 `put/union/containsAll/insert` 等**。
2. `for-in` 的底层是 **`Iterable`/`Iterator` 协议**；`for-in` = 取 `iterator()` + 反复 `next()` 到 `None`（官方给出等价脱糖，含 `while-let` 写法）。
3. 自定义类型实现 `Iterable`（+ 一个 `Iterator`）即可进 `for-in`/管道；`class` 实现的 `next()` 不写 `mut`，`struct` 才写。
4. **`ArrayDeque`** 是 `Deque` 的具体实现，两端增删（`addFirst/addLast/removeFirst/removeLast/first/last/size`），可当队列/栈，也能 `for-in`。
5. **集合算法** `filter`/`map` 返回惰性 `Iterator`（用 `for-in` 落地），`reduce`/`any`/`all` 直接出值；它们是 `std.collection` 的**全局函数**，配合 `|>` 使用，不是成员方法。
6. 这些全在 1.0.5 base SDK 的 `std.collection` 里，本地可编译、CI 可运行。

## 参考资料

1. 仓颉 1.0.5 LTS Iterable 与 Collections：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/collections/collection_iterable_collections.html
2. 仓颉 1.0.5 LTS 基础 Collection 类型概述：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/collections/collection_overview.html
3. 仓颉 1.0.5 LTS 函数调用语法糖（管道 `|>`）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/function/function_call_desugar.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
