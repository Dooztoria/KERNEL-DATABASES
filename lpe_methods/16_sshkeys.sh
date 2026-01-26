#!/bin/bash
source "$(dirname "$0")/00_common.sh"
METHOD="sshkeys"
info "Checking SSH keys..."
found=""
for key in /home/*/.ssh/id_rsa /root/.ssh/id_rsa /home/*/.ssh/id_ed25519; do
    [ -r "$key" ] 2>/dev/null && { found="$found $key"; }
done
[ -n "$found" ] && { result_json "$METHOD" "found" "Keys:$found" ""; exit 0; }
# Check writable authorized_keys
for ak in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do
    [ -w "$ak" ] 2>/dev/null && { result_json "$METHOD" "partial" "Writable: $ak" ""; exit 0; }
done
result_json "$METHOD" "skip" "No SSH access"; exit 1
