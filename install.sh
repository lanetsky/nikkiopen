#!/bin/sh

# Nikki's installer

# check env
if [[ ! -x "/bin/opkg" && ! -x "/usr/bin/apk" || ! -x "/sbin/fw4" ]]; then
	echo "only supports OpenWrt build with firewall4!"
	exit 1
fi

# include openwrt_release
. /etc/openwrt_release

# get branch/arch
arch="$DISTRIB_ARCH"
branch=
case "$DISTRIB_RELEASE" in
	*"24.10"*)
		branch="openwrt-24.10"
		;;
	*"25.12"*)
		branch="openwrt-25.12"
		;;
	"SNAPSHOT")
		branch="SNAPSHOT"
		;;
	*)
		echo "unsupported release: $DISTRIB_RELEASE"
		exit 1
		;;
esac

# download helper: wget first, curl as fallback
download() {
	url="$1"
	out="$2"
	if command -v wget >/dev/null 2>&1; then
		wget -q -T 30 -t 3 -O "$out" "$url" && return 0
	fi
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL --connect-timeout 15 --max-time 900 -o "$out" "$url" && return 0
	fi
	return 1
}

# fetch text to stdout
fetch() {
	url="$1"
	if command -v wget >/dev/null 2>&1; then
		wget -q -T 20 -t 2 -O - "$url" && return 0
	fi
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL --connect-timeout 15 --max-time 60 "$url" && return 0
	fi
	return 1
}

# release sources: latest release assets first, pinned tag as fallback
fallback_tag="v1.19.34-1"
base_latest="https://github.com/lanetsky/nikkiopen/releases/latest/download"
base_tag="https://github.com/lanetsky/nikkiopen/releases/download/${fallback_tag}"

# get latest release tag (informational only)
latest_tag=$(fetch "https://api.github.com/repos/lanetsky/nikkiopen/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
[ -z "$latest_tag" ] && latest_tag="$fallback_tag"
echo "latest release: $latest_tag"

# download release archive
archive="nikki_${arch}-${branch}.tar.gz"
archive_file="nikki_archive.tar.gz"
got=
for url in "${base_latest}/${archive}" "${base_tag}/${archive}"; do
	echo "download $url"
	if download "$url" "$archive_file"; then
		got=1
		break
	fi
	echo "failed, trying next source"
	rm -f "$archive_file"
done
if [ -z "$got" ]; then
	echo "failed to download release for $arch/$branch"
	exit 1
fi

# extract
echo "extract $archive"
tar -xzf "$archive_file" || {
	echo "failed to extract archive"
	rm -f "$archive_file"
	exit 1
}
rm -f "$archive_file"

# install packages
if [ -x "/bin/opkg" ]; then
	echo "install ipks"
	opkg install nikki*.ipk luci-app-nikki*.ipk
	rm -f nikki*.ipk luci-app-nikki*.ipk
	if [ -n "$LUCI_I18N" ]; then
		echo "install luci-i18n-nikki-ru"
		opkg install luci-i18n-nikki-ru*.ipk
	fi
	rm -f *.ipk *.json
elif [ -x "/usr/bin/apk" ]; then
	echo "install apks"
	apk add --allow-untrusted nikki*.apk luci-app-nikki*.apk
	rm -f nikki*.apk luci-app-nikki*.apk
	if [ -n "$LUCI_I18N" ]; then
		echo "install luci-i18n-nikki-ru"
		apk add --allow-untrusted luci-i18n-nikki-ru*.apk
	fi
	rm -f *.apk *.adb
fi

echo "success"
