#!/bin/sh

# Nikki's uninstaller

# stop the service and remove the leftovers of the previous run
if [ -x "/etc/init.d/nikki" ]; then
	/etc/init.d/nikki stop > /dev/null 2>&1
	/etc/init.d/nikki cleanup_leftovers > /dev/null 2>&1
fi

# apk del fails when the world contains an entry of a package that is not
# available anymore (e.g. the repository index became unreachable)
# -> remove the stale entry and retry
apk_del() {
	pkg="$1"
	out="$(apk del "$pkg" 2>&1)"
	status=$?
	echo "$out"
	[ "$status" -eq 0 ] && return 0
	for missing in $(echo "$out" | sed -n 's/^[[:space:]]*\([A-Za-z0-9_.+-]\{1,\}\) (no such package):.*/\1/p'); do
		echo "remove the stale world entry: $missing"
		sed -i "/^${missing}\($\|=\)/d" /etc/apk/world 2>/dev/null
	done
	apk del "$pkg"
}

# uninstall
if [ -x "/bin/opkg" ]; then
	opkg list-installed luci-i18n-nikki-* | cut -d ' ' -f 1 | while read -r pkg; do
		[ -n "$pkg" ] && opkg remove "$pkg"
	done
	opkg remove luci-app-nikki
	opkg remove nikki
elif [ -x "/usr/bin/apk" ]; then
	apk list --installed 2>/dev/null | grep -E '^luci-i18n-nikki-' | cut -d ' ' -f 1 | while read -r pkg; do
		[ -n "$pkg" ] && apk_del "$pkg"
	done
	apk_del luci-app-nikki
	apk_del nikki
fi
# remove config
rm -f /etc/config/nikki
# remove files
rm -rf /etc/nikki
# remove log
rm -rf /var/log/nikki
# remove temp
rm -rf /var/run/nikki
# remove feed
if [ -x "/bin/opkg" ]; then
	if grep -q nikki /etc/opkg/customfeeds.conf; then
		sed -i '/nikki/d' /etc/opkg/customfeeds.conf
	fi
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL --connect-timeout 15 --max-time 60 -o "nikki.pub" "https://nikkinikki.pages.dev/key-build.pub"
	else
		wget -q -T 60 -O "nikki.pub" "https://nikkinikki.pages.dev/key-build.pub"
	fi
	opkg-key remove nikki.pub
	rm -f nikki.pub
elif [ -x "/usr/bin/apk" ]; then
	if grep -q nikki /etc/apk/repositories.d/customfeeds.list; then
		sed -i '/nikki/d' /etc/apk/repositories.d/customfeeds.list
	fi
	rm -f /etc/apk/keys/nikki.pem
fi
# remove the leftovers of the previous run
nft delete table inet nikki > /dev/null 2>&1
ip -4 rule del table 80 > /dev/null 2>&1
ip -4 rule del table 81 > /dev/null 2>&1
ip -6 rule del table 80 > /dev/null 2>&1
ip -6 rule del table 81 > /dev/null 2>&1
ip -4 route flush table 80 > /dev/null 2>&1
ip -4 route flush table 81 > /dev/null 2>&1
ip -6 route flush table 80 > /dev/null 2>&1
ip -6 route flush table 81 > /dev/null 2>&1
ip link del nikki-dummy > /dev/null 2>&1
