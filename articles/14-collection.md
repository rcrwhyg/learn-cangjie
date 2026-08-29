# 仓颉 Collection 集合类型

> **摘要**: 数组 `Array<T>` 长度固定且不便于频繁增删，仓颉标准库 `std.collection` 提供了 `ArrayList<T>`、`HashSet<T>`、`HashMap<K, V>` 等可变集合类型来满足日常开发需求。本文依据仓颉 1.0.5 LTS SDK 的 `std.collection` 模块，系统介绍这三种核心集合的创建、增删改查、遍历、集合运算与典型用法。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已了解变量、函数、字符串、Array、Range
- 已了解泛型语法（`ArrayList<Int64>` 中的 `<T>`）
- 已完成《仓颉数组、元组与区间》《仓颉字符串与字符处理》

## 1. 概述

仓颉 `std.collection` 包提供了若干可变集合类型，最常用的是：

| 类型 | 说明 | 是否有序 | 是否允许重复 |
|---|---|---|---|
| `ArrayList<T>` | 动态数组，长度可增长 | 是（下标访问） | 是 |
| `HashSet<T>` | 哈希集合，基于哈希表实现 | 否（遍历顺序不保证） | 否 |
| `HashMap<K, V>` | 哈希映射（键值对） | 否（遍历顺序不保证） | 键不允许重复，值可重复 |

使用前需要显式 `import`：

```cangjie
import std.collection.ArrayList
import std.collection.HashSet
import std.collection.HashMap
```

> **关于文档来源**：仓颉 1.0.5 LTS 官方标准库文档托管在 `cangjie-lang.cn/docs`（**注意域名是 `cangjie-lang.cn`，不是 `docs.cangjie-lang.cn`**），可通过 `/docs?url=/1.0.5/libs/...` 形式访问 std.collection 等包的完整 API 页面。本文的 API 描述与官方 `libs/std/collection/...` 章节保持一致。

## 2. ArrayList 动态数组

`ArrayList<T>` 是 `Array<T>` 的可增长版本，内部维护一个可动态扩容的数组缓冲区。适合需要频繁在**末尾追加**、**按位置插入 / 删除**、**随机访问**元素的场景。

### 2.1 创建 ArrayList

```cangjie
let list1: ArrayList<Int64> = ArrayList<Int64>([1, 2, 3, 4, 5])  // 从字面量
let list2: ArrayList<Int64> = ArrayList<Int64>(3, {_ => 0})        // 长度 3，全部初始化为 0
let list3: ArrayList<String> = ArrayList<String>(["仓颉", "ArrayList"])
let list4: ArrayList<Int64> = ArrayList<Int64>()                    // 空
```

注意：构造器 `ArrayList<T>(n, init)` 的第二个参数是 `(Int64) -> T` 类型的 lambda，参数是当前下标，返回值是元素初始值。

### 2.2 属性

| 属性 | 类型 | 说明 |
|---|---|---|
| `size` | `Int64` | 当前元素数量 |
| `capacity` | `Int64` | 底层缓冲区的容量（>= size） |
| `first` | `T`（可空） | 第一个元素 |
| `last` | `T`（可空） | 最后一个元素 |

`first` 和 `last` 是**属性**而不是方法，不能写 `list.first()`。

### 2.3 增删改查

```cangjie
let list: ArrayList<Int64> = ArrayList<Int64>([1, 2, 3, 4, 5])

// 添加
list.add(6)                  // 末尾追加 → [1,2,3,4,5,6]
list.add(0, at: 0)           // 在下标 0 处插入 0 → [0,1,2,3,4,5,6]
list.add(all: [10, 20])      // 末尾追加整个集合

// 修改（下标赋值）
list[0] = 100
println(list[0])             // 100

// 删除
list.remove(at: 1)           // 删除下标 1 的元素
list.remove(1..3)            // 删除下标 [1, 3) 区间
list.removeIf({x => x > 100}) // 删除满足条件的元素

// 查询
println(list.size)           // 当前元素数
println(list.contains(5))    // 是否包含 5
println(list.get(0))         // 下标 0 的元素
println(list.isEmpty())      // 是否为空
```

注意：
- `ArrayList` 没有提供"按值删除单个元素"的方法，常见的做法是用 `removeIf` 配合闭包：`list.removeIf({x => x == target})`。
- `remove(at: index)` 删除的是**单个下标**对应的元素，**不是按值删除**。

### 2.4 排序、反转、切片

排序使用 `std.sort` 全局函数（`ArrayList.sort()` 已被废弃）：

