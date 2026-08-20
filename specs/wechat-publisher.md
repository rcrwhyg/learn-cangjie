# 微信公众号发布器技术设计

## 1. 决策

本项目采用 Node.js + TypeScript 实现微信公众号发布能力，不引入 Rust 实现。系统以 MCP Server 为 AI Agent 的主要入口，同时提供 CLI 作为人工操作、调试和自动化流水线入口。

核心业务能力位于独立 Core Library，CLI 和 MCP Server 只能调用核心库，不得各自实现排版或微信 API 逻辑。

## 2. 目标

- 将项目 Markdown 文章转换为微信公众号兼容 HTML。
- 使用内联 CSS 统一文章样式。
- 上传封面图和正文图片。
- 创建、查询、更新和删除微信公众号草稿。
- 为 AI Agent 提供本地 `stdio` MCP Server。
- 为未来 Web、桌面端和自动化流水线保留稳定的 TypeScript API。

第一阶段只创建草稿，不执行正式群发。

## 3. 目录

```text
tools/wechat-publisher/
├── src/
│   ├── core/       # 文章、渲染、图片、微信 API 和存储
│   ├── cli/        # CLI 适配层
│   └── mcp/        # MCP 适配层
├── test/
├── styles/
├── package.json
└── tsconfig.json
```

## 4. 运行时

- Node.js 22+，当前开发环境为 Node.js 26。
- TypeScript。
- pnpm 或 npm。
- `markdown-it` 解析 Markdown。
- `juice` 将 CSS 内联到 HTML。
- `sharp` 处理图片元数据和格式。
- `@modelcontextprotocol/sdk` 提供 MCP Server。
- `commander` 提供 CLI。
- Vitest 和 V8 provider 提供单元测试和覆盖率。
- 存储通过接口隔离；第一版使用纯 Node.js JSON 文件，避免 Node.js 版本和原生扩展兼容问题。

## 5. 数据流

```text
文章路径或 Markdown
  -> 文章校验
  -> examples/ 同步校验
  -> Markdown AST
  -> 公众号 HTML
  -> CSS 内联
  -> 正文图片上传和 URL 替换
  -> 封面素材上传
  -> draft/add
```

正文图片使用微信 `media/uploadimg`，封面图使用永久素材接口获得 `thumb_media_id`。`access_token` 必须缓存并在过期前刷新。

## 6. Core API

核心库至少提供：

- `validateArticle`
- `renderArticle`
- `uploadImage`
- `uploadCover`
- `createDraft`
- `listDrafts`
- `getDraft`
- `updateDraft`
- `deleteDraft`

Core API 不依赖 MCP，不向终端输出日志，不读取 MCP 配置。

## 7. CLI

```bash
wechat-publisher validate article.md
wechat-publisher render article.md --output preview.html
wechat-publisher preview article.md
wechat-publisher draft article.md --cover cover.png --dry-run
wechat-publisher drafts list
wechat-publisher drafts get <media-id>
wechat-publisher drafts update <media-id> article.md --cover cover.png
wechat-publisher drafts delete <media-id>
```

CLI 是 Core API 的适配层，不得复制业务逻辑。

## 8. MCP Tools

- `validate_wechat_article`
- `convert_markdown_to_wechat_html`
- `preview_wechat_html`
- `upload_wechat_image`
- `upload_wechat_cover`
- `create_wechat_draft`
- `list_wechat_drafts`
- `get_wechat_draft`
- `update_wechat_draft`
- `delete_wechat_draft`

工具名称使用 `create_wechat_draft`，避免把创建草稿误称为正式发布。

## 9. 样式

样式以主题文件维护，第一阶段提供 `default`、`minimal` 和 `code-focused` 三个主题。最终 HTML 必须包含内联样式，不能依赖微信公众号以外的 CSS 文件。

## 10. 存储演进

第一版将 Token 和本地操作元数据存放在用户目录下的权限受限 JSON 文件中。Core 只依赖存储接口，未来可以增加 SQLite adapter、Web 服务数据库或桌面端安全存储，不改变 CLI 和 MCP API。

## 11. 安全

- `WECHAT_APP_ID` 和 `WECHAT_APP_SECRET` 只从环境变量或系统密钥环读取。
- Token、AppSecret 和完整 API 响应不得写入日志。
- 默认支持 `dry-run`。
- 创建草稿前必须返回预览摘要。
- 正式群发能力必须单独实现并要求二次确认。
- 本地 MCP 使用 `stdio`，第一阶段不开放 HTTP 端口。

## 12. 演进

未来 Web、桌面端和自动化流水线直接复用 Core API。只有出现明确性能瓶颈时，才考虑将独立模块替换为 Rust，不改变 CLI 和 MCP 的公共接口。
