#!/usr/bin/env python3
"""
从Markdown文章中提取指定语言的代码示例
"""

import argparse
import os
import re
from pathlib import Path

def extract_code_blocks(md_content, language):
    """从Markdown内容中提取指定语言的代码块"""
    # 匹配 ```language 开头的代码块
    pattern = rf'```{language}\n(.*?)```'
    matches = re.findall(pattern, md_content, re.DOTALL)
    return matches

def save_code_blocks(code_blocks, output_dir, extension, prefix=''):
    """保存代码块到文件"""
    os.makedirs(output_dir, exist_ok=True)
    
    for i, code in enumerate(code_blocks, 1):
        filename = f"{output_dir}/{prefix}example_{i:03d}.{extension}"
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(code.strip())
        print(f"Saved: {filename}")

def process_articles(articles_dir, language, output_dir, extension):
    """处理所有文章，提取指定语言的代码示例"""
    articles_path = Path(articles_dir)
    
    # 支持的文章目录
    article_dirs = ['drafts', 'published', 'templates']
    
    all_code_blocks = []
    
    for article_dir in article_dirs:
        dir_path = articles_path / article_dir
        if not dir_path.exists():
            continue
        
        # 查找所有Markdown文件
        for md_file in dir_path.glob('**/*.md'):
            print(f"Processing: {md_file}")
            
            with open(md_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 提取代码块
            code_blocks = extract_code_blocks(content, language)
            all_code_blocks.extend(code_blocks)
    
    # 保存代码块
    if all_code_blocks:
        save_code_blocks(all_code_blocks, output_dir, extension, prefix=f"{language}_")
        print(f"\nTotal {len(all_code_blocks)} {language} code blocks extracted")
    else:
        print(f"\nNo {language} code blocks found")

def main():
    parser = argparse.ArgumentParser(description='Extract code examples from Markdown articles')
    parser.add_argument('--lang', required=True, help='Programming language (e.g., cangjie, java, go)')
    parser.add_argument('--output', required=True, help='Output directory for extracted code')
    parser.add_argument('--articles-dir', default='articles', help='Articles directory (default: articles)')
    
    args = parser.parse_args()
    
    # 语言到文件扩展名的映射
    extension_map = {
        'cangjie': 'cj',
        'java': 'java',
        'go': 'go',
        'kotlin': 'kt',
        'swift': 'swift',
        'rust': 'rs',
        'cpp': 'cpp',
        'c': 'c',
        'zig': 'zig',
        'python': 'py',
    }
    
    extension = extension_map.get(args.lang, args.lang)
    
    print(f"Extracting {args.lang} code examples from {args.articles_dir}/")
    print(f"Output directory: {args.output}")
    print(f"File extension: {extension}")
    print()
    
    process_articles(args.articles_dir, args.lang, args.output, extension)

if __name__ == '__main__':
    main()