include $(TOPDIR)/rules.mk

PKG_NAME:=nikki
PKG_VERSION:=1.19.34
PKG_RELEASE:=3

PKG_LICENSE:=GPL3.0+
PKG_MAINTAINER:=Joseph Mory <morytyann@gmail.com>

PKG_BUILD_FLAGS:=no-mips16

include $(INCLUDE_DIR)/package.mk

define Package/nikki
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Transparent Proxy with Mihomo on OpenWrt.
  URL:=https://github.com/nikkinikki-org
  DEPENDS:=+ca-bundle +curl +yq +firewall4 +ip-full +kmod-inet-diag +kmod-nft-socket +kmod-nft-tproxy +kmod-tun +kmod-dummy +ucode +ucode-mod-uci +ucode-mod-ubus +nftables
endef

define Package/nikki/conffiles
/etc/config/nikki
/etc/nikki/mixin.yaml
endef

define Package/nikki/install
	$(INSTALL_DIR) $(1)/etc/nikki
	$(INSTALL_DIR) $(1)/etc/nikki/ucode
	$(INSTALL_DIR) $(1)/etc/nikki/scripts
	$(INSTALL_DIR) $(1)/etc/nikki/profiles
	$(INSTALL_DIR) $(1)/etc/nikki/subscriptions
	$(INSTALL_DIR) $(1)/etc/nikki/run
	$(INSTALL_DIR) $(1)/etc/nikki/run/providers
	$(INSTALL_DIR) $(1)/etc/nikki/run/providers/rule
	$(INSTALL_DIR) $(1)/etc/nikki/run/providers/proxy

	$(INSTALL_DATA) $(CURDIR)/files/mixin.yaml $(1)/etc/nikki/mixin.yaml

	$(INSTALL_BIN) $(CURDIR)/files/ucode/include.uc $(1)/etc/nikki/ucode/include.uc
	$(INSTALL_BIN) $(CURDIR)/files/ucode/mixin.uc $(1)/etc/nikki/ucode/mixin.uc
	$(INSTALL_BIN) $(CURDIR)/files/ucode/hijack.ut $(1)/etc/nikki/ucode/hijack.ut

	$(INSTALL_BIN) $(CURDIR)/files/scripts/include.sh $(1)/etc/nikki/scripts/include.sh
	$(INSTALL_BIN) $(CURDIR)/files/scripts/firewall_include.sh $(1)/etc/nikki/scripts/firewall_include.sh
	$(INSTALL_BIN) $(CURDIR)/files/scripts/debug.sh $(1)/etc/nikki/scripts/debug.sh
	$(INSTALL_BIN) $(CURDIR)/files/scripts/migrate.sh $(1)/etc/nikki/scripts/migrate.sh

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/nikki.conf $(1)/etc/config/nikki

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/nikki.init $(1)/etc/init.d/nikki

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(CURDIR)/files/uci-defaults/firewall.sh $(1)/etc/uci-defaults/99_firewall_nikki
	$(INSTALL_BIN) $(CURDIR)/files/uci-defaults/init.sh $(1)/etc/uci-defaults/99_init_nikki
	$(INSTALL_BIN) $(CURDIR)/files/uci-defaults/migrate.sh $(1)/etc/uci-defaults/99_migrate_nikki

	$(INSTALL_DIR) $(1)/lib/upgrade/keep.d
	$(INSTALL_DATA) $(CURDIR)/files/nikki.upgrade $(1)/lib/upgrade/keep.d/nikki

	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/mihomo $(1)/usr/bin/mihomo
endef

define Package/nikki/preinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	# stop the running service before the package is replaced
	# (the old instance would keep the old binary and the old rules)
	if [ -x "/etc/init.d/nikki" ]; then
		/etc/init.d/nikki stop > /dev/null 2>&1
		/etc/init.d/nikki cleanup_leftovers > /dev/null 2>&1
	fi
fi
exit 0
endef

define Package/nikki/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	# migrate the config (e.g. left over by the official nikki)
	[ -f /etc/nikki/scripts/migrate.sh ] && /etc/nikki/scripts/migrate.sh
	# enable and (re)start the service
	/etc/init.d/nikki enable
	/etc/init.d/nikki restart
fi
exit 0
endef

define Package/nikki/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	# stop the service and remove the leftovers of the previous run
	if [ -x "/etc/init.d/nikki" ]; then
		/etc/init.d/nikki stop > /dev/null 2>&1
		/etc/init.d/nikki cleanup_leftovers > /dev/null 2>&1
	fi
fi
exit 0
endef

define Package/nikki/postrm
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ]; then
	uci -q batch <<-EOF > /dev/null
		del firewall.nikki
		commit firewall
	EOF
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
fi
exit 0
endef

MIHOMO_BINARY_URL:=https://github.com/SaltyMonkey/justclash-core-slim/releases/download/v$(PKG_VERSION)/mihomo-linux-arm64-v$(PKG_VERSION).gz

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	wget -qO- $(MIHOMO_BINARY_URL) | gzip -d -c > $(PKG_BUILD_DIR)/mihomo
	chmod +x $(PKG_BUILD_DIR)/mihomo
endef

define Build/Compile
endef

$(eval $(call BuildPackage,nikki))
