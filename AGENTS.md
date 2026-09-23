# AGENTS.md — nikkiopen project context

## Project

Fork of [nikkinikki-org/OpenWrt-nikki](https://github.com/nikkinikki-org/OpenWrt-nikki), published at [lanetsky/nikkiopen](https://github.com/lanetsky/nikkiopen).
Binary-only mihomo package (no Go build), install via one script from router.

## Current state

- mihomo version: **v1.19.31** (`nikki/Makefile` `PKG_VERSION`), current release `v1.19.31-4` (`PKG_RELEASE`)
- OpenWrt: 24.10 + 25.12, arch: aarch64_cortex-a53
- Default config: `nikki/files/nikki.conf`

## Upstream merge procedure

6 files have custom modifications — merge manually with upstream:
- `nikki/Makefile` — rewritten to binary-only (no Go/GoBinPackage/ALTERNATIVES), `Build/Prepare` downloads slim mihomo binary from `SaltyMonkey/justclash-core-slim` GitHub releases (`mihomo-linux-arm64-v$(PKG_VERSION).gz`, same tag/asset naming as MetaCubeX)
- `nikki/files/nikki.conf` — default config with custom defaults (see below)
- `nikki/files/nikki.init` — uses curl for subscription update (lines 559, 573), passes TZ env var to mihomo (line 255) for correct core log timestamps
- `nikki/files/scripts/include.sh` — paths and helper functions
- `luci-app-nikki/htdocs/luci-static/resources/view/nikki/app.js` — LuCI web UI (custom: "Taproom Nikki" branding, Start/Stop toggle in Status, no Reload button, no Enable checkbox — toggle sets+commits `config.enabled`, Restart = amber button; see "UI toggle customizations" below)
- `luci-app-nikki/htdocs/luci-static/resources/tools/nikki.js` — UI helper (RPC: start/stop/restart; see "UI toggle customizations" below — uci.set/commit quirks)
- `luci-app-nikki/po/ru/*.po` — Russian translations (incl. Start/Stop Service, Service Error strings)

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

## UI toggle customizations (re-apply after upstream merge)

LuCI 24.10 status page in `app.js` — upstream has an Enable checkbox + Reload button; we replaced them.

- `app.js`:
  - Remove Enable checkbox (`config.enabled` Flag in App Config) and Reload button (`form.Button 'reload'`).
- Status section rows: App/Core Version (readonly), Core Status (input colored green/red via poll), Service toggle + Restart button (two adjacent cells/columns, NO title labels), Open Dashboard. No Update Dashboard button (Zashboard updates itself).
- Toggle button = `form.DummyValue` (`_service_toggle`, no title) + `E('button', { id:'service_toggle', 'data-running': '0'/'1', 'click': ... })`, class `cbi-button cbi-button-action` (STOP state: `cbi-button-negative`), label `Start Service`/`Stop Service`. Poll updates both `service_toggle` and `core_status` (`poll.add`).
- `renderServiceToggle(running)`/`updateServiceToggle(element, running)`; click handler: try/catch → `nikki.stop()/start()`, disable button, errors via `ui.addTimeLimitedNotification(_('Service Error'), ..., 10000)`, then refresh status and call `ui.changes.init()` (clears stale "Unsaved Changes" indicator).
- Restart button = `form.DummyValue` (`_restart_service`, no title) + `E('button', { id:'restart_button', style:'border-color:#f59e0b; color:#f59e0b;' })` → `nikki.restart()`, same error banner + status refresh. NOT `form.Button` (no custom color class available); standard button base with amber outline/text, not a filled button. Do NOT merge both buttons into one DummyValue cell with a flex div — the theme's `@media (max-device-width:600px)` rule `.td.cbi-value-field .cbi-button { width:100% }` then stacks/overflows them (crooked on mobile) and breaks alignment on desktop; keep each button in its own titled-less option cell. No `update_dashboard` button and no `nikki.updateDashboard()`/`callNikkiAPI` (Zashboard updates itself).
- `tools/nikki.js`:
  - `status()` → `callRCList('nikki')?.nikki?.running`.
  - `start()`/`stop()` MUST follow this exact order and NOT chain on `uci.set`:
    1. `uci.set('nikki','config','enabled','1'|'0')` as a **statement** — `uci.set()` returns `undefined` (LuCI bug-trap: `.then` on it throws TypeError, silently breaking the whole click since the old `.catch()` swallowed it).
    2. `uci.save('nikki')` — stages into per-session save dir only, does NOT commit.
    3. `callUciCommit('nikki')` — own rpc.declare `{ object:'uci', method:'commit', params:['config'] }` (rpcd has no `save` method; rpcd `uci.commit` IS required to write enabled to `/etc/config` — otherwise autoload does not follow the button and OpenWrt shows a phantom "Unsaved Changes" entry). It also fires `service event config.change package=nikki` → procd reload trigger.
    4. `verifyEnabled('1'|'0')` — reads `uci.get('nikki','config','enabled')` post-save, rejects on mismatch (surfaces via banner).
    5. `callRCInit('nikki','reload')` for start, `callRCInit('nikki','stop')` for stop.
  - `reload()` exists (used by `editor.js:76`); `restart()` via `callRCInit('nikki','restart')`.
- `po/ru/nikki.po` — add msgid `Start Service`/`Stop Service`, `Service Error`, `Unable to toggle service`.

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
