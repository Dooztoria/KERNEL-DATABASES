#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="process_spy"
info "Monitoring processes (5s)..."
# Quick process monitor for cron jobs
procs=""
for i in {1..5}; do
    ps aux --sort=-start_time|head -5|grep -v "ps aux"|while read l; do
        echo "$l"|grep -qE "^root.*cron|^root.*backup|^root.*update" && procs="$procs $l"
    done
    sleep 1
done
[ -n "$procs" ] && { result_json "$METHOD" "found" "Root processes detected" ""; exit 0; }
result_json "$METHOD" "skip" "No interesting processes"; exit 1
