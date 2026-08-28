# 仓颉数组、元组与区间

> **摘要**: 数组、元组与区间是仓颉中三种最常用的复合数据结构。本文依据仓颉 1.0.5 LTS 官方文档，系统介绍 `Array<T>`（引用类型数组）、`VArray<T, $N>`（值类型数组）、`Tuple`（元组）与 `Range<T>`（区间）的定义、字面量、访问、修改与典型用法，帮助读者掌握这三种基础数据结构的使用方式。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已了解变量、函数、字符串插值
- 已了解 `struct` 与 `class` 的引用类型 / 值类型语义
- 已完成《仓颉结构类型 struct》《仓颉类类型 class》《仓颉模式匹配》

## 1. Array 引用类型数组

仓颉使用 `Array<T>` 表示数组类型，`T` 是元素类型，可以是任意类型。Array 是 struct 类型（值类型），但内部持有元素引用，因此表现为引用语义（不是 struct 的逐元素拷贝）。

### 1.1 创建 Array

#### 1.1.1 字面量

使用方括号将逗号分隔的值列表括起来即可创建 Array，编译器根据上下文自动推断元素类型：

```cangjie
let a: Array<Int64> = [0, 0, 0, 0]      // 显式标注类型
let b = ["a1", "a2", "a3"]              // 推断为 Array<String>
let empty: Array<String> = []           // 空 Array
```

元素类型不同的 Array 是不同类型，互相不能赋值：

```cangjie
var a: Array<Int64> = [1, 2, 3]
var b: Array<String> = ["x"]
// a = b   // 错误：类型不匹配
```

#### 1.1.2 构造函数

```cangjie
let empty = Array<Int64>()              // 空 Array
let zeros = Array<Int64>(3, repeat: 0)  // [0, 0, 0]
let seq = Array<Int64>(4, {i => i + 1}) // [1, 2, 3, 4]
```

`repeat` 是命名参数，所有元素都初始化为该值（不拷贝引用类型）。`{i => i + 1}` 是 lambda 初始化函数，对每个下标计算初值。

### 1.2 访问 Array

#### 1.2.1 遍历

使用 `for-in` 循环按插入顺序遍历 Array：

```cangjie
let arr = [0, 1, 2]
for (i in arr) {
    println(i)
}
```

#### 1.2.2 size 属性

```cangjie
let arr = [0, 1, 2]
println(arr.size)   // 3
```

#### 1.2.3 下标访问

使用 `arr[index]` 访问单个元素（下标类型必须是 `Int64`），非空 Array 的下标从 0 开始：

```cangjie
let arr = [10, 20, 30]
let a = arr[0]      // 10
let b = arr[1]      // 20
// let c = arr[-1] // 错误：负数下标，编译报错
// let c = arr[3]  // 错误：越界，编译报错
```

下标越界时，编译器能检查到的情况编译报错，否则运行时报异常。

#### 1.2.4 Range 切片

使用 `arr[range]` 一次性取一段子 Array：

```cangjie
let arr1 = [0, 1, 2, 3, 4, 5, 6]
let arr2 = arr1[0..5]   // [0, 1, 2, 3, 4]
let arr3 = arr1[..3]   // [0, 1, 2]，省略 start
let arr4 = arr1[2..]   // [2, 3, 4, 5, 6]，省略 end
```

### 1.3 修改 Array

Array 长度不可变（没有 add/remove 成员函数），但可以使用下标修改元素：

```cangjie
let arr = [0, 1, 2, 3, 4, 5]
arr[0] = 3
```

### 1.4 引用语义

虽然 `Array` 是 struct 类型，但其内部持有的是元素引用，因此多个变量共享同一组元素：

```cangjie
let arr1 = [0, 1, 2]
let arr2 = arr1
arr2[0] = 99
// arr1[0] 也是 99
```

> **⚠️ 注意**：Array 在赋值时不会拷贝元素；这与"struct 是值类型"的朴素印象相反，是仓颉的有意设计。

## 2. VArray 值类型数组

仓颉还提供值类型数组 `VArray<T, $N>`，其中 `$N` 是编译期确定的数组长度（通过 `$` 加字面量表示）。VArray 可以减少堆分配和 GC 压力，但**大长度 VArray 会有值拷贝开销**。

### 2.1 创建 VArray

```cangjie
var a: VArray<Int64, $3> = [1, 2, 3]
let b = VArray<Int64, $5>({i => i})      // [0, 1, 2, 3, 4]
let c = VArray<Int64, $4>(repeat: 0)     // [0, 0, 0, 0]
```

> **⚠️ 限制**：运行时后端限制下，`VArray<T, $N>` 的元素类型 `T` 或 `T` 的成员不能包含引用类型、枚举类型、Lambda 表达式（`CFunc` 除外）以及未实例化的泛型类型。

### 2.2 访问 VArray

