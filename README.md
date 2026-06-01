![GitHub License](https://img.shields.io/github/license/lanetsky/nikkiopen?style=for-the-badge&logo=github) ![GitHub Tag](https://img.shields.io/github/v/release/lanetsky/nikkiopen?style=for-the-badge&logo=github) ![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/lanetsky/nikkiopen/total?style=for-the-badge&logo=github) ![GitHub Repo stars](https://img.shields.io/github/stars/lanetsky/nikkiopen?style=for-the-badge&logo=github)

English | [Русский](README.ru.md)

---

## Taproom Nikki Fork

This is a forked version of [nikkinikki-org/OpenWrt-nikki](https://github.com/nikkinikki-org/OpenWrt-nikki) with the following modifications:

- **DNS**: 1.1.1.1 + 8.8.8.8 (instead of Chinese 223.5.5.5)
- **Mode**: tproxy/tproxy (instead of redirect/tun)
- **HWID**: MAC-based sha256 sent in subscription headers
- **UI**: "Taproom Nikki" branding
- **Removed**: geoip files, bypass China, Chinese translations
- **Architecture**: only aarch64_cortex-a53
- **OpenWrt**: 24.10 + 25.12

Download: See [Releases](https://github.com/lanetsky/nikkiopen/releases)

### Maintenance Notes

When updating from upstream, remember to:
- Update `.po` translation files in `luci-app-nikki/po/ru/` if UI changes are made
- Remove obsolete strings for deleted features

---

# Nikki

Transparent Proxy with Mihomo on OpenWrt.

## Prerequisites

- OpenWrt >= 24.10
- Linux Kernel >= 5.13
- firewall4

## Feature

- Transparent Proxy (Redirect/TPROXY/TUN, IPv4 and/or IPv6)
- Access Control
- Profile Mixin
- Profile Editor
- Scheduled Restart

## Install & Update

```shell
wget -O - https://github.com/lanetsky/nikkiopen/raw/refs/heads/main/install.sh | ash
```

## Uninstall & Reset

```shell
wget -O - https://github.com/lanetsky/nikkiopen/raw/refs/heads/main/uninstall.sh | ash
```

## How To Use

See [Wiki](https://github.com/lanetsky/nikkiopen/wiki)

## How does it work

1. Mixin and Update profile.
2. Run mihomo.
3. Set scheduled restart.
4. Set ip rule/route
5. Generate nftables and apply it.

Note that the steps above may change base on config.

## Dependencies

- ca-bundle
- curl
- yq
- firewall4
- ip-full
- kmod-inet-diag
- kmod-nft-socket
- kmod-nft-tproxy
- kmod-tun
- kmod-dummy

## Contributors

[![Contributors](https://contrib.rocks/image?repo=lanetsky/nikkiopen)](https://github.com/lanetsky/nikkiopen/graphs/contributors)

## Special Thanks

- [@ApoisL](https://github.com/apoiston)
- [@xishang0128](https://github.com/xishang0128)

## Recommended Proxy Provider

Perfect Link is recommended

All route on IEPL, All exit node at Akari, reliable and easy to use

[Official Website](https://perfectlink.io) | [Customer Service](https://t.me/PerfectlinksupportBot)
