#!/bin/bash
set -e

ip route del default 2>/dev/null || true
ip route add default via 10.78.1.1

/usr/sbin/sshd
nginx

while true; do
    echo "Telnet server OK" | nc -l -p 23 -q 1 > /dev/null 2>&1
done &

echo "[server] Ready. Services: sshd:22, nginx:80, telnet:23"
exec tail -f /dev/null
