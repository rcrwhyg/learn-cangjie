import os from "node:os";
import path from "node:path";

export interface WechatConfig {
  appId: string;
  appSecret: string;
  dataDir: string;
}

export function loadConfig(env = process.env): WechatConfig {
  const appId = env.WECHAT_APP_ID;
  const appSecret = env.WECHAT_APP_SECRET;
  if (!appId || !appSecret) {
    throw new Error(
      "缺少微信公众号凭证，请设置 WECHAT_APP_ID 和 WECHAT_APP_SECRET",
    );
  }
  return {
    appId,
    appSecret,
    dataDir:
      env.WECHAT_DATA_DIR ?? path.join(os.homedir(), ".wechat-publisher"),
  };
}
