---
name: vps-security
description: Harden and audit a Linux VPS (UFW firewall, fail2ban with exponential bantime, SSH key-only audit, security-audit checklist, cron-based monitoring). Use whenever the user wants to secure, audit, or monitor a server, or set up periodic security/usage reports via cron.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
---

# VPS Security — Hardening, Audit, Monitoring

Recurring class of work: lock down a VPS, audit its exposure, and report on it on a
schedule. Verified on Ubuntu 24.04 ARM (OCI Ampere A1), but applies to any Debian/Ubuntu.

## ⚠️ BEHAVIORAL RULE (this user — permanent)
NEVER execute a system-changing command (install, config edit, firewall rule, service
restart, stateful cron creation) without an **explicit order** AND, for anything
non-trivial, a shown plan + confirmation. Do NOT interpret vague messages
("cómo vamos?", "dale", "procede") as approval to act. This user corrected the agent
for proceeding on an ambiguous "how's it going?". Treat as permanent.
Pure read-only inspection (status checks, `ss`, `grep` config) is fine without
confirmation — but if a read reveals you should change something, stop and ask.

## When to use
- "securizar mi vps", "configura firewall", "instala fail2ban", "audita seguridad"
- "revisa puertos / ssh / uptime", conceptual Qs ("diferencia gpt mbr", "q es swap")
- Set up periodic reports via cron (usage + audit + updates, or detailed ban report).

## 1) Read-only audit (always safe, do first)
Full checklist + commands in `references/security-audit.md`. Quick pass:
```bash
sudo ufw status verbose
sudo fail2ban-client status sshd
sudo sshd -T | grep -iE "permitrootlogin|passwordauthentication"
sudo ss -tlnp | grep -oE ':[0-9]+' | sort -u
```
Docker publishes ports and **bypasses UFW** via its own iptables rules — audit the
`DOCKER-USER` chain for container-exposed ports (e.g. `iptables -S DOCKER-USER`).

## 2) UFW (host firewall) — template `templates/ufw-setup.sh`
- Default deny incoming, allow outgoing.
- Allow 22/tcp (key-only SSH), 80, 443. Deny swarm ports 2377/7946.
- Activate with `sudo ufw --force enable` (safe because 22 already allowed).
- Docker ports still bypass UFW — use the `DOCKER-USER` chain for those.

## 3) fail2ban (brute-force banning) — template `templates/jail.local`
Non-obvious part is the **bantime formula** — detail in `references/fail2ban-bantime.md`. Summary:
- `bantime.increment = true` makes the ban grow with `ban.Count` (times the IP re-banned).
- Default formula is exponential: `ban.Time * (1<<ban.Count)` → 1h,2h,4h,8h... capped at
  Count=20 (~115 years). Effectively "no limit" for real attackers.
- Logarithmic alternative: `ban.Time * (1 + int(math.log(1+ban.Count*4))) * 3600`.
- ALWAYS set `ignoreip` with the user's fixed IP + localhost so you never ban yourself.

## 4) Cron monitoring (pattern the user liked)
A read-only script run by `hermes cron` on a schedule, delivered to Telegram. Two
separate jobs at the same time:
- Weekly usage + security audit + updates → `templates/security-audit.sh`
- Detailed ban report with geo-IP of banned/suspicious IPs → `templates/ban-report.sh`
Schedule `0 9 * * 0,3` (both sunday AND wednesday). Scripts must be `+x` and tested once before scheduling.

## 5) Port exposure investigation
When you spot an open port not in UFW allow/deny rules, use `references/port-investigation.md` for the full checklist. Quick pass:
```bash
sudo ss -tulnp | grep :PORTNUM
sudo systemctl status <service>
systemctl list-dependencies <service>
grep nfs /proc/mounts || echo "no nfs mounts"
```
1. `sudo ss -tulnp` — find the process binding to the port
2. `sudo systemctl status <service>` — understand what it is
3. `systemctl list-dependencies <service>` — does anything need it?
4. `grep nfs /proc/mounts` — if empty, service is probably unused
5. `sudo docker ps --format '{{.Names}}\t{{.Ports}}' | grep PORTNUM` — check containers
6. If unused → close in UFW (`sudo ufw deny PORT/tcp && sudo ufw deny PORT/udp`) THEN disable service
7. If used only internally → close in UFW but keep service running
Example: rpcbind (port 111) was found exposed, unused, and safely disabled.

## 6) Security changelog (new in 2026-07-21)
For major security changes, maintain `/home/ubuntu/<server>-security-changelog.md` with entries containing:
- Date, type (hardening/bugfix/config), author, motive, actions taken, impact, rollback instructions

