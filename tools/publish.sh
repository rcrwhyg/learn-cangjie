#!/bin/bash

# 仓颉编程语言学习笔记 - 文章发布脚本
# 用于自动化文章发布流程

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
    
    if ! command -v git &> /dev/null; then
        log_error "Git未安装，请先安装Git"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        log_warning "Python3未安装，某些功能可能不可用"
    fi
    
    log_success "依赖检查完成"
}

# 检查Git状态
check_git_status() {
    log_info "检查Git状态..."
    
    if [ -n "$(git status --porcelain)" ]; then
        log_warning "工作目录不干净，请先提交或暂存更改"
        git status
        read -p "是否继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log_success "Git状态检查完成"
}

# 验证文章格式
validate_article() {
    local article_file=$1
    
    log_info "验证文章格式: $article_file"
    
    if [ ! -f "$article_file" ]; then
        log_error "文章文件不存在: $article_file"
        return 1
    fi
    
    # 检查文件扩展名
    if [[ ! "$article_file" =~ \.md$ ]]; then
        log_error "文章文件必须是Markdown格式(.md)"
        return 1
    fi
    
    # 检查文件大小
    local file_size=$(wc -c < "$article_file")
    if [ "$file_size" -lt 1000 ]; then
        log_warning "文章文件过小，可能内容不完整"
    fi
    
    # 检查标题
    if ! grep -q "^#" "$article_file"; then
        log_warning "文章缺少标题"
    fi
    
    # 检查摘要
    if ! grep -q "^>" "$article_file"; then
        log_warning "文章缺少摘要"
    fi
    
    # 检查代码块
    if ! grep -q '```cangjie' "$article_file"; then
        log_warning "文章缺少仓颉代码示例"
    fi
    
    log_success "文章格式验证完成"
    return 0
}

# 生成文章摘要
generate_summary() {
    local article_file=$1
    local summary_file="${article_file%.md}_summary.txt"
    
    log_info "生成文章摘要..."
    
    # 提取摘要部分
    awk '/^>/{print; exit}' "$article_file" > "$summary_file"
    
    if [ -s "$summary_file" ]; then
        log_success "摘要已生成: $summary_file"
    else
        log_warning "未能提取摘要，请手动添加"
    fi
}

# 更新文章状态
update_article_status() {
    local article_file=$1
    local status=$2
    
    log_info "更新文章状态: $status"
    
    # 创建状态文件
    local status_file="${article_file%.md}.status"
    echo "$status" > "$status_file"
    
    log_success "文章状态已更新"
}

# 提交更改
commit_changes() {
    local message=$1
    
    log_info "提交更改..."
    
    git add .
    
    if [ -n "$(git diff --cached --name-only)" ]; then
        git commit -m "$message"
        log_success "更改已提交"
    else
        log_warning "没有更改需要提交"
    fi
}

# 推送到远程
push_to_remote() {
    local branch=${1:-main}
    
    log_info "推送到远程分支: $branch"
    
    git push origin "$branch"
    
    log_success "已推送到远程"
}

# 创建标签
create_tag() {
    local tag_name=$1
    local tag_message=$2
    
    log_info "创建标签: $tag_name"
    
    git tag -a "$tag_name" -m "$tag_message"
    git push origin "$tag_name"
    
    log_success "标签已创建并推送"
}

# 生成发布报告
generate_release_report() {
    local article_file=$1
    local report_file="release_report_$(date +%Y%m%d_%H%M%S).md"
    
    log_info "生成发布报告..."
    
    cat > "$report_file" << EOF
# 文章发布报告

## 基本信息
- **文章文件**: $article_file
- **发布时间**: $(date)
- **Git提交**: $(git rev-parse --short HEAD)
- **分支**: $(git branch --show-current)

## 文章内容
$(head -20 "$article_file")

## 变更记录
$(git log --oneline -5)

## 下一步
- [ ] 检查文章在公众号中的显示效果
- [ ] 收集读者反馈
- [ ] 规划下一篇文章

---
*自动生成于 $(date)*
EOF
    
    log_success "发布报告已生成: $report_file"
}

# 主函数
main() {
    local article_file=$1
    local action=${2:-"validate"}
    
    echo "=========================================="
    echo "仓颉编程语言学习笔记 - 文章发布工具"
    echo "=========================================="
    
    # 检查依赖
    check_dependencies
    
    # 检查Git状态
    check_git_status
    
    case "$action" in
        "validate")
            if [ -z "$article_file" ]; then
                log_error "请指定文章文件"
                exit 1
            fi
            validate_article "$article_file"
            ;;
        "publish")
            if [ -z "$article_file" ]; then
                log_error "请指定文章文件"
                exit 1
            fi
            
            # 验证文章
            if ! validate_article "$article_file"; then
                log_error "文章验证失败"
                exit 1
            fi
            
            # 生成摘要
            generate_summary "$article_file"
            
            # 更新状态
            update_article_status "$article_file" "published"
            
            # 提交更改
            commit_changes "feat(article): 发布文章 $(basename "$article_file" .md)"
            
            # 推送到远程
            push_to_remote
            
            # 生成发布报告
            generate_release_report "$article_file"
            
            log_success "文章发布完成！"
            ;;
        "draft")
            if [ -z "$article_file" ]; then
                log_error "请指定文章文件"
                exit 1
            fi
            
            # 更新状态
            update_article_status "$article_file" "draft"
            
            # 提交更改
            commit_changes "draft(article): 保存文章草稿 $(basename "$article_file" .md)"
            
            log_success "文章草稿已保存"
            ;;
        "help")
            echo "用法: $0 <文章文件> [动作]"
            echo ""
            echo "动作:"
            echo "  validate  - 验证文章格式（默认）"
            echo "  publish   - 发布文章"
            echo "  draft     - 保存为草稿"
            echo "  help      - 显示帮助信息"
            echo ""
            echo "示例:"
            echo "  $0 articles/01-variables-and-types.md validate"
            echo "  $0 articles/01-variables-and-types.md publish"
            echo "  $0 articles/01-variables-and-types.md draft"
            ;;
        *)
            log_error "未知动作: $action"
            echo "使用 '$0 help' 查看帮助信息"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"