```cangjie
import std.sort.sort

let unsorted: ArrayList<Int64> = ArrayList<Int64>([3, 1, 4, 1, 5, 9, 2, 6])
sort(unsorted)               // 默认升序
// sort(unsorted, descending: true)  // 降序
// sort(unsorted, stable: true)      // 稳定排序
```

反转与切片：

```cangjie
let r: ArrayList<Int64> = ArrayList<Int64>([1, 2, 3, 4, 5])
r.reverse()                  // [5, 4, 3, 2, 1]
let slice: ArrayList<Int64> = r[1..4]  // [r[1], r[2], r[3]]
```

### 2.5 与 Array 互转

```cangjie
let list: ArrayList<Int64> = ArrayList<Int64>([1, 2, 3])
let arr: Array<Int64> = list.toArray()    // ArrayList → Array
let list2: ArrayList<Int64> = ArrayList<Int64>(arr)  // Array → ArrayList
```

完整可运行示例（`examples/cangjie/018-collection.cj`）：

<!-- example: cangjie/018-collection.cj -->
```cangjie
// Collection 集合类型示例
// 演示：ArrayList<T>（动态数组）、HashSet<T>（哈希集合）、HashMap<K, V>（哈希映射）
// 以及集合间的关系运算（|  并集、&  交集、-  差集）
// 涵盖：构造、添加、删除、查询、遍历、常用属性与方法

import std.collection.ArrayList
import std.collection.HashSet
import std.collection.HashMap
import std.sort.sort

main() {
    // ========== 1) ArrayList 动态数组 ==========

    // 1.1 创建 ArrayList
    let list1: ArrayList<Int64> = ArrayList<Int64>([1, 2, 3, 4, 5])
    let list2: ArrayList<Int64> = ArrayList<Int64>(3, {_ => 0})  // [0, 0, 0]
    let list3: ArrayList<String> = ArrayList<String>(["仓颉", "ArrayList"])
    println("list1.size = ${list1.size}, list1.first = ${list1.first}, list1.last = ${list1.last}")
    println("list2.size = ${list2.size}")
    println("list3.size = ${list3.size}")

    // 1.2 增删改查
    list1.add(6)                    // 末尾追加
    list1.add(0, at: 0)             // 在下标 0 处插入 0
    println("list1 after add = ${list1.size}")
    println("list1[0] = ${list1[0]}")
    println("list1[2] = ${list1[2]}")

    // 修改元素
    list1[0] = 100
    println("list1[0] (after set) = ${list1[0]}")

    // 删除元素
    list1.remove(at: 1)             // 删除下标 1 的元素
    list1.remove(1..3)              // 删除下标 [1, 3) 区间
    println("list1 after remove = ${list1.size}")

    // 查询
    println("list1 contains 5: ${list1.contains(5)}")
    println("list1 get(0): ${list1.get(0)}")
    println("list1 isEmpty: ${list1.isEmpty()}")

    // 1.3 排序（使用 std.sort 全局函数）
    let unsorted: ArrayList<Int64> = ArrayList<Int64>([3, 1, 4, 1, 5, 9, 2, 6])
    sort(unsorted)
    print("sorted: ")
    for (x in unsorted) {
        print("${x} ")
    }
    println("")

    // 1.4 转换为 Array
    let arr: Array<Int64> = list1.toArray()
    println("arr.size = ${arr.size}")

    // 1.5 反转 / 切片
    let r: ArrayList<Int64> = ArrayList<Int64>([1, 2, 3, 4, 5])
    r.reverse()
    println("reversed: ${r[0]}, ${r[1]}, ${r[2]}, ${r[3]}, ${r[4]}")
    let slice: ArrayList<Int64> = r[1..4]   // [r[1], r[2], r[3]]
    println("slice size = ${slice.size}")

    // 1.6 清空
    r.clear()
    println("after clear: r.size = ${r.size}")

    // ========== 2) HashSet 哈希集合 ==========

    // 2.1 创建 HashSet
    let set1: HashSet<String> = HashSet<String>(["仓颉", "ArrayList", "HashSet"])
    let set2: HashSet<Int64> = HashSet<Int64>([1, 2, 3, 4, 5])
    println("set1.size = ${set1.size}, set2.size = ${set2.size}")

    // 2.2 增删改查
    set1.add("HashMap")
    println("set1 after add: size = ${set1.size}")
    println("set1 contains HashMap: ${set1.contains("HashMap")}")

    set1.remove("ArrayList")
    println("set1 after remove: size = ${set1.size}")

    // 2.3 集合运算：并 |、交 &、差 -
    let sa: HashSet<Int64> = HashSet<Int64>([1, 2, 3, 4])
    let sb: HashSet<Int64> = HashSet<Int64>([3, 4, 5, 6])
    let unionSet: HashSet<Int64> = sa | sb        // {1,2,3,4,5,6}
    let interSet: HashSet<Int64> = sa & sb        // {3,4}
    let diffSet: HashSet<Int64>  = sa - sb        // {1,2}
    println("union size = ${unionSet.size}")
    println("inter size = ${interSet.size}")
    println("diff  size = ${diffSet.size}")

    // 2.4 子集判断
    let small: HashSet<Int64> = HashSet<Int64>([3, 4])
    println("small subsetOf sa: ${small.subsetOf(sa)}")

    // 2.5 遍历（顺序不保证）
    print("set1: ")
    for (x in set1) {
        print("${x} ")
    }
    println("")

    // 2.6 转换为 Array
    let setArr: Array<String> = set1.toArray()
    println("setArr.size = ${setArr.size}")

    // ========== 3) HashMap 哈希映射 ==========

    // 3.1 创建 HashMap
    let map1: HashMap<String, Int64> = HashMap<String, Int64>([("Alice", 30), ("Bob", 25), ("Carol", 28)])
    let map2: HashMap<String, String> = HashMap<String, String>()
    println("map1.size = ${map1.size}")
    println("map2.size = ${map2.size}, isEmpty = ${map2.isEmpty()}")

    // 3.2 增删改查
    map1.add("Dave", 35)
    println("map1[Alice] = ${map1["Alice"]}")
    map1["Alice"] = 31
    println("map1[Alice] (after set) = ${map1["Alice"]}")
    println("map1 contains Bob: ${map1.contains("Bob")}")
    println("map1 contains Eve: ${map1.contains("Eve")}")

    // 3.3 删除
    let old: Int64 = map1.remove("Bob") ?? -1
    println("removed Bob: ${old}, map1.size = ${map1.size}")

    // 3.4 遍历（顺序不保证）
    for ((k, v) in map1) {
        println("  ${k} -> ${v}")
    }

    // 3.5 keys() / values()：返回 Collection
    let keys: Collection<String> = map1.keys()
    let values: Collection<Int64> = map1.values()
    println("keys.size = ${keys.size}, values.size = ${values.size}")

    // 3.6 map2 添加内容
    map2.add("lang", "仓颉")
    map2.add("version", "1.0.5")
    println("map2.size = ${map2.size}")
    println("map2[lang] = ${map2["lang"]}")

    // ========== 4) 综合场景：统计单词频率 ==========

    let text: String = "仓颉 仓颉 cangjie cangjie cangjie 1.0.5"
    let words: Array<String> = text.split(" ")
    let freq: HashMap<String, Int64> = HashMap<String, Int64>()
    for (w in words) {
        if (freq.contains(w)) {
            freq[w] = freq[w] + 1
        } else {
            freq.add(w, 1)
        }
    }
    println("--- 词频统计 ---")
    for ((w, c) in freq) {
        println("  ${w}: ${c}")
    }
}
```

