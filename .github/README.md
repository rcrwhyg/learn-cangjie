# GitHub Actions 工作流说明

## 代码示例测试

工作流文件：`.github/workflows/code-examples-test.yml`

工作流在以下事件触发：

- 推送到 `main` 或 `draft`
- 创建或更新 Pull Request
- 手动触发

## 测试内容

工作流只测试 `examples/` 中的规范源文件，不扫描文章和模板目录。执行顺序为：

1. 检查 `examples/` 与草稿、已发布文章的同步关系。
2. 下载并校验仓颉 1.0.5 LTS Linux SDK。
3. 编译并运行规范示例。

这样可以避免把 Java/Go 对比片段或模板占位代码误判为独立程序，也避免没有示例的语言因通配符失败。

## 本地复现

```bash
# 检查文章和规范源同步
python3 .github/scripts/sync_examples.py

# 执行本地测试
./tools/test-local.sh
```

`tools/test-local.sh` 与 Actions 使用相同的 `examples/` 目录。macOS 上对仓颉执行静态库编译检查；Linux 和 Windows 执行完整编译运行。

## 微信发布器测试

工作流文件：`.github/workflows/wechat-publisher-test.yml`

该工作流在发布器代码、文章或规范示例变化时执行：

- `npm ci`
- 文章与示例同步检查
- TypeScript 类型检查
- Vitest 单元测试和 V8 覆盖率
- TypeScript 构建

普通 CI 不调用真实微信公众号 API；真实接口测试必须显式配置凭证后单独执行。

## 新增示例

1. 在 `examples/<language>/` 创建完整、可运行的源文件。
2. 在草稿或已发布文章的代码块前添加：

   `<!-- example: <language>/<file> -->`

3. 将源文件内容同步到文章代码块。
4. 运行同步检查和本地测试。

## 故障处理

- 同步失败：检查标记路径、语言名称和代码内容是否一致。
- SDK 下载失败：检查工作流中的固定下载地址和 SHA-256，不能改为忽略错误。
- macOS 链接失败：保留本地编译诊断，并使用 Linux Actions 或 Windows 环境完成运行验证。
- Actions 失败：查看失败 job 日志，修复根因后重新运行，禁止仅通过跳过测试绕过失败。
