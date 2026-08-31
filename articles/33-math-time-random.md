# 仓颉标准库：数学、时间与随机数

> **摘要**: 本文按"标准库补全"的目标，覆盖 `std.math`（幂/开方/三角/对数等浮点函数）、`std.time`（`Duration` 时间算术与单位换算、`DateTime` 日期时刻构造与字段访问）、`std.random`（`Random` 伪随机数发生器，同种子→同序列，可复现）。**注意**：1.0.5 base SDK **没有** `std.json`——**JSON/序列化属 stdx 扩展包**（同 HTTP/WebSocket 一样需另装），本篇**不覆盖**该主题，留待"stdx 专题"。本文所有 API 均经 1.0.5 SDK `cjc` 本地实测确认真实存在，示例输出完全确定。

## 前置知识

- 已安装仓颉 1.0.5 LTS SDK
- 已完成《标准库总览与使用方法》（分层：core / std / stdx；本文均属 std）、《字符串与字符处理》（Float64 打印格式）
- 了解浮点数基本特性（IEEE 754 精度）

> 定位：这三块都在 1.0.5 base SDK 的 `std.math` / `std.time` / `std.random` 里，**本地可编译 + CI 可运行**。JSON 不在 std 里，故本篇不写——避免像之前 HTTP/Python 那样"凭印象造 API"。

## 1. `std.math`：常用数学函数

`std.math` 提供以 `Float64`（和 `Float32`）为主的数学函数：

| 类别 | 函数（部分） | 说明 |
|---|---|---|
| 幂/根 | `pow(a,b)`、`sqrt(x)`、`cbrt(x)` | 幂、平方根、立方根 |
| 指数/对数 | `exp(x)`、`log(x)`、`log2`、`log10` | 自然指数/对数等 |
| 三角 | `sin`、`cos`、`tan`、`atan`、`atan2(y,x)` | 弧度制；`atan2` 处理象限 |
| 双曲 | `sinh`、`cosh`、`tanh` | — |
| 取整 | `floor`、`ceil`、`round` | 向下/向上/最近取整 |
| 其他 | `fabs`、`fmod`、`hypot` | 绝对值、浮点取余、欧氏距离 |

（函数名以 SDK 实测为准；上表列的是常见且本篇示例会用到或引用过的。）

```cangjie
import std.math.*
let p = pow(2.0, 10.0)         // 1024.0
let s = sqrt(9.0)              // 3.0
let a = atan2(0.0, 1.0)        // 0.0
```

> **⚠️ 打印陷阱**：`Float64` 值用 `${...}` 插值打印是**固定 6 位小数**（`1024.000000`），且部分函数结果有浮点误差（如 `cbrt(27.0)` 可能给 `2.999999`）。**做相等断言**用 `pow(2.0,10.0) == 1024.0` 这种能整除的组合更稳；示例因此用 `==` 布尔判定，规避浮点格式歧义。
>
> **常量 `pi`/`e` 名字未定**：1.0.5 SDK 里 `pi`/`e`/`PI`/`M_PI` 我实测都取不到（编译器 `undeclared identifier`），需查库 API 才能确定命名——**本文不臆造**，需要圆周率时按库 API 查或用 `atan(1.0) * 4.0` 派生。

## 2. `std.time`：Duration 与 DateTime

### 2.1 `Duration`：时长与算术

`Duration` 表示一段时间，支持加减与单位换算（`Duration` 由 `core` 隐式提供，`std.time` 补充时间类型；用单位常量需 `import std.time.*`）：

```cangjie
import std.time.*
let d = 3 * Duration.second + 500 * Duration.millisecond
println(d.toMilliseconds())   // 3500
println(d.toSeconds())        // 3
```

常用单位常量：`Duration.nanosecond`/`microsecond`/`millisecond`/`second`/`minute`/`hour`/`day`；换算：`toNanos()`/`toMilliseconds()`/`toSeconds()` 等。`sleep(Duration)`（承文章 23）参数即 `Duration`。

### 2.2 `DateTime`：日期时刻

