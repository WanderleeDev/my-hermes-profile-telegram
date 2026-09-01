# OpenCode + gentle-ai — condensed reference

Session-derived detail (July 2026) backing the `opencode-gentle-ai` SKILL.md. Not a mirror of upstream docs.

## OpenCode FAQ (es) — free models, verified from opencode.ai i18n
- `home.faq.q3`: "¿Necesito suscripciones extra de IA para usar OpenCode?"
  `home.faq.a3.p1`: "No necesariamente, OpenCode viene con un conjunto de modelos gratuitos que
  puedes usar sin crear una cuenta."
- `home.faq.a3.p2.beforeZen`: "Aparte de estos, puedes usar cualquiera de los modelos de
  codificación populares creando una cuenta de Zen."
- `home.faq.a3.p3`: "...OpenCode también funciona con todos los proveedores populares como
  OpenAI, Anthropic, xAI, etc."
- `home.faq.a3.p4`: "Incluso puedes conectar tus modelos locales."
- `home.faq.a6`: "OpenCode es 100% gratuito de usar. También viene con un conjunto de modelos
  gratuitos. Puede haber costos adicionales si conectas cualquier otro proveedor."
- Free-model detail (i18n copy): includes **"Big Pickle"** + promotional models, quota
  **200 requests/day**.

## gentle-ai facts
- Repo: https://github.com/Gentleman-Programming/gentle-ai (MIT, Go binary; v2.1.5 at session time)
- Installer: `curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash`
- Prereqs (install.sh `check_prerequisites`): **curl** and **git** only. No Go/Node for binary install.
- Platforms: macOS, Linux (Ubuntu/Debian/Arch/Fedora + derivatives), Windows.
- Agent matrix: OpenCode = "Full (multi-mode overlay)", per-phase routing via `gentle-orchestrator`
  / `sdd-orchestrator-{name}`. Hermes = "Detect-only" (YAML MCP, SOUL.md; install manually) — gentle-ai
  does NOT configure Hermes.
- Writes: `~/.config/opencode/` (opencode.json ~67KB, AGENTS.md, skills/, prompts/, profiles/,
  tui.json, node_modules). Engram DB at `~/.config/engram/engram.db`.
- SDD profiles CLI: `gentle-ai sync --profile cheap:openrouter/qwen/qwen3-30b-a3b:free`
- Health: `gentle-ai doctor` (read-only). Updates: `gentle-ai upgrade` + `gentle-ai sync`.
- Backups: every install/sync/upgrade snapshots config (tar.gz, dedup, keeps 5 recent).

## CodeGraph (shipped via gentle-ai)
- Binary: `~/.local/bin/codegraph` (npm shim).
- Real index: `<project>/.codegraph/` inside the repo where OpenCode runs. Lazy-init triggers on a
  structural question when `.codegraph/` is missing. Per-repo, NOT global, does NOT scan the disk.
- `~/.codegraph/` (HOME) = tool telemetry only: `telemetry.json` (machine_id, enabled flag),
  `telemetry-queue.jsonl` (CLI command log), `update-check.json`. NOT a user-file index.
- Disable telemetry: set `"enabled": false` in `~/.codegraph/telemetry.json`.
- AGENTS.md rule: prefer the `codegraph_explore` MCP tool; never run destructive lifecycle
  (`uninit`/`install`/`uninstall`/`upgrade`); `codegraph index` only for corruption recovery.

## Verified environment notes (user VPS xam-vps)
- OpenCode installed at `~/.opencode/bin/opencode` v1.18.1 (not on global PATH).
- gentle-ai at `~/.local/bin/gentle-ai` v2.1.5.
- OS Ubuntu 24.04, ARM aarch64 (Ampere, 2 OCPU / 12GB, no GPU) — local models run slow.

## How the FAQ was extracted (technique)
opencode.ai/es is an SPA; static HTML has no FAQ text. The content lives in the i18n bundle:
`/_build/assets/i18n-*.js`. Fetch it and grep for `"home.faq.q3"` / `"home.faq.a3.p1"` etc. to get
per-locale answers. Useful when a site's FAQ isn't in the initial HTML.
