#!/bin/bash
set -e

ip route del default 2>/dev/null || true
ip route add default via 10.77.1.1

echo "[client] Routes:"
ip route
exec tail -f /dev/null
