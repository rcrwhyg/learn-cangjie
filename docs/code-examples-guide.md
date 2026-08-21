# 代码示例编写指南

> 本文档说明如何编写可测试的代码示例

## 唯一来源与同步

完整可测试示例统一维护在 `examples/<language>/`，文章只负责展示。文章中的代码块必须在代码块前标记对应源文件：

```markdown
<!-- example: cangjie/001-types.cj -->
```cangjie
// 与 examples/cangjie/001-types.cj 完全一致
```
```

`example` 标记是同步工具使用的维护信息，不需要在面向读者的正文中重复说明规范源文件路径。正文应优先描述读者正在创建或运行的文件，例如 `hello.cj`；仓库内部目录和同步机制只在本指南或协作规范中说明。

不要把示例写入 `test_output/`；该目录只用于临时产物，且不应提交。`articles/templates/` 中的演示片段只用于说明文章结构，不参与自动测试。

修改示例时，先修改 `examples/` 源文件，再同步文章代码块，并运行：

```bash
python3 .github/scripts/sync_examples.py
```

## 核心原则

### 1. 可运行性
- 所有代码示例必须能够编译和运行
- 代码示例应该是完整的，不依赖外部文件
- 代码示例应该有明确的输出

### 2. 可测试性
- 代码示例应该能够被自动化测试
- 代码示例应该有预期的输出
- 代码示例应该能够验证正确性

### 3. 可读性
- 代码示例应该清晰易懂
- 代码示例应该有适当的注释
- 代码示例应该遵循语言规范

## 代码示例结构

### 基本结构

```cangjie
// 文件说明：示例代码的用途和说明

// 导入语句
import std.collection.*

// 主函数
main() {
    // 示例代码
    println("Hello, Cangjie!")
}
```

### 完整示例

```cangjie
// 示例：变量和数据类型
// 本示例演示仓颉的基本变量声明和数据类型

// 主函数
main() {
    // 变量声明
    let name = "Alice"
    let age: Int = 25
    let height: Float = 1.68
    
    // 输出结果
    println("姓名: ${name}")
    println("年龄: ${age}")
    println("身高: ${height}米")
    
    // 预期输出:
    // 姓名: Alice
    // 年龄: 25
    // 身高: 1.68米
}
```

## 语言特定规范

### 仓颉

#### 文件命名
- 使用小写字母和下划线
- 示例：`hello_world.cj`

#### 代码结构
```cangjie
// 1. 文件注释
// 2. 导入语句
// 3. 类型定义
// 4. 函数定义
// 5. 主函数
```

#### 注释规范
```cangjie
// 单行注释

/*
 * 多行注释
 */

/// 文档注释
func example() {
    // 函数体
}
```

### Java

#### 文件命名
- 使用PascalCase
- 示例：`HelloWorld.java`

#### 代码结构
```java
// 1. 包声明（可选）
// 2. 导入语句
// 3. 类定义
// 4. 主方法
```

#### 示例
```java
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
```

### Golang

#### 文件命名
- 使用小写字母和下划线
- 示例：`hello_world.go`

#### 代码结构
```go
// 1. 包声明
// 2. 导入语句
// 3. 类型定义
// 4. 函数定义
// 5. 主函数
```

#### 示例
```go
package main

import "fmt"

func main() {
    fmt.Println("Hello, World!")
}
```

### Kotlin

#### 文件命名
- 使用PascalCase
- 示例：`HelloWorld.kt`

#### 代码结构
```kotlin
// 1. 包声明（可选）
// 2. 导入语句
// 3. 类定义
// 4. 主函数
```

#### 示例
```kotlin
fun main() {
    println("Hello, World!")
}
```

### Swift

#### 文件命名
- 使用PascalCase
- 示例：`HelloWorld.swift`

#### 代码结构
```swift
// 1. 导入语句
// 2. 类型定义
// 3. 函数定义
// 4. 主代码
```

#### 示例
```swift
import Foundation

print("Hello, World!")
```

### Rust

#### 文件命名
- 使用小写字母和下划线
- 示例：`hello_world.rs`

#### 代码结构
```rust
// 1. 导入语句
// 2. 类型定义
// 3. 函数定义
// 4. 主函数
```

#### 示例
```rust
fn main() {
    println!("Hello, World!");
}
```

### C++

#### 文件命名
- 使用小写字母和下划线
- 示例：`hello_world.cpp`

#### 代码结构
```cpp
// 1. 头文件包含
// 2. 类型定义
// 3. 函数定义
// 4. 主函数
```

#### 示例
```cpp
#include <iostream>

int main() {
    std::cout << "Hello, World!" << std::endl;
    return 0;
}
```

### Python

#### 文件命名
- 使用小写字母和下划线
- 示例：`hello_world.py`

#### 代码结构
```python
# 1. 导入语句
# 2. 类型定义
# 3. 函数定义
# 4. 主代码
```

#### 示例
```python
def main():
    print("Hello, World!")

if __name__ == "__main__":
    main()
```

## 在Markdown中使用代码示例

### 基本语法

```markdown
```language
// 代码内容
```
```

### 仓颉示例

```markdown
<!-- example: cangjie/001-types.cj -->
```cangjie
main() {
    println("Hello, Cangjie!")
}
```
```

### Java示例

```markdown
```java
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
```
```

### Golang示例

```markdown
```go
package main

import "fmt"

func main() {
    fmt.Println("Hello, World!")
}
```
```

## 测试代码示例

### 本地测试

```bash
python3 .github/scripts/sync_examples.py
./tools/test-local.sh
```

### 自动化测试

使用GitHub Actions自动测试 `examples/` 中的规范源文件：

```bash
# 查看最近一次工作流
gh run list --workflow "Test Code Examples.yml" --limit 5
```

## 常见问题

### Q: 代码示例无法编译怎么办？
A: 
1. 检查语法是否正确
2. 确认使用的语言版本是否正确
3. 查看编译错误信息并修复
4. 参考官方文档

### Q: 代码示例无法运行怎么办？
A:
1. 检查是否有main函数
2. 确认依赖是否正确安装
3. 查看运行时错误信息
4. 参考语言文档

### Q: 如何确保代码示例的质量？
A:
1. 本地测试代码示例
2. 使用自动化测试工具
3. 请他人审查代码
4. 参考最佳实践

## 最佳实践

### 1. 代码示例设计
- 保持代码示例简洁
- 专注于演示一个概念
- 提供清晰的注释
- 使用有意义的变量名

### 2. 测试代码示例
- 在发布前测试所有代码示例
- 使用自动化测试工具
- 定期运行测试
- 修复失败的测试

### 3. 维护代码示例
- 定期更新代码示例
- 跟进语言版本更新
- 修复发现的问题
- 改进代码质量

## 相关文档

- [GitHub Actions说明](../.github/README.md)
- [本地测试脚本](../tools/test-local.sh)
- [示例同步检查脚本](../.github/scripts/sync_examples.py)

---

*本文档将根据实际情况不断完善*