## 7) SSH hardening (Ubuntu 24.04 socket-activation aware)
For maximum security, apply ALL four in one pass:
```bash
sudo sed -i 's/^#PermitRootLogin prohibit-password$/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^MaxAuthTries 6$/MaxAuthTries 3/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication yes$/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i '/^PubkeyAuthentication yes/a \\nAllowUsers ubuntu' /etc/ssh/sshd_config
sudo sshd -t && echo "✅ valid" || echo "❌ error"
```
### Socket-activated sshd (Ubuntu 24.04+)
`systemctl restart sshd` may fail because sshd runs via socket-activation now:
```
● ssh.socket → triggers ssh.service per connection
```
If `sshd -t` passes but restart fails, use:
```bash
sudo kill -HUP $(pgrep -x sshd | head -1)   # reload config without dropping sessions
sudo systemctl restart ssh.socket              # or restart the socket unit
```
Verify with `sudo sshd -T | grep -iE "^permitrootlogin|^maxauth|^passwordauthentication|^allowusers"`.

### Verify root access before locking down
Before setting `PermitRootLogin no`, confirm `/root/.ssh/authorized_keys` does NOT exist:
```bash
ls -la /root/.ssh/authorized_keys 2>/dev/null || echo "No root key (safe)"
```
If keys DO exist for root, add them first or migrate the user.

## 8) Script centralization pattern
When adding or reorganizing server scripts:
1. Create `~/scripts/` directory for all automation scripts
2. Move existing `.sh` files from home dir into `scripts/`
3. Update any cron jobs / systemd timers / other references with new paths
4. Remove obsolete scripts and backup their functionality if needed
Example: today we consolidated `weekly-audit.sh`, `ban-report.sh` into `~/scripts/` and updated both cron job prompts with the new paths (`/home/ubuntu/scripts/...`).

## 9) OpenRouter model verification (live API check)
Never trust cached knowledge about which `:free` models still work — they churn constantly. To verify vision-capable free models live:
```python
import urllib.request, json
env = open("~/.hermes/profiles/telegram-bot/.env").read()
m = re.search(r'^OPENROUTER_API_KEY\s*=(.*)', env, re.M)
key = m.group(1).strip().split('#')[0].strip()
req = urllib.request.Request("https://openrouter.ai/api/v1/models",
                             headers={"Authorization": f"Bearer {key}"})
with urllib.request.urlopen(req, timeout=20) as r:
    data = json.loads(r.read().decode())
vision_free = [md["id"] for md in data.get("data",[])
               if ":free" in md.get("id","")
               and "image" in (md.get("architecture",{}).get("input_modalities",[]))]
for vid in vision_free: print(vid)
```
Only the top results above should be trusted as available. Save verified list to `references/free-vision-models.md`.

## 10) Cron job drift prevention (CRITICAL)
When you change the **global model** (`model.default`), ALL unpinned cron jobs get a "drift" error and skip execution silently:
```
RuntimeError: Skipped to prevent unintended spend: global inference config drifted
```
**Always pin cron jobs to a model BEFORE changing the global one:**
```
cronjob action=update job_id=<ID> model={provider,model}
```
Or use `fallback_model` so the bot itself has a recovery path. See section 11 below.

## 11) Fallback model configuration
Add a fallback in case the primary model hits 429 rate-limits:
```yaml
fallback_model:
  provider: openrouter
  model: openrouter/free          # router auto-selects any free model
```
This is safer than pinning cron jobs to a specific model because:
- Only activates when primary fails (hy3:free returns 429)
- Does NOT cause cron drift (the cron's model stays fixed; only the user-facing request uses the fallback)
- User never notices the switch — they just keep chatting

## 12) OpenRouter 429 is REQUEST-COUNT, NOT credit exhaustion
When `total_usage: 0` and you get 429: it means daily request quota reached, not "no credits".
- 50 requests/day without $10 deposit → 1000/day with deposit
- Each `:free` model also has its own RPM cap beyond account-level limit
- Wait for midnight UTC reset or upgrade to $10 deposit tier

## Gotchas
- **Cannot restart the Hermes gateway from inside the gateway** (SIGTERM kills the chat).
  For `hermes config set` changes (e.g. `redact_pii`, model) that need a reload, tell the
  USER to run `hermes gateway restart` from SSH. Don't attempt it from the chat — it's
  blocked and would cut the session.
- fail2ban `ignoreip` must list the user's CURRENT fixed IP; if their IP changes, update it
  or they risk a self-ban.
- `redact_pii: true` only obfuscates the user ID/phone for the *model*; routing still uses
  `.env` (TELEGRAM_ALLOWED_USERS / HOME_CHANNEL) and the on-disk session index.
- Check `TELEGRAM_ALLOWED_USERS` / `HOME_CHANNEL` in the profile `.env` — that's the access
  filter and where the bot stores the user's ID; `redact_pii` does not remove it.
- **Docker bypasses UFW** for published ports — always audit `iptables -L DOCKER-USER` after
  deploying services with docker-compose/swarm.
- **rpcbind safety check** (port 111): Common false-positive. Check deps, NFS mounts, containers
  before disabling. Rollback: `enable rpcbind + start + delete UFW deny rules`.
- **Cron job drift prevention**: When changing the global model, ALWAYS re-pin cron jobs to the
  new model via `cronjob action=update job_id=X model={provider,model}` — otherwise they skip
  execution with "global inference config drifted" error.
