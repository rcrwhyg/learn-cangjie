---
name: wechat-publisher
description: Use this project skill when converting repository articles to WeChat HTML, previewing styles, uploading images, or creating and managing WeChat draft articles through the local TypeScript MCP Server.
---

# WeChat Publisher Skill

## Operating Rules

1. Treat `examples/` as the canonical source for all tested code.
2. Run the article/example synchronization check before rendering or creating a draft.
3. Prefer an article path under this repository over raw Markdown supplied by a user.
4. Use `dry_run` for the first render or when the user has not explicitly requested draft creation.
5. Creating a draft is not publishing. Never call a future publish API without explicit confirmation.
6. Never expose or print `WECHAT_APP_SECRET` or `access_token`.

## Preferred Workflow

1. Validate the article and example synchronization.
2. Render with the requested style profile.
3. Preview or save the generated HTML.
4. Confirm title, digest, author, cover image, and target action.
5. Upload images and create the draft only after confirmation.
6. Return the WeChat `media_id` and a concise operation summary.

## Available Interfaces

- CLI: `wechat-publisher validate`, `render`, `preview`, `draft`, and `drafts` commands.
- MCP: `validate_wechat_article`, `convert_markdown_to_wechat_html`, `preview_wechat_html`, image tools, and draft tools.

## Failure Handling

- Report synchronization errors before any WeChat API call.
- Report WeChat error codes without leaking credentials.
- Retry reads cautiously; do not blindly retry draft writes.
- If credentials are missing, explain the required environment variables and stop.
