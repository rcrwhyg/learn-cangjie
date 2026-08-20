import path from "node:path";
import fs from "node:fs/promises";
import os from "node:os";
import { describe, expect, it } from "vitest";
import { parseArticle } from "../src/core/article.js";
import { loadConfig } from "../src/core/config.js";
import { ArticleRenderer } from "../src/core/renderer.js";
import { PublisherService } from "../src/core/service.js";
import { TokenStore } from "../src/core/store.js";
import { HttpWechatClient } from "../src/core/wechat-client.js";

const stylesDir = path.resolve(import.meta.dirname, "../styles");

describe("article parsing", () => {
  it("reads title and digest from project Markdown", () => {
    const article = parseArticle("# Title\n\n> **摘要**: Summary\n\nBody");
    expect(article.title).toBe("Title");
    expect(article.digest).toBe("Summary");
  });
});

describe("configuration and token storage", () => {
  it("requires WeChat credentials and loads the data directory", () => {
    expect(() => loadConfig({})).toThrow("WECHAT_APP_ID");
    expect(loadConfig({ WECHAT_APP_ID: "id", WECHAT_APP_SECRET: "secret", WECHAT_DATA_DIR: "/tmp/data" })).toEqual({
      appId: "id",
      appSecret: "secret",
      dataDir: "/tmp/data",
    });
  });

  it("persists a token in the user data directory", async () => {
    const dataDir = await fs.mkdtemp(path.join(os.tmpdir(), "wechat-publisher-"));
    const store = new TokenStore(dataDir);
    expect(store.read()).toBeUndefined();
    store.write({ accessToken: "token", expiresAt: Date.now() + 1000 });
    expect(store.read()?.accessToken).toBe("token");
  });
});

describe("article renderer", () => {
  it("renders HTML with inline styles", () => {
    const renderer = new ArticleRenderer(stylesDir);
    const result = renderer.render(parseArticle("# Title\n\n## Section\n\nText"));
    expect(result.html).toContain("wechat-article");
    expect(result.html).toContain("style=");
    expect(result.html).toContain("Section");
  });
});

describe("publisher service", () => {
  it("supports dry-run without WeChat credentials", async () => {
    const service = new PublisherService({ stylesDir });
    const result = await service.createDraft(parseArticle("# Title\n\nText"), true);
    expect("html" in result).toBe(true);
  });

  it("creates a draft through the injected client", async () => {
    const calls: string[] = [];
    const service = new PublisherService({
      stylesDir,
      wechatClient: {
        uploadImage: async () => ({ url: "https://mmbiz.qpic.cn/body.png" }),
        uploadCover: async () => ({ mediaId: "cover-id" }),
        createDraft: async (input) => {
          calls.push(input.content);
          return { mediaId: "draft-id", title: input.article.title };
        },
        listDrafts: async () => [],
        getDraft: async () => ({}),
        updateDraft: async () => undefined,
        deleteDraft: async () => undefined,
      },
    });
    const result = await service.createDraft(parseArticle("# Title\n\nText", { coverImage: "cover.png" }), false);
    expect(result).toEqual({ mediaId: "draft-id", title: "Title" });
    expect(calls[0]).toContain("Text");
  });

  it("replaces local body images through the client", async () => {
    const service = new PublisherService({
      stylesDir,
      wechatClient: {
        uploadImage: async () => ({ url: "https://mmbiz.qpic.cn/body.png" }),
        uploadCover: async () => ({ mediaId: "cover-id" }),
        createDraft: async () => ({ mediaId: "draft-id", title: "Title" }),
        listDrafts: async () => [],
        getDraft: async () => ({}),
        updateDraft: async () => undefined,
        deleteDraft: async () => undefined,
      },
    });
    const result = await service.uploadBodyImages('<img src="image.png">', os.tmpdir());
    expect(result).toContain("https://mmbiz.qpic.cn/body.png");
  });
});

describe("WeChat API client", () => {
  it("caches a token and maps draft media_id", async () => {
    const dataDir = await fs.mkdtemp(path.join(os.tmpdir(), "wechat-publisher-"));
    const responses = [
      { access_token: "token", expires_in: 7200 },
      { media_id: "draft-id" },
      { item: [] },
    ];
    const client = new HttpWechatClient("id", "secret", new TokenStore(dataDir), async () => {
      return new Response(JSON.stringify(responses.shift()), { status: 200 });
    });
    const result = await client.createDraft({
      article: parseArticle("# Title\n\nText"),
      coverMediaId: "cover-id",
      content: "<p>Text</p>",
    });
    expect(result.mediaId).toBe("draft-id");
    expect((await client.listDrafts())).toEqual([]);
  });

  it("uploads media and supports draft mutations", async () => {
    const dataDir = await fs.mkdtemp(path.join(os.tmpdir(), "wechat-publisher-"));
    const imagePath = path.join(dataDir, "image.png");
    await fs.writeFile(imagePath, "image");
    const responses = [
      { access_token: "token", expires_in: 7200 },
      { url: "https://mmbiz.qpic.cn/image.png" },
      { media_id: "cover-id" },
      {},
      {},
      {},
    ];
    const client = new HttpWechatClient("id", "secret", new TokenStore(dataDir), async () => new Response(JSON.stringify(responses.shift()), { status: 200 }));
    expect(await client.uploadImage(imagePath)).toEqual({ url: "https://mmbiz.qpic.cn/image.png" });
    expect(await client.uploadCover(imagePath)).toEqual({ mediaId: "cover-id" });
    expect(await client.getDraft("draft-id")).toEqual({});
    await client.updateDraft("draft-id", { article: parseArticle("# Title\n\nText"), coverMediaId: "cover-id", content: "<p>Text</p>" });
    await client.deleteDraft("draft-id");
  });
});
