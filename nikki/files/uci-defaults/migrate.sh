#!/bin/sh

# run the config migration
# (the logic lives in /etc/nikki/scripts/migrate.sh, it is also called by the
#  package postinst, so it must not be duplicated here)
[ -f /etc/nikki/scripts/migrate.sh ] && . /etc/nikki/scripts/migrate.sh

# exit with 0
exit 0
