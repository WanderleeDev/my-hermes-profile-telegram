---
name: herdr-studio
description: "Use when managing herdr-studio on xam-vps. Covers CLI commands, workspace management, agent control, mobile web access, and security."
tags: [herdr, studio, mobile, agents, telegram, vps, security]
---

# Herdr Studio - Telegram Bot Profile

## Resumen

Herdr es el runtime para agentes de coding. Permite ejecutar agentes (Claude Code, Codex, Cursor, etc.) en terminales persistentes que sobreviven a cierres de SSH y reconexiones desde cualquier dispositivo.

**Estado actual en xam-vps:**
- herdr server: `0.8.2` (corriendo en segundo plano)
- Workspace activo: `w1` (remoter) con 2 paneles
- Agente activo: `hermes` (idle)
- herdr-gui (web client): servicio configurado pero binario no disponible

## Cómo Acceder desde el Teléfono

### Opción 1: CLI SSH (Recomendado)
```bash
# Desde tu teléfono con SSH
ssh ubuntu@<IP_VPS>
herdr list              # Ver workspaces y agentes
herdr attach w1:p1      # Adjuntarte a un panel
```

### Opción 2: Web GUI (Local)
Si estás en la misma red WiFi:
```
http://<IP_VPS>:8787
```
Token de autenticación: `cat ~/.config/herdr-gui/auth-token`

### Opción 3: Tunnel SSH desde el teléfono
```bash
# En tu teléfono (termux o app SSH)
ssh -L 8787:localhost:8787 ubuntu@<IP_VPS>
# Luego abrir navegador: http://localhost:8787
```

## Comandos CLI Esenciales

```bash
# Status general
herdr status

# Ver workspaces y agentes
herdr workspace list
herdr list

# Adjuntarse a un terminal
herdr attach w1:p1

# Ver lista de paneles
herdr pane list

# Ejecutar comando en un panel
herdr send w1:p1 "comando aqui"

# Crear nuevo workspace
herdr workspace new mi-proyecto --cwd ~/projects/mi-proyecto

# Ver logs del servidor
tail -f ~/.config/herdr/herdr-server.log
```

## Arquitectura (Qué hace por detrás)

```
┌─────────────────────────────────────────────────────┐
│  herdr server (proceso continuo)                    │
│  - Mantiene terminales vivos                        │
│  - Persiste sesiones entre reconexiones             │
│  - Socket: ~/.config/herdr/herdr.sock               │
└────────────────┬────────────────────────────────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
    ▼            ▼            ▼
 ┌──────┐   ┌──────┐   ┌──────────┐
 │ CLI  │   │ GUI  │   │ Plugins  │
 │herdr │   │ herdr│   │ herdr.   │
 │      │   │-gui  │   │ studio   │
 └──────┘   └──────┘   └──────────┘
```

**Flujo:**
1. `herdr server` corre como proceso systemd
2. Los agentes (hermes, claude-code, codex) corren en terminales dentro de herdr
3. Puedes "attach" (adjuntarte) a cualquier terminal desde cualquier lugar
4. Si cierras SSH o reinicias, los agentes siguen corriendo

## Seguridad

### Autenticación
- herdr-gui usa token en `~/.config/herdr-gui/auth-token` (modo 0600)
- El token se envía en cada request API
- Por defecto solo escucha en localhost (`0.0.0.0:8787`)

### Recomendaciones de seguridad
1. **No exponer al internet público** sin VPN/túnel
2. Usar túnel SSH para acceso remoto seguro
3. El token es secreto - no compartirlo
4. herdr-studio puede modificar archivos del workspace (riesgo si está expuesto)

### Verificar exposición
```bash
ss -tlnp | grep 8787  # Debería ser 127.0.0.1:8787 o 0.0.0.0:8787
```

## Troubleshooting

### herdr server no responde
```bash
systemctl --user status herdr
systemctl --user restart herdr
```

### Limpiar socket viejo
```bash
rm -f ~/.config/herdr/herdr.sock
herdr restart
```

### Ver logs de errores
```bash
journalctl --user -u herdr -f
```

### Reiniciar agente específico
```bash
herdr agent restart hermes
```

### herdr-gui falla al arrancar
```bash
# El binario puede no estar instalado correctamente
systemctl --user status herdr-gui
# Opcionalmente reinstalar:
herdr plugin install powerfooi/herdr-gui
```

## Integración con Hermes

- El agente `hermes` corre dentro de herdr como workspace w1
- Sesiones persistentes: puedes desconectarte y volver sin perder trabajo
- Multi-agent: puedes tener hermes, claude-code, codex en diferentes workspaces
- Control desde móvil: CLI herdr + SSH o web GUI con túnel

## Workflows Comunes

### 1. Iniciar sesión de hermes en herdr
```bash
herdr workspace new hermes --cwd ~/.hermes/profiles/telegram-bot
herdr pane new bash
herdr send w1:p1 "hermes"
```

### 2. Ver estado desde el teléfono
```bash
ssh ubuntu@xam-vps
herdr list
```

### 3. Adjuntarse a una sesión existente
```bash
herdr attach w1:p1
# Ahora estás dentro de la terminal del agente
```

### 4. Enviar comando sin adjuntarse
```bash
herdr send w1:p1 "ls -la"
```
