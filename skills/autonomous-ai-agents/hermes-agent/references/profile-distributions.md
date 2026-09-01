# Profile Distributions & Exports

## Overview

Hermes has two ways to share/export profiles:
1. **Export** (`hermes profile export`) — quick snapshot
2. **Distribution** (git repo) — full portable package

## Export (`hermes profile export`)

```bash
# Create export
hermes profile export default -o ~/profile-export.tar.gz

# Import on another machine
hermes profile import ~/profile-export.tar.gz
```

### What Export Includes
- `config.yaml` — configuration
- `plugins/` — custom plugins
- `skills/` — bundled skills
- `cron/` — scheduled tasks
- `mcp.json` — MCP server configs
- `SOUL.md` — system prompt

### What Export Excludes
- `.env` — your API keys (deliberately excluded)
- `auth.json` — OAuth tokens
- `state.db` — conversation history
- `memories/` — session memories
- `sessions/` — request dumps

### IMPORTANT: Export Uses curator_backups

The export creates a snapshot from `~/.hermes/profiles/<name>/.curator_backups/`, which is a **previous copy** of the profile, not the current state.

**Consequence:** Files created or modified after the last curator backup will NOT appear in the export.

To ensure files are included:
1. Update the skill/reference that already exists (will be in curator_backups)
2. Or use Distribution instead (see below)

## Distribution (Git Repo)

The official way to share a complete, up-to-date profile.

### Structure
```
my-agent/
├── distribution.yaml      # Manifest (required)
├── .gitignore             # Exclude secrets (required)
├── SOUL.md                # System prompt
├── config.yaml            # Configuration
├── skills/                # Custom skills
├── plugins/               # Custom plugins
├── cron/                  # Scheduled tasks
└── README.md              # Setup instructions
```

### distribution.yaml
```yaml
name: my-agent
version: 1.0.0
description: "My custom Hermes agent"
author: "Your Name"
license: MIT
hermes_requires: ">=0.12.0"

env_requires:
  - name: AGNES_API_KEY
    description: "Agnes AI API key"
    required: true
  - name: R2_ACCOUNT_ID
    description: "Cloudflare account ID"
    required: true
  - name: R2_ACCESS_KEY_ID
    description: "R2 API Access Key"
    required: true
  - name: R2_SECRET_ACCESS_KEY
    description: "R2 API Secret Key"
    required: true
```

### .gitignore
```gitignore
# Secrets
.env
auth.json

# User data
memories/
sessions/
state.db*
logs/
```

### Install
```bash
hermes profile install github.com/username/my-agent --alias
```

## When to Use Each

| Use Export When | Use Distribution When |
|-----------------|----------------------|
| Quick one-off share | Building a product |
| Moving to new machine | Team sharing |
| No git setup desired | Version tracking needed |
| No custom docs needed | Multiple users |

## Common Pitfalls

### Files Not Appearing in Export
If you create a new file in `~/.hermes/profiles/default/` and it doesn't appear in the export, check:
1. Is it inside a subdirectory that curator_backups tracks?
2. Try adding it to an existing skill instead
3. Use Distribution for full control

### Accidentally Including Secrets
Always verify export contents before sharing:
```bash
tar -tzf profile-export.tar.gz
```
Check for `.env`, `auth.json`, or any sensitive files.

## Templates

See `templates/config-example.yaml` and `templates/env-example` for portable config templates.
