export type StyleProfile = "default" | "minimal" | "code-focused";

export interface ArticleDocument {
  title: string;
  author?: string;
  digest?: string;
  markdown: string;
  sourcePath?: string;
  coverImage?: string;
  styleProfile: StyleProfile;
}

export interface RenderedArticle {
  title: string;
  digest?: string;
  html: string;
  sourcePath?: string;
}

export interface DraftInput {
  article: ArticleDocument;
  coverMediaId: string;
  content: string;
  contentSourceUrl?: string;
  needOpenComment?: boolean;
  onlyFansCanComment?: boolean;
}

export interface Draft {
  mediaId: string;
  title: string;
  digest?: string;
  createdAt?: number;
}

export interface UploadedImage {
  url: string;
}

export interface UploadedCover {
  mediaId: string;
}

export interface WechatClient {
  uploadImage(filePath: string): Promise<UploadedImage>;
  uploadCover(filePath: string): Promise<UploadedCover>;
  createDraft(input: DraftInput): Promise<Draft>;
  listDrafts(offset?: number, count?: number): Promise<Draft[]>;
  getDraft(mediaId: string): Promise<unknown>;
  updateDraft(mediaId: string, input: DraftInput): Promise<void>;
  deleteDraft(mediaId: string): Promise<void>;
}

export interface PublisherOptions {
  repositoryRoot?: string;
  stylesDir?: string;
  dataDir?: string;
  wechatClient?: WechatClient;
}
