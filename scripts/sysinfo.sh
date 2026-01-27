#!/bin/bash
# Simple sysinfo - robust version

user=$(whoami 2>/dev/null || id -un 2>/dev/null || echo "unknown")
uid=$(id -u 2>/dev/null || echo "0")
hostname=$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "target")
kernel=$(uname -r 2>/dev/null || echo "unknown")

# Uptime
if [ -f /proc/uptime ]; then
    sec=$(cut -d. -f1 /proc/uptime 2>/dev/null)
    if [ -n "$sec" ]; then
        d=$((sec/86400))
        h=$(((sec%86400)/3600))
        uptime="${d}d ${h}h"
    else
        uptime="unknown"
    fi
else
    uptime="unknown"
fi

# Memory - simpler
if command -v free >/dev/null 2>&1; then
    mem=$(free -h 2>/dev/null | awk '/^Mem:/{print $3"/"$2}')
else
    mem="unknown"
fi
[ -z "$mem" ] && mem="unknown"

# Disk
if command -v df >/dev/null 2>&1; then
    disk=$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2}')
else
    disk="unknown"
fi
[ -z "$disk" ] && disk="unknown"

# Output clean JSON
printf '{"user":"%s","uid":"%s","hostname":"%s","kernel":"%s","uptime":"%s","mem":"%s","disk":"%s"}\n' \
    "$user" "$uid" "$hostname" "$kernel" "$uptime" "$mem" "$disk"
