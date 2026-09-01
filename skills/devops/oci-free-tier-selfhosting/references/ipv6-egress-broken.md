# OCI Always-Free ARM: no IPv6 egress (breaks api.telegram.org, etc.)

## Symptom
A process that talks to `api.telegram.org` (or any host that resolves to IPv6
first) hangs forever in `connect()` — state `S`/sleeping, ~0% CPU, never
times out on its own. On the Hermes Telegram gateway this shows as:

```
WARNING [...] Discovering Telegram API fallback IPs via DNS-over-HTTPS…
WARNING [...] Connecting to Telegram (attempt 1/8)…
```
...and then it just sits there. No error, no progress.

## Root cause
OCI Always-Free ARM VM.Standard.A1.Flex has **no IPv6 egress route** — only
link-local (`fe80::/64`) and loopback `::1`. `api.telegram.org` resolves via
the system resolver to a single IPv6 address first:

```
$ getent hosts api.telegram.org
2001:67c:4e8:f004::9 api.telegram.org     # IPv6 only
$ curl -6 -s --max-time 8 -o /dev/null -w "%{http_code}\n" https://api.telegram.org
000                                        # IPv6 egress FAILS
$ curl -4 -s --max-time 8 -o /dev/null -w "%{http_code}\n" https://api.telegram.org
302                                        # IPv4 works fine
```

The connect blackholes instead of being rejected, so the client's retry/timeout
ladder never fires promptly. The Hermes Telegram adapter's "fallback IP"
transport only kicks in AFTER the primary DNS path fails — and the primary path
is the one hanging on IPv6.

## Fix (persists across reboots)
Force the system resolver to return IPv4 by pinning the host in `/etc/hosts`
with Telegram's official Bot API IPv4. Back up first, then append (needs sudo):

```bash
sudo cp /etc/hosts /etc/hosts.bak."$(date +%s)"
# Official Telegram Bot API IPv4 (149.154.160.0/20 block). Confirm current
# value via DoH before trusting:
#   curl -s 'https://dns.google/resolve?name=api.telegram.org&type=A'
printf '149.154.166.110 api.telegram.org\n' | sudo tee -a /etc/hosts
```

Verify the resolver now returns IPv4 first:
```bash
python3 -c "import socket; print(socket.getaddrinfo('api.telegram.org',443,socket.AF_UNSPEC)[0])"
# -> (<AddressFamily.AF_INET: 2>, ..., ('149.154.166.110', 443))
```

Then restart the gateway: `hermes gateway restart`. It will connect within
seconds and begin polling.

## After connecting: "Chat not found"
Once the bot reaches Telegram it may log
`Failed to send Telegram message: Chat not found` for the home-channel startup
notification. This is EXPECTED and harmless on first boot — a Telegram bot
cannot message a user until that user has initiated the conversation. Fix by
opening the chat with the bot in Telegram and sending `/start` (or any message).
The channel then binds and notifications work.

## Generalization
This is NOT a Telegram-only issue. Any outbound client that uses the system
resolver and prefers AAAA will hang on this VM: SMTP to IPv6 MX, `pip`/`npm`
hitting IPv6-only mirrors, webhooks to IPv6-first hosts. Same fix: pin the
problematic hostname to its IPv4 in `/etc/hosts`. (Disabling AAAA at
systemd-resolved is unreliable on the OCI stub resolver; the /etc/hosts pin is
the robust approach.)

## Why not just set HERMES_TELEGRAM_INIT_TIMEOUT lower?
That only shortens each retry's timeout; it does not stop the primary path from
trying IPv6 first, and a too-low value causes flaky connects. /etc/hosts IPv4
pin is the real fix.
