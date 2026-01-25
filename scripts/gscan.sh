#!/bin/bash
# Advanced GSSocket Scanner - Detect ALL backdoors

echo '{"gsockets":['
first=1

# Method 1: Find all gs-netcat processes
while read -r line; do
    [ -z "$line" ] && continue
    pid=$(echo "$line" | awk '{print $2}')
    user=$(echo "$line" | awk '{print $1}')
    cmd=$(echo "$line" | awk '{for(i=11;i<=NF;i++)printf $i" "}')
    
    # Extract secret from various sources
    secret=""
    
    # From command line -s flag
    secret=$(echo "$cmd" | grep -oP '(?<=-s )[^\s]+' | head -1)
    
    # From command line -s flag (single quotes)
    [ -z "$secret" ] && secret=$(echo "$cmd" | grep -oP "(?<=-s ')[^']+(?=')" | head -1)
    
    # From environment variable
    [ -z "$secret" ] && secret=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep -oP '(?<=GSOCKET_SECRET=).+' | head -1)
    [ -z "$secret" ] && secret=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep -oP '(?<=GS_SECRET=).+' | head -1)
    
    # From cmdline file directly
    [ -z "$secret" ] && secret=$(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ' | grep -oP '(?<=-s )[^\s]+' | head -1)
    
    # Check for config file
    [ -z "$secret" ] && [ -f "$HOME/.gsocket" ] && secret=$(cat "$HOME/.gsocket" 2>/dev/null | head -1)
    [ -z "$secret" ] && [ -f "/tmp/.gs*" ] && secret=$(cat /tmp/.gs* 2>/dev/null | head -1)
    
    # Get start time
    start=$(ps -o lstart= -p $pid 2>/dev/null | xargs)
    
    # Get listening port
    lport=$(ss -tlnp 2>/dev/null | grep "pid=$pid" | awk '{print $4}' | grep -oP ':\K[0-9]+' | head -1)
    
    # Get connection info
    conns=$(ss -tnp 2>/dev/null | grep "pid=$pid" | wc -l)
    
    # Get parent process
    ppid=$(ps -o ppid= -p $pid 2>/dev/null | xargs)
    pname=$(ps -o comm= -p $ppid 2>/dev/null | xargs)
    
    # Get mode (-l = listen, -i = interactive, etc)
    mode="unknown"
    echo "$cmd" | grep -q "\-l" && mode="listener"
    echo "$cmd" | grep -q "\-i" && mode="interactive"
    echo "$cmd" | grep -q "\-e" && mode="exec"
    
    # Get binary path
    exe=$(readlink -f /proc/$pid/exe 2>/dev/null)
    
    [ $first -eq 0 ] && echo ","
    first=0
    
    cat << ITEM
{"pid":$pid,"user":"$user","secret":"${secret:-hidden}","start":"$start","port":"${lport:-N/A}","conns":$conns,"mode":"$mode","parent":"${pname:-?}($ppid)","exe":"$exe","cmd":"$(echo "$cmd" | head -c 100)"}
ITEM

done < <(ps aux 2>/dev/null | grep -E 'gs-netcat|gsocket' | grep -v grep)

# Method 2: Check for gsocket files/configs
for f in /tmp/.gs* /tmp/gs* ~/.gsocket ~/.gs_* /dev/shm/.gs* /var/tmp/.gs*; do
    [ -f "$f" ] 2>/dev/null || continue
    content=$(cat "$f" 2>/dev/null | head -c 50)
    owner=$(stat -c '%U' "$f" 2>/dev/null)
    mtime=$(stat -c '%y' "$f" 2>/dev/null | cut -d. -f1)
    [ $first -eq 0 ] && echo ","
    first=0
    echo "{\"type\":\"file\",\"path\":\"$f\",\"owner\":\"$owner\",\"content\":\"$content\",\"mtime\":\"$mtime\"}"
done

# Method 3: Check cron for gsocket persistence
cron=$(grep -r "gs-netcat\|gsocket" /etc/cron* /var/spool/cron* 2>/dev/null | head -3)
if [ -n "$cron" ]; then
    [ $first -eq 0 ] && echo ","
    first=0
    echo "{\"type\":\"cron\",\"content\":\"$(echo "$cron" | tr '\n' ' ' | head -c 200)\"}"
fi

# Method 4: Check systemd for gsocket
sysd=$(grep -r "gs-netcat\|gsocket" /etc/systemd /lib/systemd 2>/dev/null | head -3)
if [ -n "$sysd" ]; then
    [ $first -eq 0 ] && echo ","
    first=0
    echo "{\"type\":\"systemd\",\"content\":\"$(echo "$sysd" | tr '\n' ' ' | head -c 200)\"}"
fi

# Method 5: Check network for gsocket relay connections
relay=$(ss -tnp 2>/dev/null | grep -E ':22 |:443 ' | grep -v sshd | head -5)
if [ -n "$relay" ]; then
    [ $first -eq 0 ] && echo ","
    first=0
    echo "{\"type\":\"relay_conn\",\"content\":\"$(echo "$relay" | tr '\n' ';' | head -c 200)\"}"
fi

echo ']}'
