.PHONY: up down rebuild rules flush test test1 test2 test3 test4 status logs shell-fw shell-client shell-client2 shell-server

up:
	docker compose up -d --build
	@echo ""
	@echo "Lab is up. Run 'make rules' to apply iptables."

down:
	docker compose down -v --remove-orphans

rebuild: down up

rules:
	docker exec lab-firewall bash /opt/iptables-rules.sh

flush:
	docker exec lab-firewall bash -c "\
		iptables -F && iptables -X && \
		iptables -t nat -F && iptables -t nat -X && \
		iptables -P INPUT ACCEPT && \
		iptables -P FORWARD ACCEPT && \
		iptables -P OUTPUT ACCEPT && \
		echo 'All rules flushed'"

status:
	@echo "=== FILTER ==="
	@docker exec lab-firewall iptables -L -v -n --line-numbers
	@echo ""
	@echo "=== NAT ==="
	@docker exec lab-firewall iptables -t nat -L -v -n --line-numbers
	@echo ""
	@echo "=== CONNTRACK ==="
	@docker exec lab-firewall conntrack -C 2>/dev/null || echo "conntrack not available"

# ─── Tests ──────────────────────────────────────────
test: test1 test2 test3 test4
	@echo ""
	@echo "All tests completed"

test1:
	@echo ""
	@echo "════════════════════════════════════════"
	@echo "  TEST 1: Telnet block from 10.10.10.10"
	@echo "════════════════════════════════════════"
	@bash tests/test_telnet_block.sh

test2:
	@echo ""
	@echo "════════════════════════════════════════"
	@echo "  TEST 2: Invalid TCP block"
	@echo "════════════════════════════════════════"
	@bash tests/test_invalid_tcp.sh

test3:
	@echo ""
	@echo "════════════════════════════════════════"
	@echo "  TEST 3: SSH connection limit (3/addr)"
	@echo "════════════════════════════════════════"
	@bash tests/test_ssh_connlimit.sh

test4:
	@echo ""
	@echo "════════════════════════════════════════"
	@echo "  TEST 4: ICMP rate limit (1/sec)"
	@echo "════════════════════════════════════════"
	@bash tests/test_icmp_ratelimit.sh

# ─── Shells ─────────────────────────────────────────
shell-fw:
	docker exec -it lab-firewall bash

shell-client:
	docker exec -it lab-client bash

shell-client2:
	docker exec -it lab-client2 bash

shell-server:
	docker exec -it lab-server bash

# ─── Logs ───────────────────────────────────────────
logs:
	docker compose logs -f

tcpdump-fw:
	docker exec lab-firewall tcpdump -i any -n -l
