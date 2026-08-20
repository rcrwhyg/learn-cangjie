import fs from "node:fs";
import path from "node:path";
import juice from "juice";
import MarkdownIt from "markdown-it";
import type { ArticleDocument, FooterConfig, RenderedArticle, StyleProfile } from "./types.js";

const DEFAULT_FOOTER: FooterConfig = {
  copyright: "本文原创发布于微信公众号【如春日午后阳光】，欢迎转载，请注明出处。",
  version: "本文基于仓颉1.0.5 LTS版本编写",
};

const markdown = new MarkdownIt({ html: false, linkify: true, breaks: false });
markdown.renderer.rules.fence = (tokens, index) => {
  const token = tokens[index];
  const language = token.info.trim() || "text";
  return `<div class="code-window"><div class="code-window-bar"><span class="code-dot code-dot-red"></span><span class="code-dot code-dot-yellow"></span><span class="code-dot code-dot-green"></span><span class="code-language">${escapeHtml(language)}</span></div><pre><code class="language-${escapeHtml(language)}">${highlightCode(token.content, language)}</code></pre></div>`;
};

export class ArticleRenderer {
  constructor(
    private readonly stylesDir: string,
    private readonly footer: FooterConfig = DEFAULT_FOOTER,
  ) {}

  render(article: ArticleDocument): RenderedArticle {
    const css = this.readStyle(article.styleProfile);
    const body = renderMarkdownWithStrongCompatibility(stripPublisherMetadata(article.markdown));
    const footer = `<footer class="wechat-footer"><p>${escapeHtml(this.footer.copyright)}</p><p>${escapeHtml(this.footer.version)}</p></footer>`;
    const wrapped = `<section class="wechat-article">${body}${footer}</section>`;
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

function stripPublisherMetadata(markdownContent: string): string {
  return markdownContent
    .replace(/^\s*<!--\s*example:\s*[^\n]+-->\s*$/gm, "")
    .replace(/\n---\n\s*\*\*版权声明\*\*:.*$/s, "")
    .trim();
}

function renderMarkdownWithStrongCompatibility(markdownContent: string): string {
  const strongValues: string[] = [];
  const tokenized = markdownContent.replace(/\*\*([^*\n]+)\*\*/g, (_, value: string) => {
    const token = `WECHAT_STRONG_TOKEN_${strongValues.length}`;
    strongValues.push(value);
    return token;
  });
  let rendered = markdown.render(tokenized);
  strongValues.forEach((value, index) => {
    rendered = rendered.replace(
      `WECHAT_STRONG_TOKEN_${index}`,
      `<strong>${markdown.renderInline(value)}</strong>`,
    );
  });
  return rendered;
}

function highlightCode(code: string, language: string): string {
  const tokenPattern = /(\/\/[^\n]*|#[^\n]*|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\b(?:main|let|var|class|interface|func|init|return|if|else|for|in|public|import|true|false)\b|\b(?:Int|String|Float64|Unit|Bool)\b|\b\d+(?:\.\d+)?\b)/g;
  let output = "";
  let cursor = 0;
  for (const match of code.matchAll(tokenPattern)) {
    const start = match.index ?? 0;
    output += escapeHtml(code.slice(cursor, start));
    const value = match[0];
    const category = value.startsWith("//") || value.startsWith("#")
      ? "comment"
      : value.startsWith("\"") || value.startsWith("'")
        ? "string"
        : /^(Int|String|Float64|Unit|Bool)$/.test(value)
          ? "type"
          : /^\d/.test(value)
            ? "number"
            : "keyword";
    output += `<span class="syntax-${category}">${escapeHtml(value)}</span>`;
    cursor = start + value.length;
  }
  return output + escapeHtml(code.slice(cursor));
}

function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (character) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[character] ?? character);
}
