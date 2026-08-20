import fs from "node:fs/promises";
import fsSync from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import type { ArticleDocument, Draft, PublisherOptions, RenderedArticle, WechatClient } from "./types.js";
import { checkExampleSync } from "./article.js";
import { ArticleRenderer } from "./renderer.js";
import { loadConfig } from "./config.js";
import { TokenStore } from "./store.js";
import { HttpWechatClient } from "./wechat-client.js";

export class PublisherService {
  readonly renderer: ArticleRenderer;
  private client?: WechatClient;
  private readonly configOptions: { dataDir?: string };
  private readonly repositoryRoot: string;

  constructor(options: PublisherOptions = {}) {
    this.repositoryRoot = options.repositoryRoot ?? findRepositoryRoot(process.cwd());
    this.renderer = new ArticleRenderer(options.stylesDir ?? path.join(path.dirname(fileURLToPath(import.meta.url)), "../../styles"));
    this.configOptions = { dataDir: options.dataDir };
    if (options.wechatClient) {
      this.client = options.wechatClient;
    }
  }

  get wechat(): WechatClient {
    if (!this.client) {
      const config = loadConfig();
      this.client = new HttpWechatClient(config.appId, config.appSecret, new TokenStore(this.configOptions.dataDir ?? config.dataDir));
    }
    return this.client;
  }

  validate(article: ArticleDocument): void {
    if (!article.title.trim()) throw new Error("文章标题不能为空");
    if (article.sourcePath) checkExampleSync(this.repositoryRoot);
  }

  render(article: ArticleDocument): RenderedArticle {
    this.validate(article);
    return this.renderer.render(article);
  }

  async uploadBodyImages(html: string, baseDir?: string): Promise<string> {
    const imagePattern = /<img([^>]+)src="([^"]+)"([^>]*)>/g;
    let result = html;
    for (const match of html.matchAll(imagePattern)) {
      const source = match[2];
      if (/^(https?:|data:)/.test(source)) continue;
      const localPath = path.resolve(baseDir ?? process.cwd(), source);
      const uploaded = await this.wechat.uploadImage(localPath);
      result = result.replace(`src="${source}"`, `src="${uploaded.url}"`);
    }
    return result;
  }

  async createDraft(article: ArticleDocument, dryRun = false): Promise<RenderedArticle | Draft> {
    const rendered = this.render(article);
    const html = dryRun
      ? rendered.html
      : await this.uploadBodyImages(rendered.html, article.sourcePath ? path.dirname(article.sourcePath) : undefined);
    if (dryRun) return { ...rendered, html };
    if (!article.coverImage) throw new Error("创建草稿需要 coverImage");
    const cover = await this.wechat.uploadCover(article.coverImage);
    return this.wechat.createDraft({ article, coverMediaId: cover.mediaId, content: html });
  }

  async updateDraft(mediaId: string, article: ArticleDocument): Promise<void> {
    const rendered = this.render(article);
    const html = await this.uploadBodyImages(rendered.html, article.sourcePath ? path.dirname(article.sourcePath) : undefined);
    if (!article.coverImage) throw new Error("更新草稿需要 coverImage");
    const cover = await this.wechat.uploadCover(article.coverImage);
    await this.wechat.updateDraft(mediaId, { article, coverMediaId: cover.mediaId, content: html });
  }

  async savePreview(article: ArticleDocument, outputPath: string): Promise<void> {
    const rendered = this.render(article);
    await fs.writeFile(outputPath, rendered.html, "utf8");
  }
}

function findRepositoryRoot(start: string): string {
  let current = path.resolve(start);
  while (true) {
    if (fsSyncExists(path.join(current, ".github", "scripts", "sync_examples.py"))) return current;
    const parent = path.dirname(current);
    if (parent === current) throw new Error("无法定位 learn-cangjie 仓库根目录");
    current = parent;
  }
}

function fsSyncExists(filePath: string): boolean {
  try {
    fsSync.accessSync(filePath);
    return true;
  } catch {
    return false;
  }
}
