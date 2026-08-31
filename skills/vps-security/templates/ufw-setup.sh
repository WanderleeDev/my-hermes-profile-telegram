#!/usr/bin/env bash
# UFW host-firewall setup for a VPS exposed to the internet.
# Safe to run: 22 is allowed BEFORE enable, so you won't lock yourself out (SSH is key-only).
set -e
sudo apt-get install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp      # SSH (key-only)
sudo ufw allow 80/tcp      # HTTP / Traefik
sudo ufw allow 443/tcp     # HTTPS / Traefik
# Docker Swarm ports: close to the world (single-node doesn't need them exposed)
sudo ufw deny 2377/tcp
sudo ufw deny 7946/tcp
sudo ufw deny 7946/udp
sudo ufw --force enable
sudo ufw status verbose

# NOTE: Docker-published container ports BYPASS UFW. For those (e.g. port 3000),
# restrict via the DOCKER-USER chain instead:
#   sudo iptables -I DOCKER-USER -p tcp --dport 3000 ! -s 10.0.0.0/8 -j DROP
#   sudo apt-get install -y iptables-persistent && sudo netfilter-persistent save
