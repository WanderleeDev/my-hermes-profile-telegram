#!/bin/bash
# SSH Connection Alert Script - Versión final
# Solo alerta cuando hay NUEVAS conexiones SSH (no las existentes)

BOT_TOKEN=$(grep -o 'bot_token:.*' ~/.hermes/profiles/telegram-bot/config.yaml 2>/dev/null | awk '{print $2}' | tr -d '"')
CHAT_ID="8804630280"  # User ID desde config

STATE_FILE="/home/ubuntu/.ssh_alert_state"
LOG_FILE="/home/ubuntu/.ssh_alerts.log"
PREV_STATE="/home/ubuntu/.ssh_last_connections"

# Obtener conexiones actuales (excluyendo tmux local)
current_connections=$(last -n 20 2>/dev/null | grep -E "pts/[0-9]" | grep -v "tmux" | grep -v "^$" | awk '{print $1"@"$3}' | sort -u)

if [ -z "$current_connections" ]; then
    exit 0
fi

# Si es la primera vez, guardar estado y salir
if [ ! -f "$PREV_STATE" ]; then
    echo "$current_connections" > "$PREV_STATE"
    exit 0
fi

# Obtener conexiones previas
prev_connections=$(cat "$PREV_STATE")

# Encontrar conexiones NUEVAS (que no estaban antes)
new_connections=""
while IFS= read -r conn; do
    [ -z "$conn" ] && continue
    if ! echo "$prev_connections" | grep -qF "$conn"; then
        new_connections="${new_connections}${conn}\n"
    fi
done <<< "$current_connections"

# Si no hay conexiones nuevas, actualizar estado y salir
if [ -z "$new_connections" ]; then
    echo "$current_connections" > "$PREV_STATE"
    exit 0
fi

# Construir mensaje de alerta
message="🔐 *Nueva conexión SSH*\n\n"
message+="📅 $(date '+%H:%M:%S %Y-%m-%d')\n"
message+="👤 Desde:\n"

while IFS= read -r conn; do
    [ -z "$conn" ] && continue
    user=$(echo "$conn" | cut -d'@' -f1)
    ip=$(echo "$conn" | cut -d'@' -f2)
    message+="• ${user}@${ip}\n"
done <<< "$new_connections"

message+="\n⚠️ Revisa tu servidor"

# Enviar alerta por Telegram
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=$CHAT_ID" \
    -d "text=$message" \
    -d "parse_mode=Markdown" \
    --max-time 10 > /dev/null 2>&1

# Registrar en log
echo "[$(date)] ALERT: $new_connections" >> "$LOG_FILE"

# Actualizar estado
echo "$current_connections" > "$PREV_STATE"
date +%s > "$STATE_FILE"

echo "✅ Alerta enviada"
