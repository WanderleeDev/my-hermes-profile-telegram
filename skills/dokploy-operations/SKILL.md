---
name: dokploy-operations
description: "Manage Dokploy deployments. Use for app management."
category: devops
---

# Dokploy Operations

Dokploy is a PaaS built on Docker Swarm with Traefik as reverse proxy. This skill covers common operations for managing deployments.

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Project** | Container for related services (e.g., "agent-tools") |
| **Application** | Individual service within a project (e.g., "engram", "opendesign") |
| **Stack** | Docker Compose deployment managed by Dokploy |
| **Traefik** | Reverse proxy handling HTTP/HTTPS routing |

## Common Operations

### List Active Services

```bash
# See all containers (local + swarm)
sudo docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

# See swarm services only
sudo docker service ls --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}"

# Check networks
sudo docker network ls
```

### Stop/Remove Application

```bash
# Stop container
sudo docker stop <container-name>

# Remove container
sudo docker rm <container-name>

# Remove network (if exists)
sudo docker network rm <network-name>

# Remove volume (if exists)
sudo docker volume rm <volume-name>
```

**Important:** Always check for residual networks and volumes after removal.

### Check Dokploy Panel Access

| URL | Access |
|-----|--------|
| `http://<server-ip>:3000` | Panel (blocked externally by iptables) |
| `http://localhost:3000` | Panel (from server itself) |

**SSH Tunnel for remote access:**
```bash
ssh -L 3000:localhost:3000 ubuntu@<server-ip>
```

## Security Notes

- Port 3000 is blocked externally by iptables DOCKER-USER chain
- Only internal networks (10.0.0.0/8, 172.16.0.0/12, 127.0.0.1) can access the panel
- Traefik (80/443) handles external routing to your apps

## Troubleshooting

### Container not showing in `docker ps`
- Check if it's a swarm service: `sudo docker service ls`
- Check all containers (including stopped): `sudo docker ps -a`

### Port not accessible
- Verify iptables DOCKER-USER rules: `sudo iptables -L DOCKER-USER -n -v`
- Check if port is bound: `sudo ss -tlnp | grep <port>`

### Network issues
- List networks: `sudo docker network ls`
- Inspect network: `sudo docker network inspect <network-name>`