# Hermes Telegram Bot

Multi-personality AI assistant for Telegram — bilingual (EN/ES), developer workflows, Cloudflare ops, and media generation.

## Quick Start

```bash
hermes profile install https://github.com/wanderleedev/hermes-telegram-bot --alias telegram-bot
```

After install, fill your `.env`:

```bash
cd ~/.hermes/profiles/telegram-bot
cp .env.example .env
nano .env   # fill in your real keys
```

Then start the gateway:

```bash
hermes -p telegram-bot gateway run
```

## Features

- **12+ personalities** (helpful, technical, kawaii, catgirl, pirate, shakespeare, surfer, noir, uwu, philosopher, hype, concise)
- **Multi-provider**: OpenRouter (primary), Nous Research, Agnes AI (image/video)
- **Cloudflare MCPs**: 5 servers for Workers, Bindings, Builds, Observability
- **Engram memory**: persistent memory system
- **Cron jobs**: scheduled tasks pre-configured

## Required Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `TELEGRAM_BOT_TOKEN` | Bot token from @BotFather | Yes |
| `TELEGRAM_USER_ID` | Your Telegram user ID | Yes |
| `AGNES_API_KEY` | API key for image/video generation | Yes |
| `OPENROUTER_API_KEY` | API key for model inference | Yes |
| `NOUS_API_KEY` | Nous Research API key | No |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token (for MCPs) | Yes (if using Cloudflare MCPs) |

## Update

```bash
hermes profile update telegram-bot
```

## Uninstall

```bash
hermes profile delete telegram-bot --yes
```
