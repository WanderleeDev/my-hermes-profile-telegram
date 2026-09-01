#!/usr/bin/env bash
# Detailed ban/security report. Run by `hermes cron`, deliver to Telegram.
# Must be chmod +x and test-run once before scheduling.
{
echo "🛡️ REPORTE DE BANS — xam-vps — $(date '+%Y-%m-%d %H:%M %Z')"
echo
echo "== Actualmente baneadas (con geo) =="
banned=$(sudo fail2ban-client get sshd banned 2>/dev/null | tr -d '[]'"'"' ')
if [ -z "$banned" ]; then
  echo "  (ninguna en este momento)"
else
  for ip in $banned; do
    geo=$(curl -s --max-time 8 "http://ip-api.com/json/$ip?fields=country,as,org,proxy" 2>/dev/null)
    echo "  $ip -> $geo"
  done
fi
echo
echo "== Total historico baneadas =="
sudo fail2ban-client status sshd 2>/dev/null | grep "Total banned"
echo
echo "== Top IPs sospechosas (ultimas 24h, journal sshd) =="
sudo journalctl _SYSTEMD_UNIT=ssh.service --since "24h ago" --no-pager 2>/dev/null \
  | grep -oE "from [0-9.]+" | awk '{print $2}' | sort | uniq -c | sort -rn | head -10 \
  | while read n ip; do
      geo=$(curl -s --max-time 8 "http://ip-api.com/json/$ip?fields=country" 2>/dev/null | grep -o '"country":"[^"]*"' | cut -d'"' -f4)
      echo "  $n intentos  $ip  ($geo)"
    done
echo
echo "== Usuarios mas probados (ultimas 24h) =="
sudo journalctl _SYSTEMD_UNIT=ssh.service --since "24h ago" --no-pager 2>/dev/null \
  | grep -oE "invalid user [a-z]+" | awk '{print $3}' | sort | uniq -c | sort -rn | head -8
} 2>&1