## 3. HashSet 哈希集合

`HashSet<T>` 是基于哈希表实现的**无序、不重复**集合。`T` 必须实现 `Hashable` 和 `Equatable` 接口（内置数值类型与 `String` 已自动实现）。

### 3.1 创建 HashSet

```cangjie
let set1: HashSet<String> = HashSet<String>(["仓颉", "ArrayList", "HashSet"])
let set2: HashSet<Int64>  = HashSet<Int64>([1, 2, 3, 4, 5])
let empty: HashSet<String> = HashSet<String>()
```

### 3.2 增删改查

```cangjie
let set: HashSet<String> = HashSet<String>()

set.add("仓颉")               // 添加单个元素
println(set.size)             // 1
println(set.contains("仓颉"))  // true

set.remove("仓颉")            // 删除存在的元素返回 true，不存在返回 false
println(set.isEmpty())        // true
```

### 3.3 集合运算

`HashSet` 重载了三个集合操作运算符，返回**新的 `HashSet`**，**不会修改**原集合：

| 运算符 | 含义 | 等价方法 |
|---|---|---|
| `a \| b` | 并集：`a ∪ b` | — |
| `a & b` | 交集：`a ∩ b` | — |
| `a - b` | 差集：`a - b` | — |

```cangjie
let sa: HashSet<Int64> = HashSet<Int64>([1, 2, 3, 4])
let sb: HashSet<Int64> = HashSet<Int64>([3, 4, 5, 6])
let u = sa | sb  // {1,2,3,4,5,6}
let i = sa & sb  // {3,4}
let d = sa - sb  // {1,2}
```

