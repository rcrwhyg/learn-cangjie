#!/usr/bin/env node

import path from "node:path";
import { Command } from "commander";
import { readArticle } from "../core/article.js";
import { PublisherService } from "../core/service.js";
import type { StyleProfile } from "../core/types.js";

const program = new Command();
const service = () => new PublisherService();

program.name("wechat-publisher").description("微信公众号文章排版和草稿管理工具");

program
  .command("validate <article>")
  .description("验证文章格式和 examples/ 同步状态")
  .action((article: string) => {
    service().validate(readArticle(article, "default"));
    console.log(JSON.stringify({ ok: true, article: path.resolve(article) }));
  });

program
  .command("render <article>")
  .description("将 Markdown 渲染为微信公众号 HTML")
  .option("-o, --output <file>", "输出 HTML 文件")
  .option("--style <profile>", "样式主题", "default")
  .action(async (article: string, options: { output?: string; style: StyleProfile }) => {
    const rendered = service().render(readArticle(article, options.style));
    if (options.output) {
      const fs = await import("node:fs/promises");
      await fs.writeFile(options.output, rendered.html, "utf8");
      console.log(JSON.stringify({ ok: true, output: path.resolve(options.output) }));
    } else {
      process.stdout.write(rendered.html);
    }
  });

program
  .command("preview <article>")
  .description("生成本地 HTML 预览文件")
  .option("-o, --output <file>", "输出 HTML 文件", "wechat-preview.html")
  .option("--style <profile>", "样式主题", "default")
  .action(async (article: string, options: { output: string; style: StyleProfile }) => {
    await service().savePreview(readArticle(article, options.style), options.output);
    console.log(JSON.stringify({ ok: true, output: path.resolve(options.output) }));
  });

program
  .command("draft <article>")
  .description("创建微信公众号草稿")
  .requiredOption("--cover <file>", "封面图片路径")
  .option("--style <profile>", "样式主题", "default")
  .option("--dry-run", "只渲染和验证，不调用微信写接口")
  .action(async (article: string, options: { cover: string; style: StyleProfile; dryRun?: boolean }) => {
    const document = readArticle(article, options.style, options.cover);
    const result = await service().createDraft(document, options.dryRun ?? false);
    console.log(JSON.stringify(options.dryRun ? { dryRun: true, html: (result as { html: string }).html } : result, null, 2));
  });

const drafts = program.command("drafts").description("管理微信公众号草稿");
drafts.command("list").action(async () => console.log(JSON.stringify(await service().wechat.listDrafts(), null, 2)));
drafts.command("get <mediaId>").action(async (mediaId: string) => console.log(JSON.stringify(await service().wechat.getDraft(mediaId), null, 2)));
drafts
  .command("update <mediaId> <article>")
  .requiredOption("--cover <file>", "封面图片路径")
  .option("--style <profile>", "样式主题", "default")
  .action(async (mediaId: string, article: string, options: { cover: string; style: StyleProfile }) => {
    await service().updateDraft(mediaId, readArticle(article, options.style, options.cover));
    console.log(JSON.stringify({ ok: true, mediaId }));
  });
drafts.command("delete <mediaId>").action(async (mediaId: string) => {
  await service().wechat.deleteDraft(mediaId);
  console.log(JSON.stringify({ ok: true, mediaId }));
});

program.parseAsync().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
