#!/bin/sh
# Stop the dsh container from reaching private networks. Internet stays open.
# Run as root on the Docker host after `docker compose up`. Not persistent across reboots.
set -eu

bridge="${1:-br-dsh}"
ranges="10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 100.64.0.0/10 169.254.0.0/16"

for net in $ranges; do
  if ! iptables -C DOCKER-USER -i "$bridge" -d "$net" -j DROP 2>/dev/null; then
    iptables -I DOCKER-USER -i "$bridge" -d "$net" -j DROP
  fi
done

# Replies to connections the host started (the published port) must still pass.
if ! iptables -C DOCKER-USER -i "$bridge" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null; then
  iptables -I DOCKER-USER -i "$bridge" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
fi

iptables -S DOCKER-USER
