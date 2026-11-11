![GitHub License](https://img.shields.io/github/license/lanetsky/nikkiopen?style=for-the-badge&logo=github) ![GitHub Tag](https://img.shields.io/github/v/release/lanetsky/nikkiopen?style=for-the-badge&logo=github) ![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/lanetsky/nikkiopen/total?style=for-the-badge&logo=github) ![GitHub Repo stars](https://img.shields.io/github/stars/lanetsky/nikkiopen?style=for-the-badge&logo=github)

[English](README.md) | Русский

---

## Taproom Nikki Fork

Это форк версия [nikkinikki-org/OpenWrt-nikki](https://github.com/nikkinikki-org/OpenWrt-nikki) со следующими изменениями:

- **DNS**: 1.1.1.1 + 8.8.8.8 (вместо китайского 223.5.5.5)
- **Режим**: tproxy/tproxy (вместо redirect/tun)
- **HWID**: MAC-based sha256 в заголовках подписки
- **UI**: "Taproom Nikki" брендинг
- **Удалено**: geoip файлы, bypass China, китайские переводы
- **Архитектура**: только aarch64_cortex-a53
- **OpenWrt**: 24.10 + 25.12

Скачать: см. [Releases](https://github.com/lanetsky/nikkiopen/releases)

### Заметки по поддержке

При обновлении из upstream:
- Обновлять `.po` файлы переводов в `luci-app-nikki/po/ru/` при изменениях UI
- Удалять устаревшие строки для удалённых функций

---

# Nikki

Прозрачный прокси с Mihomo на OpenWrt.

## Требования

- OpenWrt >= 24.10
- Linux Kernel >= 5.13
- firewall4

## Возможности

- Прозрачный прокси (Redirect/TPROXY/TUN, IPv4 и/или IPv6)
- Контроль доступа
- Profile Mixin
- Редактор профилей
- Запланированный перезапуск

## Установка и обновление

```shell
curl -fsSL https://github.com/lanetsky/nikkiopen/releases/latest/download/install.sh | ash
```

Если на роутере нет `curl`, используй `wget`:

```shell
wget -O - https://github.com/lanetsky/nikkiopen/releases/latest/download/install.sh | ash
```

Для установки русского перевода (luci-i18n-nikki-ru):

```shell
LUCI_I18N=1 curl -fsSL https://github.com/lanetsky/nikkiopen/releases/latest/download/install.sh | ash
```

### Если скачивание зависает (таймаут)

Если загрузка подвисает или отваливается по таймауту, попробуй один из вариантов:

```shell
# принудительно IPv4 (на роутерах с битыми IPv6-маршрутами может зависать)
curl -4 -fsSL https://github.com/lanetsky/nikkiopen/releases/latest/download/install.sh | ash

# зеркало через CDN jsDelivr
curl -fsSL https://cdn.jsdelivr.net/gh/lanetsky/nikkiopen@main/install.sh | ash

# либо скачай архив вручную и установи пакеты из него
curl -fsSL https://github.com/lanetsky/nikkiopen/releases/latest/download/nikki_aarch64_cortex-a53-openwrt-24.10.tar.gz -o nikki.tar.gz
```

## Удаление и сброс

```shell
curl -fsSL https://github.com/lanetsky/nikkiopen/releases/latest/download/uninstall.sh | ash
```

## Как использовать

См. [Wiki](https://github.com/lanetsky/nikkiopen/wiki)

## Как это работает

1. Mixin и обновление профиля.
2. Запуск mihomo.
3. Установка запланированного перезапуска.
4. Настройка ip rule/route
5. Генерация nftables и применение.

Примечание: шаги могут меняться в зависимости от конфигурации.

## Зависимости

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

## Вклад

[![Contributors](https://contrib.rocks/image?repo=lanetsky/nikkiopen)](https://github.com/lanetsky/nikkiopen/graphs/contributors)

## Особая благодарность

- [@ApoisL](https://github.com/apoiston)
- [@xishang0128](https://github.com/xishang0128)

## Рекомендуемый провайдер прокси

Рекомендуется Perfect Link

Все маршруты через IEPL, все выходные узлы Akari, надёжно и удобно

[Официальный сайт](https://perfectlink.io) | [Поддержка](https://t.me/PerfectlinksupportBot)
