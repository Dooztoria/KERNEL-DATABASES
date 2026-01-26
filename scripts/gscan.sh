#!/bin/bash
# GSSocket Monitor - Detect and monitor ALL gsocket backdoors
echo '{"gsockets":['
first=1

# Scan gs-netcat processes
while read -r line; do
    [ -z "$line" ] && continue
    pid=$(echo "$line" | awk '{print $2}')
    user=$(echo "$line" | awk '{print $1}')
    [ ! -d "/proc/$pid" ] && continue
    
    secret=""
    mode="unknown"
    
    # Get cmdline
    if [ -r "/proc/$pid/cmdline" ]; then
        cmd=$(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ')
        # Extract secret
        secret=$(echo "$cmd" | sed -n 's/.*-s[ ]*\([^ ]*\).*/\1/p' | tr -d "'" | head -1)
        # Determine mode
        echo "$cmd" | grep -q "\-l" && mode="listener"
        echo "$cmd" | grep -q "\-e" && mode="exec"
        echo "$cmd" | grep -q "\-i" && mode="interactive"
    fi
    
    # Try environ if no secret
    if [ -z "$secret" ] && [ -r "/proc/$pid/environ" ]; then
        secret=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep -E "^S=|GSOCKET" | cut -d= -f2 | head -1)
    fi
    
    [ $first -eq 0 ] && echo ","
    first=0
    echo "{\"pid\":$pid,\"user\":\"$user\",\"secret\":\"${secret:-hidden}\",\"mode\":\"$mode\"}"
done < <(ps aux 2>/dev/null | grep -E 'gs-netcat|gsocket' | grep -v grep)

# Scan gsocket files
for f in /tmp/.gs* /tmp/gs-* ~/.gsocket ~/.gs_* /dev/shm/.gs* /var/tmp/.gs* /run/.gs*; do
    [ -f "$f" ] 2>/dev/null || continue
    owner=$(stat -c '%U' "$f" 2>/dev/null || echo "?")
    content=$(head -c 50 "$f" 2>/dev/null | tr -cd 'a-zA-Z0-9')
    [ $first -eq 0 ] && echo ","
    first=0
    echo "{\"type\":\"file\",\"path\":\"$f\",\"owner\":\"$owner\",\"content\":\"$content\"}"
done

# Scan crontabs for gsocket
for ct in /etc/cron.d/* /var/spool/cron/crontabs/* /etc/crontab; do
    [ -r "$ct" ] 2>/dev/null || continue
    if grep -q "gs-netcat\|gsocket" "$ct" 2>/dev/null; then
        [ $first -eq 0 ] && echo ","
        first=0
        line=$(grep -m1 "gs-netcat\|gsocket" "$ct" | tr -d '\n' | cut -c1-100)
        echo "{\"type\":\"cron\",\"path\":\"$ct\",\"line\":\"$line\"}"
    fi
done

# Scan systemd for gsocket
for svc in /etc/systemd/system/*.service /lib/systemd/system/*.service; do
    [ -r "$svc" ] 2>/dev/null || continue
    if grep -q "gs-netcat\|gsocket" "$svc" 2>/dev/null; then
        [ $first -eq 0 ] && echo ","
        first=0
        echo "{\"type\":\"systemd\",\"path\":\"$svc\"}"
    fi
done

echo ']}'
