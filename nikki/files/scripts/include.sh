#!/bin/sh

# paths
HOME_DIR="/etc/nikki"
PROFILES_DIR="$HOME_DIR/profiles"
SUBSCRIPTIONS_DIR="$HOME_DIR/subscriptions"
MIXIN_FILE_PATH="$HOME_DIR/mixin.yaml"
RUN_DIR="$HOME_DIR/run"
RUN_PROFILE_PATH="$RUN_DIR/config.yaml"
PROVIDERS_DIR="$RUN_DIR/providers"
RULE_PROVIDERS_DIR="$PROVIDERS_DIR/rule"
PROXY_PROVIDERS_DIR="$PROVIDERS_DIR/proxy"

# log
LOG_DIR="/var/log/nikki"
APP_LOG_PATH="$LOG_DIR/app.log"
CORE_LOG_PATH="$LOG_DIR/core.log"

# temp
TEMP_DIR="/var/run/nikki"
PID_FILE_PATH="$TEMP_DIR/nikki.pid"
STARTED_FLAG_PATH="$TEMP_DIR/started.flag"
BRIDGE_NF_CALL_IPTABLES_FLAG_PATH="$TEMP_DIR/bridge_nf_call_iptables.flag"
BRIDGE_NF_CALL_IP6TABLES_FLAG_PATH="$TEMP_DIR/bridge_nf_call_ip6tables.flag"

# ucode
UCODE_DIR="$HOME_DIR/ucode"
INCLUDE_UC="$UCODE_DIR/include.uc"
MIXIN_UC="$UCODE_DIR/mixin.uc"
HIJACK_UT="$UCODE_DIR/hijack.ut"

# scripts
SH_DIR="$HOME_DIR/scripts"
INCLUDE_SH="$SH_DIR/include.sh"
FIREWALL_INCLUDE_SH="$SH_DIR/firewall_include.sh"

# nftables
NFT_DIR="$HOME_DIR/nftables"

# expression used to merge the mixin config into the profile
MIXIN_EXPR='... comments="" | . as $item ireduce ({}; . * $item ) | .proxies = .nikki-proxies + .proxies | del(.nikki-proxies) | .proxy-groups = .nikki-proxy-groups + .proxy-groups | del(.nikki-proxy-groups) | .rules = .nikki-rules + .rules | del(.nikki-rules) | explode(.)'

# functions
format_filesize() {
	local b; b=1
	local kb; kb=$((b * 1024))
	local mb; mb=$((kb * 1024))
	local gb; gb=$((mb * 1024))
	local tb; tb=$((gb * 1024))
	local pb; pb=$((tb * 1024))
	local size; size="$1"
	if [ -n "$size" ]; then
		if [ "$size" -lt "$kb" ]; then
			echo "$(awk "BEGIN {print $size / $b}") B"
		elif [ "$size" -lt "$mb" ]; then
			echo "$(awk "BEGIN {print $size / $kb}") KB"
		elif [ "$size" -lt "$gb" ]; then
			echo "$(awk "BEGIN {print $size / $mb}") MB"
		elif [ "$size" -lt "$tb" ]; then
			echo "$(awk "BEGIN {print $size / $gb}") GB"
		elif [ "$size" -lt "$pb" ]; then
			echo "$(awk "BEGIN {print $size / $tb}") TB"
		else
			echo "$(awk "BEGIN {print $size / $pb}") PB"
		fi
	fi
}

prepare_files() {
	if [ ! -d "$LOG_DIR" ]; then
		mkdir -p "$LOG_DIR"
	fi
	if [ ! -f "$APP_LOG_PATH" ]; then
		touch "$APP_LOG_PATH"
	fi
	if [ ! -f "$CORE_LOG_PATH" ]; then
		touch "$CORE_LOG_PATH"
	fi
	if [ ! -d "$TEMP_DIR" ]; then
		mkdir -p "$TEMP_DIR"
	fi
}

log() {
	echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$1] $2" >> "$APP_LOG_PATH"
}

get_openwrt_version() {
	local ver=""
	if [ -f /etc/openwrt_release ]; then
		ver="$(. /etc/openwrt_release 2>/dev/null; echo "$DISTRIB_RELEASE")"
	fi
	[ -n "$ver" ] && echo "$ver" || echo "unknown"
}

