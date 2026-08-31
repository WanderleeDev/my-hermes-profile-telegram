---
name: hermes-mcp-configuration
description: "Configure MCP servers in Hermes Agent. Use when adding MCP."
category: autonomous-ai-agents
---

# Hermes MCP Configuration

Hermes Agent has a built-in MCP client that connects to MCP servers at startup, discovers their tools, and makes them available as first-class tools.

## Configuration Location

MCP servers can be configured in two places:

1. **`config.yaml`** (legacy, single-file) — under `mcp_servers:` key
2. **`mcp.json`** (preferred for profile distributions) — separate file with Agent Plugins v1 schema

For profile distributions, use `mcp.json`. For standalone profiles, either works.

### mcp.json Format (Agent Plugins v1)

```json
{
  "$schema": "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json",
  "mcpServers": {
    "server-name": {
      "type": "streamable-http",
      "url": "https://example.com/mcp",
      "headers": { "Authorization": "Bearer ${ENV_VAR}" }
    },
    "local-server": {
      "type": "local",
      "command": "binary-name",
      "args": ["mcp"]
    }
  }
}
```

**Key differences from config.yaml:**
- Top-level key is `mcpServers` (camelCase), not `mcp_servers` (snake_case)
- Requires `$schema` field
- Server types: `streamable-http` (HTTP), `local` (stdio)
- No `timeout`/`connect_timeout` fields (use defaults)

### When to Use Which

| Scenario | Use |
|----------|-----|
| Profile distribution (git repo) | `mcp.json` |
| Standalone profile | `config.yaml` or `mcp.json` |
| Mixing MCPs from multiple sources | `mcp.json` (cleaner separation) |

## MCP Server Types

### Stdio Transport (command-based)

```yaml
mcp_servers:
  server_name:
    command: "npx"
    args: ["-y", "pkg-name"]
    env:
      SOME_API_KEY: "value"
    timeout: 120
    connect_timeout: 60
```

### HTTP Transport (url-based)

```yaml
mcp_servers:
  server_name:
    url: "https://my-server.example.com/mcp"
    headers:
      Authorization: "Bearer sk-..."
    timeout: 180
    connect_timeout: 60
```

## Popular MCP Servers

| Server | Command | Description |
|--------|---------|-------------|
| **filesystem** | `npx -y @modelcontextprotocol/server-filesystem /path` | File operations |
| **github** | `npx -y @modelcontextprotocol/server-github` | GitHub API |
| **postgres** | `npx -y @modelcontextprotocol/server-postgres postgres://...` | Database access |
| **cloudflare-api** | `https://mcp.cloudflare.com/mcp` | Cloudflare API |

## Cloudflare MCP Setup

```yaml
mcp_servers:
  cloudflare-api:
    url: "https://mcp.cloudflare.com/mcp"
    timeout: 180
  cloudflare-docs:
    url: "https://docs.mcp.cloudflare.com/mcp"
    timeout: 180
  cloudflare-bindings:
    url: "https://bindings.mcp.cloudflare.com/mcp"
    timeout: 180
  cloudflare-builds:
    url: "https://builds.mcp.cloudflare.com/mcp"
    timeout: 180
  cloudflare-observability:
    url: "https://observability.mcp.cloudflare.com/mcp"
    timeout: 180
```

## Tool Naming Convention

Tools are registered as: `mcp_{server_name}_{tool_name}`

Examples:
- `mcp_cloudflare_api_search`
- `mcp_github_list_issues`
- `mcp_filesystem_read_file`

## Restart Required

After adding/removing MCP servers, restart Hermes:
```bash
hermes gateway restart
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| MCP SDK not available | `pip install mcp` |
| Command not found | Verify binary is on PATH |
| Connection timeout | Increase `connect_timeout` |
| Tools not appearing | Check YAML indentation, restart gateway |

## References

- Official docs: https://hermes-agent.nousresearch.com/docs
- MCP spec: https://modelcontextprotocol.io/