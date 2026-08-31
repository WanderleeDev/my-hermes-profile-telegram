---
name: oci-free-tier-selfhosting
description: "Operate and size workloads on Oracle Cloud (OCI) Always Free ARM VMs — inspect the box, understand billing/egress, and pick self-hostable AI models for a CPU-only VM."
version: 1.0.0
metadata:
  hermes:
    tags: [oci, oracle-cloud, vps, always-free, self-hosting, ampere, llm-sizing, security, ufw, fail2ban]
---

# OCI Free-Tier Self-Hosting

How to inspect, reason about, and size workloads on an Oracle Cloud Infrastructure (OCI) Always Free ARM VM (VM.Standard.A1.Flex — Ampere). Covers instance inspection, billing/egress reality, and picking AI models that actually fit a CPU-only box.

## Inspecting the VM

Local system facts (no cloud API needed):
- `lscpu`, `free -h`, `df -h --total`, `cat /etc/os-release`, `uname -a`, `uptime -p`, `hostname`
- Ports actually listening: `ss -tulnp | grep LISTEN`
- Firewall: `ufw status` then `iptables -L INPUT -n --line-numbers`

Cloud/instance metadata (OCI) — link-local, only answers from inside the instance:
```
curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/
```
Returns: `shape`, `shapeConfig` (ocpus, memoryInGBs, networkingBandwidthInGbps), `canonicalRegionName`, `availabilityDomain`, `compartmentId`, `id` (OCID), `definedTags` (CreatedBy/CreatedOn), authorized SSH keys. The smart-approval layer flags this as a metadata-endpoint access but auto-approves read-only queries.

## What's REALLY exposed to the internet (two barriers)

A port "LISTENING" (`ss`) is NOT the same as "reachable from the internet". Traffic must pass TWO firewalls:
1. **OCI Security List / NSG** (configured in the OCI console) — the barrier that actually decides internet reachability.
2. **Local iptables** inside the VM.

Key gotcha: **Docker inserts its own rules into the `DOCKER` / `FORWARD` chains, bypassing the INPUT chain's `REJECT all`.** So published containers (Traefik 80/443, a panel on 3000) are reachable at the VM level even if `iptables -L INPUT` only shows port 22 allowed. Verify real Docker exposure with:
```
sudo iptables -t nat -L DOCKER -n     # DNAT rules = published ports to 0.0.0.0
sudo docker ps --format '{{.Names}}: {{.Ports}}'   # 0.0.0.0:PORT = published; bare PORT/tcp = internal only
```
A management panel (e.g. Dokploy on 3000) is only truly exposed if you ALSO opened 3000 in the OCI Security List. Safer access = SSH tunnel: `ssh -L 3000:localhost:3000 user@IP`.

## Billing & egress reality (as of 2026)

- **Egress:** OCI gives ~10 TB/month free outbound; ingress always free; overage ~$0.0085/GB. A chat bot / API uses KB–MB per message — you will never approach 10 TB. Egress cost for messaging/bot workloads ≈ $0.
- **The real cost is LLM tokens** (OpenRouter/Anthropic/etc.), billed by the AI provider, NOT by Oracle.
- **Always Free ARM (Ampere A1) allowance was HALVED on 2026-06-15**: from 4 OCPU / 24 GB RAM down to **2 OCPU / 12 GB RAM**, done quietly with no announcement. Instances created after that date are born at 2/12. Pre-existing 4/24 instances were *generally* grandfathered but with scattered auto-shutdowns and contradictory support answers — not a blindly guaranteed grandfather.
- Always Free also includes up to 200 GB Block Volume total.
- Idle reclaim: Always Free instances nearly idle for 7 straight days can be reclaimed; steady workloads (Dokploy, a bot) avoid this.
- Always confirm current limits with a web search before quoting them — Oracle changes them silently. See references/oci-free-tier-2026.md.

## Sizing self-hosted AI models on a CPU-only ARM VM

No GPU → use llama.cpp (compiles fine on ARM) with GGUF quantized models. Rough Q4 footprints and CPU-ARM throughput on a 2-OCPU box:

| Model | RAM (Q4) | Speed | Fits 12GB? | Code quality |
|-------|---------|-------|-----------|--------------|
| Gemma 4 E2B (gemma3n/gemma4 "E"=effective; ~5B real, ~2B effective, multimodal) | ~3 GB | ~8-15 tok/s | yes | aceptable |
| Qwen2.5-Coder 3B | ~3 GB | ~6-10 tok/s | yes | good (best small coder; supports FIM autocomplete) |
| Qwen2.5-Coder 7B | ~5-6 GB | ~3-5 tok/s | yes | very good, slower |
| Hy3 (Tencent, 295B MoE, 21B active) | ~150 GB Q4 | — | NO | elite — API only |

