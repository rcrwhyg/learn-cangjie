#!/usr/bin/env node

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { readArticle } from "../core/article.js";
import { PublisherService } from "../core/service.js";
import type { StyleProfile } from "../core/types.js";

const service = new PublisherService();
const server = new McpServer({ name: "wechat-publisher", version: "0.1.0" });
const style = z.enum(["default", "minimal", "code-focused"]).default("default");

server.tool(
  "validate_wechat_article",
  "验证文章格式以及 examples/ 与文章代码块的同步状态",
  { article_path: z.string() },
  async ({ article_path }) => {
    service.validate(readArticle(article_path, "default"));
    return { content: [{ type: "text", text: JSON.stringify({ ok: true, article_path }) }] };
  },
);

server.tool(
  "convert_markdown_to_wechat_html",
  "将 Markdown 文章转换为带内联 CSS 的微信公众号 HTML",
  { article_path: z.string(), style_profile: style },
  async ({ article_path, style_profile }) => {
    const rendered = service.render(readArticle(article_path, style_profile as StyleProfile));
    return { content: [{ type: "text", text: rendered.html }] };
  },
);

server.tool(
  "preview_wechat_html",
  "生成微信公众号 HTML 预览文件，不调用微信 API",
  { article_path: z.string(), output_path: z.string(), style_profile: style },
  async ({ article_path, output_path, style_profile }) => {
    await service.savePreview(readArticle(article_path, style_profile as StyleProfile), output_path);
    return { content: [{ type: "text", text: JSON.stringify({ ok: true, output_path }) }] };
  },
);

server.tool("upload_wechat_image", "上传正文图片并返回微信托管 URL", { image_path: z.string() }, async ({ image_path }) => ({
  content: [{ type: "text", text: JSON.stringify(await service.wechat.uploadImage(image_path)) }],
}));

server.tool("upload_wechat_cover", "上传封面图并返回 thumb_media_id", { image_path: z.string() }, async ({ image_path }) => ({
  content: [{ type: "text", text: JSON.stringify(await service.wechat.uploadCover(image_path)) }],
}));

server.tool(
  "create_wechat_draft",
  "渲染文章并创建微信公众号草稿；confirm=false 时只执行 dry-run",
  {
    article_path: z.string(),
    cover_image: z.string(),
    style_profile: style,
    confirm: z.boolean().default(false),
  },
  async ({ article_path, cover_image, style_profile, confirm }) => {
    const result = await service.createDraft(readArticle(article_path, style_profile as StyleProfile, cover_image), !confirm);
    return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
  },
);

server.tool(
  "update_wechat_draft",
  "重新渲染文章并更新已有微信公众号草稿",
  {
    media_id: z.string(),
    article_path: z.string(),
    cover_image: z.string(),
    style_profile: style,
    confirm: z.boolean().default(false),
  },
  async ({ media_id, article_path, cover_image, style_profile, confirm }) => {
    if (!confirm) return { content: [{ type: "text", text: "更新草稿需要 confirm=true" }] };
    await service.updateDraft(media_id, readArticle(article_path, style_profile as StyleProfile, cover_image));
    return { content: [{ type: "text", text: JSON.stringify({ ok: true, media_id }) }] };
  },
);

server.tool("list_wechat_drafts", "列出微信公众号草稿", {}, async () => ({
  content: [{ type: "text", text: JSON.stringify(await service.wechat.listDrafts(), null, 2) }],
}));

server.tool("get_wechat_draft", "读取一个微信公众号草稿", { media_id: z.string() }, async ({ media_id }) => ({
  content: [{ type: "text", text: JSON.stringify(await service.wechat.getDraft(media_id), null, 2) }],
}));

server.tool("delete_wechat_draft", "删除一个微信公众号草稿", { media_id: z.string(), confirm: z.boolean().default(false) }, async ({ media_id, confirm }) => {
  if (!confirm) return { content: [{ type: "text", text: "删除草稿需要 confirm=true" }] };
  await service.wechat.deleteDraft(media_id);
  return { content: [{ type: "text", text: JSON.stringify({ ok: true, media_id }) }] };
});

const transport = new StdioServerTransport();
await server.connect(transport);
