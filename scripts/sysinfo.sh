#!/bin/bash
# System info - outputs JSON

user=$(whoami 2>/dev/null || echo "unknown")
uid=$(id -u 2>/dev/null || echo "0")
gid=$(id -g 2>/dev/null || echo "0")
groups=$(id -Gn 2>/dev/null | tr ' ' ',' || echo "")
hostname=$(hostname 2>/dev/null || echo "unknown")
kernel=$(uname -r 2>/dev/null || echo "unknown")
arch=$(uname -m 2>/dev/null || echo "unknown")
os=$(cat /etc/os-release 2>/dev/null | grep "^PRETTY_NAME" | cut -d'"' -f2 || echo "Linux")
uptime=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")

# Memory
mem_total=$(free -h 2>/dev/null | awk '/^Mem:/{print $2}' || echo "?")
mem_used=$(free -h 2>/dev/null | awk '/^Mem:/{print $3}' || echo "?")
mem="${mem_used}/${mem_total}"

# Disk
disk=$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2" ("$5")"}' || echo "?")

# Network
ip_addr=$(hostname -I 2>/dev/null | awk '{print $1}' || ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+' | grep -v '127.0.0.1' | head -1 || echo "?")

# Output JSON
cat << ENDJSON
{
    "user": "$user",
    "uid": "$uid",
    "gid": "$gid",
    "groups": "$groups",
    "hostname": "$hostname",
    "kernel": "$kernel",
    "arch": "$arch",
    "os": "$os",
    "uptime": "$uptime",
    "mem": "$mem",
    "disk": "$disk",
    "ip": "$ip_addr"
}
ENDJSON
