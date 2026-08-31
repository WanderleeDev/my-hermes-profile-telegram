# SSHD Socket Activation on Ubuntu 24.04+

## The Problem
On Ubuntu 24.04 (and newer), `sshd` is **socket-activated** instead of running as a long-lived service:

```
● ssh.socket → triggers ssh.service per connection
```

This means `systemctl restart sshd.service` or `sudo systemctl restart sshd` will **fail**:
```
Failed to restart sshd.service: Unit sshd.service not found.
```

## How to Reload Config Changes
When editing `/etc/ssh/sshd_config`, you need to reload without killing active sessions:

```bash
# Option 1: SIGHUP to the sshd process
sudo kill -HUP $(pgrep -x sshd | head -1)

# Option 2: Restart the socket unit
sudo systemctl restart ssh.socket

# Option 3: Both (belt and suspenders)
sudo kill -HUP $(pgrep -x sshd | head -1) && sudo systemctl restart ssh.socket
```

## Verification
After reload, verify the new config is active:
```bash
sudo sshd -T 2>/dev/null | grep -iE "^permitrootlogin|^maxauth|^passwordauthentication|^allowusers"
```

## What Gets Reaped
Socket-activation doesn't change what `sshd -t` validates (syntax still works). It only changes:
- HOW the process starts (on-demand via socket, not at boot)
- HOW to restart it (via socket unit or SIGHUP, not the service unit)
- Memory usage (lower when idle, since socket listens but no daemon runs)