get_device_model() {
	if [ -f /tmp/sysinfo/model ]; then
		cat /tmp/sysinfo/model
	else
		echo "unknown"
	fi
}

get_hwid() {
	local ethaddr=""
	if command -v fw_printenv >/dev/null 2>&1; then
		ethaddr="$(fw_printenv ethaddr 2>/dev/null | cut -d= -f2 | tr -d '\r\n')"
	fi
	if [ -z "$ethaddr" ] && [ -f /sys/class/net/eth0/address ]; then
		ethaddr="$(cat /sys/class/net/eth0/address 2>/dev/null | tr -d '\r\n')"
	fi
	[ -z "$ethaddr" ] && { echo ""; return 0; }
	echo "$ethaddr" | tr '[:upper:]' '[:lower:]' | tr -d ':' | sha256sum | cut -d' ' -f1
}

# read an option of a nikki section
# unlike config_get it also works with anonymous sections (@subscription[0])
# $1 = section, $2 = option, $3 = default
nikki_uci_get() {
	uci_get nikki "$1" "$2" "$3"
}

# resolve the subscription section referenced by the profile
# $1 = section id from the profile ("subscription:<id>")
# prints the section id, returns 1 if nothing was found
# note: the official luci app creates anonymous sections (@subscription[0]),
#       they are not reachable by their id, so we fall back to the first
#       subscription section that has an url
resolve_subscription_section() {
	local wanted="$1"
	local section
	if [ -n "$wanted" ] && [ -n "$(nikki_uci_get "$wanted" "url")" ]; then
		echo "$wanted"
		return 0
	fi
	for section in $(uci -q show nikki 2>/dev/null | sed -n "s/^nikki\.\(@subscription\[[0-9]\{1,\}\]\|[A-Za-z0-9_]\{1,\}\)\.url=.*/\1/p"); do
		echo "$section"
		return 0
	done
	return 1
}

# remove the leftovers of a previous run
# (nft table, ip rules/routes, dummy device, started flag)
cleanup_leftovers() {
	local tproxy_route_table tun_route_table dummy_device
	config_load nikki
	config_get tproxy_route_table "routing" "tproxy_route_table" "80"
	config_get tun_route_table "routing" "tun_route_table" "81"
	config_get dummy_device "routing" "dummy_device" "nikki-dummy"
	nft delete table inet nikki > /dev/null 2>&1
	ip -4 rule del table "$tproxy_route_table" > /dev/null 2>&1
	ip -4 rule del table "$tun_route_table" > /dev/null 2>&1
	ip -6 rule del table "$tproxy_route_table" > /dev/null 2>&1
	ip -6 rule del table "$tun_route_table" > /dev/null 2>&1
	ip -4 route flush table "$tproxy_route_table" > /dev/null 2>&1
	ip -4 route flush table "$tun_route_table" > /dev/null 2>&1
	ip -6 route flush table "$tproxy_route_table" > /dev/null 2>&1
	ip -6 route flush table "$tun_route_table" > /dev/null 2>&1
	ip link del "$dummy_device" > /dev/null 2>&1
	rm -f "$STARTED_FLAG_PATH" > /dev/null 2>&1
}

# generate the mixin config and merge it into the profile
# $@ = the files to merge (the profile first, the mixin file optional)
# the generated mixin config is fed to yq via stdin
# every error is written to $TEMP_DIR/mixin.err and logged
mixin_apply() {
	local mixin_json="$TEMP_DIR/mixin.json"
	local mixin_yaml="$TEMP_DIR/mixin.yaml"
	rm -f "$mixin_json" "$mixin_yaml"
	if ! ucode -S "$MIXIN_UC" > "$mixin_json" 2>>"$TEMP_DIR/mixin.err"; then
		log "Mixin" "Failed to generate the mixin config."
		return 1
	fi
	if [ ! -s "$mixin_json" ]; then
		log "Mixin" "The generated mixin config is empty."
		return 1
	fi
	if ! yq -M -p json -o yaml '.' "$mixin_json" > "$mixin_yaml" 2>>"$TEMP_DIR/mixin.err"; then
		log "Mixin" "Failed to convert the mixin config."
		return 1
	fi
	if ! yq -M -i eval-all "$MIXIN_EXPR" "$@" - < "$mixin_yaml" 2>>"$TEMP_DIR/mixin.err"; then
		log "Mixin" "Failed to apply the mixin config."
		return 1
	fi
	return 0
}
