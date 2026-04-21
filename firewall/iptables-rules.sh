#!/bin/bash
set -euo pipefail

SERVER="10.78.1.2"
BLOCKED_IP="10.77.1.10"

echo "============================================"
echo "  iptables rules — Variant 3"
echo "  Protecting server: $SERVER"
echo "============================================"

# ── Сброс ────────────────────────────────────────────
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# ── Политики ─────────────────────────────────────────
iptables -P INPUT ACCEPT
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# ═════════════════════════════════════════════════════
# ЗАДАНИЕ 4: Принимать ICMP echo-req не более 1 в сек
# ═════════════════════════════════════════════════════
iptables -A FORWARD -p icmp --icmp-type echo-request -d $SERVER \
    -m hashlimit \
    --hashlimit-name icmp_to_server \
    --hashlimit-upto 1/second \
    --hashlimit-burst 1 \
    --hashlimit-mode srcip \
    --hashlimit-htable-expire 10000 \
    -j ACCEPT

iptables -A FORWARD -p icmp --icmp-type echo-request -d $SERVER -j DROP

echo "[OK] Rule 4: ICMP rate limited 1/sec (before conntrack)"

iptables -A FORWARD -p icmp --icmp-type echo-reply -j ACCEPT

iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# ═════════════════════════════════════════════════════
# ЗАДАНИЕ 1: Блокировать Telnet к серверу с 10.77.1.10
# ═════════════════════════════════════════════════════
iptables -A FORWARD -p tcp --dport 23 \
    -s $BLOCKED_IP -d $SERVER \
    -m conntrack --ctstate NEW \
    -j DROP

echo "[OK] Rule 1: Telnet from $BLOCKED_IP blocked"

# ═════════════════════════════════════════════════════
# ЗАДАНИЕ 2: Блокировка invalid TCP к серверу
# ═════════════════════════════════════════════════════
iptables -A FORWARD -p tcp -d $SERVER \
    -m conntrack --ctstate INVALID -j DROP

iptables -A FORWARD -p tcp -d $SERVER \
    ! --syn -m conntrack --ctstate NEW -j DROP

echo "[OK] Rule 2: Invalid TCP blocked"

# ═════════════════════════════════════════════════════
# ЗАДАНИЕ 3: SSH max 3 параллельных с одного IP
# ═════════════════════════════════════════════════════
iptables -A FORWARD -p tcp --dport 22 -d $SERVER \
    -m conntrack --ctstate NEW \
    -m connlimit --connlimit-above 3 --connlimit-mask 32 \
    -j REJECT --reject-with tcp-reset

echo "[OK] Rule 3: SSH max 3 conn/IP"

iptables -A FORWARD -j ACCEPT

echo "=== FORWARD chain ==="
iptables -L FORWARD -v -n --line-numbers
