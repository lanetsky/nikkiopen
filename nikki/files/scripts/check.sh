#!/bin/sh

# nikki's configuration check
# prints the effective settings (uci config + the config the core actually
# loaded) and the state of the hijack rules

. "$IPKG_INSTROOT/etc/nikki/scripts/include.sh"

config_load nikki

get() {
	uci_get nikki "$1" "$2" "$3"
}

count_yaml() {
	[ -f "$RUN_PROFILE_PATH" ] || { echo "n/a"; return 0; }
	yq -M -e ".$1 | length" "$RUN_PROFILE_PATH" 2>/dev/null || echo "0"
}

echo "=== nikki check ($(date "+%Y-%m-%d %H:%M:%S")) ==="
echo
echo "[app]"
echo "  enabled: $(get "config" "enabled" "0")"
echo "  profile: $(get "config" "profile" "not set")"
echo "  core_only: $(get "config" "core_only" "0")"
echo
echo "[dashboard]"
echo "  ui_path: $(get "mixin" "ui_path" "not set")"
echo "  ui_name: $(get "mixin" "ui_name" "NOT SET")"
echo "  ui_url: $(get "mixin" "ui_url" "not set")"
echo
echo "[tun]"
echo "  enabled: $(get "mixin" "tun_enabled" "0")"
echo "  stack: $(get "mixin" "tun_stack" "not set")"
echo "  device: $(get "mixin" "tun_device" "not set")"
echo
echo "[proxy]"
echo "  enabled: $(get "proxy" "enabled" "0")"
echo "  tcp_mode: $(get "proxy" "tcp_mode" "not set")"
echo "  udp_mode: $(get "proxy" "udp_mode" "not set")"
echo "  router_proxy: $(get "proxy" "router_proxy" "0")"
echo "  lan_proxy: $(get "proxy" "lan_proxy" "0")"
echo "  redir_port: $(get "mixin" "redir_port" "not set")"
echo "  tproxy_port: $(get "mixin" "tproxy_port" "not set")"
echo
echo "[dns]"
echo "  enabled: $(get "mixin" "dns_enabled" "0")"
echo "  listen: $(get "mixin" "dns_listen" "not set")"
echo "  mode: $(get "mixin" "dns_mode" "not set")"
echo "  dns_hijack: ipv4=$(get "proxy" "ipv4_dns_hijack" "0") ipv6=$(get "proxy" "ipv6_dns_hijack" "0")"
echo
echo "[api]"
echo "  listen: $(get "mixin" "api_listen" "not set")"
echo
echo "[loaded config: $RUN_PROFILE_PATH]"
if [ -f "$RUN_PROFILE_PATH" ]; then
	echo "  external-ui: $(yq -M -r '.external-ui // "not set"' "$RUN_PROFILE_PATH" 2>/dev/null)"
	echo "  external-ui-name: $(yq -M -r '.external-ui-name // "NOT SET"' "$RUN_PROFILE_PATH" 2>/dev/null)"
	echo "  tun.stack: $(yq -M -r '.tun.stack // "not set"' "$RUN_PROFILE_PATH" 2>/dev/null)"
	echo "  proxies: $(count_yaml "proxies")"
	echo "  proxy-groups: $(count_yaml "proxy-groups")"
	echo "  rules: $(count_yaml "rules")"
	echo "  rule-providers: $(count_yaml "rule-providers")"
	echo "  proxy-providers: $(count_yaml "proxy-providers")"
else
	echo "  not found (the core is not running)"
fi
echo
echo "[hijack]"
if nft list tables 2>/dev/null | grep -q "nikki"; then
	echo "  nft table inet nikki: present"
else
	echo "  nft table inet nikki: MISSING"
fi
for table in 80 81; do
	if ip -4 rule show 2>/dev/null | grep -q "lookup $table"; then
		echo "  ip rule table $table: present"
	else
		echo "  ip rule table $table: MISSING"
	fi
	if ip -4 route show table "$table" 2>/dev/null | grep -q "default"; then
		echo "  ip route table $table: present"
	else
		echo "  ip route table $table: MISSING"
	fi
done
echo
echo "[logs]"
echo "  app log: $APP_LOG_PATH"
echo "  core log: $CORE_LOG_PATH"
echo
