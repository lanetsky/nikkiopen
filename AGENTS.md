# AGENTS.md — nikkiopen project context

## Project

Fork of [nikkinikki-org/OpenWrt-nikki](https://github.com/nikkinikki-org/OpenWrt-nikki), published at [lanetsky/nikkiopen](https://github.com/lanetsky/nikkiopen).
Binary-only mihomo package (no Go build), install via one script from router.

## Current state

- mihomo (core) version: **v1.19.32** (`nikki/Makefile` `PKG_VERSION`), `PKG_RELEASE=2`
- nikki base: **upstream v1.26.2**; LuCI App Version: **1.26.2** (`luci-app-nikki/Makefile` `PKG_VERSION`)
- OpenWrt: 24.10 + 25.12, arch: aarch64_cortex-a53
- Default config: `nikki/files/nikki.conf`

## Upstream merge procedure

Base is upstream **v1.26.2**. Custom-modified files — merge manually with upstream:
- `nikki/Makefile` — rewritten to binary-only (no Go/GoBinPackage/ALTERNATIVES), `Build/Prepare` downloads slim mihomo binary from `SaltyMonkey/justclash-core-slim` GitHub releases (`mihomo-linux-arm64-v$(PKG_VERSION).gz`, same tag/asset naming as MetaCubeX)
- `nikki/files/nikki.conf` — default config with custom defaults (see below), incl. `log.clear_at_stop '1'`
- `nikki/files/nikki.init` — curl subscription update with HWID headers (`x-hwid`, `x-device-os`, `x-ver-os`, `x-device-model` in `update_subscription`), TZ env var passed to mihomo (after `SKIP_SYSTEM_IPV6_CHECK`) for correct core log timestamps
- `nikki/files/scripts/include.sh` — paths and `get_hwid`/`get_openwrt_version`/`get_device_model` helper functions (no geoip)
- `nikki/files/uci-defaults/migrate.sh` — upstream v1.26.2 minus the `bypass_china_mainland_ip` migration block (v1.24.3 section)
- `install.sh` — own installer (GitHub API `lanetsky/nikkiopen`), keep, do NOT adopt upstream `mihomo-meta` split
- `luci-app-nikki/htdocs/luci-static/resources/tools/nikki.js` — copy upstream, re-add `callNikkiHwid` rpc + `hwid()` method
- `luci-app-nikki/htdocs/luci-static/resources/view/nikki/app.js` — copy upstream, re-apply 'Taproom Nikki' branding
- `luci-app-nikki/htdocs/luci-static/resources/view/nikki/proxy.js` — our version (upstream does not change it; only removed `bypass_china` flags)
- `luci-app-nikki/root/usr/share/rpcd/ucode/luci.nikki` — copy upstream (url fix `api_tls_listen ?? api_listen`), re-add `hwid` method
- `luci-app-nikki/po/ru/nikki.po` — copy upstream, remove 'Bypass China Mainland IP' entries, rename msgstr 'Nikki'→'Taproom Nikki', translate new strings

Files copied from upstream v1.26.2 without changes:
- `nikki/files/nikki.upgrade`
- `nikki/files/scripts/debug.sh`, `firewall_include.sh`
- `nikki/files/ucode/hijack.ut` (dns_hijack guard fix), `include.uc`, `mixin.uc`
- `nikki/files/mixin.yaml`
- `nikki/files/uci-defaults/firewall.sh`, `init.sh`
- `luci-app-nikki/Makefile` (PKG_VERSION:=1.26.2 — keeps App Version in sync)
- `luci-app-nikki/htdocs/luci-static/resources/view/nikki/mixin.js`, `editor.js`, `log.js`
- `luci-app-nikki/root/usr/share/rpcd/acl.d/luci-app-nikki.json` (`/tmp/log/nikki/*.log` access)
- `luci-app-nikki/po/templates/nikki.pot`

Ignore/skip from upstream: `mihomo-alpha/`, `mihomo-meta/` Makefiles (upstream moved core to separate `+mihomo` pkg — we keep binary inside nikki). After merge, delete `nikki/files/nftables/` if it appears (we use ucode hijack.ut instead).

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
- CDN raw.githubusercontent.com caches old versions — known issue, not yet fixed (users get 404/429 on raw URL)
- Fallback tag: `v1.19.32-2` if API fails

## Build / Release

- `.github/workflows/build-packages.yml` — matrix build for aarch64_cortex-a53 × openwrt-24.10, openwrt-25.12
- `.github/workflows/release-packages.yml` — creates GitHub Release on tag push
- Bump procedure: edit `PKG_VERSION` (core) or `PKG_RELEASE` in `nikki/Makefile`, commit, tag `vX.Y.Z-N`, push + push tags

## Access Control

- `router_access_control`: user/group/cgroup-based via nftables (`hijack.ut`)
- `lan_access_control`: ip/ip6/mac-based via nftables
- `router_proxy=1` always enabled; root user not in bypass
- `bypass_dscp`: DSCP-based bypass (default value 4)
- Night update of rule-providers (provider-side fix): set `proxy: Proxy` in rule-providers subscription config

## Uninstall

`uninstall.sh` removes any nikki package by name (own or official), cleans configs and logs. Feed removal is harmless legacy.
