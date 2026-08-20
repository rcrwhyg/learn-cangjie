# WeChat Publisher

基于 Node.js + TypeScript 的微信公众号文章排版、图片上传和草稿管理工具。

## 安装

```bash
cd tools/wechat-publisher
npm install
npm run build
```

当前版本支持 Node.js 22+，并已在 Node.js 26 上验证。

## 本地预览

```bash
npm run dev -- validate ../../articles/drafts/01-cangjie-introduction.md
npm run dev -- render ../../articles/drafts/01-cangjie-introduction.md --output /tmp/wechat-preview.html
npm run dev -- preview ../../articles/drafts/01-cangjie-introduction.md
```

预览和校验不需要微信公众号凭证。

## 创建草稿

设置环境变量：

```bash
export WECHAT_APP_ID="..."
export WECHAT_APP_SECRET="..."
```

首次使用建议先执行 dry-run：

```bash
npm run dev -- draft ../../articles/drafts/01-cangjie-introduction.md \
  --cover /path/to/cover.png \
  --dry-run
```

确认 HTML 后再去掉 `--dry-run` 创建草稿。

## MCP Server

```bash
npm run build
node dist/mcp/index.js
```

MCP Server 使用标准输入输出通信，不开放本地网络端口。将 MCP 客户端的 server command 指向 `dist/mcp/index.js`，并传入 `WECHAT_APP_ID` 和 `WECHAT_APP_SECRET` 环境变量。

## 测试

```bash
npm run typecheck
npm test
npm run test:coverage
npm run build
```

当前 Core 覆盖率门槛为语句、行和函数 70%，分支 60%。CLI/MCP 入口通过构建和 MCP 启动检查验证，真实微信 API 不在默认测试中调用。

通用配置示例：

```json
{
  "mcpServers": {
    "wechat-publisher": {
      "command": "node",
      "args": ["/absolute/path/to/learn-cangjie/tools/wechat-publisher/dist/mcp/index.js"],
      "env": {
        "WECHAT_APP_ID": "${WECHAT_APP_ID}",
        "WECHAT_APP_SECRET": "${WECHAT_APP_SECRET}"
      }
    }
  }
}
```

详细架构见 [`specs/wechat-publisher.md`](../../specs/wechat-publisher.md)，约束见 [`rules/wechat-publisher.md`](../../rules/wechat-publisher.md)。
