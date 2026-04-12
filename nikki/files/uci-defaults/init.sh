#!/bin/sh

. "$IPKG_INSTROOT/etc/nikki/scripts/include.sh"

# check nikki.config.init
init=$(uci -q get nikki.config.init); [ -z "$init" ] && return

# generate random string for api secret and authentication password
random=$(awk 'BEGIN{srand(); printf "%06d", int(rand() * 1000000)}')

# set nikki.mixin.api_secret
uci set nikki.mixin.api_secret="$random"

# set nikki.@authentication[0].password
uci set nikki.@authentication[0].password="$random"

# set nikki.config.enable_hwid
uci set nikki.config.enable_hwid='1'

# set nikki.config.hwid (auto-generate if not exists)
[ -z "$(uci -q get nikki.config.hwid)" ] && \
    uci set nikki.config.hwid="$(hexdump -n 8 -v -e '8/1 "%02x"' /dev/urandom)"

# remove nikki.config.init
uci del nikki.config.init

# commit
uci commit nikki

# exit with 0
exit 0
