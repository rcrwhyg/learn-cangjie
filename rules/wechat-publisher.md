# 微信公众号发布器约束

## 架构约束

- 当前唯一实现语言是 Node.js + TypeScript。
- `tools/wechat-publisher/src/core/` 是唯一业务实现层。
- CLI 和 MCP Server 只能调用 Core API。
- 不在 CLI 或 MCP Tool 中直接拼接微信 API 请求。
- 不在 CLI 或 MCP Tool 中复制 Markdown 排版逻辑。
- Core 不直接依赖原生数据库扩展；存储必须通过可替换接口接入。
- 第一阶段禁止实现自动群发。

## 文章约束

- 发布前必须通过项目的 `examples/` 同步检查。
- 发布来源优先使用文章路径，不接受未经校验的任意文件路径。
- 文章必须有标题，摘要和作者可以为空。
- 公众号 HTML 必须使用内联 CSS。
- 正文本地图片必须先上传微信，再写入草稿。

## 凭证约束

- 禁止把 `WECHAT_APP_ID`、`WECHAT_APP_SECRET`、Token 写入 Git。
- 禁止在日志中输出 Secret、Token 和完整 Authorization 信息。
- 微信 API 请求必须设置超时。
- 只允许有限次数重试，不得无限重试写操作。
- 草稿写操作必须支持 dry-run 或明确确认。

## Tool 约束

- Tool 输入使用 Zod schema 校验。
- Tool 输出使用稳定的结构化 JSON。
- `create_wechat_draft` 不得执行正式发布。
- 删除和更新草稿必须要求明确的 `media_id`。
- 错误信息必须说明 API 错误码和可执行的解决建议。

## 测试约束

- Renderer、TokenStore、微信 API Client 和 DraftService 必须有单元测试。
- 真实微信 API 只允许通过显式集成测试执行。
- 默认测试必须使用 Mock API，不得依赖真实凭证。
- MCP Server 必须测试 Tool schema 和 Core API 映射。
- CLI 必须测试 dry-run 和错误退出码。
- 默认依赖必须支持当前 Node.js LTS/最新环境安装。
- `npm run test:coverage` 必须生成覆盖率报告。
- pre-commit 必须执行发布器的类型检查和单元测试。
- GitHub Actions 必须执行安装、同步检查、类型检查、覆盖率测试和构建。
- 真实微信 API 集成测试必须显式启用，不能在普通 CI 中隐式调用。
