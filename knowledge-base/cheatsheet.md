# 仓颉编程语言速查表

> 仓颉1.0.5 LTS版本常用语法和API速查

## 基础语法

### 变量声明
```cangjie
// 变量声明
let name = "Alice"          // 不可变变量
var age: Int64 = 25         // 可变变量
const pi: Float64 = 3.14    // 编译时常量
let list = [1, 2, 3]        // 数组字面量
let map = {"key": "value"}  // 字典字面量
```

### 数据类型
```cangjie
// 基本类型
let intVal: Int64 = 42
let floatVal: Float64 = 3.14
let float32Val: Float32 = 3.14159
let boolVal: Bool = true
let strVal: String = "hello"
let charVal: Rune = r'A'

// 集合类型
let array: Array<Int64> = [1, 2, 3]
let list: List<Int64> = [1, 2, 3]
let set: Set<Int64> = [1, 2, 3]
let map: Map<String, Int64> = {"a": 1, "b": 2}

// 可选类型
let optional: ?Int64 = 42
let optionalNull: ?Int64 = null
```

### 运算符
```cangjie
// 算术运算符
let sum = 1 + 2
let diff = 5 - 3
let product = 4 * 5
let quotient = 10 / 3
let remainder = 10 % 3

// 比较运算符
let isEqual = 1 == 1
let isNotEqual = 1 != 2
let isGreater = 5 > 3
let isLess = 3 < 5
let isGreaterOrEqual = 5 >= 5
let isLessOrEqual = 3 <= 5

// 逻辑运算符
let andResult = true && false
let orResult = true || false
let notResult = !true

// 位运算符
let bitwiseAnd = 0b1010 & 0b1100
let bitwiseOr = 0b1010 | 0b1100
let bitwiseXor = 0b1010 ^ 0b1100
let bitwiseNot = ~0b1010
let leftShift = 1 << 2
let rightShift = 8 >> 2
```

### 控制流
```cangjie
// if-else
if age >= 18 {
    println("成年人")
} else if age >= 12 {
    println("青少年")
} else {
    println("儿童")
}

// for循环
for i in 0..10 {
    println(i)
}

for item in [1, 2, 3] {
    println(item)
}

for (index, item) in [1, 2, 3].enumerated() {
    println("Index: ${index}, Value: ${item}")
}

// while循环
var count = 0
while count < 5 {
    println(count)
    count++
}

// switch-match
match value {
    case 1 => println("一")
    case 2 => println("二")
    case _ => println("其他")
}
```

## 函数

### 函数定义
```cangjie
// 基本函数
func greet(name: String): String {
    return "Hello, ${name}!"
}

// 默认参数
func greet(name: String, greeting: String = "Hello"): String {
    return "${greeting}, ${name}!"
}

// 可变参数
func sum(numbers: Int...): Int {
    var total = 0
    for number in numbers {
        total += number
    }
    return total
}

// 匿名函数
let add = { (a: Int, b: Int): Int => a + b }

// 高阶函数
func apply(a: Int, b: Int, operation: (Int, Int) -> Int): Int {
    return operation(a, b)
}

let result = apply(5, 3, { (a, b) => a + b })
```

## 面向对象

### 类定义
```cangjie
// 类定义
class Person {
    let name: String
    var age: Int
    
    init(name: String, age: Int) {
        this.name = name
        this.age = age
    }
    
    func introduce(): String {
        return "我叫${name}，今年${age}岁"
    }
}

// 继承
class Student extends Person {
    let school: String
    
    init(name: String, age: Int, school: String) {
        super.init(name, age)
        this.school = school
    }
    
    override func introduce(): String {
        return super.introduce() + "，在${school}上学"
    }
}

// 接口
interface Drawable {
    func draw(): Unit
}

class Circle implements Drawable {
    func draw() {
        println("画圆")
    }
}
```

## 并发编程

### 协程
```cangjie
// 协程创建
let future = spawn {
    // 异步任务
    println("在协程中执行")
    return 42
}

// 等待结果
let result = future.get()

// 协程通信
let channel = Channel<Int>(10)
spawn {
    channel.send(42)
}
let value = channel.receive()
```

## 错误处理

### 异常处理
```cangjie
// try-catch
try {
    let result = riskyOperation()
    println(result)
} catch e: Exception {
    println("错误: ${e.message}")
}

// Result类型
func divide(a: Int, b: Int): Result<Int, String> {
    if b == 0 {
        return Result.Err("除数不能为零")
    }
    return Result.Ok(a / b)
}

match divide(10, 2) {
    case Result.Ok(value) => println("结果: ${value}")
    case Result.Err(error) => println("错误: ${error}")
}
```

## 模块系统

### 模块导入
```cangjie
// 导入模块
import std.collection.*
import std.io.*

// 导入特定项
import std.collection.List
import std.io.println

// 模块定义
module mymodule {
    export func myFunction(): Unit {
        println("我的函数")
    }
}
```

