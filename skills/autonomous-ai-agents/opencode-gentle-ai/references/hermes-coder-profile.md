# Hermes 'coder' profile — verified setup (xam-vps)

Isolated coding profile that orchestrates OpenCode (worker) under gentle-ai, WITHOUT
contaminating the generalist `default` profile. All commands verified on the user's VPS
(OCI ARM, Ubuntu 24.04). Requires user "visto bueno" before writing to ~/.hermes/profiles/*
(per the user's stated VPS rule).

## Exact sequence

```bash
# 1) Create EMPTY (no skills, no cloned memory)
hermes profile create coder --no-skills \
  --description "Perfil dedicado a codigo: orquesta OpenCode como worker bajo gentle-ai."

# 2) Symlink ONLY the coding skill (stays in sync with the global copy)
mkdir -p ~/.hermes/profiles/coder/skills/autonomous-ai-agents
ln -s ~/.hermes/skills/autonomous-ai-agents/opencode-gentle-ai \
      ~/.hermes/profiles/coder/skills/autonomous-ai-agents/opencode-gentle-ai

# 3) Blank out the (copied) memory so coder is isolated from generalist data
: > ~/.hermes/profiles/coder/memories/MEMORY.md
: > ~/.hermes/profiles/coder/memories/USER.md

# 4) Write config.yaml with a model (--no-skills omits it; profile.yaml is description-only)
cat > ~/.hermes/profiles/coder/config.yaml <<'EOF'
model:
  default: tencent/hy3:free
  provider: openrouter
  base_url: https://openrouter.ai/api/v1
agent:
  max_turns: 150
  verbose: false
  reasoning_effort: medium
EOF
```

## Verify

```bash
hermes profile list
# coder row should show: tencent/hy3:free  stopped  coder
ls ~/.hermes/profiles/coder/skills/autonomous-ai-agents/   # ONLY opencode-gentle-ai
grep mcp-codegraph ~/.hermes/profiles/coder/config.yaml || echo "clean (no idle MCP)"
wc -c ~/.hermes/profiles/coder/memories/*.md               # 0 bytes = isolated
```

## Use

- `hermes profile use coder`  (sticky; loads the opencode-gentle-ai skill)
- `coder chat`                 (wrapper auto-created at ~/.local/bin/coder)
- back to generalist: `hermes profile use default`

## Notes / gotchas

- `--clone` is the WRONG choice here: it copies all 17+ generalist skills AND the
  user's OCI/Dokploy/SSH memory into the new profile. User explicitly rejected this.
- gentle-ai is "detect-only" for Hermes: it writes to `~/.config/opencode/`, never
  `~/.hermes/`. The coder profile isolates Hermes-side skills/memory only.
- opencode binary lives at `~/.opencode/bin/opencode` (not on global PATH); the
  opencode-gentle-ai skill already pins that path.
