#!/bin/bash

# 仓颉编程语言学习笔记 - Git钩子安装脚本
# 自动安装项目所需的Git钩子

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Git钩子安装脚本"
echo "=========================================="
echo ""

# 检查是否在项目根目录
if [ ! -d ".git" ]; then
    echo -e "${RED}[ERROR]${NC} 当前目录不是Git仓库"
    echo "请确保您在项目根目录"
    exit 1
fi

# 检查.git/hooks目录
if [ ! -d ".git/hooks" ]; then
    echo -e "${RED}[ERROR]${NC} .git/hooks目录不存在"
    exit 1
fi

echo -e "${BLUE}[INFO]${NC} 开始安装Git钩子..."
echo ""

# 安装pre-push钩子
if [ -f "hooks/pre-push" ]; then
    echo -e "${BLUE}[INFO]${NC} 安装pre-push钩子..."
    
    # 复制钩子文件
    cp hooks/pre-push .git/hooks/pre-push
    
    # 添加执行权限
    chmod +x .git/hooks/pre-push
    
    echo -e "${GREEN}[SUCCESS]${NC} pre-push钩子安装成功"
else
    echo -e "${YELLOW}[WARNING]${NC} 未找到hooks/pre-push文件"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}[SUCCESS]${NC} Git钩子安装完成！"
echo "=========================================="
echo ""
echo "现在，当您执行 'git push' 时，会自动运行代码测试"
echo "如果测试失败，推送将被阻止"
echo ""
echo "如需跳过测试（不推荐），请使用: git push --no-verify"
echo ""