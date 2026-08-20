import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import type { ArticleDocument, StyleProfile } from "./types.js";

export function parseArticle(
  markdown: string,
  options: { sourcePath?: string; styleProfile?: StyleProfile; coverImage?: string } = {},
): ArticleDocument {
  const title = markdown.match(/^#\s+(.+)$/m)?.[1]?.trim();
  if (!title) throw new Error("文章缺少一级标题，无法作为公众号文章发布");
  const digest = markdown.match(/^>\s*\*\*摘要\*\*:\s*(.+)$/m)?.[1]?.trim();
  return {
    title,
    digest,
    markdown,
    sourcePath: options.sourcePath,
    styleProfile: options.styleProfile ?? "default",
    coverImage: options.coverImage,
  };
}

export function readArticle(filePath: string, styleProfile: StyleProfile, coverImage?: string): ArticleDocument {
  const sourcePath = path.resolve(filePath);
  return parseArticle(fs.readFileSync(sourcePath, "utf8"), {
    sourcePath,
    styleProfile,
    coverImage: coverImage ? path.resolve(coverImage) : undefined,
  });
}

export function checkExampleSync(repositoryRoot: string): void {
  const script = path.join(repositoryRoot, ".github", "scripts", "sync_examples.py");
  execFileSync("python3", [script], { cwd: repositoryRoot, stdio: "pipe" });
}
