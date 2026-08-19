# GitHub Actions 工作流说明

> 本文档说明如何使用GitHub Actions进行自动化测试

## 工作流列表

### 1. 代码示例测试 (code-examples-test.yml)

**功能**: 自动测试所有文章中的代码示例

**触发条件**:
- 推送到main或draft分支
- 创建Pull Request
- 手动触发

**测试语言**:
- 仓颉 (Cangjie)
- Java
- Golang
- Kotlin
- Swift
- Rust
- C++
- Zig
- Python

**工作流程**:
1. 从Markdown文章中提取代码示例
2. 编译并运行每个代码示例
3. 生成测试报告
4. 上传测试结果

## 本地测试

### 使用本地测试脚本

```bash
# 运行本地测试
./tools/test-local.sh
```

### 测试特定语言

```bash
# 只测试仓颉代码
python3 .github/scripts/extract_code.py --lang cangjie --output test_output/cangjie/

# 只测试Java代码
python3 .github/scripts/extract_code.py --lang java --output test_output/java/
```

## 代码提取脚本

### extract_code.py

**功能**: 从Markdown文章中提取指定语言的代码块

**用法**:
```bash
python3 .github/scripts/extract_code.py --lang <language> --output <output_dir>
```

**参数**:
- `--lang`: 编程语言（必需）
- `--output`: 输出目录（必需）
- `--articles-dir`: 文章目录（默认: articles）

**支持的语言**:
- `cangjie` - 仓颉
- `java` - Java
- `go` - Golang
- `kotlin` - Kotlin
- `swift` - Swift
- `rust` - Rust
- `cpp` - C++
- `zig` - Zig
- `python` - Python

## 测试环境要求

### 必需工具
- Git
- Python 3.11+
- Bash

### 语言特定要求

#### 仓颉
- 仓颉SDK 1.0.5 LTS
- cjc编译器

#### Java
- JDK 21+
- javac编译器

#### Golang
- Go 1.22+

#### Kotlin
- Kotlin编译器
- JVM

#### Swift
- Xcode命令行工具（macOS）
- Swift编译器

#### Rust
- Rust工具链
- rustc编译器

#### C++
- g++编译器
- C++17支持

#### Zig
- Zig 0.11.0+

#### Python
- Python 3.11+

## 测试流程

### 1. 提取代码示例

从Markdown文章中提取指定语言的代码块：

```python
# 示例：提取仓颉代码
python3 .github/scripts/extract_code.py \
  --lang cangjie \
  --output test_output/cangjie/
```

### 2. 编译代码

编译提取的代码示例：

```bash
# 仓颉
cjc example.cj -o example

# Java
javac Example.java

# Golang
go build example.go

# Kotlin
kotlinc example.kt -include-runtime -d example.jar

# Rust
rustc example.rs -o example

# C++
g++ -std=c++17 example.cpp -o example

# Zig
zig build-exe example.zig
```

### 3. 运行代码

运行编译后的程序：

```bash
# 仓颉
./example

# Java
java -cp . Example

# Golang
./example

# Kotlin
java -jar example.jar

# Rust
./example

# C++
./example

# Zig
./example
```

### 4. 验证结果

检查程序输出是否符合预期。

## 测试报告

### 报告格式

测试完成后，会生成测试报告：

```markdown
# 代码示例测试报告

## 测试时间
2024-01-XX XX:XX:XX

## 测试结果汇总

- **总通过数**: XX
- **总失败数**: XX
- **成功率**: XX%

## 测试详情

| 语言 | 通过 | 失败 | 成功率 |
|------|------|------|--------|
| 仓颉 | XX | XX | XX% |
| Java | XX | XX | XX% |
| ... | ... | ... | ... |

---
*自动生成于 2024-01-XX*
```

### 查看报告

- **GitHub Actions**: 在Actions页面查看测试结果
- **本地测试**: 查看 `test_output/test_report.md`

## 故障排除

### 常见问题

#### 1. 仓颉编译器未找到

**问题**: `cjc: command not found`

**解决方案**:
```bash
# 检查仓颉SDK是否安装
cjc --version

# 如果未安装，下载并安装仓颉SDK
wget https://cangjie-lang.cn/download/1.0.5/cangjie-1.0.5-linux-x64.tar.gz
tar -xzf cangjie-1.0.5-linux-x64.tar.gz
export PATH=$PATH:/path/to/cangjie/bin
```

#### 2. 代码示例提取失败

**问题**: 没有提取到任何代码示例

**解决方案**:
- 检查Markdown文件中的代码块格式是否正确
- 确认代码块语言标识是否正确
- 查看extract_code.py的日志输出

#### 3. 编译错误

**问题**: 代码示例编译失败

**解决方案**:
- 检查代码语法是否正确
- 确认使用的语言版本是否正确
- 查看编译错误信息并修复

## 最佳实践

### 1. 定期测试

- 每次提交前运行本地测试
- 定期运行完整测试
- 关注测试结果

### 2. 代码示例规范

- 确保代码示例完整可运行
- 添加必要的注释
- 使用正确的语言标识
- 遵循代码风格规范

### 3. 测试覆盖率

- 确保所有文章中的代码示例都被测试
- 添加新文章时更新测试
- 定期检查测试覆盖率

## 相关文档

- [GitHub Actions文档](https://docs.github.com/en/actions)
- [项目README](../README.md)
- [贡献指南](../CONTRIBUTING.md)

---

*本文档将根据实际情况不断完善*