### 3.4 子集判断与保留

```cangjie
let small: HashSet<Int64> = HashSet<Int64>([3, 4])
println(small.subsetOf(sa))  // true

// 保留：只保留同时在另一个集合中的元素
let tmp: HashSet<Int64> = HashSet<Int64>([1, 2, 3, 4])
tmp.retain(all: sa)
println(tmp.size)  // 4（全部保留）
```

### 3.5 遍历

`HashSet` 实现 `Iterable<T>`，可用 `for-in` 遍历，**遍历顺序不保证**：

```cangjie
for (x in set1) {
    println(x)
}
```

也可以转成 `Array<T>`：

```cangjie
let arr: Array<String> = set1.toArray()
```

## 4. HashMap 哈希映射

`HashMap<K, V>` 是基于哈希表实现的**键值对映射**。`K` 必须实现 `Hashable` 和 `Equatable` 接口。

### 4.1 创建 HashMap

```cangjie
// 从字面量数组创建
let map1: HashMap<String, Int64> = HashMap<String, Int64>([("Alice", 30), ("Bob", 25), ("Carol", 28)])
let map2: HashMap<String, String> = HashMap<String, String>()  // 空
```

### 4.2 增删改查

```cangjie
let map: HashMap<String, Int64> = HashMap<String, Int64>()

// 添加 / 修改
map.add("Alice", 30)
map["Bob"] = 25                  // 下标赋值也是修改
println(map["Alice"])            // 30

// 查询
println(map.contains("Alice"))   // true
println(map.size)                // 2

// 删除
let old: Int64 = map.remove("Bob") ?? -1  // remove 返回 Option<V>，不存在时为 None，?? 给出默认值
println(map.size)                            // 1
```

注意：
- 读取键 `map["Alice"]` 时，**如果键不存在会抛出运行时异常**，而不是返回零值。要安全地读取可能不存在的键，应使用 `map.get(key)`，它返回 `Option<V>`，可配合 `getOrDefault` 给出默认值。
- `map.remove(key)` 返回 `Option<V>`（被删除的值），`map.add(key, value)` 返回 `Option<V>`（该键原来的旧值，若原本不存在则为 `None`）。
- `??` 是**elvis 运算符**（详见后续文章），如果左侧为 `None` 则返回右侧默认值。

### 4.3 遍历

```cangjie
// 遍历键值对
for ((k, v) in map) {
    println("${k} -> ${v}")
}

// 获取键、值集合
let keys: Collection<String>   = map.keys()
let values: Collection<Int64>  = map.values()
println(keys.size)    // 键的数量
println(values.size)  // 值的数量
```

遍历顺序**不保证**，与插入顺序无关。

### 4.4 典型模式：词频统计

```cangjie
let text: String = "仓颉 仓颉 cangjie cangjie cangjie 1.0.5"
let words: Array<String> = text.split(" ")
let freq: HashMap<String, Int64> = HashMap<String, Int64>()
for (w in words) {
    if (freq.contains(w)) {
        freq[w] = freq[w] + 1
    } else {
        freq.add(w, 1)
    }
}
for ((w, c) in freq) {
    println("${w}: ${c}")
}
```

输出：

```
仓颉: 2
cangjie: 3
1.0.5: 1
```

## 5. 集合选型指南

| 场景 | 推荐类型 | 理由 |
|---|---|---|
| 长度固定、只读 | `Array<T>` | 最轻量，值类型、无额外封装开销（元素缓冲仍在堆上） |
| 频繁在末尾追加 / 随机访问 | `ArrayList<T>` | 摊销 O(1) 追加，O(1) 随机访问 |
| 频繁在中间插入 / 删除 | `ArrayList<T>` + `removeIf` | O(n) 但 API 简单 |
| 需要去重 | `HashSet<T>` | O(1) `contains` |
| 需要集合运算 | `HashSet<T>` | 内置 `\|` / `&` / `-` |
| 键值对映射 | `HashMap<K, V>` | O(1) `[]` get / set |
| 需要有序映射 | `TreeMap<K, V>`（后续专题） | 按键排序 |

## 6. 常见问题（FAQ）

### Q1: `ArrayList` 和 `Array` 的区别？

`Array<T>` 长度固定，**不能动态增长**（`add` / `remove` 等方法不存在）；`ArrayList<T>` 是可变集合，**支持动态增删**。如果元素数量在编译期已知且不需要增删，优先用 `Array`；否则用 `ArrayList`。

### Q2: `HashSet` 是有序的吗？

