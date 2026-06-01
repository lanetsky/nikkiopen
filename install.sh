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

# get latest release tag from GitHub
echo "get latest release"
latest_tag=$(curl -s https://api.github.com/repos/lanetsky/nikkiopen/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
if [ -z "$latest_tag" ]; then
	echo "failed to get latest release"
	exit 1
fi
echo "latest release: $latest_tag"

# download release archive
archive="nikki_${arch}-${branch}.tar.gz"
archive_url="https://github.com/lanetsky/nikkiopen/releases/download/${latest_tag}/${archive}"
echo "download $archive_url"
wget -O "$archive" "$archive_url" || {
	echo "failed to download release for $arch/$branch"
	exit 1
}

# extract
echo "extract $archive"
tar -xzf "$archive" || {
	echo "failed to extract archive"
	rm -f "$archive"
	exit 1
}
rm -f "$archive"

# install packages
if [ -x "/bin/opkg" ]; then
	echo "install ipks"
	opkg install *.ipk
	rm -f *.ipk *.json
elif [ -x "/usr/bin/apk" ]; then
	echo "install apks"
	apk add --allow-untrusted *.apk
	rm -f *.apk *.adb
fi

echo "success"
