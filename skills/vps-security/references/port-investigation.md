# Port Investigation Checklist

When you spot an unexpected open port, follow this sequence:

## Step 1: Identify the Process
```bash
sudo ss -tulnp | grep :PORTNUM
```

## Step 2: Check Service Status
```bash
sudo systemctl status <service> --no-pager
```

## Step 3: Trace Dependencies
```bash
systemctl list-dependencies <service> --plain | head -5
```
Note: look for `remote-fs-pre.target`, `docker.service`, or other services that might break.

## Step 4: Check Active Usage
```bash
grep nfs /proc/mounts || echo "No NFS mounts"
sudo docker ps --format '{{.Names}}\t{{.Ports}}' | grep PORTNUM || echo "No containers use this port"
```

## Step 5: Check for Recent Activity
```bash
journalctl -u <service> --since '09:00' --no-pager 2>/dev/null | tail -3
ss -tulnp | grep rpcbind   # if service is rpcbind/any generic listener
```

## Step 6: Decision Tree
| Condition | Action |
|-----------|--------|
| No deps + no mounts + no containers + no recent activity | **Close in UFW + disable service** |
| Has Docker dependency | **Close in UFW only**, keep service running |
| Used by another service (e.g., NFS share) | **Keep open**, document in changelog |

## Step 7: Rollback Commands
If after disabling you find you need it:
```bash
sudo systemctl enable <service> && sudo systemctl start <service>
sudo ufw allow PORT/tcp && sudo ufw allow PORT/udp
```

## Common False Positives
- **rpcbind (port 111)**: System package installed by default on Ubuntu. Often unused. Safe to disable if no NFS involved.
- **111/tcp vs 111/udp**: rpcbind uses both — close BOTH directions.
- **Docker ports bypassing UFW**: Docker's `iptables` rules can make a port accessible even when UFW denies it. Always check `DOCKER-USER` chain and `ss -tulnp` directly.
- **localhost-only ports**: `127.0.0.X:PORT` is safe (not exposed to internet). Only worry about `0.0.0.0:PORT` or `[::]:PORT`.
