#!/bin/bash
# Advanced GSSocket Scanner v2.0
# Detects ALL gsocket backdoors: processes, files, cron, systemd

echo '{"gsockets":['
first=1

add_item() {
    [ $first -eq 0 ] && echo ","
    first=0
    echo "$1"
}

# ========== METHOD 1: Process Analysis ==========
while IFS= read -r line; do
    [ -z "$line" ] && continue
    
    pid=$(echo "$line" | awk '{print $2}')
    user=$(echo "$line" | awk '{print $1}')
    cmd=$(echo "$line" | awk '{for(i=11;i<=NF;i++)printf $i" "}')
    
    # Skip if not valid PID
    [ ! -d "/proc/$pid" ] && continue
    
    secret=""
    
    # Try multiple methods to extract secret
    # 1. From command line -s flag
    secret=$(echo "$cmd" | grep -oP '(?<=-s\s)[^\s]+' 2>/dev/null | head -1)
    [ -z "$secret" ] && secret=$(echo "$cmd" | grep -oP "(?<=-s\s')[^']+" 2>/dev/null | head -1)
    [ -z "$secret" ] && secret=$(echo "$cmd" | grep -oP '(?<=-s\s")[^"]+' 2>/dev/null | head -1)
    
    # 2. From /proc/PID/cmdline (more reliable)
    [ -z "$secret" ] && secret=$(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' '\n' | grep -A1 "^-s$" | tail -1)
    [ -z "$secret" ] && secret=$(strings /proc/$pid/cmdline 2>/dev/null | grep -oP '(?<=-s)[a-zA-Z0-9]+' | head -1)
    
    # 3. From environment variables
    [ -z "$secret" ] && secret=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep -oP '(?<=GSOCKET_SECRET=).+' | head -1)
    [ -z "$secret" ] && secret=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep -oP '(?<=GS_SECRET=).+' | head -1)
    [ -z "$secret" ] && secret=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep -oP '(?<=^S=).+' | head -1)
    
    # 4. From fd links (open files)
    if [ -z "$secret" ]; then
        for fd in /proc/$pid/fd/*; do
            target=$(readlink "$fd" 2>/dev/null)
            if [[ "$target" == *".gs"* ]] || [[ "$target" == *"gsocket"* ]]; then
                [ -f "$target" ] && secret=$(cat "$target" 2>/dev/null | head -1 | tr -d '[:space:]')
            fi
        done
    fi
    
    # Get additional info
    start=$(ps -o lstart= -p $pid 2>/dev/null | xargs)
    ppid=$(ps -o ppid= -p $pid 2>/dev/null | xargs)
    pname=$(ps -o comm= -p $ppid 2>/dev/null)
    exe=$(readlink -f /proc/$pid/exe 2>/dev/null)
    conns=$(ls /proc/$pid/fd 2>/dev/null | wc -l)
    
    # Determine mode
    mode="unknown"
    echo "$cmd" | grep -q "\-l" && mode="listener"
    echo "$cmd" | grep -q "\-i" && mode="interactive"  
    echo "$cmd" | grep -q "\-e" && mode="exec"
    echo "$cmd" | grep -q "\-p" && mode="portfwd"
    
    add_item "{\"pid\":$pid,\"user\":\"$user\",\"secret\":\"${secret:-hidden}\",\"start\":\"$start\",\"parent\":\"${pname:-?}($ppid)\",\"mode\":\"$mode\",\"conns\":$conns,\"exe\":\"$exe\"}"
    
done < <(ps aux 2>/dev/null | grep -E 'gs-netcat|gsocket|gs-pipe' | grep -v grep)

# ========== METHOD 2: File-based secrets ==========
for pattern in "/tmp/.gs*" "/tmp/gs*" "$HOME/.gsocket" "$HOME/.gs_*" "/dev/shm/.gs*" "/dev/shm/gs*" "/var/tmp/.gs*" "/root/.gs*" "/home/*/.gs*" "/home/*/.config/htop/*" "/tmp/.z/gs"; do
    for f in $pattern; do
        [ ! -f "$f" ] 2>/dev/null && continue
        content=$(head -c 100 "$f" 2>/dev/null | tr -d '\n\r' | tr '"' "'")
        owner=$(stat -c '%U' "$f" 2>/dev/null)
        mtime=$(stat -c '%y' "$f" 2>/dev/null | cut -d. -f1)
        perm=$(stat -c '%a' "$f" 2>/dev/null)
        add_item "{\"type\":\"file\",\"path\":\"$f\",\"owner\":\"$owner\",\"perm\":\"$perm\",\"mtime\":\"$mtime\",\"content\":\"$content\"}"
    done
done

# ========== METHOD 3: Cron persistence ==========
cron_hits=""
for loc in /etc/crontab /etc/cron.d/* /var/spool/cron/crontabs/* /var/spool/cron/*; do
    [ ! -f "$loc" ] 2>/dev/null && continue
    hit=$(grep -l "gs-netcat\|gsocket\|gs-pipe" "$loc" 2>/dev/null)
    [ -n "$hit" ] && cron_hits="$cron_hits $hit"
done
if [ -n "$cron_hits" ]; then
    content=$(grep -h "gs-netcat\|gsocket" $cron_hits 2>/dev/null | head -3 | tr '\n' ';' | tr '"' "'")
    add_item "{\"type\":\"cron\",\"files\":\"$cron_hits\",\"content\":\"$content\"}"
fi

# ========== METHOD 4: Systemd persistence ==========
for loc in /etc/systemd/system/*.service /lib/systemd/system/*.service /etc/systemd/system/*/*.service; do
    [ ! -f "$loc" ] 2>/dev/null && continue
    if grep -q "gs-netcat\|gsocket" "$loc" 2>/dev/null; then
        content=$(grep -E "ExecStart|Description" "$loc" 2>/dev/null | head -2 | tr '\n' ';' | tr '"' "'")
        add_item "{\"type\":\"systemd\",\"path\":\"$loc\",\"content\":\"$content\"}"
    fi
done

# ========== METHOD 5: RC/Profile persistence ==========  
for loc in /etc/rc.local /etc/profile /etc/profile.d/*.sh ~/.bashrc ~/.profile ~/.bash_profile /root/.bashrc /root/.profile; do
    [ ! -f "$loc" ] 2>/dev/null && continue
    if grep -q "gs-netcat\|gsocket" "$loc" 2>/dev/null; then
        content=$(grep "gs-netcat\|gsocket" "$loc" 2>/dev/null | head -2 | tr '\n' ';' | tr '"' "'")
        add_item "{\"type\":\"rcfile\",\"path\":\"$loc\",\"content\":\"$content\"}"
    fi
done

# ========== METHOD 6: Network connections (gsocket relay) ==========
relay_conns=$(ss -tnp 2>/dev/null | grep -E ':443\s.*gs-netcat|:22\s.*gs-netcat' | head -5)
if [ -n "$relay_conns" ]; then
    content=$(echo "$relay_conns" | tr '\n' ';' | head -c 200)
    add_item "{\"type\":\"relay\",\"content\":\"$content\"}"
fi

echo ']}'