```cangjie
var a: VArray<Int64, $3> = [1, 2, 3]
let i = a[1]      // 2
a[2] = 4          // [1, 2, 4]
let s = a.size    // 3
```

下标类型必须为 `Int64`。

## 3. Tuple 元组

元组是固定数量、固定类型的有序组合，使用 `(e1, e2, ..., eN)` 表示。

### 3.1 元组字面量

```cangjie
let x: (Int64, Float64) = (3, 3.141592)
let y: (Int64, Float64, String) = (3, 3.141592, "PI")
```

### 3.2 访问元组

使用 `t[index]` 访问，下标必须是 0 到 size-1 的整数字面量：

```cangjie
var pi = (3.14, "PI")
println(pi[0])   // 3.140000
println(pi[1])   // PI
```

### 3.3 元组的多赋值

```cangjie
var (x, y) = (1, 2)
(x, y) = (y, x)   // 交换
```

### 3.4 命名元组

可以为元组类型标记显式参数名：

```cangjie
func getFruit(): (name: String, price: Int64) {
    return ("banana", 10)
}

main() {
    let f = getFruit()
    println(f[0])   // banana
    println(f[1])   // 10
    // f.name      // 错误：参数名不能作为变量或访问
}
```

> **⚠️ 限制**：元组的参数名要么全部写，要么全部不写，不允许交替。参数名仅用于类型标注，不能作为变量或元素访问名。

### 3.5 元组的不可变性

元组定义后元素**不可更新**，但整个元组可以被覆盖替换：

```cangjie
let tuple1 = (8, false)
var tuple3 = (9, true)
tuple3 = tuple1             // 整个元组替换
// tuple3[0] = false       // 错误：tuple element can not be assigned
```

## 4. Range 区间

区间类型 `Range<T>` 用于表示拥有固定步长的序列，是泛型类型。`T` 实例化时必须支持关系操作符并可与 `Int64` 做加法，最常用的是 `Range<Int64>`。

### 4.1 区间字面量

区间字面量有两种形式：

- `start..end : step`：左闭右开区间（不包含 end）
- `start..=end : step`：左闭右闭区间（包含 end）

`step` 可省略，默认 `1`，但不能为 `0`：

```cangjie
let r1 = 0..10              // [0, 1, ..., 9]
let r2 = 0..=10             // [0, 1, ..., 10]
let r3 = 0..10 : 2          // [0, 2, 4, 6, 8]
let r4 = 10..0 : -2        // [10, 8, 6, 4, 2]
```

### 4.2 空区间

区间在以下情况为空：

- `start..end : step`：`step > 0` 且 `start >= end`，或 `step < 0` 且 `start <= end`
- `start..=end : step`：`step > 0` 且 `start > end`，或 `step < 0` 且 `start < end`

```cangjie
let empty1 = 10..0 : 1        // 空
let empty2 = 0..10 : -1       // 空
```

### 4.3 区间遍历

```cangjie
for (i in 1..=10) {
    println(i)
}
```

## 5. 一个完整示例

本示例组合了 Array 创建/访问/切片/引用语义、VArray 创建与访问、Tuple 字面量/访问/多赋值/命名、Range 字面量与 for-in 遍历：

