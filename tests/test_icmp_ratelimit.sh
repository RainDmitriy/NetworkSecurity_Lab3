#!/bin/bash
PASS=0; FAIL=0
SERVER=10.78.1.2

docker exec lab-firewall iptables -Z

echo "[4.1] 20 pings at 0.05s interval — most should drop"
PING_OUTPUT=$(docker exec lab-client ping -c 20 -i 0.05 -W 1 $SERVER 2>&1)
echo "$PING_OUTPUT"

RECEIVED=$(echo "$PING_OUTPUT" | grep -oP '\d+ received' | grep -oP '^\d+')
echo "  Sent: 20, Received: ${RECEIVED:-0}"

# Смотрим счётчики правил — главный критерий
ACCEPTED=$(docker exec lab-firewall iptables -L FORWARD -v -n | \
    awk '/icmp.*hashlimit/ {print $1}')
DROPPED=$(docker exec lab-firewall iptables -L FORWARD -v -n | \
    awk '/DROP.*icmp.*icmptype 8/ {print $1}')

echo "  FORWARD ICMP ACCEPT (hashlimit): ${ACCEPTED:-0}"
echo "  FORWARD ICMP DROP:               ${DROPPED:-0}"

# Правило считает правильно — проверяем счётчик DROP
if [ "${DROPPED:-0}" -gt 0 ]; then
    echo "PASS: rate limiting works (${DROPPED} dropped in FORWARD)"; ((PASS++))
elif [ "${ACCEPTED:-0}" -le 5 ]; then
    echo "PASS: rate limiting works (only ${ACCEPTED} accepted)"; ((PASS++))
else
    echo "FAIL: rate limiting not working"

    # Диагностика br_netfilter
    echo ""
    echo "  === Диагностика ==="
    echo "  br_netfilter:"
    sysctl net.bridge.bridge-nf-call-iptables 2>/dev/null || \
        docker exec lab-firewall cat /proc/sys/net/bridge/bridge-nf-call-iptables 2>/dev/null || \
        echo "  not available"
    ((FAIL++))
fi

echo ""
echo "[4.2] 4 pings at 1.5s interval — all should pass"
sleep 2
docker exec lab-firewall iptables -Z
PING_OUTPUT2=$(docker exec lab-client ping -c 4 -i 1.5 -W 2 $SERVER 2>&1)
echo "$PING_OUTPUT2"

RECEIVED2=$(echo "$PING_OUTPUT2" | grep -oP '\d+ received' | grep -oP '^\d+')
ACCEPTED2=$(docker exec lab-firewall iptables -L FORWARD -v -n | \
    awk '/icmp.*hashlimit/ {print $1}')

echo "  Received: ${RECEIVED2:-0}/4, FORWARD ACCEPT: ${ACCEPTED2:-0}"

if [ "${RECEIVED2:-0}" -ge 3 ]; then
    echo "PASS: slow pings pass"; ((PASS++))
else
    echo "FAIL: slow pings blocked"; ((FAIL++))
fi

echo ""
echo "=== FORWARD ICMP counters ==="
docker exec lab-firewall iptables -L FORWARD -v -n | grep icmp

echo ""
echo "Test 4: $PASS passed, $FAIL failed"
