#!/bin/sh

# Nikki's uninstaller

# uninstall
if [ -x "/bin/opkg" ]; then
	opkg list-installed luci-i18n-nikki-* | cut -d ' ' -f 1 | xargs opkg remove
	opkg remove luci-app-nikki
	opkg remove nikki
elif [ -x "/usr/bin/apk" ]; then
	apk list --installed --manifest luci-i18n-nikki-* | cut -d ' ' -f 1 | xargs apk del
	apk del luci-app-nikki
	apk del nikki
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