<!-- example: cangjie/016-array-tuple-range.cj -->
```cangjie
// 数组、元组与区间示例
// 演示：Array（引用类型）创建与访问、VArray（值类型）、Tuple 字面量与访问、Range 字面量

main() {
    // 1) Array 字面量
    let a: Array<Int64> = [1, 2, 3, 4, 5]
    let b = ["a1", "a2", "a3"]                  // 推断为 Array<String>
    println("a.size = ${a.size}")
    println("b.size = ${b.size}")

    // 2) Array 构造
    let empty = Array<Int64>()
    println("empty.size = ${empty.size}")
    let zeros = Array<Int64>(3, repeat: 0)
    let seq = Array<Int64>(4, {i => i * i})      // [0, 1, 4, 9]
    println("zeros = ${zeros.size}, seq[2] = ${seq[2]}")

    // 3) 访问与修改
    println("a[0] = ${a[0]}")
    a[0] = 100
    println("a[0] (after) = ${a[0]}")

    // 4) Range 下标切片
    let s = a[0..3]                              // [100, 2, 3]
    println("slice = ${s.size}")

    // 5) Array 引用语义：共享元素
    let arr1 = [0, 1, 2]
    let arr2 = arr1
    arr2[0] = 99
    println("arr1[0] = ${arr1[0]}, arr2[0] = ${arr2[0]}")  // 都是 99

    // 6) VArray 值类型数组
    var va: VArray<Int64, $3> = [10, 20, 30]
    println("va[1] = ${va[1]}")
    va[2] = 300
    println("va[2] = ${va[2]}")
    println("va.size = ${va.size}")

    // 7) VArray 构造
    let vSeq = VArray<Int64, $5>({i => i * 2})    // [0, 2, 4, 6, 8]
    let vZero = VArray<Int64, $4>(repeat: 0)
    println("vSeq[3] = ${vSeq[3]}, vZero[0] = ${vZero[0]}")

    // 8) Tuple 字面量与访问
    let pi = (3.14, "PI")
    println("pi[0] = ${pi[0]}, pi[1] = ${pi[1]}")

    // 9) 元组多赋值
    var (x, y) = (1, 2)
    println("x = ${x}, y = ${y}")
    (x, y) = (y, x)                              // 交换
    println("after swap: x = ${x}, y = ${y}")

    // 10) 命名元组（带类型参数名）
    func getFruit(): (name: String, price: Int64) {
        return ("banana", 10)
    }
    let f = getFruit()
    println("fruit[0] = ${f[0]}, fruit[1] = ${f[1]}")

    // 11) Range 字面量
    let r1 = 0..10                                 // [0, 1, ..., 9]
    let r2 = 0..=10                                // [0, 1, ..., 10]
    let _ = (r1, r2)                                 // 占位：仅用于演示 Range 类型
    let r3 = 0..10 : 2                             // 步长 2: [0, 2, ..., 8]
    let r4 = 10..0 : -2                           // 倒序: [10, 8, ..., 2]
    println("r4 reversed:")
    for (i in r4) {
        println("  ${i}")
    }
    println("r3 step 2 elements:")
    for (i in r3) {
        println("  ${i}")
    }

    // 12) Range 遍历与 for-in
    var sum = 0
    for (i in 1..=100) {
        sum += i
    }
    println("sum 1..=100 = ${sum}")

    // 13) 空 Range
    let emptyRange = 10..0 : 1                     // 空
    var count = 0
    for (i in emptyRange) {
        count += 1
    }
    println("empty range count = ${count}")
}
```

预期输出：

```text
a.size = 5
b.size = 3
empty.size = 0
zeros = 3, seq[2] = 4
a[0] = 1
a[0] (after) = 100
slice = 3
arr1[0] = 99, arr2[0] = 99
va[1] = 20
va[2] = 300
va.size = 3
vSeq[3] = 6, vZero[0] = 0
pi[0] = 3.140000, pi[1] = PI
x = 1, y = 2
after swap: x = 2, y = 1
fruit[0] = banana, fruit[1] = 10
r3 step 2 elements:
  0
  2
  4
  6
  8
r4 reversed:
  10
  8
  6
  4
  2
sum 1..=100 = 5050
empty range count = 0
```

## 6. 常见问题

### Q1: Array 是值类型还是引用类型？

Array 是 `struct` 类型但内部持有元素引用，多个变量共享同一组元素；修改元素会影响所有引用。这与其他语言中数组的"引用类型"语义一致。

### Q2: VArray 和 Array 怎么选？

- VArray 长度固定，无堆分配，无 GC 压力；但大长度 VArray 在传递和赋值时拷贝开销大
- Array 长度不可变（没有 add/remove），但可使用丰富的成员函数
- 性能敏感的小型集合选 VArray；通用场景选 Array

### Q3: 元组可以修改元素吗？

不可以。元组元素定义后不可变，但整个元组变量可以被覆盖替换。

### Q4: 命名元组能用名字访问元素吗？

不能。`f.name` 会编译报错；只能通过 `f[0]`、`f[1]` 等下标访问。命名仅用于类型标注，提升可读性。

### Q5: Range 的 step 可以为 0 吗？

不可以。`start..end : 0` 编译报错。

### Q6: Array 下标越界会怎样？

- 编译期能识别的越界：编译报错
- 运行期越界：抛运行时异常

### Q7: 命名元组的参数名可以单独使用吗？

不可以。命名要么全部写，要么全部不写，不能交替。参数名仅用于类型标注。

### Q8: Range 能用 for-in 遍历吗？

是的。Range 支持 `for-in` 遍历，其底层遵循标准库的迭代器协议（详见标准库）。

## 7. 总结

1. `Array<T>` 是引用类型数组，长度不可变但元素可修改；内部持有元素引用，多个变量共享。
2. `VArray<T, $N>` 是值类型数组，长度由编译期常量 `$N` 决定，适合性能敏感的小型集合。
3. 元组是固定数量、固定类型的有序组合，元素不可修改但整个元组可替换；支持命名参数提升可读性。
4. Range 字面量有 `..` 和 `..=` 两种形式，步长可指定，默认为 1 且不能为 0。
5. Range 可与 `for-in`、Array 切片、`while` 循环等多种场景配合。
6. Array 的引用语义、Tuple 的不可变性、VArray 的拷贝开销是设计上的有意选择，使用时需留意。

## 参考资料

1. 仓颉 1.0.5 LTS 数组类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/array.html
2. 仓颉 1.0.5 LTS 元组类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/tuple.html
3. 仓颉 1.0.5 LTS 区间类型：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/basic_data_type/range.html

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
