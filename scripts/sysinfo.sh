#!/bin/bash
# System Information Script - No fancy formatting to avoid shell errors

user=$(whoami 2>/dev/null || echo "unknown")
uid=$(id -u 2>/dev/null || echo "0")
hostname=$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "unknown")
kernel=$(uname -r 2>/dev/null || echo "unknown")
arch=$(uname -m 2>/dev/null || echo "unknown")

# Uptime - simple format
uptime_raw=$(cat /proc/uptime 2>/dev/null | cut -d. -f1)
if [ -n "$uptime_raw" ]; then
    days=$((uptime_raw / 86400))
    hours=$(((uptime_raw % 86400) / 3600))
    uptime="${days}d ${hours}h"
else
    uptime="unknown"
fi

# Memory
mem_info=$(free -h 2>/dev/null | awk '/^Mem:/{print $3"/"$2}')
if [ -z "$mem_info" ]; then
    mem_info="unknown"
fi

# Disk
disk_info=$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2}')
if [ -z "$disk_info" ]; then
    disk_info="unknown"
fi

# IP addresses
ip_addr=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ -z "$ip_addr" ]; then
    ip_addr=$(ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
fi
if [ -z "$ip_addr" ]; then
    ip_addr="unknown"
fi

# OS info
if [ -f /etc/os-release ]; then
    os=$(grep "^PRETTY_NAME=" /etc/os-release 2>/dev/null | cut -d'"' -f2)
fi
if [ -z "$os" ]; then
    os=$(uname -s 2>/dev/null || echo "unknown")
fi

# Output JSON - escape special characters
cat << EOJSON
{
    "user": "$user",
    "uid": "$uid",
    "hostname": "$hostname",
    "kernel": "$kernel",
    "arch": "$arch",
    "uptime": "$uptime",
    "mem": "$mem_info",
    "disk": "$disk_info",
    "ip": "$ip_addr",
    "os": "$os"
}
EOJSON
