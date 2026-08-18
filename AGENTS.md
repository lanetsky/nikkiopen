# AGENTS.md — nikkiopen project context

## Project

Fork of [nikkinikki-org/OpenWrt-nikki](https://github.com/nikkinikki-org/OpenWrt-nikki), published at [lanetsky/nikkiopen](https://github.com/lanetsky/nikkiopen).
Binary-only mihomo package (no Go build), install via one script from router.

## Current state

- mihomo version: **v1.19.30** (`nikki/Makefile` `PKG_VERSION`)
- OpenWrt: 24.10 + 25.12, arch: aarch64_cortex-a53
- Default config: `nikki/files/nikki.conf`

## Upstream merge procedure

7 files have custom modifications — merge manually with upstream:
- `nikki/Makefile` — rewritten to binary-only (no Go/GoBinPackage/ALTERNATIVES), `Build/Prepare` downloads mihomo from GitHub releases
- `nikki/files/nikki.conf` — default config with custom defaults (see below)
- `nikki/files/nikki.init` — uses curl for subscription update (lines 559, 573)
- `nikki/files/scripts/include.sh` — paths and helper functions
- `luci-app-nikki/htdocs/luci/resources/view/nikki.js` — LuCI web UI
- `luci-app-nikki/po/ru/*.po` — Russian translations

~12 files can be copied without changes:
- `nikki/files/nikki.upgrade`
- `nikki/files/scripts/debug.sh`, `firewall_include.sh`
- `nikki/files/ucode/hijack.ut`
- `nikki/files/mixin.yaml`
- `nikki/files/uci-defaults/`
- `luci-app-nikki/` (except htdocs and po/ru)

After merge, delete `nikki/files/nftables/` if it appears (we use ucode hijack.ut instead).

## Our customizations vs upstream

- DNS: 1.1.1.1 + 8.8.8.8 (upstream uses Chinese 223.5.5.5)
- Mode: tproxy/tproxy (upstream redirect/tun)
- HWID: MAC-based sha256 in subscription headers
- UI: "Taproom Nikki" branding
- Removed: geoip files, bypass China, Chinese translations
- `+curl` in DEPENDS required: nikki.init uses curl for subscription updates

## Default config changes (nikki/files/nikki.conf)

Compared to upstream defaults:
- `config config`: `enabled=1`, `test_profile=0`, `scheduled_restart=1`, `scheduled_restart_cron='0 4 * * 1'` (Mon 04:00)
- `config procd`: `fast_reload=1`
- `config subscription`: `user_agent='mihomo'` (upstream 'clash')
- `config proxy`: `ipv6_dns_hijack=0`, `ipv6_proxy=0`
- `config proxy`: `proxy_tcp_dport='21 22 80 110 143 194 443 465 853 993 995 8080 8443'` (upstream '0-65535')
- `config proxy`: `proxy_udp_dport='123 443 8443'` (upstream '0-65535')
- `config proxy`: `bypass_dscp='4'` (unchanged from upstream)
- `config router_access_control`: bypass for dnsmasq/ftp/logd/nobody/ntp/ubus users+groups, adguardhome/aria2/dnsmasq/netbird/qbittorrent/sysntpd/tailscale/zerotier cgroups
- `config lan_access_control`: default allow all, user can add per-IP bypasses

## install.sh

- Downloads latest release via GitHub API: `api.github.com/repos/lanetsky/nikkiopen/releases/latest`
- Extracts `nikki_{arch}-{branch}.tar.gz`, installs ipk/apk
- `LUCI_I18N=1` env var enables Russian translation install
- CDN raw.githubusercontent.com caches old versions — workaround: URL with commit hash
- Fallback tag: `v1.19.26-1` if API fails

## Build / Release

- `.github/workflows/build-packages.yml` — matrix build for aarch64_cortex-a53 × openwrt-24.10, openwrt-25.12
- `.github/workflows/release-packages.yml` — creates GitHub Release on tag push
- Bump procedure: edit `PKG_VERSION` in Makefile, commit `bump: mihomo vX.Y.Z`, tag `vX.Y.Z-1`, push + push tags

## Access Control

- `router_access_control`: user/group/cgroup-based via nftables (`hijack.ut`)
- `lan_access_control`: ip/ip6/mac-based via nftables
- `router_proxy=1` always enabled; root user not in bypass
- `bypass_dscp`: DSCP-based bypass (default value 4)
- Night update of rule-providers (provider-side fix): set `proxy: Proxy` in rule-providers subscription config

## Uninstall

`uninstall.sh` removes any nikki package by name (own or official), cleans configs and logs. Feed removal is harmless legacy.
