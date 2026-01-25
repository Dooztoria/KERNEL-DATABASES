#!/bin/bash
hostname=$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "unknown")
ip=$(hostname -I 2>/dev/null | awk '{print $1}' || ip route get 1 2>/dev/null | awk '{print $7}' | head -1)
kernel=$(uname -r 2>/dev/null)
arch=$(uname -m 2>/dev/null)
user=$(whoami 2>/dev/null)
uid=$(id -u 2>/dev/null)
groups=$(id -Gn 2>/dev/null | tr ' ' ',')
uptime=$(uptime -p 2>/dev/null | sed 's/up //' || uptime | awk -F'( |,|:)+' '{print $6"h"$7"m"}')
mem=$(free -h 2>/dev/null | awk '/Mem:/{print $3"/"$2}')
disk=$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2}')
cpu=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "?")
os=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || uname -o)

cat << EOF
{"hostname":"$hostname","ip":"$ip","kernel":"$kernel","arch":"$arch","user":"$user","uid":"$uid","groups":"$groups","uptime":"$uptime","mem":"$mem","disk":"$disk","cpu":"$cpu","os":"$os"}
EOF
