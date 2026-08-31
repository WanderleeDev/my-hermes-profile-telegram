---
name: cloudflare-mcp-setup
description: "Setup Cloudflare MCP. Use when configuring Cloudflare."
category: devops
---

# Cloudflare MCP Setup for Hermes

This skill covers configuring Cloudflare's MCP servers and skills in Hermes Agent.

## What are Cloudflare MCP Servers?

Cloudflare provides 5 official MCP servers that give AI agents access to:
- **Cloudflare API** (2,500+ endpoints)
- **Documentation**
- **Bindings management**
- **Build history**
- **Observability**

## Official MCP Servers

| Server | URL | Purpose |
|--------|-----|---------|
| **cloudflare-api** | `https://mcp.cloudflare.com/mcp` | Full API access (DNS, Workers, R2, etc.) |
| **cloudflare-docs** | `https://docs.mcp.cloudflare.com/mcp` | Official documentation |
| **cloudflare-bindings** | `https://bindings.mcp.cloudflare.com/mcp` | KV, D1, R2 bindings |
| **cloudflare-builds** | `https://builds.mcp.cloudflare.com/mcp` | Build/deployment history |
| **cloudflare-observability** | `https://observability.mcp.cloudflare.com/mcp` | Logs and metrics |

## Installation Steps

### 1. Clone Cloudflare Skills Repository

```bash
git clone https://github.com/cloudflare/skills.git ~/.cloudflare-skills
```

### 2. Add MCP Servers to Hermes Config

Add to `~/.hermes/profiles/<profile>/config.yaml`:

```yaml
mcp_servers:
  cloudflare-api:
    url: "https://mcp.cloudflare.com/mcp"
    timeout: 180
    connect_timeout: 60
  cloudflare-docs:
    url: "https://docs.mcp.cloudflare.com/mcp"
    timeout: 180
    connect_timeout: 60
  cloudflare-bindings:
    url: "https://bindings.mcp.cloudflare.com/mcp"
    timeout: 180
    connect_timeout: 60
  cloudflare-builds:
    url: "https://builds.mcp.cloudflare.com/mcp"
    timeout: 180
    connect_timeout: 60
  cloudflare-observability:
    url: "https://observability.mcp.cloudflare.com/mcp"
    timeout: 180
    connect_timeout: 60
```

### 3. Copy Skills to Hermes

```bash
mkdir -p ~/.hermes/profiles/<profile>/skills/cloudflare
cp ~/.cloudflare-skills/rules/*.mdc ~/.hermes/profiles/<profile>/skills/cloudflare/
```

### 4. Restart Hermes Gateway

```bash
hermes gateway restart
```

## Available Skills

The Cloudflare skills repository includes:
- `workers.mdc` — Workers development guidelines
- More skills in the `rules/` directory

## API Token (Optional)

For write operations (modifying DNS, creating Workers, etc.):
1. Create token at https://dash.cloudflare.com/profile/api-tokens
2. Add to Hermes `.env` file:
```bash
CLOUDFLARE_API_TOKEN=your_token_here
```

## Key Resources

| Resource | URL |
|----------|-----|
| Skills Repository | https://github.com/cloudflare/skills |
| MCP Repository | https://github.com/cloudflare/mcp |
| Docs for Agents | https://developers.cloudflare.com/docs-for-agents/ |
| MCP Playgrounds | https://labs.cloudflare.dev/mcp/ |

## API Reference

For listing Pages projects and Workers scripts, see `references/cloudflare-api-workflow.md`

## Cloudflare Projects Example (from session 2026-08-26)

Successfully queried Cloudflare API to list:
- **Account ID**: `2884c63d70470fc763e5bc49f7259994`
- **Pages Projects**: 7 total (you-dont-need-js-for-that, ngx-iconify-stack-docs, demo-ngx-theme-stack, angular-components, ngx-theme-stack-docs, ubuntu-desktop, astro-retro-blog)
- **Workers Scripts**: 2 total (semantic-search, tanstack-start-app)

API endpoint pattern: `https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/{resource}`