import fs from "node:fs/promises";
import type {
  Draft,
  DraftInput,
  UploadedCover,
  UploadedImage,
  WechatClient,
} from "./types.js";
import { TokenStore } from "./store.js";

const API_ROOT = "https://api.weixin.qq.com";

export class WechatApiError extends Error {
  constructor(
    message: string,
    readonly errorCode?: number,
    readonly response?: unknown,
  ) {
    super(message);
    this.name = "WechatApiError";
  }
}

export class HttpWechatClient implements WechatClient {
  constructor(
    private readonly appId: string,
    private readonly appSecret: string,
    private readonly tokenStore: TokenStore,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  async uploadImage(filePath: string): Promise<UploadedImage> {
    const form = new FormData();
    form.append("media", new Blob([await fs.readFile(filePath)]), filePath);
    return this.postForm<UploadedImage>("/cgi-bin/media/uploadimg", form);
  }

  async uploadCover(filePath: string): Promise<UploadedCover> {
    const form = new FormData();
    form.append("media", new Blob([await fs.readFile(filePath)]), filePath);
    const result = await this.postForm<{ media_id: string }>("/cgi-bin/material/add_material?type=image", form);
    return { mediaId: result.media_id };
  }

  createDraft(input: DraftInput): Promise<Draft> {
    return this.postJson<{ media_id: string }>("/cgi-bin/draft/add", {
      articles: [{
        title: input.article.title,
        author: input.article.author ?? "",
        digest: input.article.digest ?? "",
        content: input.content,
        content_source_url: input.contentSourceUrl ?? "",
        thumb_media_id: input.coverMediaId,
        need_open_comment: input.needOpenComment ?? false,
        only_fans_can_comment: input.onlyFansCanComment ?? false,
      }],
    }).then((result) => ({ mediaId: result.media_id, title: input.article.title, digest: input.article.digest }));
  }

  async listDrafts(offset = 0, count = 20): Promise<Draft[]> {
    const result = await this.postJson<{ item?: Draft[] }>("/cgi-bin/draft/batchget", { offset, count, no_content: true });
    return (result.item ?? []).map((item) => ({
      mediaId: (item as Draft & { media_id?: string }).media_id ?? item.mediaId,
      title: item.title,
      digest: item.digest,
      createdAt: item.createdAt,
    }));
  }

  getDraft(mediaId: string): Promise<unknown> {
    return this.postJson("/cgi-bin/draft/get", { media_id: mediaId });
  }

  updateDraft(mediaId: string, input: DraftInput): Promise<void> {
    return this.postJson<void>("/cgi-bin/draft/update", {
      media_id: mediaId,
      index: 0,
      articles: {
        title: input.article.title,
        author: input.article.author ?? "",
        digest: input.article.digest ?? "",
        content: input.content,
        content_source_url: input.contentSourceUrl ?? "",
        thumb_media_id: input.coverMediaId,
      },
    });
  }

  deleteDraft(mediaId: string): Promise<void> {
    return this.postJson<void>("/cgi-bin/draft/delete", { media_id: mediaId });
  }

  private async getAccessToken(): Promise<string> {
    const cached = this.tokenStore.read();
    if (cached && cached.expiresAt > Date.now() + 60_000) return cached.accessToken;
    const url = new URL(`${API_ROOT}/cgi-bin/token`);
    url.searchParams.set("grant_type", "client_credential");
    url.searchParams.set("appid", this.appId);
    url.searchParams.set("secret", this.appSecret);
    const response = await this.fetchImpl(url);
    const result = await response.json() as { access_token?: string; expires_in?: number; errcode?: number; errmsg?: string };
    if (!response.ok || !result.access_token) throw new WechatApiError(result.errmsg ?? "获取 access_token 失败", result.errcode, result);
    this.tokenStore.write({ accessToken: result.access_token, expiresAt: Date.now() + (result.expires_in ?? 7200) * 1000 });
    return result.access_token;
  }

  private async postForm<T>(endpoint: string, form: FormData): Promise<T> {
    return this.request<T>(endpoint, { method: "POST", body: form });
  }

  private async postJson<T>(endpoint: string, body: unknown): Promise<T> {
    return this.request<T>(endpoint, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(body) });
  }

  private async request<T>(endpoint: string, init: RequestInit): Promise<T> {
    const token = await this.getAccessToken();
    const url = new URL(`${API_ROOT}${endpoint}`);
    url.searchParams.set("access_token", token);
    const response = await this.fetchImpl(url, { ...init, signal: AbortSignal.timeout(30_000) });
    const result = await response.json() as T & { errcode?: number; errmsg?: string };
    if (!response.ok || (result.errcode && result.errcode !== 0)) {
      throw new WechatApiError(result.errmsg ?? "微信公众号 API 请求失败", result.errcode, result);
    }
    return result;
  }
}
