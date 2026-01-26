#!/bin/bash
# GSSocket Scanner - Detect active GSockets on system

info() { echo "[*] $*" >&2; }

# Arrays to store results
declare -a results

# Method 1: Process scan for gs-netcat/defunct
info "Scanning processes..."
while IFS= read -r line; do
    pid=$(echo "$line" | awk '{print $2}')
    user=$(echo "$line" | awk '{print $1}')
    cmd=$(echo "$line" | awk '{for(i=11;i<=NF;i++)printf "%s ",$i}')
    
    # Try to extract secret from /proc
    secret=""
    if [ -r "/proc/$pid/cmdline" ]; then
        secret=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null | grep -oE '\-s [^ ]+' | awk '{print $2}')
    fi
    if [ -z "$secret" ] && [ -r "/proc/$pid/environ" ]; then
        secret=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep -E '^GS_SECRET=|^S=' | cut -d= -f2 | head -1)
    fi
    
    # Determine mode
    mode="unknown"
    echo "$cmd" | grep -q "\-l" && mode="listen"
    echo "$cmd" | grep -q "\-i" && mode="interactive"
    
    results+=("{\"type\":\"process\",\"pid\":$pid,\"user\":\"$user\",\"secret\":\"$secret\",\"mode\":\"$mode\"}")
done < <(ps aux 2>/dev/null | grep -E 'gs-netcat|defunct|gsocket' | grep -v grep)

# Method 2: Check /proc for hidden processes
info "Checking /proc for hidden processes..."
for pid in /proc/[0-9]*; do
    pid_num=$(basename "$pid")
    [ -r "$pid/comm" ] || continue
    
    comm=$(cat "$pid/comm" 2>/dev/null)
    cmdline=$(tr '\0' ' ' < "$pid/cmdline" 2>/dev/null)
    
    # Check if it's gsocket related
    if echo "$cmdline" | grep -qE 'gs-netcat|defunct|gsocket|-s [A-Za-z0-9]'; then
        # Not already found
        if ! printf '%s\n' "${results[@]}" | grep -q "\"pid\":$pid_num"; then
            user=$(stat -c '%U' "$pid" 2>/dev/null || echo "unknown")
            secret=$(echo "$cmdline" | grep -oE '\-s [^ ]+' | awk '{print $2}')
            results+=("{\"type\":\"process\",\"pid\":$pid_num,\"user\":\"$user\",\"secret\":\"$secret\",\"mode\":\"hidden\"}")
        fi
    fi
done

# Method 3: Check for .dat secret files
info "Checking for secret files..."
for f in /tmp/.gs* /dev/shm/.gs* ~/.config/htop/*.dat /var/www/*/*.dat /home/*/.config/htop/*.dat; do
    if [ -f "$f" ] 2>/dev/null; then
        secret=$(cat "$f" 2>/dev/null | head -1)
        owner=$(stat -c '%U' "$f" 2>/dev/null || echo "unknown")
        results+=("{\"type\":\"secret_file\",\"path\":\"$f\",\"secret\":\"$secret\",\"owner\":\"$owner\"}")
    fi
done

# Method 4: Check network connections
info "Checking network connections..."
if command -v ss >/dev/null 2>&1; then
    while IFS= read -r line; do
        port=$(echo "$line" | grep -oE ':[0-9]+' | head -1 | tr -d ':')
        pid=$(echo "$line" | grep -oP 'pid=\K[0-9]+' | head -1)
        if [ -n "$pid" ] && [ -n "$port" ]; then
            # Check if this PID is gsocket
            cmdline=$(cat "/proc/$pid/cmdline" 2>/dev/null | tr '\0' ' ')
            if echo "$cmdline" | grep -qE 'gs-netcat|defunct'; then
                results+=("{\"type\":\"network\",\"port\":$port,\"pid\":$pid}")
            fi
        fi
    done < <(ss -tlnp 2>/dev/null | grep -E 'LISTEN')
fi

# Method 5: Check crontab for gsocket entries
info "Checking crontab..."
cron_entry=$(crontab -l 2>/dev/null | grep -E 'defunct|gs-netcat|gsocket')
if [ -n "$cron_entry" ]; then
    results+=("{\"type\":\"cron\",\"entry\":\"$(echo "$cron_entry" | head -1 | sed 's/"/\\"/g')\"}")
fi

# Method 6: Check systemd services
info "Checking systemd..."
for svc in /etc/systemd/system/*.service /lib/systemd/system/*.service; do
    if [ -f "$svc" ] && grep -qE 'gs-netcat|defunct|gsocket' "$svc" 2>/dev/null; then
        results+=("{\"type\":\"systemd\",\"path\":\"$svc\"}")
    fi
done

# Method 7: Check .bashrc/.profile for gsocket
info "Checking shell profiles..."
for f in ~/.bashrc ~/.profile ~/.bash_profile /etc/profile /home/*/.bashrc /home/*/.profile; do
    if [ -f "$f" ] && grep -qE 'defunct|gs-netcat|gsocket' "$f" 2>/dev/null; then
        results+=("{\"type\":\"profile\",\"path\":\"$f\"}")
    fi
done

# Output JSON
echo -n '{"gsockets":['
first=1
for r in "${results[@]}"; do
    [ $first -eq 0 ] && echo -n ","
    echo -n "$r"
    first=0
done
echo ']}'
