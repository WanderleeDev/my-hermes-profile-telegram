#!/usr/bin/env bash
# Weekly security+usage audit. Run by `hermes cron`, deliver to Telegram.
# Must be chmod +x and test-run once before scheduling.
{
echo "📊 RESUMEN SEMANAL — xam-vps — $(date '+%Y-%m-%d %H:%M %Z')"
echo
echo "== SISTEMA =="
uptime
free -h | head -2
df -h / | tail -1
echo
echo "== DOCKER / SWARM =="
sudo docker info --format 'Swarm: {{.Swarm.LocalNodeState}}' 2>/dev/null
sudo docker ps --format '  {{.Names}} -> {{.Status}}' 2>/dev/null
echo
echo "== GATEWAY TELEGRAM =="
echo "  estado: $(systemctl --user is-active hermes-gateway-telegram-bot 2>/dev/null)"
echo
echo "== AUDITORIA SEGURIDAD =="
echo "  UFW: $(sudo ufw status | head -1)"
sudo fail2ban-client status sshd 2>/dev/null | grep -E "Currently banned|Total banned" | sed 's/^/  /'
sudo sshd -T 2>/dev/null | grep -iE "passwordauthentication|permitrootlogin" | sed 's/^/  /'
echo "  puertos WAN: $(sudo ss -tlnp 2>/dev/null | grep -oE ':[0-9]+' | sort -u | tr '\n' ' ')"
echo
echo "== UPDATES =="
sudo apt-get update -qq 2>/dev/null
sudo apt-get -s upgrade 2>/dev/null | grep -E "^[0-9]+ upgraded" | sed 's/^/  /'
[ -f /var/run/reboot-required ] && echo "  Reboot: REQUERIDO" || echo "  Reboot: no"
} 2>&1
