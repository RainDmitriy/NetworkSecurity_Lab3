#!/bin/bash
PASS=0; FAIL=0
SERVER=10.78.1.2

# Cleanup
docker exec lab-client bash -c "pkill -f 'ssh.*$SERVER' 2>/dev/null; pkill -f 'nc.*$SERVER' 2>/dev/null" || true
sleep 1
docker exec lab-firewall iptables -Z

echo "[3.1] Opening 3 persistent SSH connections..."

# sshpass + ssh -N (no command) — держит соединение открытым
for i in 1 2 3; do
    docker exec -d lab-client bash -c \
        "sshpass -p labpass ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
         -N root@$SERVER 2>/dev/null &"
    sleep 1
    echo "  Connection $i initiated"
done

sleep 3

# Проверяем ESTABLISHED на сервере
CONNS=$(docker exec lab-server ss -tn state established '( sport = :22 )' | \
    grep -c "10.77.1.2")
echo "  SSH ESTABLISHED on server: $CONNS"

# Проверяем conntrack
CT=$(docker exec lab-firewall conntrack -L 2>/dev/null | \
    grep "dport=22" | grep "src=10.77.1.2" | grep -c "ESTABLISHED")
echo "  Conntrack ESTABLISHED: $CT"

if [ "$CONNS" -ge 3 ]; then
    echo "PASS: 3 connections established"; ((PASS++))
elif [ "$CT" -ge 3 ]; then
    echo "PASS: 3 connections in conntrack"; ((PASS++))
else
    echo "nly $CONNS connections on server, $CT in conntrack"
fi

echo ""
echo "[3.2] 4th connection — should be REJECTED"
RESULT=$(docker exec lab-client bash -c \
    "sshpass -p labpass ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
     -o ConnectTimeout=3 root@$SERVER echo 'connected' 2>&1")
echo "  Result: $RESULT"

sleep 1
REJECTED=$(docker exec lab-firewall iptables -L FORWARD -v -n | \
    awk '/connlimit/ {print $1}')
echo "  Connlimit hits: ${REJECTED:-0}"

if echo "$RESULT" | grep -qi "reset\|refused\|timeout\|error"; then
    echo "PASS: 4th connection rejected"; ((PASS++))
elif [ "${REJECTED:-0}" -gt 0 ]; then
    echo "PASS: connlimit triggered ($REJECTED hits)"; ((PASS++))
else
    echo "FAIL: connlimit not triggered"; ((FAIL++))
fi

echo ""
echo "=== Full conntrack ==="
docker exec lab-firewall conntrack -L 2>/dev/null | grep "dport=22" | grep "10.77.1.2"
echo ""
echo "=== Server SSH sessions ==="
docker exec lab-server ss -tn state established '( sport = :22 )'

# Cleanup
docker exec lab-client bash -c "pkill -f 'ssh.*$SERVER' 2>/dev/null" || true

echo ""
echo "Test 3: $PASS passed, $FAIL failed"
