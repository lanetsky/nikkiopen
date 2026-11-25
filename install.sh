#!/bin/sh

# Nikki's installer

# check env
if { [ ! -x "/bin/opkg" ] && [ ! -x "/usr/bin/apk" ]; } || [ ! -x "/sbin/fw4" ]; then
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

# download file: curl first (works better on routers), wget as fallback
# note: busybox wget / uclient-fetch / GNU wget differ, so only common flags are used (-q -T -O)
download() {
	url="$1"
	out="$2"
	max_time="$3"
	if command -v curl >/dev/null 2>&1; then
		if curl -fsSL --connect-timeout 15 --max-time "$max_time" -o "$out" "$url"; then
			echo "  fetched with curl"
			return 0
		fi
		rm -f "$out"
	fi
	if command -v wget >/dev/null 2>&1; then
		if wget -q -T "$max_time" -O "$out" "$url"; then
			echo "  fetched with wget"
			return 0
		fi
		rm -f "$out"
	fi
	return 1
}

# fetch text to stdout
fetch_text() {
	url="$1"
	max_time="$2"
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL --connect-timeout 10 --max-time "$max_time" "$url" && return 0
	fi
	if command -v wget >/dev/null 2>&1; then
		wget -q -T "$max_time" -O - "$url" && return 0
	fi
	return 1
}

# release sources: latest release assets first, pinned tag as fallback
fallback_tag="v1.19.34-5"
base_latest="https://github.com/lanetsky/nikkiopen/releases/latest/download"
base_tag="https://github.com/lanetsky/nikkiopen/releases/download/${fallback_tag}"

# get latest release tag (informational only)
latest_tag=$(fetch_text "https://api.github.com/repos/lanetsky/nikkiopen/releases/latest" 45 | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
[ -z "$latest_tag" ] && latest_tag="$fallback_tag"
echo "latest release: $latest_tag"

# workdir (tmpfs on openwrt, removed on exit)
workdir=$(mktemp -d 2>/dev/null)
[ -n "$workdir" ] || workdir="/tmp/nikki-install.$$"
mkdir -p "$workdir" || exit 1
cleanup() {
	cd / 2>/dev/null
	rm -rf "$workdir"
}
trap cleanup EXIT INT TERM

# download release archive
archive="nikki_${arch}-${branch}.tar.gz"
archive_file="$workdir/nikki_archive.tar.gz"
got=
for url in "${base_latest}/${archive}" "${base_tag}/${archive}"; do
	echo "download $url"
	if download "$url" "$archive_file" 900; then
		got=1
		break
	fi
	echo "  failed, trying next source"
done
if [ -z "$got" ]; then
	echo "failed to download release for $arch/$branch"
	echo "download it manually and install the packages:"
	echo "  curl -fsSL https://github.com/lanetsky/nikkiopen/releases/latest/download/${archive} -o ${archive}"
	exit 1
fi

# extract
echo "extract $archive"
cd "$workdir" || exit 1
tar -xzf "$archive_file" || {
	echo "failed to extract archive"
	exit 1
}
rm -f "$archive_file"

# stop the running service before the packages are replaced
# (the old instance would keep the old binary and the old rules)
if [ -x "/etc/init.d/nikki" ]; then
	echo "stop nikki service"
	/etc/init.d/nikki stop > /dev/null 2>&1
fi

# install packages
if [ -x "/bin/opkg" ]; then
	echo "install ipks"
	if ! opkg install nikki*.ipk luci-app-nikki*.ipk; then
		echo "failed to install the packages"
		exit 1
	fi
	rm -f nikki*.ipk luci-app-nikki*.ipk
	if [ -n "$LUCI_I18N" ]; then
		echo "install luci-i18n-nikki-ru"
		opkg install luci-i18n-nikki-ru*.ipk || echo "  failed to install luci-i18n-nikki-ru"
	fi
	rm -f *.ipk *.json
elif [ -x "/usr/bin/apk" ]; then
	echo "install apks"
	if ! apk add --allow-untrusted nikki*.apk luci-app-nikki*.apk; then
		echo "failed to install the packages"
		echo "check the output above, the most common reasons are:"
		echo "  - a dependency that the package manager cannot find (e.g. yq),"
		echo "    the repositories must be reachable and up to date (apk update)"
		echo "  - the packages are not signed, --allow-untrusted is used automatically"
		exit 1
	fi
	rm -f nikki*.apk luci-app-nikki*.apk
	if [ -n "$LUCI_I18N" ]; then
		echo "install luci-i18n-nikki-ru"
		apk add --allow-untrusted luci-i18n-nikki-ru*.apk || echo "  failed to install luci-i18n-nikki-ru"
	fi
	rm -f *.apk *.adb
fi

# verify the installation
if [ ! -x "/etc/init.d/nikki" ]; then
	echo "the nikki service is not installed"
	exit 1
fi

echo "success"
