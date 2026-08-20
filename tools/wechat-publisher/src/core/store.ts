import fs from "node:fs";
import path from "node:path";

interface TokenRecord {
  accessToken: string;
  expiresAt: number;
}

export class TokenStore {
  private readonly filePath: string;

  constructor(dataDir: string) {
    fs.mkdirSync(dataDir, { recursive: true, mode: 0o700 });
    this.filePath = path.join(dataDir, "token.json");
  }

  read(): TokenRecord | undefined {
    try {
      return JSON.parse(fs.readFileSync(this.filePath, "utf8")) as TokenRecord;
    } catch {
      return undefined;
    }
  }

  write(record: TokenRecord): void {
    fs.writeFileSync(this.filePath, JSON.stringify(record), { mode: 0o600 });
  }
}
