#!/bin/bash
PASS=0; FAIL=0
SERVER=10.78.1.2

docker exec lab-firewall iptables -Z

echo "[2.1] ACK without connection → server — should be dropped"
docker exec lab-client hping3 -A -p 22 -c 5 --fast $SERVER 2>&1

sleep 1

echo ""
echo "=== FORWARD counters ==="
docker exec lab-firewall iptables -L FORWARD -v -n --line-numbers

# Берём сумму счётчиков строк INVALID и !syn
DROPPED=$(docker exec lab-firewall iptables -L FORWARD -v -n | \
    awk '/ctstate INVALID|flags:!0x17/ {sum += $1} END {print sum+0}')
echo "  Total dropped (INVALID + !syn): $DROPPED"

if [ "$DROPPED" -gt 0 ]; then
    echo "PASS: $DROPPED invalid packets dropped"; ((PASS++))
else
    echo "FAIL: nothing dropped"; ((FAIL++))
fi

echo ""
echo "[2.2] RST without connection → server"
docker exec lab-client hping3 -R -p 22 -c 5 --fast $SERVER 2>&1

echo ""
echo "[2.3] Normal TCP to server SSH — should SUCCEED"
if docker exec lab-client bash -c "echo '' | nc -w 3 $SERVER 22" 2>/dev/null; then
    echo "PASS: normal TCP works"; ((PASS++))
else
    echo "FAIL: normal TCP blocked"; ((FAIL++))
fi

echo ""
echo "Test 2: $PASS passed, $FAIL failed"
