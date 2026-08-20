# 代码示例测试规范

> 本规范定义代码示例的唯一来源、文章同步和测试流程。

## 核心决策

### 1. `examples/` 是唯一规范来源

- 所有需要测试的完整示例必须存放在 `examples/<language>/`。
- `test_output/` 不再存放或提交提取后的示例文件。
- 文章中的代码块是公众号展示内容，不能作为独立测试源。
- `articles/templates/` 是写作模板，不属于待测试文章。

### 2. 文章必须显式引用示例

完整示例的代码块前必须添加标记：

```markdown
<!-- example: cangjie/001-types.cj -->
```cangjie
// 内容必须与 examples/cangjie/001-types.cj 一致
```
```

标记路径相对于 `examples/`。文章可以引用不同语言，但扩展名、代码块语言和源文件必须匹配。

### 3. 同步检查是强制门禁

```bash
python3 .github/scripts/sync_examples.py
```

检查失败时禁止提交或推送。检查器会确认：

- 文章中的可测试代码块都有引用标记。
- 引用的源文件存在且语言匹配。
- 文章代码与源文件内容一致。
- `examples/` 中每个示例都被文章引用。

## 测试流程

### 本地

```bash
./tools/test-local.sh
```

本地脚本先执行同步检查，再直接测试 `examples/` 中的规范源文件。没有某种语言示例时安全跳过，不把空目录通配符当作文件。

仓颉在 macOS 上默认执行静态库编译检查，因为仓颉 1.0.5 native runtime 可能无法链接当前 macOS SDK；Linux 和 Windows 环境执行完整编译与运行。遇到 macOS 链接问题时，必须保留编译诊断，并在 GitHub Actions 或 Windows 上完成运行验证，不得把未验证的代码标记为通过。

### GitHub Actions

工作流文件：`.github/workflows/code-examples-test.yml`

- 只测试 `examples/` 中的规范源文件。
- 先检查文章与示例同步，再安装固定版本的仓颉 SDK。
- SDK 下载使用固定地址和 SHA-256 校验，下载失败必须使工作流失败。
- 工作流不测试没有规范源文件的语言，也不测试模板片段。

## 新增或修改示例

1. 查阅仓颉 1.0.5 LTS 官方文档，确认语法和 API。
2. 在 `examples/cangjie/` 创建或修改完整源文件。
3. 在文章中添加或更新对应代码块和 `example` 标记。
4. 运行 `python3 .github/scripts/sync_examples.py`。
5. 运行 `./tools/test-local.sh`。
6. 查看 GitHub Actions 结果后，才能进入发布流程。

修改示例时必须同时检查文章代码块；禁止只修改 `test_output/` 或只修改文章代码块。

## 通过标准

- 同步检查通过。
- 所有规范源文件在当前环境完成规定的编译检查。
- 支持运行的平台上执行结果正确。
- GitHub Actions 工作流成功。

## 相关文件

- `examples/README.md`
- `.github/scripts/sync_examples.py`
- `tools/test-local.sh`
- `.github/workflows/code-examples-test.yml`
- `docs/code-examples-guide.md`
