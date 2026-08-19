#!/bin/bash

# 仓颉编程语言学习笔记 - 本地代码测试脚本
# 用于在本地测试所有代码示例

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    local missing=()
    
    # 检查仓颉
    if ! command -v cjc &> /dev/null; then
        missing+=("cangjie (cjc)")
    fi
    
    # 检查Python
    if ! command -v python3 &> /dev/null; then
        missing+=("python3")
    fi
    
    # 检查Java
    if ! command -v java &> /dev/null; then
        missing+=("java")
    fi
    
    # 检查Go
    if ! command -v go &> /dev/null; then
        missing+=("go")
    fi
    
    # 检查Kotlin
    if ! command -v kotlinc &> /dev/null; then
        missing+=("kotlin")
    fi
    
    # 检查Rust
    if ! command -v rustc &> /dev/null; then
        missing+=("rust")
    fi
    
    # 检查C++
    if ! command -v g++ &> /dev/null; then
        missing+=("g++")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_warning "以下工具未安装:"
        for tool in "${missing[@]}"; do
            echo "  - $tool"
        done
        log_warning "某些语言的代码示例将无法测试"
    else
        log_success "所有依赖已安装"
    fi
}

# 测试仓颉代码
test_cangjie() {
    log_info "测试仓颉代码示例..."
    
    python3 .github/scripts/extract_code.py --lang cangjie --output test_output/cangjie/
    
    if [ ! -d "test_output/cangjie" ] || [ -z "$(ls -A test_output/cangjie)" ]; then
        log_warning "未找到仓颉代码示例"
        return 0
    fi
    
    local passed=0
    local failed=0
    
    for file in test_output/cangjie/*.cj; do
        echo "Testing $file..."
        if cjc "$file" -o "${file%.cj}" 2>/dev/null; then
            if grep -q "^main()" "$file"; then
                if "./${file%.cj}" 2>/dev/null; then
                    log_success "✓ $file"
                    ((passed++))
                else
                    log_error "✗ $file (运行失败)"
                    ((failed++))
                fi
            else
                log_success "✓ $file (编译成功)"
                ((passed++))
            fi
        else
            log_error "✗ $file (编译失败)"
            ((failed++))
        fi
    done
    
    log_info "仓颉测试结果: $passed 通过, $failed 失败"
    return $failed
}

# 测试Java代码
test_java() {
    log_info "测试Java代码示例..."
    
    python3 .github/scripts/extract_code.py --lang java --output test_output/java/
    
    if [ ! -d "test_output/java" ] || [ -z "$(ls -A test_output/java)" ]; then
        log_warning "未找到Java代码示例"
        return 0
    fi
    
    local passed=0
    local failed=0
    
    for file in test_output/java/*.java; do
        echo "Testing $file..."
        classname=$(basename "$file" .java)
        if javac "$file" -d test_output/java/ 2>/dev/null; then
            if java -cp test_output/java/ "$classname" 2>/dev/null; then
                log_success "✓ $file"
                ((passed++))
            else
                log_error "✗ $file (运行失败)"
                ((failed++))
            fi
        else
            log_error "✗ $file (编译失败)"
            ((failed++))
        fi
    done
    
    log_info "Java测试结果: $passed 通过, $failed 失败"
    return $failed
}

# 测试Go代码
test_go() {
    log_info "测试Go代码示例..."
    
    python3 .github/scripts/extract_code.py --lang go --output test_output/go/
    
    if [ ! -d "test_output/go" ] || [ -z "$(ls -A test_output/go)" ]; then
        log_warning "未找到Go代码示例"
        return 0
    fi
    
    local passed=0
    local failed=0
    
    for file in test_output/go/*.go; do
        echo "Testing $file..."
        if go run "$file" 2>/dev/null; then
            log_success "✓ $file"
            ((passed++))
        else
            log_error "✗ $file"
            ((failed++))
        fi
    done
    
    log_info "Go测试结果: $passed 通过, $failed 失败"
    return $failed
}

# 测试Kotlin代码
test_kotlin() {
    log_info "测试Kotlin代码示例..."
    
    python3 .github/scripts/extract_code.py --lang kotlin --output test_output/kotlin/
    
    if [ ! -d "test_output/kotlin" ] || [ -z "$(ls -A test_output/kotlin)" ]; then
        log_warning "未找到Kotlin代码示例"
        return 0
    fi
    
    local passed=0
    local failed=0
    
    for file in test_output/kotlin/*.kt; do
        echo "Testing $file..."
        jarfile="${file%.kt}.jar"
        if kotlinc "$file" -include-runtime -d "$jarfile" 2>/dev/null; then
            if java -jar "$jarfile" 2>/dev/null; then
                log_success "✓ $file"
                ((passed++))
            else
                log_error "✗ $file (运行失败)"
                ((failed++))
            fi
        else
            log_error "✗ $file (编译失败)"
            ((failed++))
        fi
    done
    
    log_info "Kotlin测试结果: $passed 通过, $failed 失败"
    return $failed
}

# 测试Rust代码
test_rust() {
    log_info "测试Rust代码示例..."
    
    python3 .github/scripts/extract_code.py --lang rust --output test_output/rust/
    
    if [ ! -d "test_output/rust" ] || [ -z "$(ls -A test_output/rust)" ]; then
        log_warning "未找到Rust代码示例"
        return 0
    fi
    
    local passed=0
    local failed=0
    
    for file in test_output/rust/*.rs; do
        echo "Testing $file..."
        if rustc "$file" -o "${file%.rs}" 2>/dev/null; then
            if "./${file%.rs}" 2>/dev/null; then
                log_success "✓ $file"
                ((passed++))
            else
                log_error "✗ $file (运行失败)"
                ((failed++))
            fi
        else
            log_error "✗ $file (编译失败)"
            ((failed++))
        fi
    done
    
    log_info "Rust测试结果: $passed 通过, $failed 失败"
    return $failed
}

# 测试C++代码
test_cpp() {
    log_info "测试C++代码示例..."
    
    python3 .github/scripts/extract_code.py --lang cpp --output test_output/cpp/
    
    if [ ! -d "test_output/cpp" ] || [ -z "$(ls -A test_output/cpp)" ]; then
        log_warning "未找到C++代码示例"
        return 0
    fi
    
    local passed=0
    local failed=0
    
    for file in test_output/cpp/*.cpp; do
        echo "Testing $file..."
        if g++ -std=c++17 "$file" -o "${file%.cpp}" 2>/dev/null; then
            if "./${file%.cpp}" 2>/dev/null; then
                log_success "✓ $file"
                ((passed++))
            else
                log_error "✗ $file (运行失败)"
                ((failed++))
            fi
        else
            log_error "✗ $file (编译失败)"
            ((failed++))
        fi
    done
    
    log_info "C++测试结果: $passed 通过, $failed 失败"
    return $failed
}

# 测试Python代码
test_python() {
    log_info "测试Python代码示例..."
    
    python3 .github/scripts/extract_code.py --lang python --output test_output/python/
    
    if [ ! -d "test_output/python" ] || [ -z "$(ls -A test_output/python)" ]; then
        log_warning "未找到Python代码示例"
        return 0
    fi
    
    local passed=0
    local failed=0
    
    for file in test_output/python/*.py; do
        echo "Testing $file..."
        if python3 "$file" 2>/dev/null; then
            log_success "✓ $file"
            ((passed++))
        else
            log_error "✗ $file"
            ((failed++))
        fi
    done
    
    log_info "Python测试结果: $passed 通过, $failed 失败"
    return $failed
}

# 生成测试报告
generate_report() {
    local total_passed=$1
    local total_failed=$2
    
    log_info "生成测试报告..."
    
    cat > test_output/test_report.md << EOF
# 代码示例测试报告

## 测试时间
$(date)

## 测试结果汇总

- **总通过数**: $total_passed
- **总失败数**: $total_failed
- **成功率**: $(( total_passed * 100 / (total_passed + total_failed) ))%

## 测试详情

详细测试结果请查看各语言的测试日志。

---
*自动生成于 $(date)*
EOF
    
    log_success "测试报告已生成: test_output/test_report.md"
}

# 主函数
main() {
    echo "=========================================="
    echo "仓颉编程语言学习笔记 - 本地代码测试"
    echo "=========================================="
    echo ""
    
    # 检查依赖
    check_dependencies
    echo ""
    
    # 创建测试输出目录
    mkdir -p test_output
    
    # 测试各种语言
    local total_passed=0
    local total_failed=0
    
    test_cangjie
    total_failed=$((total_failed + $?))
    
    test_java
    total_failed=$((total_failed + $?))
    
    test_go
    total_failed=$((total_failed + $?))
    
    test_kotlin
    total_failed=$((total_failed + $?))
    
    test_rust
    total_failed=$((total_failed + $?))
    
    test_cpp
    total_failed=$((total_failed + $?))
    
    test_python
    total_failed=$((total_failed + $?))
    
    echo ""
    echo "=========================================="
    echo "测试完成"
    echo "=========================================="
    
    # 生成报告
    generate_report $total_passed $total_failed
    
    if [ $total_failed -eq 0 ]; then
        log_success "所有代码示例测试通过！"
        exit 0
    else
        log_error "有 $total_failed 个代码示例测试失败"
        exit 1
    fi
}

# 执行主函数
main "$@"