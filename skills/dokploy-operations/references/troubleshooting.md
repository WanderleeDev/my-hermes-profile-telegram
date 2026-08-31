# Dokploy Troubleshooting Guide

## Common Issues

### 1. Container Shows as "Up" But Not Accessible

**Symptoms:** Container runs but app returns connection refused

**Check:**
```bash
# Verify port mapping
sudo docker ps | grep <container>

# Check if port is listening
sudo ss -tlnp | grep <port>

# Inspect container network
sudo docker inspect <container> | grep -A10 NetworkSettings
```

**Solution:** Port may not be published to host. Check Docker Compose for `ports:` vs `expose:`.

---

### 2. Traefik Not Routing to Service

**Symptoms:** 502 Bad Gateway or connection refused

**Check:**
```bash
# View Traefik logs
sudo docker logs dokploy-traefik

# Check Traefik API (if enabled)
sudo docker exec traefik traefik api --raw
```

**Common causes:**
- Missing labels in Docker Compose
- Service not healthy
- Network mismatch

---

### 3. Port 3000 Access Denied

**Symptoms:** "Connection refused" when accessing Dokploy panel

**Check:**
```bash
# Verify iptables rules
sudo iptables -L DOCKER-USER -n -v

# Check if service is listening
sudo ss -tlnp | grep 3000
```

**Solution:** Use SSH tunnel or access from localhost:
```bash
ssh -L 3000:localhost:3000 ubuntu@<server-ip>
```

---

### 4. Database Container Not Healthy

**Symptoms:** Postgres container shows "starting" instead of "healthy"

**Check:**
```bash
# View logs
sudo docker logs <postgres-container>

# Check health status
sudo docker inspect <postgres-container> | grep -A5 Health
```

**Solution:** Database may need time to initialize. Check if data directory has correct permissions.

---

### 5. Orphaned Networks After Removal

**Symptoms:** Stale networks after removing application

**Clean up:**
```bash
# List unused networks
sudo docker network ls --filter "dangling=true"

# Remove unused networks
sudo docker network prune
```

---

## Quick Diagnostics

```bash
# Full status check
echo "=== Containers ===" && sudo docker ps
echo "=== Networks ===" && sudo docker network ls
echo "=== Volumes ===" && sudo docker volume ls
echo "=== Services ===" && sudo docker service ls
echo "=== Ports ===" && sudo ss -tlnp | grep -E ":80|:443|:3000"
```