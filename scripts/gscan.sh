#!/bin/bash
# GSSocket Scanner

echo '{"gsockets":['
first=1

emit() {
    [ $first -eq 0 ] && echo ","
    first=0
    echo "$1"
}

# Scan processes
while IFS= read -r line; do
    [ -z "$line" ] && continue
    echo "$line" | grep -q grep && continue
    
    pid=$(echo "$line" | awk '{print $2}')
    user=$(echo "$line" | awk '{print $1}')
    
    secret="hidden"
    mode="unknown"
    
    if [ -r "/proc/$pid/cmdline" ]; then
        cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
        # Extract -s argument
        secret=$(echo "$cmd" | sed -n "s/.*-s[[:space:]]*'\([^']*\)'.*/\1/p")
        [ -z "$secret" ] && secret=$(echo "$cmd" | sed -n 's/.*-s[[:space:]]*\([^[:space:]]*\).*/\1/p')
        [ -z "$secret" ] && secret="hidden"
        
        echo "$cmd" | grep -q "\-l" && mode="listener"
        echo "$cmd" | grep -q "\-e" && mode="backdoor"
        echo "$cmd" | grep -q "\-i" && mode="client"
    fi
    
    emit "{\"type\":\"process\",\"pid\":$pid,\"user\":\"$user\",\"secret\":\"$secret\",\"mode\":\"$mode\"}"
done < <(ps aux 2>/dev/null | grep -E 'gs-netcat|gsocket' | grep -v grep)

# Scan files
for f in /tmp/.gs* /tmp/gs-* /dev/shm/.gs* /dev/shm/gs* /var/tmp/.gs* ~/.gsocket ~/.gs_*; do
    [ -e "$f" ] 2>/dev/null || continue
    owner=$(stat -c '%U' "$f" 2>/dev/null || echo "?")
    emit "{\"type\":\"file\",\"path\":\"$f\",\"owner\":\"$owner\"}"
done

# Scan crontabs
crontabs="/etc/crontab"
[ -d /etc/cron.d ] && crontabs="$crontabs /etc/cron.d/*"
[ -d /var/spool/cron/crontabs ] && crontabs="$crontabs /var/spool/cron/crontabs/*"

for ct in $crontabs; do
    [ -r "$ct" ] || continue
    if grep -qiE 'gs-netcat|gsocket' "$ct" 2>/dev/null; then
        emit "{\"type\":\"cron\",\"path\":\"$ct\"}"
    fi
done

# Scan systemd
for svc in /etc/systemd/system/*.service /lib/systemd/system/*.service; do
    [ -r "$svc" ] 2>/dev/null || continue
    if grep -qiE 'gs-netcat|gsocket' "$svc" 2>/dev/null; then
        emit "{\"type\":\"systemd\",\"path\":\"$svc\"}"
    fi
done

echo ']}'
