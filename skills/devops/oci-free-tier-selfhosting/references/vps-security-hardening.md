# VPS Security Hardening (OCI Always-Free ARM, Ubuntu 24.04)

Condensed, reusable recipes for locking down a single-node OCI ARM VPS that
runs Docker Swarm + Dokploy + Traefik and is driven remotely by the Hermes
Telegram gateway. Derived from a real session on host `xam-vps`.

## Pre-flight safety rules
- SSH is key-only (`PasswordAuthentication no`). NEVER `ufw deny 22` or
  `ufw reset` without first confirming key login works — you get locked out.
- Because the agent is reached via Telegram (a channel independent of SSH),
  even if SSH gets wedged you can still issue fixes through the bot. This is
  why it is safe to (re)configure the firewall remotely.
- `sudo reboot` / `shutdown -r` is HARD-BLOCKED by the agent runtime. The user
  must trigger the reboot themselves; the agent can only prepare and verify.

## 1) UFW — host firewall
```bash
sudo apt-get install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp      # SSH (key-only)
sudo ufw allow 80/tcp      # HTTP (Traefik)
sudo ufw allow 443/tcp     # HTTPS (Traefik)
sudo ufw deny 2377/tcp     # Docker Swarm manager — close to world
sudo ufw deny 7946/tcp     # Docker Swarm node comm
sudo ufw deny 7946/udp
sudo ufw --force enable    # --force because 22 is already allowed
```
Verify: `sudo ufw status verbose` (Status: active, deny incoming).

### CRITICAL gotcha — Docker bypasses UFW
UFW filters the INPUT chain. Published containers insert DNAT rules in the
`DOCKER`/`FORWARD` chains and are reachable despite UFW. So a web panel on
`:3000` published by a container is STILL open after `ufw enable`.

Fix with the `DOCKER-USER` chain (evaluated before Docker's own rules):
```bash
# Drop any 3000 traffic NOT coming from private/LAN/loopback
sudo iptables -I DOCKER-USER -p tcp --dport 3000 ! -s 10.0.0.0/8  -j DROP
sudo iptables -I DOCKER-USER -p tcp --dport 3000 ! -s 172.16.0.0/12 -j DROP
sudo iptables -I DOCKER-USER -p tcp --dport 3000 ! -s 127.0.0.0/8   -j DROP
sudo iptables -I DOCKER-USER -p tcp --dport 3000 -j DROP
# Persist across reboots:
sudo apt-get install -y iptables-persistent
sudo netfilter-persistent save
```
`iptables -S DOCKER-USER` should end with `-A DOCKER-USER ... --dport 3000 -j DROP`.

## 2) fail2ban — brute-force banning
```bash
sudo apt-get install -y fail2ban
sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
EOF
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
```
Verify: `sudo fail2ban-client status sshd` (Jail list: sshd, Currently banned: 0).
Useful: `sudo fail2ban-client set sshd unbanip <IP>` if you lock yourself out.
Note: only the `sshd` jail is configured by default; add more jails if you later
expose other login-bearing services (web panels, etc.).

## 3) Hermes security audit (profile-scoped)
Read (do NOT blindly edit) `~/.hermes/profiles/<name>/config.yaml`.
Confirm these are at safe defaults (absence = safe default is applied):
- `security.redact_secrets` -> default `true` (masks API keys in tool output/logs)
- `approvals.mode` -> default `smart` (prompts before destructive commands)
- `tirith_enabled` -> default `true` if the binary is present
- `privacy.redact_pii` -> default `false`; **recommend setting `true` for
  Telegram** so the user's ID/phone are hashed before reaching the model.
  Requires a gateway restart to take effect.
Credential files should be `600`: `~/.hermes/.env`, `~/.hermes/auth.json`.

Agent isolation: `hermes -p <profile>` can drive any profile, but each
profile has isolated config/sessions/skills/memory under
`~/.hermes/profiles/<name>/`. For Docker-hosted Hermes the official compose
mounts `~/.hermes:/opt/data` and runs `gateway run` with `restart: unless-stopped`.

## Post-change verification checklist
After any firewall/gateway change, confirm ALL of:
- `sudo ss -tlnp | grep ':22'` -> sshd listening
- `sudo docker ps` -> dokploy / postgres / traefik Up
- `systemctl --user is-active hermes-gateway-telegram-bot` -> active
- `sudo ufw status` -> active, expected rules
- Dokploy panel 3000 still blocked from WAN (DOCKER-USER DROP present)
