# Docker Swarm Basics for Dokploy

Dokploy uses Docker Swarm for orchestration. Understanding Swarm concepts helps troubleshoot deployment issues.

## Key Concepts

### Service vs Container
- **Service**: Declarative definition (what should run)
- **Container**: Actual running instance of a service

### Replicas
- Number of identical container instances
- Dokploy typically uses 1 replica for panel, multiple for apps

### Networks
- **ingress**: Overlay network for swarm routing
- **dokploy-network**: Internal swarm network
- **Custom networks**: Created per project (e.g., `agenttools-engram-tq17ar_default`)

### Volumes
- Persistent storage for databases
- Named volumes survive container recreation

## Common Commands

```bash
# List swarm services
sudo docker service ls

# List swarm networks
sudo docker network ls --filter "type=swarm"

# Inspect service
sudo docker service inspect <service-name>

# Scale service
sudo docker service scale <service>=<replicas>

# View service logs
sudo docker service logs <service-name>
```

## Dokploy Architecture

```
Internet → Traefik (80/443) → Docker Swarm Services → Containers
                    ↓
              Dokploy Panel (3000) - internal only
```

## Service Naming Pattern

Dokploy generates names like: `{project}-{app}-{random}_-{index}`

Example: `agenttools-engram-tq17ar-engram-1`