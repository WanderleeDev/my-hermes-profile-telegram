---
name: herdr-studio
description: "Use when managing herdr-studio on xam-vps. Covers CLI commands, workspace management, agent control, mobile web access via port 8787, and security."
tags: [herdr, studio, mobile, agents, telegram, vps, security]
---

# Herdr Studio - Telegram Bot Profile

## Resumen

Herdr es el runtime para agentes de coding. Permite ejecutar agentes (Claude Code, Codex, Cursor, Hermes, etc.) en terminales persistentes que sobreviven a cierres de SSH y reconexiones desde cualquier dispositivo.

**Estado actual en xam-vps:**
- herdr server: `0.8.2` (corriendo en segundo plano)
- herdr-gui (web client): `0.5.2` (corriendo en puerto 8787)
- Workspace activo: `w1` (remoter) con 2 paneles
- Agente activo: `hermes` (idle)

## Acceso desde Telegram

El bot puede mostrar información de herdr cuando lo pidas:

### Comandos disponibles en Telegram
```
/herdr status    → Muestra estado de agentes y workspaces
/herdr list      → Lista todos los workspaces y paneles
/herdr <cmd>     → Ejecuta un comando en el workspace w1
```

### Ejemplo de uso
1. Te conectas por SSH al VPS y activas una sesión de herdr
2. Desde Telegram le pides al bot: "/herdr status"
3. El bot ejecuta `herdr workspace list` y te responde con el estado

### Configuración del comando
El bot ejecuta comandos herdr usando el terminal tool con el workspace adecuado.

## URL de acceso web
```
https://herdr-studio.wanderlee.site
```
- Túnel Cloudflare activo (corriendo)
- Requiere token o contraseña
- Mobile-first, accesible desde cualquier navegador

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
│  herdr server (proceso continuo systemd)            │
│  - Mantiene terminales vivos                        │
│  - Persiste sesiones entre reconexiones             │
│  - Socket: ~/.config/herdr/herdr.sock               │
└────────────────┬────────────────────────────────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
    ▼            ▼            ▼
 ┌──────┐   ┌────────┐   ┌──────────┐
 │ CLI  │   │  Web   │   │ Plugins  │
 │herdr │   │ herdr  │   │ herdr.   │
 │      │   │ -gui   │   │ studio   │
 │      │   │ :8787  │   │          │
 └──────┘   └────────┘   └──────────┘
```

**Flujo:**
1. `herdr server` corre como proceso systemd
2. Los agentes (hermes, claude-code, codex) corren en terminales dentro de herdr
3. herdr-gui provee interfaz web mobile-first
4. Puedes "attach" (adjuntarte) a cualquier terminal desde cualquier lugar
5. Si cierras SSH o reinicias, los agentes siguen corriendo

## Seguridad

### Autenticación
- herdr-gui usa token en `~/.config/herdr-gui/auth-token` (modo 0600)
- El token se envía en cada request API
- Por defecto escucha en `0.0.0.0:8787` (todas las interfaces)

### Recomendaciones de seguridad
1. **No exponer al internet público sin protección** - usar túnel SSH
2. El token es secreto - no compartirlo
3. herdr-gui puede ejecutar comandos en tu VPS (poderoso)
4. Para acceso remoto seguro, usa túnel SSH en vez de exponer directamente

### Verificar exposición
```bash
ss -tlnp | grep 8787
# Debería mostrar: 0.0.0.0:8787 (todas las interfaces)
```

## Troubleshooting

### herdr-gui no arranca
```bash
systemctl --user status herdr-gui
systemctl --user restart herdr-gui
```

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
journalctl --user -u herdr-gui -f
```

### Reiniciar agente específico
```bash
herdr agent restart hermes
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

### 2. Ver estado desde el teléfono (CLI)
```bash
ssh ubuntu@xam-vps
herdr list
```

### 3. Ver estado desde el teléfono (Web)
- Abrir navegador
- Ir a: `http://<IP_VPS>:8787`
- Ingresar token: `cat ~/.config/herdr-gui/auth-token`

### 4. Adjuntarse a una sesión existente
```bash
herdr attach w1:p1
# Ahora estás dentro de la terminal del agente
```

### 5. Enviar comando sin adjuntarse
```bash
herdr send w1:p1 "ls -la"
```

## Instalación (si se necesita reinstalar)

```bash
# Instalar desde GitHub
curl -fsSL https://github.com/powerfooi/herdr-studio/releases/latest/download/install-herdr-gui.sh | sh

# Configurar servicio systemd
herdr-gui service install

# Verificar
systemctl --user status herdr-gui
ss -tlnp | grep 8787
```

