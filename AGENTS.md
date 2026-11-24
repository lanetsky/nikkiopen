# AGENTS.md — nikkiopen project context

## Project

Fork of [nikkinikki-org/OpenWrt-nikki](https://github.com/nikkinikki-org/OpenWrt-nikki), published at [lanetsky/nikkiopen](https://github.com/lanetsky/nikkiopen).
Binary-only mihomo package (no Go build), install via one script from router.

## Current state

- mihomo (core) version: **v1.19.34** (`nikki/Makefile` `PKG_VERSION`), `PKG_RELEASE=2`
- nikki base: **upstream v1.26.2**; LuCI App Version: **1.26.2** (`luci-app-nikki/Makefile` `PKG_VERSION`)
- OpenWrt: 24.10 + 25.12, arch: aarch64_cortex-a53
- Default config: `nikki/files/nikki.conf`

## Upstream merge procedure

Base is upstream **v1.26.2**. Custom-modified files — merge manually with upstream:
- `nikki/Makefile` — rewritten to binary-only (no Go/GoBinPackage/ALTERNATIVES), `Build/Prepare` downloads slim mihomo binary from `SaltyMonkey/justclash-core-slim` GitHub releases (`mihomo-linux-arm64-v$(PKG_VERSION).gz`, same tag/asset naming as MetaCubeX)
- `nikki/files/nikki.conf` — default config with custom defaults (see below), incl. `log.clear_at_stop '1'`
- `nikki/files/nikki.init` — curl subscription update with HWID headers (`x-hwid`, `x-device-os`, `x-ver-os`, `x-device-model` in `update_subscription`), TZ env var passed to mihomo (after `SKIP_SYSTEM_IPV6_CHECK`) for correct core log timestamps, subscription section resolution via `uci_get` (works with anonymous sections), mixin/profile/hijack errors are logged instead of silently ignored
- `nikki/files/scripts/include.sh` — paths and `get_hwid`/`get_openwrt_version`/`get_device_model` helper functions (no geoip), plus `nikki_uci_get`, `resolve_subscription_section`, `cleanup_leftovers`, `mixin_apply`, `MIXIN_EXPR`
- `nikki/files/scripts/migrate.sh` — the whole config migration (upstream v1.26.2 blocks + fork specific blocks), called by `99_migrate_nikki` and by the package postinst
- `nikki/files/uci-defaults/migrate.sh` — thin wrapper that runs `/etc/nikki/scripts/migrate.sh` (do NOT duplicate the logic there)
- `nikki/files/ucode/hijack.ut` — upstream file **with the geoip nft includes removed** (we do not ship `nikki/files/nftables/`); keep it removed, otherwise a config with `bypass_china_mainland_ip=1` breaks the whole hijack table
- `install.sh` — own installer (GitHub API `lanetsky/nikkiopen`), keep, do NOT adopt upstream `mihomo-meta` split
- `luci-app-nikki/htdocs/luci-static/resources/tools/nikki.js` — copy upstream, re-add `callNikkiHwid` rpc + `hwid()` method
- `luci-app-nikki/htdocs/luci-static/resources/view/nikki/app.js` — copy upstream, re-apply 'Taproom Nikki' branding
- `luci-app-nikki/htdocs/luci-static/resources/view/nikki/mixin.js` — copy upstream, re-apply MIBoard dashboard presets + `ui_name` auto-fill (see below)
- `luci-app-nikki/htdocs/luci-static/resources/view/nikki/proxy.js` — our version (upstream does not change it; only removed `bypass_china` flags)
- `luci-app-nikki/root/usr/share/rpcd/ucode/luci.nikki` — copy upstream (url fix `api_tls_listen ?? api_listen`), re-add `hwid` method
- `luci-app-nikki/po/ru/nikki.po` — copy upstream, remove 'Bypass China Mainland IP' entries, rename msgstr 'Nikki'→'Taproom Nikki', translate new strings

Files copied from upstream v1.26.2 without changes:
- `nikki/files/nikki.upgrade`
- `nikki/files/scripts/debug.sh`, `firewall_include.sh`
- `nikki/files/ucode/include.uc`, `mixin.uc`
- `nikki/files/mixin.yaml`
- `nikki/files/uci-defaults/firewall.sh`, `init.sh`
- `luci-app-nikki/Makefile` (PKG_VERSION:=1.26.2 — keeps App Version in sync; own `PKG_RELEASE` — bump it for fork-specific LuCI changes, otherwise opkg skips same-version packages)
- `luci-app-nikki/htdocs/luci-static/resources/view/nikki/editor.js`, `log.js`
- `luci-app-nikki/root/usr/share/rpcd/acl.d/luci-app-nikki.json` (`/tmp/log/nikki/*.log` access)
- `luci-app-nikki/po/templates/nikki.pot`

Ignore/skip from upstream: `mihomo-alpha/`, `mihomo-meta/` Makefiles (upstream moved core to separate `+mihomo` pkg — we keep binary inside nikki). After merge, delete `nikki/files/nftables/` if it appears (we use ucode hijack.ut instead).

## Our customizations vs upstream

- DNS: 1.1.1.1 + 8.8.8.8 (upstream uses Chinese 223.5.5.5)
- Mode: tproxy/tproxy (upstream redirect/tun)
- HWID: MAC-based sha256 in subscription headers
- UI: "Taproom Nikki" branding
- Dashboard picker in Mixin: extra MIBoard presets (`blagodaren/miboard`) + `ui_name` auto-fill; default panel stays Zashboard
- Removed: geoip files, bypass China, Chinese translations
- `+curl` in DEPENDS required: nikki.init uses curl for subscription updates
- `+ucode +ucode-mod-uci +ucode-mod-ubus +nftables` in DEPENDS: the mixin (`ucode -S mixin.uc`) and the hijack (`utpl -S hijack.ut`) need them
- Package lifecycle scripts (`nikki/Makefile`): `preinst` stops the running service + cleans leftovers before the package is replaced, `postinst` runs the migration and restarts the service, `prerm` stops the service and cleans leftovers, `postrm` removes the firewall include and the nft/ip leftovers
- Config compatibility with the official nikki 2026.x (see `nikki/files/scripts/migrate.sh`): anonymous subscription sections are renamed to a named one, `bypass_china_mainland_ip*` is forced to 0, missing proxy options are restored
- Nothing fails silently anymore: the mixin, the profile checks, the ip rules and the nft hijack log their errors to `/var/log/nikki/app.log`

## Dashboard (Mixin → External Control Config)

- `ui_path` → mihomo `external-ui`; `ui_name` → `external-ui-name`; `ui_url` → `external-ui-url` (archive downloaded by the core: auto on start if the target dir is empty, or `POST /upgrade/ui` = LuCI button "Update Dashboard")
- `mixin.js` presets for `ui_url` (combobox, free text allowed): Zashboard (CDN Fonts) / Zashboard / MetaCubeXD / YACD / Razord / MIBoard / MIBoard (CDN Fonts)
- `onchange` on `ui_url` fills `ui_name` with the panel's canonical folder name (`miboard`, `zashboard`, `metacubexd`, `yacd`, `razord`) via `this.section.getUIElement(section_id, 'ui_name').setValue(name)` — LuCI `form.Value` with `.value()` renders a `ui.Combobox` and fires `widget-change` → `onchange`
- MIBoard serves at `/ui/miboard/` and reads `?hostname=…&port=…&secret=…` (also zashboard-compatible `#/setup?…`), so the LuCI "Open Dashboard" button auto-connects it
- switching panel: old panel folder stays in `/etc/nikki/run/ui/<old-name>/` (mihomo only cleans the target dir) — remove manually
- default config (`nikki/files/nikki.conf`): `ui_path 'ui'`, `ui_url` = Zashboard CDN fonts, `ui_name` unset → panel at `/ui/`

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
- Installer must NOT depend on `raw.githubusercontent.com` (timeout/blocked for many users) — `install.sh`/`uninstall.sh` are attached to release assets, install cmd: `https://github.com/lanetsky/nikkiopen/releases/latest/download/install.sh`
- `install.sh` resolves the archive via `/releases/latest/download/` (no hard dependency on `api.github.com`), falls back to pinned tag `v1.19.34-3`
- **Router `wget` is uclient-fetch, not busybox wget** — it does NOT support `-t` (tries) and its `-T` is a connect/request timeout. Use only flags common to busybox/uclient-fetch/GNU wget: `-q -T N -O file`. Never `-t`.
- Tool order in scripts: **curl first** (works on routers where uclient-fetch cannot connect to github.com), wget as fallback
- Works in its own temp dir (`mktemp -d`, removed by a trap), it does not pollute the current directory anymore
- **Stops the running nikki service before the packages are replaced** (the old instance would keep the old binary and the old nft/ip rules)
- **Checks the exit code of `opkg install` / `apk add`** and exits with an error instead of printing "success"; on apk failure it prints the usual reasons (missing dependency like `yq`, unreachable repositories)
- CDN jsDelivr mirror documented in README as fallback: `https://cdn.jsdelivr.net/gh/lanetsky/nikkiopen@main/install.sh`
- `.github/workflows/sync-release-scripts.yml` — on push to main re-uploads `install.sh`/`uninstall.sh` to the latest release assets (keeps `/releases/latest/download/install.sh` fresh); release assets are cached by GitHub CDN for ~5 min after re-upload
- Fallback tag: `v1.19.34-3` if API fails

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

- Stops the service and removes the leftovers (nft table `inet nikki`, ip rules/routes 80/81, dummy device) before and after the removal
- `apk del` fails when the world contains an entry of a package that is not available anymore (e.g. the repository index became unreachable): the stale world entry is parsed from the apk error output (`X (no such package)`), removed from `/etc/apk/world` and the removal is retried
- The `luci-i18n-nikki-ru` package is looked up with `apk list --installed | grep` (not `apk list --manifest`, whose output format differs between apk versions)