## 常用API

### 字符串操作
```cangjie
let str = "Hello, World!"

// 字符串方法
let length = str.length()
let upper = str.toUpperCase()
let lower = str.toLowerCase()
let substring = str.substring(0, 5)
let replaced = str.replace("World", "Cangjie")
let split = str.split(", ")
let trimmed = str.trim()
let contains = str.contains("World")
let startsWith = str.startsWith("Hello")
let endsWith = str.endsWith("!")
```

### 数组操作
```cangjie
let array = [1, 2, 3, 4, 5]

// 数组方法
let length = array.length()
let first = array.first()
let last = array.last()
let reversed = array.reversed()
let sorted = array.sorted()
let mapped = array.map({ x => x * 2 })
let filtered = array.filter({ x => x > 3 })
let sum = array.reduce(0, { acc, x => acc + x })
let contains = array.contains(3)
let indexOf = array.indexOf(3)
```

### 文件操作
```cangjie
import std.fs.*

// 读取文件
let content = File.readToString("file.txt")

// 写入文件
File.writeString("file.txt", "Hello, Cangjie!")

// 文件信息
let exists = File.exists("file.txt")
let size = File.size("file.txt")
```

### 网络操作
```cangjie
import std.net.*

// HTTP请求
let response = HttpClient.get("https://api.example.com/data")
let body = response.body()
let status = response.statusCode()
```

## 类型转换

### 基本转换
```cangjie
// 数字转换
let intVal = 42
let floatVal = intVal.toFloat()
let doubleVal = intVal.toDouble()
let strVal = intVal.toString()

// 字符串转换
let str = "42"
let intVal = str.toInt()
let floatVal = str.toFloat()

// 安全转换
let str = "abc"
let intVal = str.toIntOrNull()  // 返回null
```

## 模式匹配

### 匹配表达式
```cangjie
// 基本匹配
match value {
    case 1 => println("一")
    case 2 => println("二")
    case _ => println("其他")
}

// 类型匹配
match obj {
    case s: String => println("字符串: ${s}")
    case i: Int => println("整数: ${i}")
    case _ => println("其他类型")
}

// 解构匹配
match point {
    case (0, 0) => println("原点")
    case (x, 0) => println("在x轴上: ${x}")
    case (0, y) => println("在y轴上: ${y}")
    case (x, y) => println("点: (${x}, ${y})")
}
```

## 泛型

### 泛型定义
```cangjie
// 泛型函数
func identity<T>(value: T): T {
    return value
}

// 泛型类
class Box<T> {
    let value: T
    
    init(value: T) {
        this.value = value
    }
    
    func getValue(): T {
        return value
    }
}

// 泛型约束
func print<T: ToString>(value: T) {
    println(value.toString())
}
```

## 注解

### 常用注解
```cangjie
// 重写注解
class Child extends Parent {
    @Override
    func method(): Unit {
        // 实现
    }
}

// 废弃注解
@Deprecated("使用newMethod代替")
func oldMethod(): Unit {
    // 实现
}

// 单元测试
@Test
func testAddition() {
    assert(add(1, 2) == 3)
}
```

## 常用模式

### 单例模式
```cangjie
class Database {
    static let instance = Database()
    
    private init() {}
    
    func query(sql: String): Unit {
        println("执行查询: ${sql}")
    }
}

// 使用
Database.instance.query("SELECT * FROM users")
```

### 工厂模式
```cangjie
interface Animal {
    func speak(): String
}

class Dog implements Animal {
    func speak(): String {
        return "汪汪"
    }
}

class Cat implements Animal {
    func speak(): String {
        return "喵喵"
    }
}

class AnimalFactory {
    static func create(type: String): Animal {
        match type {
            case "dog" => return Dog()
            case "cat" => return Cat()
            case _ => throw Exception("未知动物类型")
        }
    }
}
```

### 观察者模式
```cangjie
interface Observer {
    func update(message: String): Unit
}

class Subject {
    private var observers: List<Observer> = []
    
    func attach(observer: Observer) {
        observers.append(observer)
    }
    
    func detach(observer: Observer) {
        observers.remove(observer)
    }
    
    func notify(message: String) {
        for observer in observers {
            observer.update(message)
        }
    }
}
```

## 性能优化

### 内存优化
```cangjie
// 使用值类型
struct Point {
    let x: Double
    let y: Double
}

// 避免不必要的装箱
let primitive = 42  // 值类型
let boxed: Any = 42  // 引用类型

// 使用StringBuilder
let builder = StringBuilder()
for i in 0..1000 {
    builder.append(i.toString())
}
let result = builder.toString()
```

### 并发优化
```cangjie
// 使用线程池
let executor = Executors.newFixedThreadPool(4)

for i in 0..10 {
    executor.submit({
        println("任务${i}在${Thread.currentThread().name}执行")
    })
}

executor.shutdown()
```

---

*本速查表基于仓颉1.0.5 LTS版本，将随版本更新而更新*