不是。`HashSet` 基于哈希表实现，遍历顺序不保证，与插入顺序无关。如果需要有序集合，可以使用 `std.collection` 中的 `TreeSet`（红黑树实现）。

### Q3: `HashMap` 的键可以为 `null` 吗？

不可以。`HashMap` 的键类型 `K` 必须实现 `Hashable` 和 `Equatable` 接口，`null` 不满足约束。

### Q4: `ArrayList` 怎么按值删除单个元素？

`ArrayList` 没有提供 `remove(value)` 方法（因为可能与 `remove(range:)` 产生歧义），但可以用 `removeIf` 配合闭包：

```cangjie
list.removeIf({x => x == target})
```

如果希望保留所有匹配的元素，注意 `ArrayList` **并没有 `retain` 方法**（`retain(all:)` 是 `HashSet` 的方法，不能用在 `ArrayList` 上）。对 `ArrayList` 想按条件保留元素，更好的写法是新建一个 `ArrayList`：

```cangjie
let kept: ArrayList<Int64> = ArrayList<Int64>()
for (x in list) {
    if (x != target) {
        kept.add(x)
    }
}
// 用 `kept` 替换原 list
```

### Q5: `HashMap` 的 `[]` 读取不存在的键会怎样？

**会触发运行时异常**，不会返回零值。要安全访问可能不存在的键，请用 `map.get(key)`（返回 `Option<V>`）配合 `getOrDefault`，或先用 `contains(key)` 判断存在再取值。

### Q6: 集合运算后修改原集合会不会影响结果集？

不会。`a | b`、`a & b`、`a - b` 都返回**新集合**，对原集合和结果集合的修改互不影响。

### Q7: 怎么判断两个集合内容相等？

`ArrayList`、`HashSet`、`HashMap` 都实现了 `Equatable<T>` 接口，可以直接用 `==` / `!=` 比较内容。`Array<T>` 也可以用 `==` 比较内容相等。

### Q8: 仓颉有栈 / 队列类型吗？

`std.collection` 提供了 `LinkedList<T>`（双向链表）、`Deque<T>`（双端队列）等，但**不在本文范围**。栈 / 队列可以用 `ArrayList` 末尾操作模拟。

## 7. 总结

1. **导入**：使用前需要 `import std.collection.ArrayList` / `HashSet` / `HashMap`。
2. **ArrayList**：动态数组，属性 `size` / `first` / `last` / `capacity`，方法 `add` / `remove` / `get` / `contains` / `toArray` / `reverse` / `clear`，配合 `std.sort.sort` 排序。
3. **HashSet**：无序不重复集合，运算符 `|` / `&` / `-` 实现并 / 交 / 差，方法 `add` / `remove` / `contains` / `subsetOf` / `retain`。
4. **HashMap**：键值映射，方法 `add` / `[]` / `contains` / `remove` / `keys()` / `values()`，`for (k, v in map)` 遍历键值对。
5. 选型：固定长度 → `Array`；动态数组 → `ArrayList`；去重 → `HashSet`；键值对 → `HashMap`。
6. 集合运算（`| & -`）返回新集合，不修改原集合。
7. `ArrayList.remove(value)` 不可用；用 `removeIf` 配合闭包按条件删除。
8. `HashMap[k]` 读取不存在的键会**抛出运行时异常**；安全访问请用 `map.get(key)`（返回 `Option<V>`）或先 `contains(key)`。

## 参考资料

1. 仓颉 1.0.5 LTS 文档索引：https://docs.cangjie-lang.cn/docs/1.0.5/
2. 仓颉 1.0.5 LTS std.collection 包总览：https://cangjie-lang.cn/docs?url=%2F1.0.5%2Flibs%2Fstd%2Fcollection%2Fcollection_package_overview.html
3. 仓颉 1.0.5 LTS ArrayList 类：https://cangjie-lang.cn/docs?url=%2F1.0.5%2Flibs%2Fstd%2Fcollection%2Farraylist.html
4. 仓颉 1.0.5 LTS HashSet 类：https://cangjie-lang.cn/docs?url=%2F1.0.5%2Flibs%2Fstd%2Fcollection%2Fhashset.html
5. 仓颉 1.0.5 LTS HashMap 类：https://cangjie-lang.cn/docs?url=%2F1.0.5%2Flibs%2Fstd%2Fcollection%2Fhashmap.html
6. 仓颉 1.0.5 LTS std.collection.concurrent 包总览：https://cangjie-lang.cn/docs?url=%2F1.0.5%2Flibs%2Fstd%2Fcollection_concurrent%2Fcollection_concurrent_package_overview.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