**MoE gotcha:** even though only N params are "active" per token, ALL weights must be resident in memory. Hy3's 295B needs ~90 GB even at extreme Q2 → impossible on a 12 GB VM. Big models like Hy3 are API-only (e.g. `tencent/hy3:free` on OpenRouter).

**Recommendation pattern (hybrid):** run Dokploy / n8n / bots / small local models on the free VM; get high-quality coding/reasoning via a cheap-or-free API model. For local *code* specifically, Qwen-Coder beats a same-size generalist.

## OpenRouter :free models for Hermes

Hermes needs **tool calling** — not every free model supports it. Tool-calling `:free` options: `tencent/hy3:free`, `deepseek/deepseek-chat-v3:free`, `deepseek/deepseek-r1:free`, `qwen/qwen3-coder:free` (best for code), `qwen/qwen-2.5-72b-instruct:free`, `meta-llama/llama-3.3-70b-instruct:free`, `z-ai/glm-4.5-air:free`.
Caveats: strict rate limits (an agent burns them fast), OpenRouter often requires a one-time ~$10 balance to unlock decent free limits, free tiers may train on prompts, availability fluctuates. Switch with `hermes model` or `hermes config set model.default <tag>` + `hermes config set model.provider openrouter`.

## Deploying services (when Dokploy is present)

If Dokploy is already running, deploy new services (n8n, etc.) THROUGH its panel rather than by hand — Traefik gives automatic domain + SSL, and DB/backups/env are managed in the UI. n8n is light (~150-700 MB) and fits easily. Prefer Postgres over SQLite for n8n; add Redis "queue mode" only for heavy parallel workflows.

## Securing the VPS (hardening recipes)
A single-node OCI ARM VPS driven remotely by the Hermes Telegram gateway should
be hardened with UFW (host firewall) + fail2ban (SSH brute-force) + a
`DOCKER-USER` rule to close the Dokploy panel (port 3000) to the world, plus a
Hermes profile security audit. Full, copy-paste recipes and a post-change
verification checklist are in **`references/vps-security-hardening.md`**.

Key sequence/safety notes baked into that reference:
- SSH is key-only → safe to reconfigure the firewall remotely (Telegram is an
  independent channel, so you can still fix a wedged SSH via the bot).
- `sudo reboot`/`shutdown -r` is HARD-BLOCKED by the agent runtime — the user
  must trigger reboots; the agent only prepares + verifies.
- UFW alone does NOT close container-published ports (Docker bypasses INPUT);
  you MUST use the `DOCKER-USER` chain for any published container port.
- Also close Swarm ports 2377/tcp and 7946 (tcp+udp) to the world on single-node.

## Pitfalls
- Don't quote OCI free-tier limits from memory — they changed silently in June 2026. Search first.
- Don't equate "listening port" with "internet-exposed". Check OCI Security List + Docker NAT rules, not just iptables INPUT.
- Don't propose running a large MoE (or any >~10B dense) model locally on a CPU free-tier VM — it won't fit; route to an API.
- "E2B/E4B" in Gemma naming = *effective* params (fewer resident than raw count), not a quantization level.
- Don't think `ufw enable` closes a Docker-published panel — it doesn't. Use the `DOCKER-USER` chain (see reference).

## No IPv6 egress (silent connect hangs)
Always-Free ARM VMs have **no IPv6 egress route** — only link-local + loopback.
Any outbound client that prefers AAAA (IPv6) will **hang forever in `connect()`**
with ~0% CPU: Telegram Bot API, SMTP to IPv6 MX, IPv6-only pip/npm mirrors,
webhooks to IPv6-first hosts. Symptom on Hermes' Telegram gateway: it logs
`Discovering Telegram API fallback IPs…` / `Connecting to Telegram (attempt 1/8)…`
and then sits there. Diagnose fast: `curl -6 -o /dev/null -w "%{http_code}\n" <url>`
(returns 000) vs `curl -4 …` (200/302). Fix = pin the host to its IPv4 in
`/etc/hosts` (persists across reboots). Full recipe + the "Chat not found after
first connect" gotcha → `references/ipv6-egress-broken.md`.
