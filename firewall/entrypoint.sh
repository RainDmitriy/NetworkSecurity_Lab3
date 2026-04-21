#!/bin/bash
set -e

echo "[firewall] IP forwarding: $(cat /proc/sys/net/ipv4/ip_forward)"
echo "[firewall] Interfaces:"
ip -br addr
echo "[firewall] Ready — run 'make rules'"
exec tail -f /dev/null