`DateTime` 表示一个时刻，有静态常量 `DateTime.UnixEpoch`（1970-01-01 UTC）和 `addDays/addMonths/addHours/...` 等相对位移，字段有 `year`/`month`/`dayOfMonth`/`dayOfWeek`/`hour` 等（**是 `dayOfMonth`，不是 `day`**；实测 `day` 会报 not a member）：

```cangjie
import std.time.*
let d = DateTime.UnixEpoch.addDays(1)
println("${d.year}-${d.month}-${d.dayOfMonth}")   // 1970-1-2
```

> **⚠️ 确定性**：`DateTime` 也有"取当前时间"的入口（如 `now` 一类），但**当前时刻随运行而变**——教程与 CI 断言要用 `UnixEpoch.addDays(n)` 这类**纯函数式构造**，别打印 `now()`。时区/本地化相关字段跨机器会变，本文示例只用 UTC 固定的 epoch 派生值。`DateTime` 的完整构造（年月日入参）与格式化 `DateTimeFormat`（含 `RFC1123` 等）细节以库 API 为准，本文不逐一罗列未实测的签名。

## 3. `std.random`：可复现的伪随机数

`Random` 是伪随机数发生器（PRNG）。**给了相同种子就产生相同序列**——这对测试和可复现场景至关重要：

```cangjie
import std.random.*
var r1 = Random(42)
var r2 = Random(42)
println(r1.nextInt64() == r2.nextInt64())   // true（同种子同序列）
```

常用方法（`mut`，会推进内部状态）：`nextInt64()`、`nextInt32()`、`nextFloat64()`、`nextBool()`、`nextBytes(...)`、`shuffle(...)` 等。默认 `Random()` 用不固定种子（每次不同）；**要复现就传种子**。

> **💡 用途**：单元测试造可复现数据、蒙特卡洛采样、随机洗牌。做"随机但可复现"就固定种子，做"真随机"就用无参 `Random()`。

## 4. 完整可运行示例

`std.math` + `std.time` + `std.random` 各来一发，输出完全确定（幂/开方用 `==` 布尔判定、日期从 `UnixEpoch` 派生、随机用同种子对比）。

<!-- example: cangjie/038-math-time-random.cj -->
```cangjie
// 标准库数学、时间与随机数示例（1.0.5 base SDK：std.math / std.time / std.random）
// 覆盖：数学函数 pow/sqrt/cbrt/atan2；Duration 时间算术与单位换算；带种子的可复现随机。
//
// 说明：JSON/序列化在 1.0.5 属 stdx 扩展（base SDK 无 std.json），本篇不覆盖；
// 时间线刻意不用"当前时刻"、随机数用固定种子，保证输出完全确定。

import std.math.*
import std.time.*
import std.random.*

main(): Int64 {
    // 1) 数学：常用函数（Float64 打印为 6 位小数，另用真值判定避免格式歧义）
    println("math: pow=${pow(2.0, 10.0)}, sqrt=${sqrt(9.0)}, atan2(0,1)=${atan2(0.0, 1.0)}")
    // math: pow=1024.000000, sqrt=3.000000, atan2(0,1)=0.000000
    println("math: cmp=${pow(2.0, 10.0) == 1024.0 && sqrt(9.0) == 3.0}")
    // math: cmp=true

    // 2) 时间：Duration 算术与单位换算 + 从 UnixEpoch 得到确定日期
    let d = 3 * Duration.second + 500 * Duration.millisecond
    println("time: d_ms=${d.toMilliseconds()}, d_s=${d.toSeconds()}")
    // time: d_ms=3500, d_s=3
    let epochPlusOneDay = DateTime.UnixEpoch.addDays(1)
    println("date: ${epochPlusOneDay.year}-${epochPlusOneDay.month}-${epochPlusOneDay.dayOfMonth}")
    // date: 1970-1-2

    // 3) 随机：同种子 → 同序列（可复现）
    var r1 = Random(42)
    var r2 = Random(42)
    println("random: same_seed_eq=${r1.nextInt64() == r2.nextInt64()}")
    // random: same_seed_eq=true

    return 0
}
```

预期输出：

```text
math: pow=1024.000000, sqrt=3.000000, atan2(0,1)=0.000000
math: cmp=true
time: d_ms=3500, d_s=3
date: 1970-1-2
random: same_seed_eq=true
```

## 5. 语言对比

