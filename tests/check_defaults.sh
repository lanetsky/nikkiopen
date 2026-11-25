#!/bin/sh

# checks the defaults of a fresh installation
# usage: tests/check_defaults.sh [path/to/nikki.conf]

CONFIG="${1:-nikki/files/nikki.conf}"
FAILS=0
CHECKS=0

# get an option of a section
# $1 = section, $2 = option
opt() {
	sed -n "/^config $1 /,/^config /p" "$CONFIG" \
		| sed -n "s/^[[:space:]]*option '$2' '\(.*\)'\$/\1/p" \
		| head -n 1
}

# check $1 = $2
eq() {
	CHECKS=$((CHECKS + 1))
	if [ "$1" = "$2" ]; then
		echo "  ok   $3 = $1"
	else
		echo "  FAIL $3: expected '$2', got '$1'"
		FAILS=$((FAILS + 1))
	fi
}

# check that $1 is not empty
ne() {
	CHECKS=$((CHECKS + 1))
	if [ -n "$1" ]; then
		echo "  ok   $2 = $1"
	else
		echo "  FAIL $2: expected a value, got an empty one"
		FAILS=$((FAILS + 1))
	fi
}

echo "=== defaults of a fresh installation ($CONFIG) ==="

echo "[app]"
eq "$(opt "config" "enabled")" "1" "config.enabled"
eq "$(opt "config" "profile")" "subscription:subscription" "config.profile"
eq "$(opt "config" "scheduled_restart")" "1" "config.scheduled_restart"
ne "$(opt "config" "scheduled_restart_cron")" "config.scheduled_restart_cron"
eq "$(opt "config" "test_profile")" "0" "config.test_profile"

echo "[dashboard]"
eq "$(opt "mixin" "ui_path")" "ui" "mixin.ui_path"
eq "$(opt "mixin" "ui_name")" "zashboard" "mixin.ui_name"
ne "$(opt "mixin" "ui_url")" "mixin.ui_url"
CHECKS=$((CHECKS + 1))
case "$(opt "mixin" "ui_url")" in
	*zashboard*) echo "  ok   mixin.ui_url points to zashboard" ;;
	*) echo "  FAIL mixin.ui_url: expected zashboard, got '$(opt "mixin" "ui_url")'"; FAILS=$((FAILS + 1)) ;;
esac

echo "[tun]"
eq "$(opt "mixin" "tun_enabled")" "1" "mixin.tun_enabled"
eq "$(opt "mixin" "tun_stack")" "system" "mixin.tun_stack"
ne "$(opt "mixin" "tun_device")" "mixin.tun_device"

echo "[proxy]"
eq "$(opt "proxy" "enabled")" "1" "proxy.enabled"
eq "$(opt "proxy" "tcp_mode")" "tproxy" "proxy.tcp_mode"
eq "$(opt "proxy" "udp_mode")" "tproxy" "proxy.udp_mode"
eq "$(opt "proxy" "router_proxy")" "1" "proxy.router_proxy"
eq "$(opt "proxy" "lan_proxy")" "1" "proxy.lan_proxy"
eq "$(opt "proxy" "ipv6_dns_hijack")" "0" "proxy.ipv6_dns_hijack"
eq "$(opt "proxy" "ipv6_proxy")" "0" "proxy.ipv6_proxy"
ne "$(opt "mixin" "redir_port")" "mixin.redir_port"
ne "$(opt "mixin" "tproxy_port")" "mixin.tproxy_port"

echo "[dns]"
eq "$(opt "mixin" "dns_enabled")" "1" "mixin.dns_enabled"
ne "$(opt "mixin" "dns_listen")" "mixin.dns_listen"
eq "$(opt "mixin" "dns_mode")" "fake-ip" "mixin.dns_mode"

echo "[api]"
ne "$(opt "mixin" "api_listen")" "mixin.api_listen"

echo "[routing]"
eq "$(opt "routing" "tproxy_route_table")" "80" "routing.tproxy_route_table"
eq "$(opt "routing" "tun_route_table")" "81" "routing.tun_route_table"
eq "$(opt "routing" "dummy_device")" "nikki-dummy" "routing.dummy_device"

echo "[subscription]"
eq "$(opt "subscription" "user_agent")" "mihomo" "subscription.user_agent"

echo "[log]"
eq "$(opt "log" "clear_at_stop")" "1" "log.clear_at_stop"

echo "[unsupported options]"
CHECKS=$((CHECKS + 1))
if grep -q "bypass_china_mainland_ip" "$CONFIG"; then
	echo "  FAIL bypass_china_mainland_ip must not be in the config (the geoip sets are not shipped)"
	FAILS=$((FAILS + 1))
else
	echo "  ok   no bypass_china_mainland_ip"
fi
CHECKS=$((CHECKS + 1))
if grep -qi "gvisor" "$CONFIG"; then
	echo "  FAIL the config must not use the gvisor stack"
	FAILS=$((FAILS + 1))
else
	echo "  ok   no gvisor stack"
fi

echo
if [ "$FAILS" -eq 0 ]; then
	echo "all $CHECKS checks passed"
	exit 0
fi
echo "$FAILS of $CHECKS checks failed"
exit 1
