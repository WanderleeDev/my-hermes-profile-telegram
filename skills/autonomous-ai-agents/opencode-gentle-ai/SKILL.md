---
name: opencode-gentle-ai
description: "Install and orchestrate OpenCode as a coding worker, layered with the Gentleman gentle-ai ecosystem (SDD, Engram memory, CodeGraph). Covers the 'built-in free models need no account' correction and the VPS install/path/telemetry gotchas."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [Coding-Agent, OpenCode, gentle-ai, Autonomous, Code-Review, SDD]
    related_skills: [opencode, claude-code, codex, hermes-agent]
---

# OpenCode + Gentle-AI (coding-worker stack)

Companion to the bundled `opencode` skill. This skill captures what the bundled one gets WRONG or
omits: OpenCode's built-in free models need NO account/API key, and how to layer the Gentleman
**gentle-ai** ecosystem on top, plus install/path/telemetry gotchas observed on a real VPS.

## When to Use
- Setting up OpenCode on a user's machine/VPS, especially with gentle-ai.
- User asks about free models / "do I need an API key for OpenCode".
- User wants SDD, persistent memory, or curated skills on top of OpenCode.
- Orchestrating OpenCode from Hermes (Hermes = orchestrator, OpenCode = worker).

## CRITICAL CORRECTION: OpenCode has built-in free models (no account)
The bundled `opencode` skill wrongly implies you always need `opencode auth login` / an API key.
OpenCode's own FAQ (opencode.ai/es) says: *"No necesariamente, OpenCode viene con un conjunto de
modelos gratuitos que puedes usar sin crear una cuenta."*
- Built-in free models include **"Big Pickle"** + promotional models, quota **200 requests/day**
  (verified from opencode.ai i18n, July 2026).
- Work out-of-the-box after install — no `auth login`, no key.
- **Zen** (Gentleman-curated: GLM-5.2, GLM-5.1, Kimi K2.7 Code, MiMo-V2.5, Qwen3, ...) needs an
  account; non-profit, passes provider cost through.
- **External providers** (OpenAI, Anthropic, xAI) and **local (Ollama)** need keys/setup. On a small
  VPS (2 OCPU/12GB, no GPU) local models run slow.

## Install OpenCode
Official installer drops the binary at `~/.opencode/bin/opencode` — often NOT on global PATH.
```bash
curl -fsSL https://opencode.ai/install | bash
$HOME/.opencode/bin/opencode --version   # pin this path if `which opencode` is empty
```
Also available: `npm i -g opencode-ai@latest`, `brew install anomalyco/tap/opencode`.

## Install gentle-ai (ecosystem configurator, NOT an agent installer)
gentle-ai equips OpenCode with Spec-Driven Development (SDD), persistent memory (Engram), curated
skills, MCP servers (incl. CodeGraph), per-phase model routing, and a teaching persona.
```bash
curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash
gentle-ai install      # select ONLY OpenCode if user wants OpenCode-only
gentle-ai doctor       # read-only health check
```
- Prereqs (from install.sh `check_prerequisites`): **curl** and **git** only. No Go/Node for the
  binary install. Debian/Ubuntu officially supported; ARM aarch64 artifacts exist.
- Writes stack to `~/.config/opencode/` (opencode.json, AGENTS.md, skills/, prompts/, profiles/,
  tui.json, node_modules). Engram DB at **`~/.engram/engram.db`** (dot-dir in HOME — NOT
  `~/.config/engram/`, which does not exist). `protocol-mode.json` also lives in `~/.engram/`.
- Agent matrix: OpenCode = "Full (multi-mode overlay)" + per-phase routing (`gentle-orchestrator`,
  `sdd-orchestrator-{name}`). **Hermes = detect-only** (gentle-ai does NOT configure Hermes) — so
  gentle-ai lives on OpenCode and Hermes stays the orchestrator.
- SDD profile example: `gentle-ai sync --profile cheap:openrouter/qwen/qwen3-30b-a3b:free`
- Updates: `gentle-ai upgrade` + `gentle-ai sync`.

## CodeGraph index location (common confusion)
- Real codebase index = `<project>/.codegraph/` INSIDE the repo where OpenCode runs. Lazy-init
  triggers when a structural question is asked and `.codegraph/` is missing. Per-repo, NOT global,
  does NOT scan your whole disk.
- `~/.codegraph/` (in HOME) = tool **telemetry** only: `telemetry.json` (machine_id, enabled flag),
  `telemetry-queue.jsonl` (CLI command log), `update-check.json`. NOT an index of user files.
- Disable telemetry: set `"enabled": false` in `~/.codegraph/telemetry.json`.
- Best practice: open OpenCode inside the specific repo, never in `~`/root, so the index stays
  isolated per project.

