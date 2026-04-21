#!/bin/bash
PASS=0; FAIL=0
SERVER=10.78.1.2

echo "[1.1] Telnet from client2 (10.77.1.10) → server:23 — should FAIL"
if docker exec lab-client2 bash -c "echo '' | nc -w 3 $SERVER 23" 2>/dev/null; then
    echo "FAIL: connection succeeded"; ((FAIL++))
else
    echo "PASS: connection blocked"; ((PASS++))
fi

echo "[1.2] Telnet from client (10.77.1.2) → server:23 — should SUCCEED"
if docker exec lab-client bash -c "echo '' | nc -w 3 $SERVER 23" 2>/dev/null; then
    echo "PASS: connection succeeded"; ((PASS++))
else
    echo "FAIL: connection blocked"; ((FAIL++))
fi

echo ""
echo "Test 1: $PASS passed, $FAIL failed"
