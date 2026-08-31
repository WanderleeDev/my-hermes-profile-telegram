# My Hermes — Telegram Profile

Telegram bot Hermes profile with Agnes AI, GitHub MCP (readonly), Cloudflare, and 30+ skills.

## What's Included

- **Agnes AI Integration**: Image/video generation (agnes-image-2.1-flash, agnes-video-2.5-flash)
- **GitHub MCP**: Native GitHub tools (issues, PRs, code review)
- **GitHub Skills**: Auth, PR workflow, issues, repo management
- **30+ Skills**: Cloudflare, DevOps, media, productivity, research, social media, and more
- **Telegram Integration**: Bot token, allowed users, home channel
- **Custom Plugins**: `image_gen/agnes` and `video_gen/agnes`

## Quick Install

```bash
hermes profile install github.com/WanderleeDev/my-hermes-profile-telegram --alias
```

Then fill in your `.env`:
```bash
cp .env.example .env
# Edit .env with your API keys and Telegram bot token
```

## Requirements

- Hermes Agent >= 0.12.0
- Agnes AI API key (https://agnes-ai.com)
- Telegram bot token from @BotFather
- GitHub fine-grained token (read-only for repos/issues)

## Author

WanderleeDev

## License

MIT
