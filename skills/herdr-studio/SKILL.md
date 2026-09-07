---
name: herdr-studio
description: "Use when managing herdr-studio on xam-vps. Covers CLI commands, workspace management, agent control, and mobile web access via Dokploy port 3000."
tags: [herdr, studio, mobile, agents, telegram, vps]
---

# Herdr Studio - Telegram Bot Profile

## Overview

Herdr es el runtime para agentes de coding. Herdr-studio es el cliente web mobile-first que permite ver y controlar los agentes desde el teléfono.

**Estado actual en xam-vps:**
- herdr server: corriendo (version 0.8.2)
- herdr-studio: accesible via Dokploy en puerto 3000
- Agente activo: `hermes` en workspace w1, pane p1
- Plugin: `herdr.studio` instalado

## Acceso Web

herdr-studio está disponible en el puerto 3000 vía Dokploy:
- URL: `https://xam-vps.tudominio.com` (o IP del VPS)
- También accesible desde red local: `http://<IP_VPS>:3000`

## Comandos CLI Esenciales

```bash
# Status general
herdr status

# Ver agentes activos
herdr list

# Ver workspaces
herdr workspace list

# Ver panes/terminales
herdr pane list

# Controlar agente específico
herdr agent focus <workspace>:<pane>

# Ejecutar comando en terminal
herdr send <workspace>:<pane> "comando a ejecutar"

# Ver logs del servidor
cat ~/.config/herdr/herdr-server.log

# Plugins instalados
ls ~/.local/state/herdr/plugins/
```

## Estructura de Archivos

```
~/.config/herdr/           # Config y sockets
  ├── config.toml
  ├── herdr.sock          # Socket principal
  └── herdr-server.log    # Logs del servidor

~/.local/state/herdr/      # Estado y plugins
  └── plugins/
      └── herdr.studio/   # Plugin del web client

~/.local/bin/herdr         # Binario principal
~/.local/bin/herdr-gui     # GUI desktop (opcional)
```

## Workflows Comunes

### 1. Ver estado de agentes
```bash
herdr list
# Muestra: agentes, workspaces, panes activos, estado
```

### 2. Adjuntarse a una terminal
```bash
# Desde SSH en el VPS
herdr attach w1:p1    # workspace w1, pane p1
```

### 3. Desde el teléfono (herdr-studio)
- Abrir navegador → ir a la URL de Dokploy
- Ver workspaces y agentes en tiempo real
- Poder adjuntarse a terminales
- Ver output de agentes en ejecución

### 4. Crear nuevo workspace
```bash
herdr workspace new mi-proyecto
herdr pane new        # crear terminal dentro del workspace
```

## Integración con Hermes

El agente `hermes` corre dentro de herdr como workspace w1. Esto permite:
- Sesiones persistentes que sobreviven a cierres de SSH
- Acceso móvil via herdr-studio
- Múltiples workspaces para diferentes proyectos
- Control desde cualquier dispositivo con navegador

## Troubleshooting

### herdr no responde
```bash
systemctl --user status herdr
# Si está caído:
systemctl --user start herdr
```

### Limpiar socket viejo
```bash
rm -f ~/.config/herdr/herdr.sock
herdr restart
```

### Ver logs de errores
```bash
tail -f ~/.config/herdr/herdr-server.log
```

### Reiniciar agente
```bash
herdr agent restart hermes
```

## Notas para Distribución

Al clonar el perfil en otro VPS:
1. Instalar herdr: `curl -fsSL https://get.herdr.dev | bash`
2. Iniciar: `systemctl --user enable --now herdr`
3. Acceder a herdr-studio via navegador en puerto 3000
4. Configurar Dokploy o reverse proxy si se desea acceso remoto
