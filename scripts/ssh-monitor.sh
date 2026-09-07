#!/bin/bash
# SSH Connection Monitor - Tiempo real
# Monitorea logs de SSH y notifica por Telegram

BOT_TOKEN=$(grep -o 'bot_token:.*' ~/.hermes/profiles/telegram-bot/config.yaml 2>/dev/null | awk '{print $2}' | tr -d '"')
CHAT_ID="8804630280"
STATE_FILE="/home/ubuntu/.ssh_monitor_state"
LOG_FILE="/home/ubuntu/.ssh_monitor.log"

# Obtener posición actual del log
get_log_position() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "0"
    fi
}

# Guardar posición
save_position() {
    echo "$1" > "$STATE_FILE"
}

# Enviar notificación
send_alert() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=$message" \
        -d "parse_mode=Markdown" \
        --max-time 10 > /dev/null 2>&1
    echo "[$(date)] $message" >> "$LOG_FILE"
}

# Inicializar
last_pos=$(get_log_position)

# Determinar fuente de logs
if [ -f /var/log/auth.log ]; then
    LOG_SOURCE="/var/log/auth.log"
elif [ -f /var/log/secure ]; then
    LOG_SOURCE="/var/log/secure"
else
    # Usar journalctl como fallback
    LOG_SOURCE="journal"
fi

echo "🔍 SSH Monitor iniciado..."
echo "   Fuente: $LOG_SOURCE"
echo "   Última posición: $last_pos"

while true; do
    if [ "$LOG_SOURCE" = "journal" ]; then
        # Monitorear journalctl
        current_pos=$(journalctl -u ssh -n 1 --no-pager --output=short-precise 2>/dev/null | wc -l)
        new_entries=$(journalctl -u ssh --no-pager -n 0 --since "5 minutes ago" 2>/dev/null | grep -E "Accepted|session opened|New session" | tail -5)
        
        if [ -n "$new_entries" ]; then
            while IFS= read -r line; do
                [ -z "$line" ] && continue
                # Extraer IP y usuario
                ip=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | tail -1)
                user=$(echo "$line" | grep -oE 'user [^ ]+' | awk '{print $2}' || echo "unknown")
                
                if [ -n "$ip" ]; then
                    send_alert "🔐 *Nueva conexión SSH*

👤 Usuario: $user
🌐 IP: $ip
⏰ $(date '+%H:%M:%S')

⚠️ Verifica tu servidor"
                    sleep 2  # Evitar spam
                fi
            done <<< "$new_entries"
        fi
    else
        # Monitorear archivo de log con tail
        current_size=$(wc -c < "$LOG_SOURCE" 2>/dev/null || echo "0")
        
        if [ "$current_size" -gt "$last_pos" ]; then
            # Leer nuevas líneas
            new_content=$(tail -c +$((last_pos + 1)) "$LOG_SOURCE" 2>/dev/null | grep -E "Accepted|session opened|New session|Reverse address" | tail -10)
            
            if [ -n "$new_content" ]; then
                while IFS= read -r line; do
                    [ -z "$line" ] && continue
                    ip=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | tail -1)
                    user=$(echo "$line" | grep -oE 'user [^ ]+' | awk '{print $2}' || echo "unknown")
                    
                    if [ -n "$ip" ]; then
                        send_alert "🔐 *Nueva conexión SSH*

👤 Usuario: $user
🌐 IP: $ip
⏰ $(date '+%H:%M:%S')

⚠️ Verifica tu servidor"
                        sleep 2
                    fi
                done <<< "$new_content"
            fi
        fi
        
        last_pos=$current_size
    fi
    
    sleep 30
done
