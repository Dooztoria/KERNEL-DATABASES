#!/bin/bash
echo '{"gsockets":['
first=1

# Scan for gs-netcat processes
while read -r line; do
    [ -z "$line" ] && continue
    pid=$(echo "$line" | awk '{print $2}')
    user=$(echo "$line" | awk '{print $1}')
    [ ! -d "/proc/$pid" ] && continue
    
    # Extract secret from cmdline
    secret=""
    if [ -r "/proc/$pid/cmdline" ]; then
        cmdline=$(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ')
        secret=$(echo "$cmdline" | sed -n 's/.*-s \([^ ]*\).*/\1/p' | head -1)
        [ -z "$secret" ] && secret=$(echo "$cmdline" | sed -n "s/.*-s'\([^']*\)'.*/\1/p" | head -1)
    fi
    
    # Try environment
    if [ -z "$secret" ] && [ -r "/proc/$pid/environ" ]; then
        secret=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep "^S=" | cut -d= -f2 | head -1)
        [ -z "$secret" ] && secret=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep "GSOCKET_SECRET=" | cut -d= -f2 | head -1)
    fi
    
    mode="listener"
    echo "$cmdline" | grep -q "\-i" && mode="interactive"
    echo "$cmdline" | grep -q "\-e" && mode="exec"
    
    [ $first -eq 0 ] && echo ","
    first=0
    echo "{\"pid\":$pid,\"user\":\"$user\",\"secret\":\"${secret:-hidden}\",\"mode\":\"$mode\"}"
done < <(ps aux 2>/dev/null | grep -E 'gs-netcat|gsocket' | grep -v grep)

# Check for gsocket files
for f in /tmp/.gs* /tmp/gs* ~/.gsocket ~/.gs_* /dev/shm/.gs* /var/tmp/.gs*; do
    [ -f "$f" ] 2>/dev/null || continue
    owner=$(stat -c '%U' "$f" 2>/dev/null)
    [ $first -eq 0 ] && echo ","
    first=0
    echo "{\"type\":\"file\",\"path\":\"$f\",\"owner\":\"$owner\"}"
done

echo ']}'
