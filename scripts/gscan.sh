#!/bin/bash
# GSSocket Hunter

declare -a procs secrets

# Process scan
for pid in /proc/[0-9]*; do
    [ -r "$pid/cmdline" ] || continue
    p=$(basename "$pid")
    cmd=$(tr '\0' ' ' < "$pid/cmdline" 2>/dev/null)
    exe=$(readlink "$pid/exe" 2>/dev/null)
    
    if echo "$cmd$exe" | grep -qiE 'gs-netcat|defunct|gsocket'; then
        user=$(stat -c '%U' "$pid" 2>/dev/null)
        secret=$(echo "$cmd" | grep -oE '\-s [^ ]+' | awk '{print $2}')
        procs+=("$p|$user|$secret")
    fi
done

# Secret files
while IFS= read -r f; do
    [ -f "$f" ] || continue
    sec=$(head -c 50 "$f" 2>/dev/null | tr -d '\n')
    owner=$(stat -c '%U' "$f" 2>/dev/null)
    secrets+=("$f|$sec|$owner")
done < <(find /tmp /dev/shm /var/www /home -name "*.dat" -o -name "defunct.dat" 2>/dev/null | head -20)

# Output JSON
echo -n '{"gsockets":['
first=1

for p in "${procs[@]}"; do
    IFS='|' read -r pid user secret <<< "$p"
    [ $first -eq 0 ] && echo -n ','
    echo -n "{\"type\":\"process\",\"pid\":$pid,\"user\":\"$user\",\"secret\":\"$secret\"}"
    first=0
done

for s in "${secrets[@]}"; do
    IFS='|' read -r path secret owner <<< "$s"
    [ $first -eq 0 ] && echo -n ','
    # Escape path for JSON
    path=$(echo "$path" | sed 's/"/\\"/g')
    echo -n "{\"type\":\"secret_file\",\"path\":\"$path\",\"secret\":\"$secret\",\"owner\":\"$owner\"}"
    first=0
done

echo ']}'
