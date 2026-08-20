import fs from "node:fs";
import path from "node:path";
import juice from "juice";
import MarkdownIt from "markdown-it";
import type { ArticleDocument, RenderedArticle, StyleProfile } from "./types.js";

const markdown = new MarkdownIt({ html: false, linkify: true, breaks: false });

export class ArticleRenderer {
  constructor(private readonly stylesDir: string) {}

  render(article: ArticleDocument): RenderedArticle {
    const css = this.readStyle(article.styleProfile);
    const body = markdown.render(article.markdown);
    const wrapped = `<section class="wechat-article">${body}</section>`;
    return {
      title: article.title,
      digest: article.digest,
      sourcePath: article.sourcePath,
      html: juice.inlineContent(wrapped, css),
    };
  }

  private readStyle(profile: StyleProfile): string {
    const filePath = path.join(this.stylesDir, `${profile}.css`);
    if (!fs.existsSync(filePath)) throw new Error(`不存在的样式主题: ${profile}`);
    return fs.readFileSync(filePath, "utf8");
  }
}