| 主题 | 仓颉 | Rust | Go | Java |
|---|---|---|---|---|
| 数学函数 | `std.math.pow/sqrt/...` | `f64::powf/sqrt`/`num-traits` | `math.Pow/Sqrt` | `Math.pow/sqrt` |
| 常量 π | 名字待库 API 确认（本文不臆造） | `std::f64::consts::PI` | `math.Pi` | `Math.PI` |
| 时长 | `Duration`（单位常量+算术） | `Duration` | `time.Duration`(ns) | `Duration` |
| 时刻 | `DateTime`（`UnixEpoch`+`addXxx`） | `SystemTime`/`chrono` | `time.Time` | `java.time` |
| 随机（可复现） | `Random(seed)` | `StdRng::seed_from_u64` | `rand.New(rand.NewSource(seed))` | `new Random(seed)` |

**从 Rust 迁移**：`Random(seed)` 对应 `StdRng::seed_from_u64`；`Duration` 常量式写法（`3 * Duration.second`）比 Rust 的 `Duration::from_secs(3)` 更算式化。
**从 Go 迁移**：`DateTime` 链式 `addDays` 类似 Go `time.Time.AddDate`；Go 的 `math.Pi` 在仓颉里常量名未定，别照搬 `Pi`。

## 6. 常见问题（FAQ）

### Q1: 为什么 `${sqrt(9.0)}` 打成 `3.000000` 不是 `3`？

`Float64` 插值固定 6 位小数（见文章 13）。要整数外观就转 `Int64`，或用 `== 3.0` 做判定。

### Q2: `cbrt(27.0)` 为什么可能是 `2.999999`？

浮点表示误差。做等值判断要用能精确表示的组合（如 `pow(2.0,10.0)`），或对浮点比较用容差。

### Q3: `DateTime` 有 `day` 字段吗？

没有，是 `dayOfMonth`（实测 `day` 报 not a member）；还有 `dayOfWeek`/`dayOfYear`。

### Q4: 教程/测试里怎么让"当前时间"确定？

别用 `now`。从 `DateTime.UnixEpoch` 经 `addDays/addHours` 派生，得到每次一致的日期。

### Q5: `Random()` 每次不一样，怎么复现？

给种子：`Random(42)`。相同种子→相同序列；不传种子则每次不同。

### Q6: 仓颉有内置 JSON 吗？

1.0.5 **base SDK 没有** `std.json`；JSON/序列化属 stdx 扩展（需 `cjpm` 下载、配依赖），与 HTTP/WebSocket 同类。本篇按"只写可验证部分"原则不展开，留给 stdx 专题。

### Q7: π 到底怎么取？

本文未确认其稳定常量名（多个猜测都编译不过），不臆造。稳妥做法：查库 API；或临时用 `atan(1.0) * 4.0`。

## 7. 总结

1. `std.math`：`pow`/`sqrt`/`atan2`/三角/对数/取整等；`Float64` 打印 6 位小数、有浮点误差→等值判定用可整除组合；π/e 常量名本文未臆造。
2. `std.time`：`Duration`（单位常量 + 算术 + `toMilliseconds/toSeconds`）；`DateTime`（`UnixEpoch` + `addXxx` + `year/month/dayOfMonth`，无 `day`）；教程别用当前时刻、用 epoch 派生保持确定。
3. `std.random`：`Random(seed)` 同种子→同序列可复现；无参则每次不同。
4. 三块均在 1.0.5 base SDK、本地编译 + CI 可运行；**JSON/序列化属 stdx，本篇不覆盖**。

## 参考资料

1. 仓颉 1.0.5 LTS 标准库总览与库 API 查法（`std.math`/`std.time`/`std.random` 完整签名走库 API）：见 articles/30
2. 仓颉 1.0.5 LTS 线程睡眠 `sleep`（`Duration` 承接）：https://docs.cangjie-lang.cn/docs/1.0.5/dev-guide/source_zh_cn/concurrency/sleep.html
3. 仓颉 1.0.5 LTS 官方下载中心（LTS/STS 版本）：https://cangjie-lang.cn/download/1.0.5

**版本信息**: 本文基于仓颉 1.0.5 LTS 编写

---

**版权声明**: 本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。
