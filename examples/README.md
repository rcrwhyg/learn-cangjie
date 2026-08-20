# 代码示例

`examples/` 是项目代码示例的唯一规范来源。

- 每个可测试示例只在这里维护一份源文件。
- 文章通过 `<!-- example: 路径 -->` 标记引用示例。
- 文章中的代码块必须与源文件保持同步。
- 运行 `python3 .github/scripts/sync_examples.py` 检查同步状态。
- `articles/templates/` 只存放写作模板，不参与示例测试。

新增示例时，先在 `examples/` 创建源文件，再将相同内容放入文章代码块并添加引用标记。