## Orchestration from Hermes
- One-shot: `terminal(command="$HOME/.opencode/bin/opencode run '...'", workdir="~/project")`
  (no pty needed).
- Interactive: `terminal(command="opencode", workdir="~/project", background=true, pty=true)` then
  drive with `process(action="submit"|"poll"|"log")`, exit with Ctrl+C (`\x03`) — never `/exit`.
- Pin the `~/.opencode/bin/opencode` path when `opencode` is not on PATH.

## Hermes 'coder' profile (isolation)
When the user wants a dedicated coding profile in Hermes (orchestrator) that does NOT contaminate
the generalist default profile:
- **Do NOT use `hermes profile create coder --clone`**: `--clone` copies ALL of the active
  profile's skills (17+ generalist skills) AND its memory (USER.md/MEMORY.md with the user's
  OCI/Dokploy/SSH data) into the new profile. That defeats isolation and bloats the coder profile.
  The user explicitly flagged this: the default profile must stay generalist; the coder profile must
  be isolated and dedicated to code.
- Correct recipe (verified on this stack):
  ```bash
  hermes profile create coder --no-skills \
    --description "Perfil dedicado a codigo: orquesta OpenCode como worker bajo gentle-ai."
  # --no-skills leaves skills empty and drops a .no-bundled-skills marker (no hermes update sync)
  # symlink ONLY the coding skill (keeps it in sync with the global skill, no duplication):
  mkdir -p ~/.hermes/profiles/coder/skills/autonomous-ai-agents
  ln -s ~/.hermes/skills/autonomous-ai-agents/opencode-gentle-ai \
        ~/.hermes/profiles/coder/skills/autonomous-ai-agents/opencode-gentle-ai
  # blank out inherited memory so coder starts with its own isolated context:
  : > ~/.hermes/profiles/coder/memories/MEMORY.md
  : > ~/.hermes/profiles/coder/memories/USER.md
  # `--no-skills` ALSO omits config.yaml, so `coder chat` warns "no API keys".
  # Write a minimal config.yaml with the model (profile.yaml holds ONLY the
  # description — do NOT look for the model there):
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
  # verify: hermes profile list should now show the model under the coder row.
  ```
- Verify: `ls ~/.hermes/profiles/coder/skills/autonomous-ai-agents/` should show ONLY
  `opencode-gentle-ai`; `grep mcp-codegraph ~/.hermes/profiles/coder/config.yaml` should be empty
  (no idle MCP RAM); memory files should be 0 bytes.
- Use: `hermes profile use coder` (sticky) to load the skill, or the wrapper `coder chat`.
  Return to generalist with `hermes profile use default`.
- gentle-ai is "detect-only" for Hermes — it writes to `~/.config/opencode/`, never to
  `~/.hermes/`. So the coder profile isolates Hermes-side skills/memory only; opencode+gentle-ai
  live at the user level regardless of which Hermes profile is active.

## Pitfalls
- PATH: official install puts binary at `~/.opencode/bin/opencode`, may be off PATH.
- Do NOT assume an API key is mandatory — built-in free models work account-less.
- `~/.codegraph/` is telemetry, not a file index — don't panic on seeing it.
- gentle-ai does NOT touch Hermes config (detect-only); isolate "OpenCode-only" by selecting only
  OpenCode in `gentle-ai install`.
- On small/no-GPU VPS, local models are slow; prefer free integrated or OpenRouter-free models.
- **CodeGraph MCP server eats ~194 MB at idle**: when Hermes has `mcp-codegraph` enabled
  (config.yaml `mcp_servers.codegraph` + `- mcp-codegraph` toolset), Hermes auto-launches
  `codegraph serve --mcp` as a background daemon. opencode/gentle-ai are CLIs and cost 0 at idle;
  only this MCP server stays resident. To stop: `pkill -f 'codegraph serve --mcp'`,
  `pkill -f 'codegraph.js serve --mcp'`, `pkill -f 'mcp_stdio_watchdog.*codegraph'`, then
  `kill -9 <surviving watchdog PID>` (the watchdog often survives pkill). To stop auto-launch,
  remove the `codegraph` block from `mcp_servers` and drop `- mcp-codegraph` from the toolset.

## User workflow preference (observed)
- **Ask for explicit approval before running install/config changes on the user's VPS** (installing
  OpenCode/gentle-ai, writing `~/.config/opencode/`). Plan first, execute after "visto bueno".
  Read-only checks (version, doctor, listing files) are fine without approval.

## References
- `references/opencode-gentle-ai.md` — verified FAQ quotes, gentle-ai facts, CodeGraph detail, VPS env notes.
- `references/hermes-coder-profile.md` — exact verified command sequence + config.yaml template for the isolated coder profile (covers the `--no-skills` model gap).
